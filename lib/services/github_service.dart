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

  bool get isPermissionError => status == 403 || status == 404;

  String get friendlyMessage {
    try {
      final decoded = jsonDecode(message);
      if (decoded is Map && decoded['message'] is String) {
        return 'HTTP $status: ${decoded['message']}';
      }
    } catch (_) {}
    if (message.length > 220) {
      return 'HTTP $status: ${message.substring(0, 220)}…';
    }
    return 'HTTP $status: $message';
  }

  @override
  String toString() => friendlyMessage;
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
        fullName: j['full_name'] as String? ?? '',
        name: j['name'] as String? ?? '',
        isPrivate: j['private'] as bool? ?? false,
        description: j['description'] as String?,
        defaultBranch: j['default_branch'] as String? ?? 'main',
      );

  Map<String, dynamic> toJson() => {
        'full_name': fullName,
        'name': name,
        'private': isPrivate,
        'description': description,
        'default_branch': defaultBranch,
      };
}

class WorkflowInspection {
  final bool exists;
  final String? workflowFile;
  final bool needsRepair;
  final String? sha;

  const WorkflowInspection({
    required this.exists,
    this.workflowFile,
    this.needsRepair = false,
    this.sha,
  });

  /// Checks whether a workflow is missing the NOVA dispatch inputs,
  /// mobile session-info artifact support, or safe Tailscale guards, or uses
  /// the invalid `if: ${{ secrets.TAILSCALE_AUTHKEY != '' }}` expression.
  static bool yamlNeedsRepair(String yaml) {
    final directSecretsInIf = RegExp(
      r'^\s*if:\s*.*(?<!steps\.)\bsecrets\.',
      multiLine: true,
    );
    if (directSecretsInIf.hasMatch(yaml)) return true;
    if (!yaml.contains('Upload session info artifact')) return true;
    // Dispatching inputs that an older workflow does not declare is rejected by
    // GitHub. Repair it before sending the session's web/RDP preferences.
    if (!yaml.contains('web_access:') || !yaml.contains('enable_rdp:')) return true;
    if (yaml.contains('tailscale up') &&
        !yaml.contains('steps.secrets.outputs.tailscale') &&
        !yaml.contains('if [ -z "\$TS_KEY" ]')) {
      return true;
    }
    return false;
  }
}

class SecretsCheckResult {
  final List<String> names;
  final bool permissionDenied;
  final String? error;

  const SecretsCheckResult({
    required this.names,
    this.permissionDenied = false,
    this.error,
  });
}

class WorkflowStepState {
  final String name;
  final String status; // queued | in_progress | completed
  final String? conclusion; // success | failure | skipped ...
  WorkflowStepState(this.name, this.status, this.conclusion);
}

class BackupInfo {
  final String tag;
  final String title;
  final DateTime createdAt;
  final int totalBytes;
  final int partCount;
  final bool complete;

  BackupInfo({
    required this.tag,
    required this.title,
    required this.createdAt,
    required this.totalBytes,
    this.partCount = 0,
    required this.complete,
  });

  /// Parses `win11-backup-YYYYMMDD-HHMMSS` into a UTC DateTime when possible.
  static DateTime? parseTagTimestamp(String tag) {
    final m = RegExp(r'(\d{4})(\d{2})(\d{2})-(\d{2})(\d{2})(\d{2})').firstMatch(tag);
    if (m == null) return null;
    final year = int.tryParse(m.group(1)!);
    final month = int.tryParse(m.group(2)!);
    final day = int.tryParse(m.group(3)!);
    final hour = int.tryParse(m.group(4)!);
    final minute = int.tryParse(m.group(5)!);
    final second = int.tryParse(m.group(6)!);
    if (year == null || month == null || day == null || hour == null || minute == null || second == null) {
      return null;
    }
    return DateTime.utc(year, month, day, hour, minute, second);
  }
}

class SessionInfo {
  final String? webUrl;
  final String? tailscaleIp;
  final String? winUser;
  SessionInfo({this.webUrl, this.tailscaleIp, this.winUser});
}

class MinecraftSessionInfo {
  final String? webUrl;
  final String? version;
  final DateTime? startedAt;

