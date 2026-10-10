import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:http/http.dart' as http;

import '../core/const.dart';
import 'seal.dart';

class GhException implements Exception {
  final int status;
  final String message;
  GhException(this.status, this.message);
  @override
  String toString() => 'GitHub API $status: $message';
}

class Repo {
  final String fullName;
  final String name;
  final bool isPrivate;
  final String? description;
  final String defaultBranch;
  Repo({
    required this.fullName,
    required this.name,
    required this.isPrivate,
    this.description,
    this.defaultBranch = 'main',
  });

  factory Repo.fromJson(Map<String, dynamic> j) => Repo(
        fullName: j['full_name'] as String,
        name: j['name'] as String,
        isPrivate: j['private'] as bool? ?? false,
        description: j['description'] as String?,
        defaultBranch: j['default_branch'] as String? ?? 'main',
      );
}

class StepState {
  final String name;
  final String status; // queued | in_progress | completed
  final String? conclusion; // success | failure | skipped ...
  StepState(this.name, this.status, this.conclusion);
}

class BackupInfo {
  final String tag;
  final DateTime createdAt;
  final int totalBytes;
  final bool complete;
  BackupInfo({required this.tag, required this.createdAt, required this.totalBytes, required this.complete});
}

class SessionInfo {
  final String? webUrl;
  final String? tailscaleIp;
  final String? winUser;
  SessionInfo({this.webUrl, this.tailscaleIp, this.winUser});
}

class GitHubService {
  final String token;
  GitHubService(this.token);

