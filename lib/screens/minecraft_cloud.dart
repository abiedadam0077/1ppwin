import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/const.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../services/github_service.dart';
import '../services/minecraft_versions.dart';
import '../state/app_state.dart';

const MethodChannel _minecraftViewerChannel = MethodChannel('nova/minecraft_viewer');

class MinecraftCloudScreen extends StatefulWidget {
  const MinecraftCloudScreen({super.key});

  @override
  State<MinecraftCloudScreen> createState() => _MinecraftCloudScreenState();
}

class _MinecraftCloudScreenState extends State<MinecraftCloudScreen> {
  final _repoName = TextEditingController();
  final _clientId = TextEditingController();
  final _viewerPassword = TextEditingController();
  final _backupPassword = TextEditingController();
  final _versionService = MinecraftVersionService();

  Repo? _repo;
  MinecraftVersionManifest? _manifest;
  List<MinecraftWorldBackup> _backups = [];
  List<String> _secretNames = [];
  Map<String, dynamic>? _run;
  List<WorkflowStepState> _steps = [];
  MinecraftSessionInfo? _sessionInfo;
  String? _knownViewerPassword;
  String? _error;
  String? _versionsError;
  String? _versionId;
  String _versionType = 'release';
  String _hours = '2';
  String _memoryGb = '4';
  String _resolution = '1280x720';
  String _renderDistance = '6';
  String _fpsLimit = '30';
  String _restoreTag = 'none';
  DateTime? _dispatchRequestedAt;
  int? _dispatchPreviousRunId;
  Timer? _pollTimer;
  bool _busy = false;
  bool _refreshBusy = false;
  String? _refreshingRepo;
  bool _savingSecrets = false;
  bool _workflowExists = false;
  bool _stopRequested = false;
  bool _restored = false;
  bool _initializing = false;

  bool get _isActive {
    final status = _run?['status'] as String? ?? '';
    return status == 'queued' || status == 'in_progress' || status == 'waiting';
  }

  bool get _secretsReady =>
      _secretNames.contains(Const.secretMinecraftClientId) &&
      _secretNames.contains(Const.secretMinecraftAccess) &&
      _secretNames.contains(Const.secretMinecraftBackup);

  @override
  void initState() {
    super.initState();
    _pollTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (mounted && (_isActive || _dispatchRequestedAt != null)) {
        _refreshRepo(showSpinner: false);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _repoName.dispose();
    _clientId.dispose();
    _viewerPassword.dispose();
    _backupPassword.dispose();
    super.dispose();
  }

  String _storedChoice(
    SharedPreferences preferences,
    String key,
    List<String> allowed,
    String fallback,
  ) {
    final value = preferences.getString(key);
    return value != null && allowed.contains(value) ? value : fallback;
  }

  Future<void> _initialize() async {
    if (_initializing || _restored) return;
    _initializing = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _hours = _storedChoice(prefs, 'minecraft_hours', const ['1', '2', '3', '4'], '2');
        _memoryGb = _storedChoice(prefs, 'minecraft_memory_gb', const ['2', '4', '6', '8'], '4');
        _resolution = _storedChoice(prefs, 'minecraft_resolution', const ['1280x720', '1600x900'], '1280x720');
        _renderDistance = _storedChoice(prefs, 'minecraft_render_distance', const ['4', '6', '8', '10', '12'], '6');
        _fpsLimit = _storedChoice(prefs, 'minecraft_fps_limit', const ['20', '30', '45', '60'], '30');
        _versionType = _storedChoice(prefs, 'minecraft_version_type', const ['release', 'snapshot'], 'release');
        _restoreTag = prefs.getString('minecraft_restore_tag') ?? 'none';
      });

