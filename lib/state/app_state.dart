import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/const.dart';
import '../services/auth_service.dart';
import '../services/github_service.dart';

class ActivityEntry {
  final DateTime time;
  final String type; // L10n key e.g. 'act_login', 'act_save_secrets'
  final String detail; // Safe non-sensitive detail e.g. repo fullName or run ID
  final bool ok;

  ActivityEntry(this.time, this.type, this.ok, {this.detail = ''});

  /// Backwards-compatible getter for legacy callers.
  String get text => detail.isEmpty ? type : '$type • $detail';

  Map<String, dynamic> toJson() => {
        't': time.toIso8601String(),
        'k': type,
        'd': detail,
        'x': text,
        'ok': ok,
      };

  static ActivityEntry fromJson(Map<String, dynamic> j) {
    final time = DateTime.tryParse(j['t'] as String? ?? '') ?? DateTime.now();
    final ok = j['ok'] as bool? ?? true;
    final k = j['k'] as String?;
    final d = j['d'] as String? ?? '';
    if (k != null && k.isNotEmpty) {
      return ActivityEntry(time, k, ok, detail: d);
    }
    // Migrate legacy raw text entries cleanly
    final raw = j['x'] as String? ?? '';
    if (raw.startsWith('login')) {
      return ActivityEntry(time, 'act_login', ok);
    } else if (raw.startsWith('logout')) {
      return ActivityEntry(time, 'act_logout', ok);
    } else if (raw.startsWith('repo:')) {
      return ActivityEntry(time, 'act_select_repo', ok, detail: raw.substring(5));
    } else if (raw.contains('secret')) {
      return ActivityEntry(time, 'act_save_secrets', ok);
    } else if (raw.startsWith('dispatch')) {
      return ActivityEntry(time, 'act_start_run', ok, detail: raw.replaceFirst('dispatch ', ''));
    } else if (raw.startsWith('cancel')) {
      return ActivityEntry(time, 'act_stop_run', ok, detail: raw);
    }
    return ActivityEntry(time, raw, ok);
  }
}

class RepoReadiness {
  final bool checking;
  final bool hasWorkflow;
  final bool workflowNeedsRepair;
  final bool hasRequiredSecrets;
  final bool hasTailscaleSecret;
  final bool secretsPermissionDenied;

  const RepoReadiness({
    this.checking = false,
    this.hasWorkflow = false,
    this.workflowNeedsRepair = false,
    this.hasRequiredSecrets = false,
    this.hasTailscaleSecret = false,
    this.secretsPermissionDenied = false,
  });

  bool get isFullyReady => hasWorkflow && !workflowNeedsRepair && hasRequiredSecrets;
}

class AppState extends ChangeNotifier {
  final AuthService auth = AuthService();
  GitHubService? api;

  // session
  String? token;
  Map<String, dynamic>? user;
  List<Repo> repos = [];
  String? reposError;
  Repo? selectedRepo;
  String? workflowFile;
  bool workflowNeedsRepair = false;
  List<String> secretNames = [];
  bool secretsPermissionDenied = false;
  String? secretsError;
  final Map<String, RepoReadiness> repoReadiness = {};

  // live dashboard & backups state
  Map<String, dynamic>? latestRunData;
  List<BackupInfo>? backupsList;
  bool backupsBusy = false;
  String? backupsError;
  bool backupsPermissionDenied = false;

  // active run
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
  int currentTab = 0;
  List<ActivityEntry> activity = [];
  bool busy = false;
  bool statusBusy = false;
  bool initialized = false;
  bool justLoggedIn = false;

  void setTab(int index) {
    if (currentTab == index) return;
    currentTab = index;
    notifyListeners();
  }

