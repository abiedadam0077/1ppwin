import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/const.dart';
import '../services/auth_service.dart';
import '../services/github_service.dart';

class ActivityEntry {
  final DateTime time;
  final String text;
  final bool ok;
  ActivityEntry(this.time, this.text, this.ok);

  Map<String, dynamic> toJson() => {'t': time.toIso8601String(), 'x': text, 'ok': ok};
  static ActivityEntry fromJson(Map<String, dynamic> j) =>
      ActivityEntry(DateTime.tryParse(j['t'] as String? ?? '') ?? DateTime.now(), j['x'] as String? ?? '', j['ok'] as bool? ?? true);
}

class AppState extends ChangeNotifier {
  final AuthService auth = AuthService();
  GitHubService? api;

  // session
  String? token;
  Map<String, dynamic>? user;
  List<Repo> repos = [];
  Repo? selectedRepo;
  String? workflowFile;
  List<String> secretNames = [];

  // run
  int? runId;
  DateTime? runStartedAt;
  int dispatchedHours = 4;
  SessionInfo? sessionInfo;

  /// Only kept in RAM so the Ready screen can reveal/copy it. Never persisted.
  String? inMemoryAccessPassword;

  // sign-in
  String? authError;
  bool authBusy = false;
  DeviceCode? deviceCode;
  bool deviceWaiting = false;
  bool clientSecretSaved = false;
  bool _deviceCancelled = false;
  String? _lastCode;
  final Set<String> _usedCodes = {};

  /// Bumped whenever the session changes, so a slow `init()` never overwrites
  /// a sign-in that finished while it was still loading.
  int _sessionEpoch = 0;

  // ui
  String lang = 'ar';
  List<ActivityEntry> activity = [];
  bool busy = false;
  bool initialized = false;
  bool justLoggedIn = false;