  Map<String, String> get _h => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'NOVA-Windows-Cloud',
      };

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    final uri = Uri.parse('${Const.apiBase}$path');
    http.Response res;
    switch (method) {
      case 'GET':
        res = await http.get(uri, headers: _h);
        break;
      case 'POST':
        res = await http.post(uri, headers: {..._h, 'Content-Type': 'application/json'}, body: body == null ? null : jsonEncode(body));
        break;
      case 'PUT':
        res = await http.put(uri, headers: {..._h, 'Content-Type': 'application/json'}, body: body == null ? null : jsonEncode(body));
        break;
      case 'DELETE':
        res = await http.delete(uri, headers: _h);
        break;
      default:
        throw GhException(0, 'bad method');
    }
    if (res.statusCode >= 400) {
      throw GhException(res.statusCode, res.body);
    }
    if (res.body.isEmpty) return null;
    return jsonDecode(res.body);
  }

  // ── User & repos ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getUser() async =>
      (await _send('GET', '/user')) as Map<String, dynamic>;

  Future<List<Repo>> listRepos() async {
    final j = await _send('GET', '/user/repos?sort=updated&per_page=100&affiliation=owner,organization_member,collaborator');
    return (j as List).map((e) => Repo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Repo> createRepo(String name, {required bool isPrivate}) async {
    final j = await _send('POST', '/user/repos', body: {'name': name, 'private': isPrivate, 'auto_init': false});
    return Repo.fromJson(j as Map<String, dynamic>);
  }

  /// Returns the workflow id/file if the Windows workflow exists, else null.
  Future<String?> findWindowsWorkflow(String repo) async {
    try {
      final j = await _send('GET', '/repos/$repo/actions/workflows');
      for (final w in (j as Map<String, dynamic>)['workflows'] as List? ?? []) {
        final path = w['path'] as String? ?? '';
        final nm = w['name'] as String? ?? '';
        if (path.endsWith(Const.workflowFile) || nm.toLowerCase().contains('windows 11')) {
          return path.split('/').last;
        }
      }
      return null;
    } on GhException catch (e) {
      if (e.status == 404 || e.status == 403) return null;
      rethrow;
    }
  }

  /// Creates/updates the Windows workflow file in the repo (contents: write).
  Future<void> createWorkflowFile(String repo, String branch, String yamlContent) async {
    String? sha;
    try {
      final cur = await _send('GET', '/repos/$repo/contents/.github/workflows/${Const.workflowFile}') as Map<String, dynamic>;
      sha = cur['sha'] as String?;
    } catch (_) {
      sha = null;
    }
    await _send('PUT', '/repos/$repo/contents/.github/workflows/${Const.workflowFile}', body: {
      'message': 'NOVA Windows Cloud: add Windows 11 workflow',
      'content': base64Encode(utf8.encode(yamlContent)),
      if (sha != null) 'sha': sha,
      'branch': branch,
    });
  }

  // ── Secrets ───────────────────────────────────────────────────────────────

  Future<List<String>> listSecretNames(String repo) async {
    try {
      final j = await _send('GET', '/repos/$repo/actions/secrets?per_page=100');
      return ((j as Map<String, dynamic>)['secrets'] as List? ?? [])
          .map((e) => e['name'] as String)
          .toList();
    } on GhException {
      return [];
    }
  }

  /// Encrypts [value] with the repo's public key and stores it as an Actions secret.
  Future<void> putSecret(String repo, String name, String value) async {
    final pk = await _send('GET', '/repos/$repo/actions/secrets/public-key') as Map<String, dynamic>;
    final keyId = pk['key_id'] as String;
    final keyBytes = base64Decode(pk['key'] as String);
    final sealed = await GitHubSeal.seal(Uint8List.fromList(utf8.encode(value)), Uint8List.fromList(keyBytes));
    await _send('PUT', '/repos/$repo/actions/secrets/$name', body: {
      'encrypted_value': base64Encode(sealed),
      'key_id': keyId,
    });
  }

  Future<void> deleteSecret(String repo, String name) async {
    await _send('DELETE', '/repos/$repo/actions/secrets/$name');
  }

  // ── Workflow runs ─────────────────────────────────────────────────────────

  Future<void> dispatch(String repo, String workflowFile, {required int hours, required bool fresh}) async {
    await _send('POST', '/repos/$repo/actions/workflows/$workflowFile/dispatches', body: {
      'ref': 'main',
      'inputs': {'hours': '$hours', 'fresh_install': fresh ? 'true' : 'false'},
    });
  }

  Future<Map<String, dynamic>?> latestRun(String repo) async {
    final j = await _send('GET', '/repos/$repo/actions/runs?per_page=5');
    final runs = (j as Map<String, dynamic>)['workflow_runs'] as List? ?? [];
    if (runs.isEmpty) return null;
    return runs.first as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getRun(String repo, int id) async {
    try {
      return await _send('GET', '/repos/$repo/actions/runs/$id') as Map<String, dynamic>?;
    } on GhException {
      return null;
    }
  }

  Future<List<StepState>> runSteps(String repo, int runId) async {
    final j = await _send('GET', '/repos/$repo/actions/runs/$runId/jobs');
    final jobs = (j as Map<String, dynamic>)['jobs'] as List? ?? [];
    if (jobs.isEmpty) return [];
    final steps = (jobs.first as Map<String, dynamic>)['steps'] as List? ?? [];
    return steps
        .map((s) => StepState(
              s['name'] as String? ?? '',
              s['status'] as String? ?? 'queued',
              s['conclusion'] as String?,
            ))
        .toList();
  }

  Future<void> cancelRun(String repo, int runId) async {
    await _send('POST', '/repos/$repo/actions/runs/$runId/cancel');
  }

  /// Reads the `session-info` artifact uploaded mid-run by the workflow.
  Future<SessionInfo?> sessionInfo(String repo, int runId) async {
    try {
      final j = await _send('GET', '/repos/$repo/actions/runs/$runId/artifacts');
      final arts = (j as Map<String, dynamic>)['artifacts'] as List? ?? [];
      for (final a in arts) {
        if (a['name'] == 'session-info') {
          final url = a['archive_download_url'] as String;
          final res = await http.get(Uri.parse(url), headers: _h);
          if (res.statusCode != 200) return null;
          final zip = ZipDecoder().decodeBytes(res.bodyBytes);
          for (final f in zip) {
            if (!f.isFile) continue;
            final text = utf8.decode(f.content as List<int>, allowMalformed: true);
            if (f.name.contains('info.txt') || text.contains('WEB_URL')) {
              return _parseInfo(text);
            }
          }
        }
      }
      return null;
    } on GhException {
      return null;
    } catch (_) {
      return null;
    }
  }

  SessionInfo _parseInfo(String text) {
    String? grab(String key) {
      final m = RegExp('$key=(.*)').firstMatch(text);
      final v = m?.group(1)?.trim();
      return (v == null || v.isEmpty) ? null : v;
    }

    return SessionInfo(webUrl: grab('WEB_URL'), tailscaleIp: grab('TS_IP'), winUser: grab('WIN_USER'));
  }

  // ── Backups (Releases) ────────────────────────────────────────────────────

  Future<List<BackupInfo>> backups(String repo) async {
    final j = await _send('GET', '/repos/$repo/releases?per_page=100');
    final out = <BackupInfo>[];
    for (final r in j as List) {
      final tag = r['tag_name'] as String? ?? '';
      if (!tag.startsWith(Const.backupPrefix)) continue;
      final assets = r['assets'] as List? ?? [];
      var complete = false;
      var total = 0;
      for (final a in assets) {
        if (a['name'] == 'COMPLETE') complete = true;
        total += (a['size'] as int? ?? 0);
      }
      out.add(BackupInfo(
        tag: tag,
        createdAt: DateTime.tryParse(r['created_at'] as String? ?? '') ?? DateTime.now(),
        totalBytes: total,
        complete: complete,
      ));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }
}