      final st = context.read<AppState>();
      if (st.api == null) return;
      if (st.repos.isEmpty && !st.busy) await st.loadRepos();
      final savedName = prefs.getString('minecraft_repo_full_name');
      if (savedName != null && mounted) {
        final found = st.repos.where((repo) =>
            repo.fullName == savedName && repo.isPrivate && repo.fullName != st.selectedRepo?.fullName);
        if (found.isNotEmpty) setState(() => _repo = found.first);
      }
      await Future.wait<void>([_loadVersions(), if (_repo != null) _refreshRepo()]);
      if (mounted) {
        setState(() {
          _restored = true;
          if (_repo != null && _versionId == null && _manifest != null) {
            _versionId = _manifest!.latestRelease;
          }
        });
      }
    } finally {
      _initializing = false;
    }
  }

  Future<void> _loadVersions() async {
    if (mounted) setState(() => _versionsError = null);
    try {
      final manifest = await _versionService.fetch();
      final prefs = await SharedPreferences.getInstance();
      final savedVersion = prefs.getString('minecraft_version_id');
      if (!mounted) return;
      final versionExists = savedVersion != null &&
          manifest.versions.any((v) => v.id == savedVersion && v.type == _versionType);
      final latestForType = _versionType == 'snapshot' && manifest.latestSnapshot.isNotEmpty
          ? manifest.latestSnapshot
          : manifest.latestRelease;
      setState(() {
        _manifest = manifest;
        _versionId = versionExists ? savedVersion : latestForType;
        _versionsError = null;
      });
    } catch (error) {
      if (mounted) setState(() => _versionsError = '$error');
    }
  }

  Future<void> _refreshRepo({bool showSpinner = true}) async {
    final repo = _repo;
    final api = context.read<AppState>().api;
    if (repo == null || api == null || _refreshingRepo == repo.fullName) return;
    _refreshingRepo = repo.fullName;
    if (showSpinner && mounted) setState(() => _refreshBusy = true);
    try {
      final secrets = await api.checkSecrets(repo.fullName);
      final workflow = await api.workflowFileExists(
        repo.fullName,
        Const.minecraftWorkflowFile,
        branch: repo.defaultBranch,
      );
      final run = await api.latestWorkflowRun(repo.fullName, Const.minecraftWorkflowFile);
      final backups = await api.minecraftWorldBackups(repo.fullName);

      final nextRun = run;
      final candidateRunId = nextRun?['id'] as int?;
      final belongsToDispatch = _dispatchRequestedAt == null ||
          (candidateRunId != null && candidateRunId != _dispatchPreviousRunId);
      final visibleRun = belongsToDispatch ? nextRun : null;
      final active = _runIsActive(visibleRun);
      final runId = visibleRun?['id'] as int?;
      final steps = active && runId != null ? await api.runSteps(repo.fullName, runId) : <WorkflowStepState>[];
      final info = active && runId != null ? await api.minecraftSessionInfo(repo.fullName, runId) : null;
      if (!mounted || _repo?.fullName != repo.fullName) return;
      setState(() {
        _secretNames = secrets.names;
        _workflowExists = workflow;
        _run = visibleRun;
        _steps = steps;
        _sessionInfo = info;
        _backups = backups;
        _stopRequested = _stopRequested && active;
        if (visibleRun != null) {
          _dispatchRequestedAt = null;
          _dispatchPreviousRunId = null;
        }
        if (!_isActive) _stopRequested = false;
        if (_restoreTag != 'none' && !backups.any((backup) => backup.complete && backup.tag == _restoreTag)) {
          _restoreTag = 'none';
        }
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('minecraft_restore_tag', _restoreTag);
    } catch (error) {
      if (mounted && _repo?.fullName == repo.fullName) {
        setState(() => _error = '$error');
      }
    } finally {
      if (_refreshingRepo == repo.fullName) _refreshingRepo = null;
      if (mounted && showSpinner && _refreshingRepo == null) {
        setState(() => _refreshBusy = false);
      }
    }
  }

  bool _runIsActive(Map<String, dynamic>? run) {
    final status = run?['status'] as String? ?? '';
    return status == 'queued' || status == 'in_progress' || status == 'waiting';
  }

  Future<void> _selectRepository() async {
    final st = context.read<AppState>();
    if (st.api == null) return;
    if (st.repos.isEmpty && !st.busy) await st.loadRepos();
    if (!mounted) return;
    final privateRepos = st.repos.where((repo) =>
        repo.isPrivate && repo.fullName != st.selectedRepo?.fullName).toList();
    final selected = await showModalBottomSheet<Object>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NovaTheme.card,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheetContext).height * 0.72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: NovaTheme.neonCyan),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        L10n.of(sheetContext).t('minecraft_private_repo_title'),
                        style: const TextStyle(color: NovaTheme.text, fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
              if (privateRepos.isEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Text(
                        L10n.of(sheetContext).t('minecraft_no_private_repo'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: NovaTheme.textDim, height: 1.5),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: privateRepos.length,
                    separatorBuilder: (_, __) => const Divider(color: NovaTheme.cardBorder, height: 1),
                    itemBuilder: (context, index) {
                      final repo = privateRepos[index];
                      return ListTile(
                        leading: const Icon(Icons.lock_outline_rounded, color: NovaTheme.neonPurpleSoft),
                        title: Text(repo.fullName, textDirection: TextDirection.ltr, style: const TextStyle(color: NovaTheme.text)),
                        subtitle: Text(repo.description ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                        onTap: () => Navigator.pop(sheetContext, repo),
                      );
                    },
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: GradientButton(
                  label: L10n.of(sheetContext).t('minecraft_create_repo'),
                  icon: Icons.create_new_folder_rounded,
                  onPressed: () => Navigator.pop(sheetContext, _MinecraftCreateRequest.create),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || selected == null) return;
    if (selected == _MinecraftCreateRequest.create) {
      await _showCreateRepositoryDialog();
    } else if (selected is Repo) {
      await _setRepository(selected);
    }
  }

  Future<void> _showCreateRepositoryDialog() async {
    _repoName.text = 'minecraft-java-cloud';
    final t = L10n.of(context);
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NovaTheme.card,
        icon: const Icon(Icons.sports_esports_rounded, color: NovaTheme.neonCyan),
        title: Text(t.t('minecraft_create_repo')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.t('minecraft_create_repo_body'), style: const TextStyle(color: NovaTheme.textDim, height: 1.45)),
            const SizedBox(height: 12),
            TextField(
              controller: _repoName,
              autofocus: true,
              autocorrect: false,
              decoration: InputDecoration(labelText: t.t('repo_name')),
              textDirection: TextDirection.ltr,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.t('cancel'))),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, _repoName.text.trim()),
            icon: const Icon(Icons.add_rounded),
            label: Text(t.t('create')),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    final st = context.read<AppState>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = await st.api!.createRepo(
        name.trim(),
        isPrivate: true,
        description: 'NOVA Minecraft Java Cloud: Actions workflow and encrypted world snapshots',
      );
      await st.loadRepos();
      await _setRepository(repo);
      await _installWorkflow(allowOverwrite: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.t('minecraft_repo_created'))),
      );
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setRepository(Repo repo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('minecraft_repo_full_name', repo.fullName);
    if (!mounted) return;
    setState(() {
      _repo = repo;
      _run = null;
      _steps = [];
      _sessionInfo = null;
      _backups = [];
      _secretNames = [];
      _workflowExists = false;
      _dispatchRequestedAt = null;
      _dispatchPreviousRunId = null;
      _error = null;
    });
    await _refreshRepo();
  }

  Future<bool> _installWorkflow({bool allowOverwrite = false}) async {
    final repo = _repo;
    final api = context.read<AppState>().api;
    if (repo == null || api == null) return false;
    final exists = await api.workflowFileExists(
      repo.fullName,
      Const.minecraftWorkflowFile,
      branch: repo.defaultBranch,
    );
    if (exists && !allowOverwrite) {
      final t = L10n.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: NovaTheme.card,
          icon: const Icon(Icons.warning_amber_rounded, color: NovaTheme.warn),
          title: Text(t.t('minecraft_replace_workflow_title')),
          content: Text(t.t('minecraft_replace_workflow_body')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.t('cancel'))),
            FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(t.t('minecraft_install_workflow'))),
          ],
        ),
      );
      if (confirmed != true) return false;
    }
    final yaml = await rootBundle.loadString('assets/minecraft-cloud.yml');
    await api.createWorkflowFileAt(
      repo.fullName,
      repo.defaultBranch,
      workflowFile: Const.minecraftWorkflowFile,
      yamlContent: yaml,
      productName: 'Minecraft Java Cloud',
      workflowName: 'Minecraft',
    );
    if (!mounted) return false;
    setState(() => _workflowExists = true);
    await _refreshRepo();
    return true;
  }

  Future<void> _installWorkflowFromButton() async {
    if (!mounted) return;
    setState(() => _error = null);
    try {
      await _installWorkflow();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _saveMinecraftSecrets() async {
    final repo = _repo;
    final api = context.read<AppState>().api;
    if (repo == null || api == null || _savingSecrets) return;
    final clientId = _clientId.text.trim();
    final viewerPassword = _viewerPassword.text.trim();
    final backupPassword = _backupPassword.text.trim();
    if (clientId.isNotEmpty &&
        !RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$')
            .hasMatch(clientId)) {
      setState(() => _error = L10n.of(context).t('minecraft_client_id_invalid'));
      return;
    }
    final secrets = <String, String>{
      if (clientId.isNotEmpty) Const.secretMinecraftClientId: clientId,
      if (viewerPassword.isNotEmpty) Const.secretMinecraftAccess: viewerPassword,
      if (backupPassword.isNotEmpty) Const.secretMinecraftBackup: backupPassword,
    };
    if (secrets.isEmpty) return;
    setState(() {
      _savingSecrets = true;
      _error = null;
    });
    try {
      final names = await api.putSecretsVerified(repo.fullName, secrets);
      if (!mounted) return;
      setState(() {
        _secretNames = names;
        if (viewerPassword.isNotEmpty) _knownViewerPassword = viewerPassword;
        _clientId.clear();
        _viewerPassword.clear();
        _backupPassword.clear();
      });
      await context.read<AppState>().log(
        'act_save_secrets',
        true,
        detail: '${repo.fullName} (Minecraft Cloud secrets)',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).t('minecraft_secrets_saved'))),
      );
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _savingSecrets = false);
    }
  }

  String _generatePassword() {
    const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#\$%&*_-';
    final random = Random.secure();
    return List.generate(28, (_) => alphabet[random.nextInt(alphabet.length)]).join();
  }

  Future<void> _saveOptions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('minecraft_hours', _hours);
    await prefs.setString('minecraft_memory_gb', _memoryGb);
    await prefs.setString('minecraft_resolution', _resolution);
    await prefs.setString('minecraft_render_distance', _renderDistance);
    await prefs.setString('minecraft_fps_limit', _fpsLimit);
    await prefs.setString('minecraft_version_type', _versionType);
    if (_versionId != null) await prefs.setString('minecraft_version_id', _versionId!);
    await prefs.setString('minecraft_restore_tag', _restoreTag);
  }

  Future<bool> _confirmRestoreVersion(MinecraftVersion selectedVersion) async {
    if (_restoreTag == 'none') return true;
    MinecraftWorldBackup? backup;
    for (final candidate in _backups) {
      if (candidate.complete && candidate.tag == _restoreTag) {
        backup = candidate;
        break;
      }
    }
    final savedVersion = backup?.minecraftVersion;
    if (savedVersion == null || savedVersion == selectedVersion.id) return true;

    final t = L10n.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NovaTheme.card,
        icon: const Icon(Icons.warning_amber_rounded, color: NovaTheme.warn),
        title: Text(t.t('minecraft_backup_version')),
        content: Text(t.t('minecraft_restore_version_warning')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(t.t('cancel'))),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(t.t('minecraft_restore_version_continue')),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _startMinecraft() async {
    final repo = _repo;
    final api = context.read<AppState>().api;
    if (repo == null || api == null || _busy || _isActive || _dispatchRequestedAt != null) return;
    final version = _selectedVersion;
    if (version == null) {
      setState(() => _error = L10n.of(context).t('minecraft_choose_version'));
      return;
    }
    if (!await _confirmRestoreVersion(version) || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
      _dispatchPreviousRunId = _run?['id'] as int?;
      _dispatchRequestedAt = DateTime.now().toUtc();
      _run = null;
      _steps = [];
      _sessionInfo = null;
      _stopRequested = false;
    });
    try {
      if (!_workflowExists && !(await _installWorkflow())) {
        throw StateError(L10n.of(context).t('minecraft_workflow_required'));
      }
      await _saveOptions();
      if (!_secretsReady) {
        throw StateError(L10n.of(context).t('minecraft_secrets_required'));
      }
      await api.dispatchWorkflow(
        repo.fullName,
        Const.minecraftWorkflowFile,
        branch: repo.defaultBranch,
        inputs: {
          'version': version.id,
          'hours': _hours,
          'memory_gb': _memoryGb,
          'resolution': _resolution,
          'render_distance': _renderDistance,
          'fps_limit': _fpsLimit,
          'restore_tag': _restoreTag,
        },
      );
      await context.read<AppState>().log(
        'act_start_run',
        true,
        detail: '${repo.fullName} Minecraft Java ${version.id}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(L10n.of(context).t('minecraft_dispatched'))),
        );
      }
      await _refreshRepo(showSpinner: false);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = '$error';
          _dispatchRequestedAt = null;
          _dispatchPreviousRunId = null;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _requestStop() async {
    final repo = _repo;
    final runId = _run?['id'] as int?;
    final api = context.read<AppState>().api;
    if (repo == null || runId == null || api == null || _stopRequested) return;
    try {
      await api.requestMinecraftGracefulStop(repo.fullName, runId);
      if (!mounted) return;
      setState(() => _stopRequested = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(L10n.of(context).t('minecraft_stop_sent'))),
      );
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _chooseVersion() async {
    final manifest = _manifest;
    if (manifest == null) return;
    var query = '';
    var selectedType = _versionType;
    final selected = await showModalBottomSheet<MinecraftVersion>(
      context: context,
      isScrollControlled: true,
      backgroundColor: NovaTheme.card,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final matches = manifest.versions.where((version) {
            if (version.type != selectedType) return false;
            return query.isEmpty || version.id.toLowerCase().contains(query.toLowerCase());
          }).take(250).toList();
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.82,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
                    child: Row(
                      children: [
                        const Icon(Icons.view_list_rounded, color: NovaTheme.neonCyan),
                        const SizedBox(width: 9),
                        Expanded(child: Text(L10n.of(context).t('minecraft_versions'), style: const TextStyle(color: NovaTheme.text, fontSize: 17, fontWeight: FontWeight.w800))),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close_rounded)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      autofocus: true,
                      onChanged: (value) => setSheetState(() => query = value.trim()),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search_rounded),
                        hintText: L10n.of(context).t('minecraft_search_versions'),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: Text(L10n.of(context).t('minecraft_release')),
                          selected: selectedType == 'release',
                          onSelected: (_) => setSheetState(() => selectedType = 'release'),
                        ),
                        ChoiceChip(
                          label: Text(L10n.of(context).t('minecraft_snapshot')),
                          selected: selectedType == 'snapshot',
                          onSelected: (_) => setSheetState(() => selectedType = 'snapshot'),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final version = matches[index];
                        final latest = version.id == manifest.latestRelease || version.id == manifest.latestSnapshot;
                        return ListTile(
                          dense: true,
                          title: Row(
                            children: [
                              Expanded(child: Text(version.id, textDirection: TextDirection.ltr, style: const TextStyle(color: NovaTheme.text, fontWeight: FontWeight.w700))),
                              if (latest) StatusBadge(label: L10n.of(context).t('minecraft_latest'), color: NovaTheme.ok),
                            ],
                          ),
                          subtitle: Text(version.releasedAt?.toLocal().toString().split('.').first ?? version.type),
                          trailing: version.id == _versionId ? const Icon(Icons.check_circle, color: NovaTheme.neonCyan) : null,
                          onTap: () => Navigator.pop(context, version),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _versionType = selected.type;
      _versionId = selected.id;
    });
    await _saveOptions();
  }

  MinecraftVersion? get _selectedVersion {
    final id = _versionId;
    if (id == null || _manifest == null) return null;
    for (final version in _manifest!.versions) {
      if (version.id == id && version.type == _versionType) return version;
    }
    return null;
  }

  Future<void> _connectToSession() async {
    final uri = MinecraftSessionInfo.parseTrustedViewerUri(_sessionInfo?.webUrl);
    if (uri == null) return;
    var password = _knownViewerPassword;
    if (password == null || password.isEmpty) {
      password = await _askViewerPassword();
    }
    if (!mounted || password == null || password.isEmpty) return;
    final controllerUrl = uri.replace(
      path: '${uri.path.replaceAll(RegExp(r'/+$'), '')}/controller.html',
      query: null,
      fragment: null,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MinecraftPlayScreen(
          viewerUrl: controllerUrl.toString(),
          viewerPassword: password!,
          version: _sessionInfo?.version ?? _versionId ?? '',
        ),
      ),
    );
  }

  Future<String?> _askViewerPassword() async {
    final controller = TextEditingController();
    final t = L10n.of(context);
    final password = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NovaTheme.card,
        title: Text(t.t('minecraft_viewer_password')),
        content: TextField(
          controller: controller,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(hintText: t.t('minecraft_viewer_password_hint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.t('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, controller.text), child: Text(t.t('continue'))),
        ],
      ),
    );
    controller.dispose();
    return password;
  }

  String _currentStatus(L10n t) {
    if (_dispatchRequestedAt != null && _run == null) return t.t('minecraft_status_waiting');
    final status = _run?['status'] as String? ?? '';
    final conclusion = _run?['conclusion'] as String? ?? '';
    if (status == 'queued' || status == 'waiting') return t.t('minecraft_status_queued');
    if (status == 'completed') {
      return conclusion == 'success' ? t.t('minecraft_status_finished') : t.t('minecraft_status_failed');
    }
    if (status != 'in_progress') return t.t('minecraft_status_idle');
    for (final step in _steps) {
      if (step.status != 'in_progress') continue;
      final name = step.name.toLowerCase();
      if (name.contains('validate')) return t.t('minecraft_status_validating');
      if (name.contains('java')) return t.t('minecraft_status_java');
      if (name.contains('install linux')) return t.t('minecraft_status_graphics');
      if (name.contains('restore')) return t.t('minecraft_status_restoring');
      if (name.contains('viewer')) return t.t('minecraft_status_viewer');
      if (name.contains('authenticate')) return t.t('minecraft_status_launching');
      if (name.contains('snapshot')) return t.t('minecraft_status_saving');
    }
    return t.t('minecraft_status_running');
  }

  Color _statusColor() {
    if (_dispatchRequestedAt != null && _run == null) return NovaTheme.neonCyan;
    final status = _run?['status'] as String? ?? '';
    final conclusion = _run?['conclusion'] as String? ?? '';
    if (status == 'in_progress' || status == 'queued' || status == 'waiting') return NovaTheme.neonCyan;
    if (conclusion == 'success') return NovaTheme.ok;
    if (status == 'completed') return NovaTheme.danger;
    return NovaTheme.textDim;
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String _backupLabel(MinecraftWorldBackup backup, L10n t, {bool worlds = false}) {
    final name = worlds && backup.worldNames.isNotEmpty
        ? backup.worldNames.join(', ')
        : backup.title;
    final version = backup.minecraftVersion == null ? '' : ' • ${backup.minecraftVersion}';
    return '$name$version • ${backup.worldCount} ${t.t('minecraft_world_count')}';
  }

  Widget _sectionTitle(String title, IconData icon, {Color color = NovaTheme.neonCyan}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: TextStyle(color: color, fontSize: 13.5, fontWeight: FontWeight.w800))),
          ],
        ),
      );

  Widget _settingDropdown({
    required String label,
    required String value,
    required List<String> values,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      dropdownColor: NovaTheme.card,
      decoration: InputDecoration(labelText: label),
      items: values.map((item) => DropdownMenuItem<String>(value: item, child: Text(item, textDirection: TextDirection.ltr))).toList(),
      onChanged: onChanged,
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    if (!_restored && st.api != null && !_busy) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_restored) _initialize();
      });
    }
    final version = _selectedVersion;
    final latestBackup = _backups.where((backup) => backup.complete).isEmpty
        ? null
        : _backups.firstWhere((backup) => backup.complete);
    final restoreValue = _backups.any((backup) => backup.complete && backup.tag == _restoreTag)
        ? _restoreTag
        : 'none';

    return GlowBackground(
      aurora: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.t('minecraft_cloud')),
          actions: [
            IconButton(
              tooltip: t.t('refresh'),
              onPressed: _refreshBusy || _repo == null ? null : () => _refreshRepo(),
              icon: _refreshBusy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.refresh_rounded, color: NovaTheme.neonCyan),
            ),
          ],
        ),
        body: st.api == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: NovaEmptyState(
                    icon: Icons.person_off_outlined,
                    title: t.t('need_login'),
                    subtitle: t.t('minecraft_github_required'),
                    color: NovaTheme.warn,
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  GlassCard(
                    aurora: true,
                    borderColor: NovaTheme.neonPurple.withOpacity(0.65),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.sports_esports_rounded, color: NovaTheme.neonCyan, size: 25),
                            const SizedBox(width: 10),
                            Expanded(child: Text(t.t('minecraft_cloud'), style: const TextStyle(color: NovaTheme.text, fontSize: 17, fontWeight: FontWeight.w900))),
                            const StatusBadge(label: 'JAVA', color: NovaTheme.neonPurpleSoft),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(t.t('minecraft_intro'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 12.5, height: 1.5)),
                        const SizedBox(height: 10),
                        Text(t.t('minecraft_limits_summary'), style: const TextStyle(color: NovaTheme.warn, fontSize: 11.5, height: 1.45)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionTitle(t.t('minecraft_repository'), Icons.folder_special_rounded),
                  GlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    onTap: _busy ? null : _selectRepository,
                    child: Row(
                      children: [
                        Icon(_repo?.isPrivate == true ? Icons.lock_rounded : Icons.folder_open_rounded, color: NovaTheme.neonPurpleSoft),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_repo?.fullName ?? t.t('minecraft_select_private_repo'), textDirection: _repo == null ? null : TextDirection.ltr, style: const TextStyle(color: NovaTheme.text, fontSize: 12.5, fontWeight: FontWeight.w700)),
                              Text(_repo == null ? t.t('minecraft_repo_private_hint') : t.t('minecraft_private_repo_title'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 10.5)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: NovaTheme.neonCyan),
                      ],
                    ),
                  ),
                  if (_repo != null) ...[
                    const SizedBox(height: 14),
                    _buildWorkflowAndSecrets(t),
                    const SizedBox(height: 14),
                    _sectionTitle(t.t('minecraft_version'), Icons.system_update_alt_rounded),
                    GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (_versionsError != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.t('minecraft_versions_error'), style: const TextStyle(color: NovaTheme.warn, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 6),
                                Text(_versionsError!, textDirection: TextDirection.ltr, style: const TextStyle(color: NovaTheme.textDim, fontSize: 11)),
                                TextButton.icon(onPressed: _loadVersions, icon: const Icon(Icons.refresh_rounded), label: Text(t.t('retry'))),
                              ],
                            )
                          else if (_manifest == null)
                            const Center(child: Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2)))
                          else ...[
                            Wrap(
                              spacing: 8,
                              children: [
                                ChoiceChip(
                                  label: Text(t.t('minecraft_release')),
                                  selected: _versionType == 'release',
                                  onSelected: (_) {
                                    setState(() {
                                      _versionType = 'release';
                                      if (!_manifest!.versions.any((item) => item.id == _versionId && item.type == 'release')) {
                                        _versionId = _manifest!.latestRelease;
                                      }
                                    });
                                    unawaited(_saveOptions());
                                  },
                                ),
                                ChoiceChip(
                                  label: Text(t.t('minecraft_snapshot')),
                                  selected: _versionType == 'snapshot',
                                  onSelected: (_) {
                                    setState(() {
                                      _versionType = 'snapshot';
                                      if (!_manifest!.versions.any((item) => item.id == _versionId && item.type == 'snapshot')) {
                                        _versionId = _manifest!.latestSnapshot;
                                      }
                                    });
                                    unawaited(_saveOptions());
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: _chooseVersion,
                              icon: const Icon(Icons.search_rounded),
                              label: Row(
                                children: [
                                  Expanded(child: Text(version?.id ?? t.t('minecraft_choose_version'), textAlign: TextAlign.start, textDirection: TextDirection.ltr)),
                                  if (version?.id == _manifest?.latestRelease || version?.id == _manifest?.latestSnapshot)
                                    StatusBadge(label: t.t('minecraft_latest'), color: NovaTheme.ok),
                                ],
                              ),
                            ),
                            Text(t.t('minecraft_version_source'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 10.5)),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle(t.t('minecraft_resources'), Icons.tune_rounded),
                    GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(child: _settingDropdown(label: t.t('minecraft_duration'), value: _hours, values: const ['1', '2', '3', '4'], onChanged: (value) {
                                setState(() => _hours = value ?? _hours);
                                unawaited(_saveOptions());
                              })),
                              const SizedBox(width: 10),
                              Expanded(child: _settingDropdown(label: t.t('minecraft_java_heap'), value: _memoryGb, values: const ['2', '4', '6', '8'], onChanged: (value) {
                                setState(() => _memoryGb = value ?? _memoryGb);
                                unawaited(_saveOptions());
                              })),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(child: _settingDropdown(label: t.t('minecraft_resolution'), value: _resolution, values: const ['1280x720', '1600x900'], onChanged: (value) {
                                setState(() => _resolution = value ?? _resolution);
                                unawaited(_saveOptions());
                              })),
                              const SizedBox(width: 10),
                              Expanded(child: _settingDropdown(label: t.t('minecraft_render_distance'), value: _renderDistance, values: const ['4', '6', '8', '10', '12'], onChanged: (value) {
                                setState(() => _renderDistance = value ?? _renderDistance);
                                unawaited(_saveOptions());
                              })),
                            ],
                          ),
                          _settingDropdown(label: t.t('minecraft_fps_limit'), value: _fpsLimit, values: const ['20', '30', '45', '60'], onChanged: (value) {
                            setState(() => _fpsLimit = value ?? _fpsLimit);
                            unawaited(_saveOptions());
                          }),
                          const SizedBox(height: 8),
                          Text(t.t('minecraft_resource_note'), style: const TextStyle(color: NovaTheme.warn, fontSize: 11, height: 1.45)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _sectionTitle(t.t('minecraft_worlds'), Icons.public_rounded, color: NovaTheme.neonPurpleSoft),
                    GlassCard(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(t.t('minecraft_restore_hint'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5, height: 1.4)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: restoreValue,
                            isExpanded: true,
                            dropdownColor: NovaTheme.card,
                            decoration: InputDecoration(labelText: t.t('minecraft_restore_worlds')),
                            items: [
                              DropdownMenuItem(value: 'none', child: Text(t.t('minecraft_start_empty'))),
                              for (final backup in _backups.where((item) => item.complete))
                                DropdownMenuItem(
                                  value: backup.tag,
                                  child: Text(
                                    _backupLabel(backup, t),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              setState(() => _restoreTag = value ?? 'none');
                              unawaited(_saveOptions());
                            },
                          ),
                          const SizedBox(height: 10),
                          if (_backups.isEmpty)
                            Text(t.t('minecraft_no_backups'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5))
                          else
                            ..._backups.take(4).map((backup) => Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Icon(backup.complete ? Icons.verified_outlined : Icons.warning_amber_rounded, size: 16, color: backup.complete ? NovaTheme.ok : NovaTheme.warn),
                                      const SizedBox(width: 7),
                                      Expanded(child: Text(_backupLabel(backup, t, worlds: true), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NovaTheme.textDim, fontSize: 10.5))),
                                      Text(_fmtSize(backup.totalBytes), style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 10)),
                                    ],
                                  ),
                                )),
                          if (latestBackup != null)
                            Text('${t.t('minecraft_latest_backup')}: ${latestBackup.createdAt.toLocal().toString().split('.').first}', style: const TextStyle(color: NovaTheme.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildRunCard(t),
                    const SizedBox(height: 14),
                    if (_error != null) ...[
                      NovaErrorState(
                        icon: Icons.error_outline_rounded,
                        title: t.t('error'),
                        subtitle: _error!,
                        subtitleDirection: TextDirection.ltr,
                        action: TextButton.icon(onPressed: () => setState(() => _error = null), icon: const Icon(Icons.close_rounded), label: Text(t.t('dismiss'))),
                      ),
                      const SizedBox(height: 12),
                    ],
                    GradientButton(
                      label: _busy ? t.t('minecraft_starting') : t.t('minecraft_start'),
                      icon: _busy ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded,
                      onPressed: _busy || _isActive || _dispatchRequestedAt != null || version == null || !_secretsReady ? null : _startMinecraft,
                    ),
                    if (!_secretsReady) ...[
                      const SizedBox(height: 7),
                      Text(t.t('minecraft_secrets_required'), textAlign: TextAlign.center, style: const TextStyle(color: NovaTheme.warn, fontSize: 10.5)),
                    ],
                  ],
                  if (_repo == null && !st.busy) ...[
                    const SizedBox(height: 12),
                    GradientButton(label: t.t('minecraft_select_private_repo'), icon: Icons.folder_open_rounded, onPressed: _selectRepository),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _buildWorkflowAndSecrets(L10n t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(_workflowExists ? Icons.account_tree_rounded : Icons.build_circle_outlined, color: _workflowExists ? NovaTheme.ok : NovaTheme.warn),
              const SizedBox(width: 9),
              Expanded(child: Text(_workflowExists ? t.t('minecraft_workflow_ready') : t.t('minecraft_workflow_missing'), style: const TextStyle(color: NovaTheme.text, fontSize: 12, fontWeight: FontWeight.w700))),
              if (!_workflowExists)
                TextButton(onPressed: _busy ? null : _installWorkflowFromButton, child: Text(t.t('minecraft_install_workflow'))),
            ],
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.security_rounded, color: NovaTheme.neonPurpleSoft),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.t('minecraft_auth_and_secrets'), style: const TextStyle(color: NovaTheme.text, fontWeight: FontWeight.w800, fontSize: 13))),
                  StatusBadge(label: _secretsReady ? t.t('ready') : t.t('not_ready'), color: _secretsReady ? NovaTheme.ok : NovaTheme.warn),
                ],
              ),
              const SizedBox(height: 8),
              Text(t.t('minecraft_auth_help'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 11, height: 1.45)),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse('https://entra.microsoft.com/#view/Microsoft_AAD_RegisteredApps/ApplicationsListBlade'),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new_rounded, size: 16),
                  label: Text(t.t('minecraft_register_microsoft_app')),
                ),
              ),
              _secretStatusRow(t.t('minecraft_client_id'), Const.secretMinecraftClientId),
              _secretStatusRow(t.t('minecraft_viewer_password'), Const.secretMinecraftAccess),
              _secretStatusRow(t.t('minecraft_backup_password'), Const.secretMinecraftBackup),
              const SizedBox(height: 8),
              TextField(
                controller: _clientId,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                decoration: InputDecoration(labelText: t.t('minecraft_client_id'), hintText: t.t('minecraft_client_id_hint')),
              ),
              TextField(
                controller: _viewerPassword,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t.t('minecraft_viewer_password'),
                  hintText: t.t('minecraft_keep_secret_hint'),
                  suffixIcon: IconButton(tooltip: t.t('minecraft_generate_password'), icon: const Icon(Icons.auto_awesome_rounded), onPressed: () => setState(() => _viewerPassword.text = _generatePassword())),
                ),
              ),
              TextField(
                controller: _backupPassword,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: t.t('minecraft_backup_password'),
                  hintText: t.t('minecraft_keep_secret_hint'),
                  suffixIcon: IconButton(tooltip: t.t('minecraft_generate_password'), icon: const Icon(Icons.auto_awesome_rounded), onPressed: () => setState(() => _backupPassword.text = _generatePassword())),
                ),
              ),
              const SizedBox(height: 9),
              SecondaryNeonButton(
                label: _savingSecrets ? t.t('saving') : t.t('minecraft_save_secrets'),
                icon: Icons.lock_rounded,
                onPressed: _savingSecrets || _busy ? null : _saveMinecraftSecrets,
              ),
              const SizedBox(height: 6),
              Text(t.t('minecraft_secret_storage_note'), style: const TextStyle(color: NovaTheme.textMuted, fontSize: 10.5, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _secretStatusRow(String label, String name) {
    final exists = _secretNames.contains(name);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(exists ? Icons.check_circle_outline_rounded : Icons.radio_button_unchecked_rounded, size: 15, color: exists ? NovaTheme.ok : NovaTheme.warn),
          const SizedBox(width: 7),
          Expanded(child: Text(label, style: const TextStyle(color: NovaTheme.textDim, fontSize: 10.5))),
          Text(exists ? L10n.of(context).t('minecraft_secret_configured') : L10n.of(context).t('minecraft_secret_missing'), style: TextStyle(color: exists ? NovaTheme.ok : NovaTheme.warn, fontSize: 9.5)),
        ],
      ),
    );
  }

  Widget _buildRunCard(L10n t) {
    final isBusy = _isActive || _dispatchRequestedAt != null;
    final runId = _run?['id'];
    final color = _statusColor();
    return GlassCard(
      borderColor: color.withOpacity(0.55),
      glowColor: color,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(isBusy ? Icons.sync_rounded : Icons.cloud_done_outlined, color: color),
              const SizedBox(width: 9),
              Expanded(child: Text(t.t('minecraft_session'), style: const TextStyle(color: NovaTheme.text, fontWeight: FontWeight.w800))),
              StatusBadge(label: _currentStatus(t), color: color, pulsing: isBusy),
            ],
          ),
          if (runId != null) ...[
            const SizedBox(height: 5),
            Text('#$runId • ${_run?['head_branch'] ?? ''}', textDirection: TextDirection.ltr, style: const TextStyle(color: NovaTheme.textMuted, fontSize: 10.5)),
          ],
          if (_steps.isNotEmpty) ...[
            const Divider(color: NovaTheme.cardBorder, height: 18),
            for (final step in _steps.where((step) => step.status == 'in_progress' || step.conclusion == 'failure' || step.conclusion == 'success').take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(step.conclusion == 'success' ? Icons.check_circle : step.conclusion == 'failure' ? Icons.error : Icons.sync, size: 15, color: step.conclusion == 'failure' ? NovaTheme.danger : step.conclusion == 'success' ? NovaTheme.ok : NovaTheme.neonCyan),
                    const SizedBox(width: 7),
                    Expanded(child: Text(step.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: NovaTheme.textDim, fontSize: 10.5))),
                  ],
                ),
              ),
          ],
          if (_sessionInfo?.webUrl != null && _isActive) ...[
            const SizedBox(height: 10),
            GradientButton(
              label: t.t('minecraft_connect'),
              icon: Icons.videogame_asset_rounded,
              onPressed: _connectToSession,
            ),
          ],
          if (_isActive) ...[
            const SizedBox(height: 7),
            OutlinedButton.icon(
              onPressed: _stopRequested ? null : _requestStop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: Text(_stopRequested ? t.t('minecraft_stop_pending') : t.t('minecraft_stop_save')),
            ),
          ],
          if (_isActive && _sessionInfo?.webUrl == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(t.t('minecraft_waiting_viewer'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 10.5)),
            ),
        ],
      ),
    );
  }
}