  const MinecraftSessionInfo({this.webUrl, this.version, this.startedAt});

  /// Session artifacts must never be able to send the viewer password to an
  /// arbitrary HTTPS host. The workflow publishes only a root Cloudflare Quick
  /// Tunnel URL; reject credentials, nonstandard ports, paths, query strings, and other hosts.
  static Uri? parseTrustedViewerUri(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final uri = Uri.tryParse(raw.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        !uri.hasAuthority ||
        uri.userInfo.isNotEmpty ||
        uri.port != 443 ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.query.isNotEmpty ||
        uri.fragment.isNotEmpty ||
        !RegExp(r'^[a-z0-9-]+\.trycloudflare\.com$')
            .hasMatch(uri.host.toLowerCase())) {
      return null;
    }
    return uri;
  }
}

class MinecraftWorldBackup {
  final String tag;
  final String title;
  final DateTime createdAt;
  final int totalBytes;
  final int worldCount;
  final List<String> worldNames;
  final String? minecraftVersion;
  final bool complete;

  const MinecraftWorldBackup({
    required this.tag,
    required this.title,
    required this.createdAt,
    required this.totalBytes,
    required this.worldCount,
    required this.worldNames,
    this.minecraftVersion,
    required this.complete,
  });

  static MinecraftWorldBackup fromRelease(Map<String, dynamic> release) {
    final tag = release['tag_name'] as String? ?? '';
    final assets = release['assets'] as List? ?? const [];
    final marker = assets.any((asset) => asset is Map && asset['name'] == 'COMPLETE');
    final totalBytes = assets.fold<int>(0, (total, asset) {
      if (asset is! Map || asset['name'] == 'COMPLETE') return total;
      return total + ((asset['size'] as num?)?.toInt() ?? 0);
    });

    List<String> names = const [];
    String? minecraftVersion;
    final body = release['body'] as String? ?? '';
    for (final line in body.split('\n')) {
      const versionPrefix = 'NOVA_MINECRAFT_VERSION=';
      if (line.startsWith(versionPrefix)) {
        final candidate = line.substring(versionPrefix.length).trim();
        if (RegExp(r'^[A-Za-z0-9._+-]{1,40}$').hasMatch(candidate)) {
          minecraftVersion = candidate;
        }
        continue;
      }
      const namesPrefix = 'NOVA_MINECRAFT_WORLDS=';
      if (!line.startsWith(namesPrefix)) continue;
      try {
        final decoded = jsonDecode(line.substring(namesPrefix.length));
        if (decoded is List) {
          names = decoded.whereType<String>().take(100).toList(growable: false);
        }
      } catch (_) {
        // Keep the release visible, but do not trust a malformed world manifest.
      }
    }

    final createdAt = DateTime.tryParse(release['published_at'] as String? ?? '') ??
        DateTime.tryParse(release['created_at'] as String? ?? '') ??
        BackupInfo.parseTagTimestamp(tag) ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    return MinecraftWorldBackup(
      tag: tag,
      title: (release['name'] as String?)?.trim().isNotEmpty == true
          ? release['name'] as String
          : tag,
      createdAt: createdAt.toLocal(),
      totalBytes: totalBytes,
      worldCount: names.length,
      worldNames: names,
      minecraftVersion: minecraftVersion,
      complete: marker,
    );
  }
}

class GitHubService {
  String token;

  /// Called once when the API answers 401 (expired token). Returning a fresh
  /// access token retries the request; returning null gives up.
  final Future<String?> Function()? onUnauthorized;

  GitHubService(this.token, {this.onUnauthorized});

  Map<String, String> get _h => {
        'Authorization': 'Bearer $token',
        'Accept': 'application/vnd.github+json',
        'X-GitHub-Api-Version': '2022-11-28',
        'User-Agent': 'NOVA-Windows-Cloud',
      };

