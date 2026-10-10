import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
    token = await auth.storedToken();
    if (token != null && token!.isNotEmpty) {
      api = GitHubService(token!);
      await refreshUser();
    }
    activity = (prefs.getStringList('activity') ?? [])
        .map((e) => ActivityEntry.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    initialized = true;
    notifyListeners();
  }

  Future<void> setLang(String l) async {
    lang = l;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', l);
    notifyListeners();
  }

  Locale get locale => Locale(lang);

  // ── auth ──────────────────────────────────────────────────────────────────

  String? pendingVerifier;

  Future<void> startLogin() async {
    final (uri, verifier) = await auth.authorizeUrlWithVerifier();
    pendingVerifier = verifier;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Called with the novawindowscloud://oauth/callback?code=... deep link.
  Future<String?> handleCallback(Uri uri) async {
    final code = uri.queryParameters['code'];
    if (code == null || pendingVerifier == null) return 'missing code';
    try {
      final t = await auth.exchangeCode(code, pendingVerifier!);
      token = t;
      await auth.saveToken(t);
      api = GitHubService(t);
      await refreshUser();
      log('login', true);
      return null;
    } catch (e) {
      return e.toString();
    }
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
    token = null;
    api = null;
    user = null;
    selectedRepo = null;
    repos = [];
    await auth.clearToken();
    log('logout', true);
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