  void setJustLoggedIn(bool v) {
    justLoggedIn = v;
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    lang = prefs.getString('lang') ?? 'ar';
    activity = (prefs.getStringList('activity') ?? [])
        .map((e) => ActivityEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    clientSecretSaved = (await auth.storedClientSecret() ?? '').isNotEmpty;
    await _restoreSession();
    initialized = true;
    notifyListeners();
  }

  /// Reuses a stored token, refreshing it first when it is about to expire.
  Future<void> _restoreSession() async {
    final stored = await auth.storedToken();
    if (stored == null || stored.isEmpty) return;
    final epoch = _sessionEpoch;

    api = GitHubService(stored, onUnauthorized: renewToken);
    token = stored;

    final expiry = await auth.storedExpiry();
    if (_sessionEpoch != epoch) return;
    final nowSeconds = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    if (expiry != null && expiry - nowSeconds < 120) {
      try {
        final renewed = await renewToken();
        if (_sessionEpoch != epoch) return;
        if (renewed == null) {
          // Expiring token without a usable refresh token: ask to sign in again.
          await _forgetSession();
          return;
        }
      } on AuthException {
        await _forgetSession();
        return;
      } catch (_) {
        // Network problem: keep the session and let the UI retry later.
      }
    }

    try {
      final freshUser = await api!.getUser();
      if (_sessionEpoch == epoch) user = freshUser;
    } on GhException catch (e) {
      if (e.status == 401) {
        if (_sessionEpoch == epoch) await _forgetSession();
        return;
      }
      if (_sessionEpoch == epoch) user = null;
    } catch (_) {
      if (_sessionEpoch == epoch) user = null;
    }
  }

  Future<void> setLang(String l) async {
    lang = l;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', l);
    notifyListeners();
  }

  Locale get locale => Locale(lang);

  // ── auth ──────────────────────────────────────────────────────────────────

  /// Device flow: shows a code the user confirms in the browser. Uses no
  /// client secret and no deep link, so it works on every Android device.
  Future<void> startDeviceLogin() async {
    if (deviceWaiting || authBusy) return;
    authError = null;
    deviceCode = null;
    authBusy = true;
    _deviceCancelled = false;
    notifyListeners();

    try {
      final code = await auth.requestDeviceCode();
      deviceCode = code;
      deviceWaiting = true;
      notifyListeners();

      final tokens = await auth.pollDeviceToken(code, cancelled: () => _deviceCancelled);
      if (tokens != null) {
        await _acceptTokens(tokens);
      }
    } on AuthException catch (e) {
      await _failLogin(e.message);
    } catch (e) {
      await _failLogin('$e');
    } finally {
      authBusy = false;
      deviceWaiting = false;
      notifyListeners();
    }
  }

  void cancelDeviceLogin() {
    _deviceCancelled = true;
    deviceWaiting = false;
    notifyListeners();
  }

  /// Web application flow (advanced): opens GitHub in the browser and comes
  /// back through the novawindowscloud:// deep link.
  Future<void> startLogin() async {
    if (authBusy) return;
    authError = null;
    authBusy = true;
    notifyListeners();
    try {
      final (uri, verifier, state) = await auth.authorizeUrlWithVerifier();
      await auth.savePendingLogin(verifier, state);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw AuthException('Could not open the browser. Please try again.');
      }
    } on AuthException catch (e) {
      await _failLogin(e.message);
    } catch (e) {
      await _failLogin('$e');
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  /// Called with the novawindowscloud://oauth/callback?... deep link.
  /// Returns an error message for the UI, or null on success/ignored link.
  Future<String?> handleCallback(Uri uri) async {
    final error = uri.queryParameters['error'];
    if (error != null && error.isNotEmpty) {
      final message = friendlyAuthError(error, uri.queryParameters['error_description']);
      await _failLogin(message);
      return message;
    }

    final code = uri.queryParameters['code'];
    if (code == null || code.isEmpty) {
      final message =
          'GitHub did not return a sign-in code. Check that the GitHub App callback URL is exactly ${Const.redirectUri}.';
      await _failLogin(message);
      return message;
    }
    if (_usedCodes.contains(code)) return null;

    final pending = await auth.pendingLogin();
    if (pending == null) {
      const message = 'The sign-in request is no longer available. Please start the sign-in again.';
      await _failLogin(message);
      return message;
    }
    final (verifier, storedState) = pending;
    final state = uri.queryParameters['state'];
    if (storedState != null && state != null && state != storedState) {
      const message = 'The sign-in response could not be verified (state mismatch). Please try again.';
      await _failLogin(message);
      return message;
    }
    return _exchange(code, verifier);
  }

  /// Retries the last callback after the user added the client secret.
  Future<void> retryExchange() async {
    final code = _lastCode;
    final pending = await auth.pendingLogin();
    if (code == null || pending == null) {
      authError = null;
      notifyListeners();
      return;
    }
    authError = null;
    notifyListeners();
    await _exchange(code, pending.$1);
  }

  /// Escape hatch when the deep link never reaches the app: the user pastes the
  /// callback URL (or the bare `code`) by hand.
  Future<String?> submitManualInput(String text) async {
    final raw = text.trim();
    if (raw.isEmpty) return 'empty';
    if (raw.startsWith('novawindowscloud://')) {
      return handleCallback(Uri.parse(raw));
    }
    var value = raw;
    final marker = raw.indexOf('code=');
    if (marker >= 0) {
      value = raw.substring(marker + 'code='.length);
      final amp = value.indexOf('&');
      if (amp >= 0) value = value.substring(0, amp);
      value = Uri.decodeComponent(value);
    }
    return handleCallback(Uri.parse('${Const.redirectUri}?code=${Uri.encodeComponent(value)}'));
  }

  Future<void> saveClientSecret(String value) async {
    await auth.saveClientSecret(value);
    clientSecretSaved = value.trim().isNotEmpty;
    notifyListeners();
  }

  Future<void> openDevicePage() async {
    final code = deviceCode;
    if (code == null) return;
    await launchUrl(Uri.parse(code.verificationUri), mode: LaunchMode.externalApplication);
  }

  Future<String?> _exchange(String code, String verifier) async {
    // Remembered up-front: the same callback can arrive twice (cold-start link
    // + stream) and the code is only valid for a single exchange.
    _usedCodes.add(code);
    authBusy = true;
    _lastCode = code;
    notifyListeners();
    try {
      final tokens = await auth.exchangeCode(code, verifier);
      _lastCode = null;
      await _acceptTokens(tokens);
      return null;
    } on AuthException catch (e) {
      await _failLogin(e.message);
      return e.message;
    } catch (e) {
      await _failLogin('$e');
      return '$e';
    } finally {
      authBusy = false;
      notifyListeners();
    }
  }

  Future<void> _acceptTokens(TokenSet tokens) async {
    await auth.saveTokenSet(tokens);
    token = tokens.accessToken;
    api = GitHubService(token!, onUnauthorized: renewToken);
    await auth.clearPendingLogin();
    _lastCode = null;
    authError = null;
    await refreshUser();
    await log('login', true);
    justLoggedIn = true;
    notifyListeners();
  }

  /// Renews an expiring access token. Returns null when there is no refresh
  /// token at all; throws [AuthException] when GitHub rejects the refresh.
  Future<String?> renewToken() async {
    final refreshToken = await auth.storedRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;
    try {
      final tokens = await auth.refresh(refreshToken);
      await auth.saveTokenSet(tokens);
      token = tokens.accessToken;
      return token;
    } on AuthException {
      // GitHub rejected the refresh token: drop the session so the user lands
      // on the sign-in screen instead of on failing API calls.
      await _forgetSession();
      notifyListeners();
      return null;
    }
  }

  Future<void> _failLogin(String message) async {
    authError = message;
    await log('login: $message', false);
    notifyListeners();
  }

  Future<void> _forgetSession() async {
    _sessionEpoch++;
    token = null;
    api = null;
    user = null;
    selectedRepo = null;
    repos = [];
    workflowFile = null;
    secretNames = [];
    runId = null;
    sessionInfo = null;
    await auth.clearAll();
  }

  Future<void> refreshUser() async {
    try {
      user = await api!.getUser();
    } catch (_) {
      user = null;
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _forgetSession();
    justLoggedIn = false;
    await log('logout', true);
    notifyListeners();
  }

  // ── repos ─────────────────────────────────────────────────────────────────

  Future<void> loadRepos() async {
    busy = true;
    notifyListeners();
    try {
      repos = await api!.listRepos();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> selectRepo(Repo r) async {
    selectedRepo = r;
    workflowFile = null;
    secretNames = [];
    notifyListeners();
    workflowFile = await api!.findWindowsWorkflow(r.fullName);
    secretNames = await api!.listSecretNames(r.fullName);
    log('repo:${r.fullName}', true);
    notifyListeners();
  }

  bool get repoReady => workflowFile != null;
  bool get secretsReady =>
      secretNames.contains('ACCESS_PASSWORD') && secretNames.contains('BACKUP_PASSWORD');

  Future<void> saveSecrets({
    required String access,
    required String backup,
    String? tailscale,
  }) async {
    final r = selectedRepo!;
    await api!.putSecret(r.fullName, 'ACCESS_PASSWORD', access);
    await api!.putSecret(r.fullName, 'BACKUP_PASSWORD', backup);
    if (tailscale != null && tailscale.isNotEmpty) {
      await api!.putSecret(r.fullName, 'TAILSCALE_AUTHKEY', tailscale);
    }
    secretNames = await api!.listSecretNames(r.fullName);
    log('secrets saved', true);
    notifyListeners();
  }

  // ── runs ──────────────────────────────────────────────────────────────────

  Future<void> startRun({required int hours, required bool fresh}) async {
    dispatchedHours = hours;
    runStartedAt = DateTime.now().toUtc();
    runId = null;
    sessionInfo = null;
    await api!.dispatch(selectedRepo!.fullName, workflowFile!, hours: hours, fresh: fresh);
    log('dispatch ${selectedRepo!.fullName} (${hours}h)', true);
    notifyListeners();
  }

  Future<void> cancelCurrentRun() async {
    if (runId == null) return;
    await api!.cancelRun(selectedRepo!.fullName, runId!);
    log('cancel run #$runId', true);
    notifyListeners();
  }

  // ── activity ──────────────────────────────────────────────────────────────

  Future<void> log(String text, bool ok) async {
    activity.insert(0, ActivityEntry(DateTime.now(), text, ok));
    if (activity.length > 100) activity = activity.sublist(0, 100);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('activity', activity.map((e) => jsonEncode(e.toJson())).toList());
    notifyListeners();
  }
}