  Future<http.Response> _attempt(String method, Uri uri, Object? body) async {
    switch (method) {
      case 'GET':
        return http.get(uri, headers: _h);
      case 'POST':
        return http.post(
          uri,
          headers: {..._h, 'Content-Type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
        );
      case 'PUT':
        return http.put(
          uri,
          headers: {..._h, 'Content-Type': 'application/json'},
          body: body == null ? null : jsonEncode(body),
        );
      case 'DELETE':
        return http.delete(uri, headers: _h);
      default:
        throw GhException(0, 'bad method');
    }
  }

  Future<dynamic> _send(String method, String path, {Object? body}) async {
    final uri = Uri.parse('${Const.apiBase}$path');
    var res = await _attempt(method, uri, body);

    if (res.statusCode == 401 && onUnauthorized != null) {
      String? fresh;
      try {
        fresh = await onUnauthorized!();
      } catch (_) {
        fresh = null;
      }
      if (fresh != null && fresh.isNotEmpty) {
        token = fresh;
        res = await _attempt(method, uri, body);
      }
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
    final j = await _send(
      'GET',
      '/user/repos?sort=updated&per_page=100&affiliation=owner,organization_member,collaborator',
    );
    return (j as List).map((e) => Repo.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Repo> createRepo(
    String name, {
    required bool isPrivate,
    String? description,
  }) async {
    final j = await _send('POST', '/user/repos', body: {
      'name': name,
      'private': isPrivate,
      'auto_init': true,
      'description': description ?? 'NOVA Windows 11 Cloud VM Repository',
    });
    return Repo.fromJson(j as Map<String, dynamic>);
  }

  /// Inspects `.github/workflows/windows11.yml` in [repo] to verify whether it
  /// exists and whether its YAML syntax/features are up to date.
  Future<WorkflowInspection> inspectWorkflow(String repo) async {
    try {
      final cur = await _send(
        'GET',
        '/repos/$repo/contents/.github/workflows/${Const.workflowFile}',
      ) as Map<String, dynamic>;
      final sha = cur['sha'] as String?;
      final encoded = (cur['content'] as String? ?? '').replaceAll('\n', '').replaceAll('\r', '');
      var needsRepair = false;
      if (encoded.isNotEmpty) {
        try {
          final yaml = utf8.decode(base64Decode(encoded), allowMalformed: true);
          needsRepair = WorkflowInspection.yamlNeedsRepair(yaml);
        } catch (_) {}
      }
      return WorkflowInspection(
        exists: true,
        workflowFile: Const.workflowFile,
        needsRepair: needsRepair,
        sha: sha,
      );
    } on GhException catch (e) {
      if (e.status != 404 && e.status != 403) rethrow;
    } catch (_) {}

    final fallback = await findWindowsWorkflow(repo);
    if (fallback != null) {
      // Only the NOVA-managed workflow declares all dispatch inputs and uploads
      // the session-info artifact required by the mobile progress/ready screens.
      return WorkflowInspection(exists: true, workflowFile: fallback, needsRepair: true);
    }
    return const WorkflowInspection(exists: false);
  }

  /// Returns the workflow file name if the Windows workflow exists, else null.
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

  /// Creates or updates `.github/workflows/windows11.yml` in the repository.
  /// The Windows path stays fixed so callers cannot accidentally replace it.
  Future<void> createWorkflowFile(String repo, String branch, String yamlContent) =>
      createWorkflowFileAt(
        repo,
        branch,
        workflowFile: Const.workflowFile,
        yamlContent: yamlContent,
        productName: 'Windows Cloud',
        workflowName: 'Windows 11',
      );

  /// Creates or updates a workflow at a validated filename beneath
  /// `.github/workflows/`. This lets Minecraft Cloud remain independent from
  /// the existing Windows workflow and its Tailscale configuration.
  Future<void> createWorkflowFileAt(
    String repo,
    String branch, {
    required String workflowFile,
    required String yamlContent,
    required String productName,
    required String workflowName,
  }) async {
    if (!RegExp(r'^[A-Za-z0-9._-]+\.ya?ml$').hasMatch(workflowFile)) {
      throw ArgumentError.value(workflowFile, 'workflowFile', 'Expected a workflow filename.');
    }
    if (yamlContent.trim().isEmpty) {
      throw ArgumentError.value(yamlContent, 'yamlContent', 'Workflow content cannot be empty.');
    }

    final workflowPath = '.github/workflows/$workflowFile';
    final encodedBranch = Uri.encodeQueryComponent(branch);
    String? sha;
    try {
      final cur = await _send(
        'GET',
        '/repos/$repo/contents/$workflowPath?ref=$encodedBranch',
      ) as Map<String, dynamic>;
      sha = cur['sha'] as String?;
    } catch (_) {
      try {
        final cur = await _send(
          'GET',
          '/repos/$repo/contents/$workflowPath',
        ) as Map<String, dynamic>;
        sha = cur['sha'] as String?;
      } catch (_) {
        sha = null;
      }
    }

    final action = sha == null ? 'add' : 'update';
    final payload = <String, dynamic>{
      'message': 'NOVA $productName: $action $workflowName workflow',
      'content': base64Encode(utf8.encode(yamlContent)),
      if (sha != null) 'sha': sha,
      'branch': branch,
    };

    try {
      await _send('PUT', '/repos/$repo/contents/$workflowPath', body: payload);
    } on GhException catch (e) {
      if ((e.status == 404 || e.status == 422) && sha == null) {
        // Empty repository where the default branch does not exist yet.
        final retryPayload = Map<String, dynamic>.from(payload)..remove('branch');
        await _send('PUT', '/repos/$repo/contents/$workflowPath', body: retryPayload);
      } else {
        rethrow;
      }
    }
  }

  Future<bool> workflowFileExists(String repo, String workflowFile, {String? branch}) async {
    if (!RegExp(r'^[A-Za-z0-9._-]+\.ya?ml$').hasMatch(workflowFile)) {
      throw ArgumentError.value(workflowFile, 'workflowFile', 'Expected a workflow filename.');
    }
    final ref = branch == null ? '' : '?ref=${Uri.encodeQueryComponent(branch)}';
    try {
      await _send('GET', '/repos/$repo/contents/.github/workflows/$workflowFile$ref');
      return true;
    } on GhException catch (e) {
      if (e.status == 404) return false;
      rethrow;
    }
  }

  // ── Secrets ───────────────────────────────────────────────────────────────

  Future<SecretsCheckResult> checkSecrets(String repo) async {
    try {
      final j = await _send('GET', '/repos/$repo/actions/secrets?per_page=100');
      final names = ((j as Map<String, dynamic>)['secrets'] as List? ?? [])
          .map((e) => e['name'] as String)
          .toList();
      return SecretsCheckResult(names: names);
    } on GhException catch (e) {
      return SecretsCheckResult(
        names: const [],
        permissionDenied: e.isPermissionError,
        error: e.friendlyMessage,
      );
    } catch (e) {
      return SecretsCheckResult(names: const [], error: '$e');
    }
  }

  Future<List<String>> listSecretNames(String repo) async {
    final res = await checkSecrets(repo);
    return res.names;
  }

  /// Encrypts [value] with the repo's public key and stores it as an Actions secret.
  Future<void> putSecret(String repo, String name, String value) async {
    final pk = await _send('GET', '/repos/$repo/actions/secrets/public-key') as Map<String, dynamic>;
    final keyId = pk['key_id'] as String;
    final keyBytes = base64Decode(pk['key'] as String);
    final sealed = await GitHubSeal.seal(
      Uint8List.fromList(utf8.encode(value)),
      Uint8List.fromList(keyBytes),
    );
    await _send('PUT', '/repos/$repo/actions/secrets/$name', body: {
      'encrypted_value': base64Encode(sealed),
      'key_id': keyId,
    });
  }

  /// Encrypts and uploads multiple secrets using a single public-key fetch, then
  /// verifies with GitHub that all saved secret names exist in the repository.
  Future<List<String>> putSecretsVerified(String repo, Map<String, String> secrets) async {
    final pk = await _send('GET', '/repos/$repo/actions/secrets/public-key') as Map<String, dynamic>;
    final keyId = pk['key_id'] as String;
    final keyBytes = Uint8List.fromList(base64Decode(pk['key'] as String));

    for (final entry in secrets.entries) {
      final sealed = await GitHubSeal.seal(
        Uint8List.fromList(utf8.encode(entry.value)),
        keyBytes,
      );
      await _send('PUT', '/repos/$repo/actions/secrets/${entry.key}', body: {
        'encrypted_value': base64Encode(sealed),
        'key_id': keyId,
      });
    }

    final verifyJson = await _send('GET', '/repos/$repo/actions/secrets?per_page=100') as Map<String, dynamic>;
    final confirmedNames = (verifyJson['secrets'] as List? ?? [])
        .map((e) => e['name'] as String)
        .toList();

    for (final key in secrets.keys) {
      if (!confirmedNames.contains(key)) {
        throw GhException(500, 'GitHub did not confirm secret $key after upload.');
      }
    }
    return confirmedNames;
  }

  Future<void> deleteSecret(String repo, String name) async {
    await _send('DELETE', '/repos/$repo/actions/secrets/$name');
  }

  // ── Workflow runs ─────────────────────────────────────────────────────────

  Future<void> dispatch(
    String repo,
    String workflowFile, {
    required int hours,
    required bool fresh,
    bool webAccess = true,
    bool enableRdp = true,
    String branch = 'main',
  }) async {
    await _send('POST', '/repos/$repo/actions/workflows/$workflowFile/dispatches', body: {
      'ref': branch,
      'inputs': {
        'hours': '$hours',
        'fresh_install': fresh ? 'true' : 'false',
        'web_access': webAccess ? 'true' : 'false',
        'enable_rdp': enableRdp ? 'true' : 'false',
      },
    });
  }

  Future<void> dispatchWorkflow(
    String repo,
    String workflowFile, {
    required String branch,
    required Map<String, String> inputs,
  }) async {
    if (!RegExp(r'^[A-Za-z0-9._-]+\.ya?ml$').hasMatch(workflowFile)) {
      throw ArgumentError.value(workflowFile, 'workflowFile', 'Expected a workflow filename.');
    }
    await _send(
      'POST',
      '/repos/$repo/actions/workflows/$workflowFile/dispatches',
      body: {'ref': branch, 'inputs': inputs},
    );
  }

  Future<Map<String, dynamic>?> latestRun(String repo) async {
    final j = await _send('GET', '/repos/$repo/actions/runs?per_page=5');
    final runs = (j as Map<String, dynamic>)['workflow_runs'] as List? ?? [];
    if (runs.isEmpty) return null;
    for (final r in runs) {
      final map = r as Map<String, dynamic>;
      final path = map['path'] as String? ?? '';
      final name = (map['name'] as String? ?? '').toLowerCase();
      if (path.endsWith(Const.workflowFile) || name.contains('windows')) {
        return map;
      }
    }
    return runs.first as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> latestWorkflowRun(String repo, String workflowFile) async {
    if (!RegExp(r'^[A-Za-z0-9._-]+\.ya?ml$').hasMatch(workflowFile)) {
      throw ArgumentError.value(workflowFile, 'workflowFile', 'Expected a workflow filename.');
    }
    final j = await _send(
      'GET',
      '/repos/$repo/actions/workflows/$workflowFile/runs?per_page=1',
    );
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

  Future<List<WorkflowStepState>> runSteps(String repo, int runId) async {
    final j = await _send('GET', '/repos/$repo/actions/runs/$runId/jobs');
    final jobs = (j as Map<String, dynamic>)['jobs'] as List? ?? [];
    if (jobs.isEmpty) return [];
    final steps = (jobs.first as Map<String, dynamic>)['steps'] as List? ?? [];
    return steps
        .map((s) => WorkflowStepState(
              s['name'] as String? ?? '',
              s['status'] as String? ?? 'queued',
              s['conclusion'] as String?,
            ))
        .toList();
  }

  Future<void> cancelRun(String repo, int runId) async {
    await _send('POST', '/repos/$repo/actions/runs/$runId/cancel');
  }

  /// Sends a graceful stop signal (`nova-stop-<runId>` release) so the running
  /// Windows VM loop exits cleanly, shuts down Windows, and saves the encrypted
  /// backup to Releases without being killed mid-upload by job cancellation.
  Future<void> requestGracefulStop(String repo, int runId) async {
    final tag = 'nova-stop-$runId';
    try {
      await _send('POST', '/repos/$repo/releases', body: {
        'tag_name': tag,
        'name': 'Stop signal for run $runId',
        'body': 'Graceful stop & backup save requested from NOVA Windows Cloud mobile app.',
        'prerelease': true,
      });
    } on GhException catch (e) {
      // If release already exists (422), the signal is already active.
      if (e.status != 422) rethrow;
    }
  }

  /// Requests a graceful Minecraft client shutdown without cancelling its
  /// GitHub Actions job, so the workflow can snapshot and upload world saves.
  Future<void> requestMinecraftGracefulStop(String repo, int runId) async {
    final tag = 'nova-minecraft-stop-$runId';
    try {
      await _send('POST', '/repos/$repo/releases', body: {
        'tag_name': tag,
        'name': 'Minecraft stop signal for run $runId',
        'body': 'Graceful Minecraft Java Cloud stop requested from NOVA.',
        'prerelease': true,
      });
    } on GhException catch (e) {
      // A 422 here means the one-shot stop signal was already created.
      if (e.status != 422) rethrow;
    }
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

  Future<MinecraftSessionInfo?> minecraftSessionInfo(String repo, int runId) async {
    try {
      final j = await _send('GET', '/repos/$repo/actions/runs/$runId/artifacts');
      final artifacts = (j as Map<String, dynamic>)['artifacts'] as List? ?? [];
      for (final artifact in artifacts) {
        if (artifact['name'] != 'minecraft-session-info') continue;
        final downloadUrl = artifact['archive_download_url'] as String?;
        if (downloadUrl == null) return null;
        final response = await http.get(Uri.parse(downloadUrl), headers: _h);
        if (response.statusCode != 200) return null;
        final zip = ZipDecoder().decodeBytes(response.bodyBytes);
        for (final file in zip) {
          if (!file.isFile) continue;
          final text = utf8.decode(file.content as List<int>, allowMalformed: true);
          if (!file.name.endsWith('info.txt') && !text.contains('MC_VERSION=')) continue;

          String? value(String key) {
            final match = RegExp('^' + RegExp.escape(key) + r'=(.*)$', multiLine: true).firstMatch(text);
            final result = match?.group(1)?.trim();
            return result == null || result.isEmpty ? null : result;
          }

          final rawUrl = value('WEB_URL');
          final trustedUri = MinecraftSessionInfo.parseTrustedViewerUri(rawUrl);
          final safeUrl = trustedUri == null ? null : trustedUri.toString();
          return MinecraftSessionInfo(
            webUrl: safeUrl,
            version: value('MC_VERSION'),
            startedAt: DateTime.tryParse(value('STARTED_AT') ?? ''),
          );
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

    return SessionInfo(
      webUrl: grab('WEB_URL'),
      tailscaleIp: grab('TS_IP'),
      winUser: grab('WIN_USER'),
    );
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
      var parts = 0;
      for (final a in assets) {
        final name = a['name'] as String? ?? '';
        if (name == 'COMPLETE') {
          complete = true;
        } else if (name.contains('.part')) {
          parts++;
          total += (a['size'] as int? ?? 0);
        } else {
          total += (a['size'] as int? ?? 0);
        }
      }
      final parsedFromTag = BackupInfo.parseTagTimestamp(tag);
      final publishedAt = DateTime.tryParse(r['published_at'] as String? ?? '');
      final createdAt = DateTime.tryParse(r['created_at'] as String? ?? '');
      out.add(BackupInfo(
        tag: tag,
        title: (r['name'] as String?)?.trim().isNotEmpty == true ? r['name'] as String : tag,
        createdAt: (parsedFromTag ?? publishedAt ?? createdAt ?? DateTime.now()).toLocal(),
        totalBytes: total,
        partCount: parts,
        complete: complete,
      ));
    }
    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  Future<List<MinecraftWorldBackup>> minecraftWorldBackups(String repo) async {
    final j = await _send('GET', '/repos/$repo/releases?per_page=100');
    final releases = (j as List).whereType<Map<String, dynamic>>();
    final backups = releases
        .where((release) =>
            (release['tag_name'] as String? ?? '').startsWith(Const.minecraftBackupPrefix))
        .map(MinecraftWorldBackup.fromRelease)
        .toList();
    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  }
}