enum _MinecraftCreateRequest { create }

class MinecraftPlayScreen extends StatefulWidget {
  final String viewerUrl;
  final String viewerPassword;
  final String version;

  const MinecraftPlayScreen({
    super.key,
    required this.viewerUrl,
    required this.viewerPassword,
    required this.version,
  });

  @override
  State<MinecraftPlayScreen> createState() => _MinecraftPlayScreenState();
}

class _MinecraftPlayScreenState extends State<MinecraftPlayScreen> {
  final Set<String> _heldKeys = {};
  final Set<String> _toggleKeys = {};
  int? _platformViewId;
  String _viewerStatus = 'connecting';
  double _controlScale = 1;
  double _controlOpacity = 0.78;
  bool _leftHanded = false;
  bool _controlsVisible = true;
  bool _settingsReady = false;

  @override
  void initState() {
    super.initState();
    _minecraftViewerChannel.setMethodCallHandler(_onNativeCall);
    _restoreControlSettings();
  }

  Future<void> _restoreControlSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _controlScale = prefs.getDouble('minecraft_control_scale') ?? 1;
      _controlOpacity = prefs.getDouble('minecraft_control_opacity') ?? 0.78;
      _leftHanded = prefs.getBool('minecraft_left_handed') ?? false;
      _controlsVisible = prefs.getBool('minecraft_controls_visible') ?? true;
      _settingsReady = true;
    });
  }

  Future<Object?> _onNativeCall(MethodCall call) async {
    if (call.method == 'viewerStatus' && call.arguments is Map) {
      final args = Map<Object?, Object?>.from(call.arguments as Map);
      if (args['viewId'] == _platformViewId && mounted) {
        setState(() => _viewerStatus = args['status'] as String? ?? 'connecting');
      }
    }
    return null;
  }

  @override
  void dispose() {
    _releaseHeldKeys();
    _minecraftViewerChannel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _send(String method, [Map<String, Object?> extra = const {}]) async {
    final viewId = _platformViewId;
    if (viewId == null) return;
    try {
      await _minecraftViewerChannel.invokeMethod<void>(method, {'viewId': viewId, ...extra});
    } on PlatformException {
      // The view can be disposed between a pointer-up event and the channel call.
    } on MissingPluginException {
      if (mounted) setState(() => _viewerStatus = 'unsupported');
    }
  }

  void _setKey(String key, bool down) {
    if (down) {
      if (!_heldKeys.add(key)) return;
    } else {
      if (!_heldKeys.remove(key)) return;
    }
    _send('sendKey', {'key': key, 'down': down});
  }

  void _releaseHeldKeys() {
    final keys = _heldKeys.toList(growable: false);
    _heldKeys.clear();
    for (final key in keys) {
      _send('sendKey', {'key': key, 'down': false});
    }
    _send('clickPointer', {'button': 'left', 'down': false});
    _send('clickPointer', {'button': 'right', 'down': false});
  }

  void _updateJoystick(Offset point, double side) {
    final dx = (point.dx - side / 2) / (side / 2);
    final dy = (point.dy - side / 2) / (side / 2);
    const threshold = 0.24;
    final next = <String>{
      if (dy < -threshold) 'w',
      if (dy > threshold) 's',
      if (dx < -threshold) 'a',
      if (dx > threshold) 'd',
    };
    for (final key in {'w', 'a', 's', 'd'}) {
      if (next.contains(key) != _heldKeys.contains(key)) _setKey(key, next.contains(key));
    }
  }

  Widget _joystick() {
    final side = 142 * _controlScale;
    return Opacity(
      opacity: _controlOpacity,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanDown: (details) => _updateJoystick(details.localPosition, side),
        onPanUpdate: (details) => _updateJoystick(details.localPosition, side),
        onPanEnd: (_) => _updateJoystick(Offset(side / 2, side / 2), side),
        onPanCancel: () => _updateJoystick(Offset(side / 2, side / 2), side),
        child: SizedBox(
          width: side,
          height: side,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: NovaTheme.bg.withOpacity(0.50),
              shape: BoxShape.circle,
              border: Border.all(color: NovaTheme.neonCyan.withOpacity(0.75), width: 2),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.circle, size: side * 0.25, color: NovaTheme.neonBlue.withOpacity(0.55)),
                const Positioned(top: 8, child: Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white70)),
                const Positioned(bottom: 8, child: Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white70)),
                const Positioned(left: 8, child: Icon(Icons.keyboard_arrow_left_rounded, color: Colors.white70)),
                const Positioned(right: 8, child: Icon(Icons.keyboard_arrow_right_rounded, color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _touchButton({
    required String label,
    required IconData icon,
    double size = 58,
    String? key,
    String? mouseButton,
    bool toggleOnTap = false,
  }) {
    final toggled = key != null && _toggleKeys.contains(key);
    return Opacity(
      opacity: _controlOpacity,
      child: GestureDetector(
        onTapDown: (_) {
          if (toggleOnTap && key != null) {
            final next = !toggled;
            setState(() {
              if (next) {
                _toggleKeys.add(key);
              } else {
                _toggleKeys.remove(key);
              }
            });
            _setKey(key, next);
          } else if (key != null) {
            _setKey(key, true);
          } else if (mouseButton != null) {
            _send('clickPointer', {'button': mouseButton, 'down': true});
          }
        },
        onTapUp: (_) {
          if (toggleOnTap) return;
          if (key != null) _setKey(key, false);
          if (mouseButton != null) _send('clickPointer', {'button': mouseButton, 'down': false});
        },
        onTapCancel: () {
          if (toggleOnTap) return;
          if (key != null) _setKey(key, false);
          if (mouseButton != null) _send('clickPointer', {'button': mouseButton, 'down': false});
        },
        child: Container(
          width: size * _controlScale,
          height: size * _controlScale,
          decoration: BoxDecoration(
            color: (toggled ? NovaTheme.neonBlue : NovaTheme.bg2).withOpacity(0.9),
            borderRadius: BorderRadius.circular(size * 0.36),
            border: Border.all(color: toggled ? NovaTheme.neonCyan : NovaTheme.cardBorderBright, width: 1.5),
            boxShadow: toggled ? [BoxShadow(color: NovaTheme.neonCyan.withOpacity(0.25), blurRadius: 12)] : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: size * 0.38),
              const SizedBox(height: 1),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lookArea(double width, double height) => Positioned(
        left: width * 0.25,
        right: width * 0.25,
        top: 80,
        bottom: min(155 * _controlScale, max(88.0, height * 0.24)),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanUpdate: (details) => _send('movePointer', {
            'dx': details.delta.dx,
            'dy': details.delta.dy,
          }),
          child: Align(
            alignment: _leftHanded ? Alignment.centerLeft : Alignment.centerRight,
            child: Opacity(
              opacity: _controlOpacity * 0.75,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.18), borderRadius: BorderRadius.circular(22)),
                child: const Icon(Icons.control_camera_rounded, color: Colors.white54, size: 18),
              ),
            ),
          ),
        ),
      );

  Future<void> _showControlSettings() async {
    var scale = _controlScale;
    var opacity = _controlOpacity;
    var leftHanded = _leftHanded;
    var visible = _controlsVisible;
    final t = L10n.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: NovaTheme.card,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.t('minecraft_control_settings'), style: const TextStyle(color: NovaTheme.text, fontWeight: FontWeight.w800, fontSize: 17)),
                const SizedBox(height: 12),
                Text('${t.t('minecraft_control_size')}: ${(scale * 100).round()}%', style: const TextStyle(color: NovaTheme.textDim)),
                Slider(value: scale, min: 0.75, max: 1.3, divisions: 11, onChanged: (value) => setSheetState(() => scale = value)),
                Text('${t.t('minecraft_control_opacity')}: ${(opacity * 100).round()}%', style: const TextStyle(color: NovaTheme.textDim)),
                Slider(value: opacity, min: 0.35, max: 0.95, divisions: 12, onChanged: (value) => setSheetState(() => opacity = value)),
                SwitchListTile.adaptive(title: Text(t.t('minecraft_left_handed')), value: leftHanded, onChanged: (value) => setSheetState(() => leftHanded = value)),
                SwitchListTile.adaptive(title: Text(t.t('minecraft_show_controls')), value: visible, onChanged: (value) => setSheetState(() => visible = value)),
                const SizedBox(height: 8),
                GradientButton(
                  label: t.t('save_settings'),
                  icon: Icons.save_rounded,
                  onPressed: () => Navigator.pop(sheetContext),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      _controlScale = scale;
      _controlOpacity = opacity;
      _leftHanded = leftHanded;
      _controlsVisible = visible;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('minecraft_control_scale', scale);
    await prefs.setDouble('minecraft_control_opacity', opacity);
    await prefs.setBool('minecraft_left_handed', leftHanded);
    await prefs.setBool('minecraft_controls_visible', visible);
  }

  Future<void> _showTextEntry() async {
    final controller = TextEditingController();
    final t = L10n.of(context);
    final text = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: NovaTheme.card,
        title: Text(t.t('minecraft_send_text')),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 2,
          decoration: InputDecoration(hintText: t.t('minecraft_send_text_hint')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: Text(t.t('cancel'))),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            icon: const Icon(Icons.send_rounded),
            label: Text(t.t('minecraft_send')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty) return;
    await _send('typeText', {'text': text});
  }

  Future<void> _exitViewer() async {
    _releaseHeldKeys();
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return PopScope<void>(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _releaseHeldKeys();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.black.withOpacity(0.48),
          title: Text('Minecraft Java ${widget.version}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.white)),
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: _exitViewer),
          actions: [
            IconButton(tooltip: t.t('minecraft_send_text'), icon: const Icon(Icons.keyboard_alt_outlined), onPressed: _showTextEntry),
            IconButton(tooltip: t.t('minecraft_control_settings'), icon: const Icon(Icons.tune_rounded), onPressed: _showControlSettings),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final height = constraints.maxHeight;
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (isAndroid)
                    AndroidView(
                      viewType: 'nova/minecraft_viewer',
                      creationParamsCodec: const StandardMessageCodec(),
                      creationParams: {
                        'url': widget.viewerUrl,
                        'password': widget.viewerPassword,
                        'username': 'nova',
                      },
                      onPlatformViewCreated: (id) => setState(() => _platformViewId = id),
                    )
                  else
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(t.t('minecraft_android_view_only'), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
                      ),
                    ),
                  Positioned(
                    top: 62,
                    right: 10,
                    child: StatusBadge(
                      label: t.t('minecraft_viewer_${_viewerStatus}'),
                      color: _viewerStatus == 'connected' ? NovaTheme.ok : NovaTheme.neonCyan,
                      pulsing: _viewerStatus == 'connecting',
                    ),
                  ),
                  if (_controlsVisible && isAndroid && _settingsReady) ...[
                    _lookArea(width, height),
                    Positioned(
                      left: _leftHanded ? null : 16,
                      right: _leftHanded ? 16 : null,
                      bottom: 24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _joystick(),
                          const SizedBox(height: 7),
                          _touchButton(label: t.t('minecraft_sprint'), icon: Icons.directions_run_rounded, size: 48, key: 'ctrl', toggleOnTap: true),
                        ],
                      ),
                    ),
                    Positioned(
                      right: _leftHanded ? null : 14,
                      left: _leftHanded ? 14 : null,
                      bottom: 22,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            _touchButton(label: t.t('minecraft_inventory'), icon: Icons.backpack_outlined, size: 48, key: 'e'),
                            const SizedBox(width: 6),
                            _touchButton(label: t.t('minecraft_menu'), icon: Icons.menu_rounded, size: 48, key: 'escape'),
                            const SizedBox(width: 6),
                            _touchButton(label: t.t('minecraft_crouch'), icon: Icons.keyboard_arrow_down_rounded, size: 48, key: 'shift', toggleOnTap: true),
                          ]),
                          const SizedBox(height: 8),
                          Row(mainAxisSize: MainAxisSize.min, children: [
                            _touchButton(label: t.t('minecraft_attack'), icon: Icons.gps_fixed_rounded, size: 64, mouseButton: 'left'),
                            const SizedBox(width: 8),
                            _touchButton(label: t.t('minecraft_jump'), icon: Icons.arrow_upward_rounded, size: 58, key: 'space'),
                            const SizedBox(width: 8),
                            _touchButton(label: t.t('minecraft_use'), icon: Icons.touch_app_rounded, size: 64, mouseButton: 'right'),
                          ]),
                        ],
                      ),
                    ),
                    Positioned(
                      top: 62,
                      left: 10,
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        for (final digit in const ['1', '2', '3']) ...[
                          _touchButton(label: digit, icon: Icons.circle_outlined, size: 40, key: digit),
                          const SizedBox(width: 4),
                        ],
                        _touchButton(label: 'Q', icon: Icons.front_hand_outlined, size: 40, key: 'q'),
                      ]),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