  void setJustLoggedIn(bool v) {
    justLoggedIn = v;
    notifyListeners();
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    lang = prefs.getString('lang') ?? 'ar';
    activity = (prefs.getStringList('activity') ?? [])
        .map((e) {
          try {
            return ActivityEntry.fromJson(jsonDecode(e) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<ActivityEntry>()
        .toList();

    final savedRepoJson = prefs.getString('selected_repo_json');
    if (savedRepoJson != null && savedRepoJson.isNotEmpty) {
      try {
        selectedRepo = Repo.fromJson(jsonDecode(savedRepoJson) as Map<String, dynamic>);
      } catch (_) {
        selectedRepo = null;
      }
    }

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
      if (_sessionEpoch == epoch) {
        user = freshUser;
        // Refresh repositories and selected repo status in the background
        unawaited(loadRepos());
        if (selectedRepo != null) {
          unawaited(selectRepo(selectedRepo!, silentLog: true));
        }
      }
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

  /// Direct sign-in using a user-provided GitHub Personal Access Token (PAT).
  /// Stored only in the device's secure keystore; never embedded in the APK.
  Future<String?> signInWithPersonalToken(String rawToken) async {
    final trimmed = rawToken.trim();
    if (trimmed.isEmpty) return 'Token is empty';
    authError = null;
    authBusy = true;
    notifyListeners();
    try {
      final probe = GitHubService(trimmed);
      final freshUser = await probe.getUser();
      await auth.saveTokenSet(TokenSet(accessToken: trimmed));
      token = trimmed;
      api = GitHubService(trimmed, onUnauthorized: renewToken);
      user = freshUser;
      await log('act_login', true, detail: '@${freshUser['login'] ?? ''}');
      justLoggedIn = true;
      unawaited(loadRepos());
      notifyListeners();
      return null;
    } on GhException catch (e) {
      final msg = e.status == 401
          ? 'Invalid or expired GitHub token (HTTP 401).'
          : e.friendlyMessage;
      await _failLogin(msg);
      return msg;
    } catch (e) {
      await _failLogin('$e');
      return '$e';
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
    if (raw.startsWith('ghp_') || raw.startsWith('github_pat_') || raw.startsWith('ghu_') || raw.startsWith('gho_')) {
      return signInWithPersonalToken(raw);
    }
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
    final loginName = user?['login'] as String? ?? '';
    await log('act_login', true, detail: loginName.isNotEmpty ? '@$loginName' : '');
    justLoggedIn = true;
    unawaited(loadRepos());
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
      await _forgetSession();
      notifyListeners();
      return null;
    }
  }

  Future<void> _failLogin(String message) async {
    authError = message;
    await log('act_login', false, detail: _sanitizeLogDetail(message));
    notifyListeners();
  }

  Future<void> _forgetSession() async {
    _sessionEpoch++;
    token = null;
    api = null;
    user = null;
    selectedRepo = null;
    repos = [];
    reposError = null;
    workflowFile = null;
    workflowNeedsRepair = false;
    secretNames = [];
    secretsPermissionDenied = false;
    secretsError = null;
    repoReadiness.clear();
    latestRunData = null;
    backupsList = null;
    backupsError = null;
    backupsPermissionDenied = false;
    runId = null;
    sessionInfo = null;
    inMemoryAccessPassword = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('selected_repo_json');
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
    currentTab = 0;
    await log('act_logout', true);
    notifyListeners();
  }

  // ── repos ─────────────────────────────────────────────────────────────────

  Future<void> loadRepos() async {
    if (api == null) return;
    busy = true;
    reposError = null;
    notifyListeners();
    try {
      repos = await api!.listRepos();
      // Keep selectedRepo in sync with updated repo metadata if present
      if (selectedRepo != null) {
        for (final r in repos) {
          if (r.fullName == selectedRepo!.fullName) {
            selectedRepo = r;
            break;
          }
        }
      }
      unawaited(_probeAllReposReadiness());
    } on GhException catch (e) {
      reposError = e.friendlyMessage;
    } catch (e) {
      reposError = '$e';
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _probeAllReposReadiness() async {
    final currentApi = api;
    if (currentApi == null) return;
    final snapshot = List<Repo>.from(repos);

    for (final r in snapshot) {
      repoReadiness[r.fullName] = RepoReadiness(
        checking: true,
        hasWorkflow: repoReadiness[r.fullName]?.hasWorkflow ?? false,
        workflowNeedsRepair: repoReadiness[r.fullName]?.workflowNeedsRepair ?? false,
        hasRequiredSecrets: repoReadiness[r.fullName]?.hasRequiredSecrets ?? false,
        hasTailscaleSecret: repoReadiness[r.fullName]?.hasTailscaleSecret ?? false,
      );
    }
    notifyListeners();

    // Probe in small batches of 4 to avoid rate limits while keeping UI snappy
    const batchSize = 4;
    for (var i = 0; i < snapshot.length; i += batchSize) {
      if (api != currentApi) return;
      final chunk = snapshot.skip(i).take(batchSize);
      await Future.wait(chunk.map((r) => _probeSingleRepo(r)));
      notifyListeners();
    }

    // If no repo is selected yet and we found a ready/workflow repo, auto-select it
    if (selectedRepo == null && repos.isNotEmpty) {
      Repo? candidate;
      for (final r in repos) {
        final rd = repoReadiness[r.fullName];
        if (rd != null && rd.isFullyReady) {
          candidate = r;
          break;
        }
      }
      if (candidate == null) {
        for (final r in repos) {
          final rd = repoReadiness[r.fullName];
          if (rd != null && rd.hasWorkflow) {
            candidate = r;
            break;
          }
        }
      }
      if (candidate != null) {
        await selectRepo(candidate, silentLog: true);
      }
    }
  }

  Future<RepoReadiness> _probeSingleRepo(Repo r) async {
    final currentApi = api;
    if (currentApi == null) return const RepoReadiness();
    try {
      final wf = await currentApi.inspectWorkflow(r.fullName);
      SecretsCheckResult sec = const SecretsCheckResult(names: []);
      if (wf.exists) {
        sec = await currentApi.checkSecrets(r.fullName);
      }
      final readiness = RepoReadiness(
        checking: false,
        hasWorkflow: wf.exists,
        workflowNeedsRepair: wf.needsRepair,
        hasRequiredSecrets: sec.names.contains(Const.secretAccess) && sec.names.contains(Const.secretBackup),
        hasTailscaleSecret: sec.names.contains(Const.secretTailscale),
        secretsPermissionDenied: sec.permissionDenied,
      );
      repoReadiness[r.fullName] = readiness;
      return readiness;
    } catch (_) {
      const readiness = RepoReadiness(checking: false);
      repoReadiness[r.fullName] = readiness;
      return readiness;
    }
  }

  Future<void> selectRepo(Repo r, {bool silentLog = false}) async {
    selectedRepo = r;
    statusBusy = true;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_repo_json', jsonEncode(r.toJson()));

    if (!silentLog) {
      await log('act_select_repo', true, detail: r.fullName);
    }

    await refreshSelectedRepoStatus();
  }

  /// Refreshes workflow status, secrets, latest run, and backups for [selectedRepo].
  Future<void> refreshSelectedRepoStatus() async {
    final r = selectedRepo;
    final currentApi = api;
    if (r == null || currentApi == null) {
      statusBusy = false;
      notifyListeners();
      return;
    }

    statusBusy = true;
    secretsError = null;
    notifyListeners();

    try {
      final wfFuture = currentApi.inspectWorkflow(r.fullName);
      final secFuture = currentApi.checkSecrets(r.fullName);
      final runFuture = currentApi.latestRun(r.fullName).catchError((_) => null);

      final wf = await wfFuture;
      final sec = await secFuture;
      final latestRun = await runFuture;

      workflowFile = wf.exists ? (wf.workflowFile ?? Const.workflowFile) : null;
      workflowNeedsRepair = wf.needsRepair;
      secretNames = sec.names;
      secretsPermissionDenied = sec.permissionDenied;
      secretsError = sec.error;
      latestRunData = latestRun;

      repoReadiness[r.fullName] = RepoReadiness(
        checking: false,
        hasWorkflow: wf.exists,
        workflowNeedsRepair: wf.needsRepair,
        hasRequiredSecrets: secretsReady,
        hasTailscaleSecret: hasTailscaleSecret,
        secretsPermissionDenied: sec.permissionDenied,
      );

      // Update active run state if a run is currently in progress or queued
      final status = latestRun?['status'] as String? ?? '';
      if (status == 'in_progress' || status == 'queued' || status == 'waiting') {
        runId = latestRun!['id'] as int?;
        final startedStr = latestRun['run_started_at'] as String? ?? latestRun['created_at'] as String? ?? '';
        runStartedAt = DateTime.tryParse(startedStr) ?? runStartedAt;
        if (runId != null) {
          sessionInfo = await currentApi.sessionInfo(r.fullName, runId!);
        }
      } else {
        runId = null;
        sessionInfo = null;
      }
    } catch (_) {
      // handled per field
    } finally {
      statusBusy = false;
      notifyListeners();
    }

    unawaited(loadBackups());
  }

  Future<Repo> createAndSetupRepo(
    String name, {
    required bool isPrivate,
    bool installWorkflow = true,
  }) async {
    try {
      final repo = await api!.createRepo(name, isPrivate: isPrivate);
      await log('act_create_repo', true, detail: repo.fullName);
      if (installWorkflow) {
        final yaml = await rootBundle.loadString('assets/windows11.yml');
        await api!.createWorkflowFile(repo.fullName, repo.defaultBranch, yaml);
        await log('act_install_workflow', true, detail: repo.fullName);
      }
      await loadRepos();
      await selectRepo(repo, silentLog: true);
      return repo;
    } catch (e) {
      await log('act_create_repo', false, detail: '$name (${_sanitizeLogDetail('$e')})');
      rethrow;
    }
  }

  Future<void> installOrRepairWorkflow({Repo? target}) async {
    final r = target ?? selectedRepo;
    if (r == null || api == null) return;
    try {
      final yaml = await rootBundle.loadString('assets/windows11.yml');
      await api!.createWorkflowFile(r.fullName, r.defaultBranch, yaml);
      await log('act_install_workflow', true, detail: r.fullName);
      if (selectedRepo?.fullName == r.fullName) {
        await refreshSelectedRepoStatus();
      } else {
        await _probeSingleRepo(r);
        notifyListeners();
      }
    } catch (e) {
      await log('act_install_workflow', false, detail: '${r.fullName} (${_sanitizeLogDetail('$e')})');
      rethrow;
    }
  }

  bool get repoReady => workflowFile != null && !workflowNeedsRepair;
  bool get hasWorkflowFile => workflowFile != null;
  bool get hasAccessSecret => secretNames.contains(Const.secretAccess);
  bool get hasBackupSecret => secretNames.contains(Const.secretBackup);
  bool get hasTailscaleSecret => secretNames.contains(Const.secretTailscale);
  bool get secretsReady => hasAccessSecret && hasBackupSecret;

  bool get isLiveRunActive {
    final st = latestRunData?['status'] as String? ?? '';
    return st == 'in_progress' || st == 'queued' || st == 'waiting';
  }

  BackupInfo? get latestCompleteBackup {
    final list = backupsList;
    if (list == null || list.isEmpty) return null;
    for (final b in list) {
      if (b.complete) return b;
    }
    return null;
  }

  Future<void> saveSecrets({
    required String access,
    required String backup,
    String? tailscale,
  }) async {
    final r = selectedRepo;
    if (r == null) {
      throw StateError('No repository selected');
    }
    final toSave = <String, String>{};
    if (access.trim().isNotEmpty) {
      toSave[Const.secretAccess] = access.trim();
    }
    if (backup.trim().isNotEmpty) {
      toSave[Const.secretBackup] = backup.trim();
    }
    if (tailscale != null && tailscale.trim().isNotEmpty) {
      toSave[Const.secretTailscale] = tailscale.trim();
    }
    if (toSave.isEmpty) {
      throw ArgumentError('No secret values provided');
    }

    try {
      final confirmedNames = await api!.putSecretsVerified(r.fullName, toSave);
      secretNames = confirmedNames;
      secretsPermissionDenied = false;
      secretsError = null;
      if (access.trim().isNotEmpty) {
        inMemoryAccessPassword = access.trim();
      }
      repoReadiness[r.fullName] = RepoReadiness(
        checking: false,
        hasWorkflow: workflowFile != null,
        workflowNeedsRepair: workflowNeedsRepair,
        hasRequiredSecrets: secretsReady,
        hasTailscaleSecret: hasTailscaleSecret,
        secretsPermissionDenied: false,
      );
      await log('act_save_secrets', true, detail: '${r.fullName} (${toSave.keys.join(', ')})');
      notifyListeners();
    } on GhException catch (e) {
      if (e.isPermissionError) {
        secretsPermissionDenied = true;
      }
      secretsError = e.friendlyMessage;
      await log('act_save_secrets', false, detail: '${r.fullName} (HTTP ${e.status})');
      notifyListeners();
      rethrow;
    } catch (e) {
      await log('act_save_secrets', false, detail: r.fullName);
      notifyListeners();
      rethrow;
    }
  }

  // ── backups ───────────────────────────────────────────────────────────────

  Future<void> loadBackups() async {
    final r = selectedRepo;
    final currentApi = api;
    if (r == null || currentApi == null) return;

    backupsBusy = true;
    backupsError = null;
    backupsPermissionDenied = false;
    notifyListeners();

    try {
      backupsList = await currentApi.backups(r.fullName);
    } on GhException catch (e) {
      backupsPermissionDenied = e.isPermissionError;
      backupsError = e.friendlyMessage;
      backupsList = null;
    } catch (e) {
      backupsError = '$e';
      backupsList = null;
    } finally {
      backupsBusy = false;
      notifyListeners();
    }
  }

  // ── runs ──────────────────────────────────────────────────────────────────

  Future<void> startRun({
    required int hours,
    required bool fresh,
    bool isRestore = false,
  }) async {
    final r = selectedRepo;
    if (r == null || api == null) {
      throw StateError('No repository selected');
    }
    final actionKey = isRestore ? 'act_restore_backup' : 'act_start_run';

    try {
      // Automatically install or repair `.github/workflows/windows11.yml` if missing or outdated!
      if (workflowFile == null || workflowNeedsRepair) {
        final yaml = await rootBundle.loadString('assets/windows11.yml');
        await api!.createWorkflowFile(r.fullName, r.defaultBranch, yaml);
        workflowFile = Const.workflowFile;
        workflowNeedsRepair = false;
        await log('act_install_workflow', true, detail: r.fullName);
      }

      dispatchedHours = hours;
      runStartedAt = DateTime.now().toUtc();
      runId = null;
      sessionInfo = null;

      await api!.dispatch(
        r.fullName,
        workflowFile ?? Const.workflowFile,
        hours: hours,
        fresh: fresh,
        branch: r.defaultBranch,
      );
      await log(actionKey, true, detail: '${r.fullName} (${hours}h)');
      notifyListeners();
    } catch (e) {
      await log(actionKey, false, detail: '${r.fullName} (${_sanitizeLogDetail('$e')})');
      notifyListeners();
      rethrow;
    }
  }

  /// Requests a graceful stop & backup save via release signal when Windows is
  /// running, or cancels the workflow run when [forceCancel] is true.
  Future<void> stopOrCancelCurrentRun({bool forceCancel = false}) async {
    final r = selectedRepo;
    final id = runId;
    if (r == null || id == null || api == null) return;

    try {
      if (forceCancel) {
        await api!.cancelRun(r.fullName, id);
      } else {
        try {
          await api!.requestGracefulStop(r.fullName, id);
        } catch (_) {
          await api!.cancelRun(r.fullName, id);
        }
      }
      await log('act_stop_run', true, detail: '${r.fullName} (#$id)');
      notifyListeners();
    } catch (e) {
      await log('act_stop_run', false, detail: '${r.fullName} (#$id)');
      rethrow;
    }
  }

  Future<void> cancelCurrentRun() => stopOrCancelCurrentRun(forceCancel: false);

  // ── activity ──────────────────────────────────────────────────────────────

  String _sanitizeLogDetail(String input) {
    var s = input;
    // Strip any accidental token-like patterns
    s = s.replaceAll(RegExp(r'gh[pousr]_[A-Za-z0-9_]+'), '[REDACTED]');
    s = s.replaceAll(RegExp(r'github_pat_[A-Za-z0-9_]+'), '[REDACTED]');
    s = s.replaceAll(RegExp(r'tskey-[A-Za-z0-9_-]+'), '[REDACTED]');
    if (s.length > 100) s = '${s.substring(0, 100)}…';
    return s;
  }

  Future<void> log(String type, bool ok, {String detail = ''}) async {
    final safeDetail = _sanitizeLogDetail(detail);
    activity.insert(0, ActivityEntry(DateTime.now(), type, ok, detail: safeDetail));
    if (activity.length > 100) activity = activity.sublist(0, 100);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('activity', activity.map((e) => jsonEncode(e.toJson())).toList());
    notifyListeners();
  }

  Future<void> clearActivity() async {
    activity.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('activity');
    notifyListeners();
  }
}
