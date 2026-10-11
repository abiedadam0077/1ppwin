import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/const.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../services/github_service.dart';
import '../state/app_state.dart';

class SessionSetupScreen extends StatefulWidget {
  const SessionSetupScreen({super.key});

  @override
  State<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends State<SessionSetupScreen> {
  double _hours = 4;
  bool _fresh = false;
  bool _rdp = true;
  bool _web = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final st = context.read<AppState>();
    _hours = st.sessionHours.toDouble();
    _fresh = st.sessionFreshInstall;
    _web = st.webAccessEnabled;
    _rdp = st.rdpEnabled;
  }

  void _setFresh(AppState st, bool fresh) {
    setState(() => _fresh = fresh);
    st.updateSessionOptions(fresh: fresh);
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final repo = st.selectedRepo;
    final h = _hours.round().clamp(1, Const.maxSessionHours).toInt();
    final latestBackup = st.latestCompleteBackup;
    final backupLabel = latestBackup != null
        ? latestBackup.tag
        : st.backupsError != null
            ? t.t('backups_load_failed')
            : st.backupsBusy || st.backupsList == null
                ? t.t('loading_backups')
                : st.backupsList!.isEmpty
                    ? t.t('no_backups')
                    : t.t('backup_incomplete');

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('session'))),
        body: repo == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: NovaEmptyState(
                    icon: Icons.folder_open_rounded,
                    title: t.t('no_repo_selected'),
                    subtitle: t.t('no_repo_selected_sub'),
                    color: NovaTheme.neonCyan,
                    action: GradientButton(
                      label: t.t('choose_repo'),
                      icon: Icons.folder_open_rounded,
                      onPressed: () {
                        st.setTab(1);
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      children: [
                        Text(
                          t.t('session_sub'),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: NovaTheme.textDim, fontSize: 12.5, height: 1.35),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          padding: const EdgeInsets.all(14),
                          borderColor: NovaTheme.neonBlue.withOpacity(0.55),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.timer_outlined, color: NovaTheme.neonCyan, size: 19),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      t.t('duration'),
                                      style: const TextStyle(color: NovaTheme.text, fontSize: 13.5, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                  StatusBadge(
                                    label: '$h ${t.t('hours')}',
                                    color: NovaTheme.neonCyan,
                                    icon: Icons.schedule_rounded,
                                  ),
                                ],
                              ),
                              Slider.adaptive(
                                value: _hours,
                                min: 1,
                                max: Const.maxSessionHours.toDouble(),
                                divisions: Const.maxSessionHours - 1,
                                activeColor: NovaTheme.neonBlue,
                                onChanged: (value) {
                                  setState(() => _hours = value);
                                  st.updateSessionOptions(hours: value.round());
                                },
                              ),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('1h', style: TextStyle(color: NovaTheme.textDim, fontSize: 11)),
                                    Text(
                                      '${Const.maxSessionHours}h',
                                      style: const TextStyle(color: NovaTheme.textDim, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${h * 60} ${t.t('minutes')}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5),
                              ),
                              const Divider(color: NovaTheme.cardBorder, height: 22),
                              Row(
                                children: [
                                  Expanded(
                                    child: _bootOption(
                                      icon: Icons.restore_rounded,
                                      label: t.t('restore_prev'),
                                      selected: !_fresh,
                                      onTap: () => _setFresh(st, false),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _bootOption(
                                      icon: Icons.cleaning_services_outlined,
                                      label: t.t('fresh_install'),
                                      selected: _fresh,
                                      onTap: () => _setFresh(st, true),
                                    ),
                                  ),
                                ],
                              ),
                              if (_fresh) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: NovaTheme.warn.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(11),
                                    border: Border.all(color: NovaTheme.warn.withOpacity(0.48)),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.warning_amber_rounded, color: NovaTheme.warn, size: 17),
                                      const SizedBox(width: 7),
                                      Expanded(
                                        child: Text(
                                          t.t('fresh_warn'),
                                          style: const TextStyle(color: NovaTheme.warn, fontSize: 11, height: 1.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const Divider(color: NovaTheme.cardBorder, height: 22),
                              Row(
                                children: [
                                  const Icon(Icons.public_rounded, color: NovaTheme.neonCyan, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      t.t('session_options'),
                                      style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12.5, fontWeight: FontWeight.w800),
                                    ),
                                  ),
                                ],
                              ),
                              NeonSwitch(
                                label: t.t('web_access'),
                                sub: 'Cloudflare HTTPS Tunnel',
                                icon: Icons.language_rounded,
                                value: _web,
                                onChanged: (value) {
                                  setState(() => _web = value);
                                  st.updateSessionOptions(webAccess: value);
                                },
                              ),
                              NeonSwitch(
                                label: t.t('enable_rdp'),
                                sub: st.hasTailscaleSecret
                                    ? 'TAILSCALE_AUTHKEY ✓'
                                    : 'TAILSCALE_AUTHKEY (${t.t('secret_optional')})',
                                icon: Icons.desktop_windows_outlined,
                                value: _rdp,
                                onChanged: (value) {
                                  setState(() => _rdp = value);
                                  st.updateSessionOptions(enableRdp: value);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.fact_check_outlined, color: NovaTheme.neonCyan, size: 18),
                                  const SizedBox(width: 7),
                                  Text(
                                    t.t('summary'),
                                    style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12.5, fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  repo.fullName,
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: NovaTheme.text, fontSize: 12.5, fontWeight: FontWeight.w700),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  StatusBadge(
                                    label: '$h ${t.t('hours')}',
                                    color: NovaTheme.neonBlue,
                                    icon: Icons.timer_outlined,
                                  ),
                                  StatusBadge(
                                    label: t.t(_fresh ? 'fresh_install' : 'restore_session'),
                                    color: _fresh ? NovaTheme.warn : NovaTheme.neonPurpleSoft,
                                    icon: _fresh ? Icons.cleaning_services_outlined : Icons.restore_rounded,
                                  ),
                                  StatusBadge(
                                    label: backupLabel,
                                    color: latestBackup != null ? NovaTheme.ok : NovaTheme.textDim,
                                    icon: latestBackup != null ? Icons.cloud_done_rounded : Icons.backup_outlined,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
                      child: GradientButton(
                        label: t.t('start_windows'),
                        icon: Icons.rocket_launch_rounded,
                        busy: _busy,
                        onPressed: _busy
                            ? null
                            : () async {
                                setState(() => _busy = true);
                                try {
                                  await st.startRun(
                                    hours: h,
                                    fresh: _fresh,
                                    webAccess: _web,
                                    enableRdp: _rdp,
                                  );
                                  if (context.mounted) {
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(builder: (_) => const ProgressScreen()),
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('${t.t('error')}: $e')),
                                    );
                                  }
                                } finally {
                                  if (mounted) setState(() => _busy = false);
                                }
                              },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _bootOption({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) => InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 66),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? NovaTheme.neonBlue.withOpacity(0.16) : NovaTheme.bg2.withOpacity(0.7),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: selected ? NovaTheme.neonCyan.withOpacity(0.75) : NovaTheme.cardBorder),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                color: selected ? NovaTheme.neonCyan : NovaTheme.textMuted,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? NovaTheme.text : NovaTheme.textDim,
                    fontSize: 10.5,
                    height: 1.2,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: selected ? NovaTheme.neonCyan : NovaTheme.textMuted, size: 16),
            ],
          ),
        ),
      );
}

/// Screen #7: Live workflow progress driven by REAL job steps from the GitHub API.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  Timer? _timer;
  List<WorkflowStepState> _steps = [];
  Map<String, dynamic>? _run;
  String? _error;
  bool _repairing = false;
  bool _navigatedToReady = false;

  static const _stageToStep = <String, List<String>>{
    'checking_permissions': ['Set up job', 'Record start time'],
    'checking_secrets': ['Check secrets'],
    'preparing_runner': ['Enable KVM', 'Free disk space & choose storage location', 'Pull images'],
    'restoring_backup': ['Restore saved Windows'],
    'starting_vm': ['Start Windows'],
    'starting_web': ['Start web access (password-protected)'],
    'connecting_tailscale': ['Connect Tailscale (optional, for RDP)'],
    'windows_running': ['Windows is running (open the link in the step above)'],
  };

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) => _poll());
    _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (!mounted) return;
    final st = context.read<AppState>();
    if (st.api == null || st.selectedRepo == null) return;
    final repoName = st.selectedRepo!.fullName;

    try {
      Map<String, dynamic>? candidate;
      if (st.runId != null) {
        candidate = await st.api!.getRun(repoName, st.runId!);
      }
      candidate ??= await st.api!.latestRun(repoName);
      if (candidate == null) return;

      final createdAt = DateTime.tryParse(candidate['created_at'] as String? ?? '');
      final mine = st.runStartedAt == null ||
          createdAt == null ||
          !createdAt.isBefore(st.runStartedAt!.subtract(const Duration(minutes: 2)));
      if (!mine) {
        // Still waiting for the newly dispatched workflow run to appear on GitHub
        if (mounted) setState(() {});
        return;
      }

      _run = candidate;
      st.latestRunData = candidate;
      final id = candidate['id'] as int;
      st.runId = id;

      final startedStr = candidate['run_started_at'] as String? ?? candidate['created_at'] as String? ?? '';
      final parsedStart = DateTime.tryParse(startedStr);
      if (parsedStart != null) st.runStartedAt = parsedStart;

      final status = candidate['status'] as String? ?? '';
      if (status != 'queued' && status != 'waiting') {
        _steps = await st.api!.runSteps(repoName, id);
        final needsWebInfo = st.webAccessEnabled && st.sessionInfo?.webUrl == null;
        final needsRdpInfo = st.rdpEnabled && st.hasTailscaleSecret && st.sessionInfo?.tailscaleIp == null;
        if (needsWebInfo || needsRdpInfo) {
          final info = await st.api!.sessionInfo(repoName, id);
          if (info != null) st.sessionInfo = info;
        }
      }

      _error = null;
      if (mounted) setState(() {});

      final expectsAccessRoute = st.webAccessEnabled || (st.rdpEnabled && st.hasTailscaleSecret);
      if (_isRunning && (st.sessionInfo != null || !expectsAccessRoute) && !_navigatedToReady) {
        _navigatedToReady = true;
        _goReady();
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  bool get _isRunning {
    final s = _stepByName('Windows is running (open the link in the step above)');
    return s != null && s.status == 'in_progress';
  }

  bool get _isRunFailed {
    final status = _run?['status'] as String? ?? '';
    final conclusion = _run?['conclusion'] as String? ?? '';
    return status == 'completed' &&
        (conclusion == 'failure' || conclusion == 'startup_failure' || conclusion == 'cancelled');
  }

  String? get _failedStepName {
    for (final s in _steps) {
      if (s.conclusion == 'failure') return s.name;
    }
    return null;
  }

  WorkflowStepState? _stepByName(String n) {
    for (final s in _steps) {
      if (s.name == n) return s;
    }
    return null;
  }

  int get _completedStepCount => _steps
      .where((step) => step.status == 'completed' && (step.conclusion == 'success' || step.conclusion == 'skipped'))
      .length;

  double? get _stepProgress =>
      _steps.isEmpty ? null : (_completedStepCount / _steps.length).clamp(0.0, 1.0).toDouble();

  void _goReady() {
    if (!mounted) return;
    final nav = Navigator.of(context);
    _timer?.cancel();
    nav.pushReplacement(MaterialPageRoute(builder: (_) => const ReadyScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final stages = _stageToStep.keys.toList();
    final runHtmlUrl = _run?['html_url'] as String?;
    final status = _run?['status'] as String? ?? 'queued';
    final conclusion = _run?['conclusion'] as String?;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.t('monitor')),
          actions: [
            IconButton(
              tooltip: t.t('refresh'),
              icon: const Icon(Icons.refresh, color: NovaTheme.neonCyan),
              onPressed: _poll,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 174,
                    height: 174,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [NovaTheme.neonBlue.withOpacity(0.18), NovaTheme.bg.withOpacity(0.02)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isRunFailed ? NovaTheme.danger : NovaTheme.neonBlue).withOpacity(0.20),
                                blurRadius: 34,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 164,
                          height: 164,
                          child: CircularProgressIndicator(
                            value: _stepProgress,
                            strokeWidth: 8,
                            backgroundColor: NovaTheme.cardElevated.withOpacity(0.78),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isRunFailed ? NovaTheme.danger : NovaTheme.neonCyan,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const WindowsMark(size: 34),
                            const SizedBox(height: 7),
                            Text(
                              _steps.isEmpty ? '—' : '${((_stepProgress ?? 0) * 100).round()}%',
                              style: const TextStyle(
                                color: NovaTheme.text,
                                fontSize: 23,
                                height: 1,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (_steps.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Directionality(
                                textDirection: TextDirection.ltr,
                                child: Text(
                                  '$_completedStepCount / ${_steps.length}',
                                  style: const TextStyle(
                                    color: NovaTheme.textDim,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    t.t('workflow_progress'),
                    style: const TextStyle(color: NovaTheme.text, fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  StatusBadge(
                    label: _isRunFailed
                        ? '${t.t('run_failed_title')} (${conclusion ?? ''})'
                        : _isRunning
                            ? t.t('windows_running')
                            : status == 'queued' || status == 'waiting'
                                ? t.t('session_queued')
                                : t.t('session_preparing'),
                    color: _isRunFailed
                        ? NovaTheme.danger
                        : _isRunning
                            ? NovaTheme.ok
                            : NovaTheme.neonCyan,
                    pulsing: !_isRunFailed && !_isRunning,
                    icon: _isRunFailed
                        ? Icons.error_outline
                        : _isRunning
                            ? Icons.check_circle
                            : null,
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: GlassCard(
                  borderColor: NovaTheme.danger.withOpacity(0.55),
                  glowColor: NovaTheme.danger,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.cloud_off_rounded, color: NovaTheme.danger, size: 19),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: NovaTheme.text, fontSize: 12, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),

            if (_isRunFailed) ...[
              GlassCard(
                borderColor: NovaTheme.danger,
                glowColor: NovaTheme.danger,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: NovaTheme.danger, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.t('run_failed_title'),
                            style: const TextStyle(
                              color: NovaTheme.danger,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_failedStepName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${t.t('failed_step')} $_failedStepName',
                        style: const TextStyle(color: NovaTheme.text, fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                    ],
                    const SizedBox(height: 12),
                    GradientButton(
                      height: 48,
                      label: t.t('repair_workflow'),
                      icon: Icons.build_circle_outlined,
                      busy: _repairing,
                      onPressed: () async {
                        setState(() => _repairing = true);
                        try {
                          await st.installOrRepairWorkflow();
                          await st.startRun(
                            hours: st.dispatchedHours,
                            fresh: st.sessionFreshInstall,
                            webAccess: st.webAccessEnabled,
                            enableRdp: st.rdpEnabled,
                          );
                          _run = null;
                          _steps = [];
                          await _poll();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${t.t('error')}: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _repairing = false);
                        }
                      },
                    ),
                    if (runHtmlUrl != null) ...[
                      const SizedBox(height: 8),
                      SecondaryNeonButton(
                        label: t.t('open_in_github'),
                        icon: Icons.open_in_new,
                        color: NovaTheme.neonCyan,
                        onPressed: () => launchUrl(
                          Uri.parse(runHtmlUrl),
                          mode: LaunchMode.externalApplication,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Column(
                children: [
                  for (var i = 0; i < stages.length; i++) _stageRow(t, stages, i),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_isRunning) ...[
              GradientButton(
                label: t.t('access_windows'),
                icon: Icons.desktop_windows_rounded,
                onPressed: _goReady,
              ),
              const SizedBox(height: 12),
            ],

            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Text(
                    t.t('dont_close'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: NovaTheme.textDim, fontSize: 12, height: 1.4),
                  ),
                  if (runHtmlUrl != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(runHtmlUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new, size: 15, color: NovaTheme.neonCyan),
                      label: Text(
                        t.t('open_in_github'),
                        style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (!_isRunFailed)
              SecondaryNeonButton(
                label: t.t('cancel_run'),
                icon: Icons.stop_circle_outlined,
                color: NovaTheme.danger,
                onPressed: () async {
                  await context.read<AppState>().stopOrCancelCurrentRun(forceCancel: true);
                  if (context.mounted) Navigator.of(context).maybePop();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _stageRow(L10n t, List<String> stages, int i) {
    final key = stages[i];
    final needed = _stageToStep[key]!;
    String state; // done | active | failed | pending
    if (key == 'checking_permissions') {
      state = _run != null ? 'done' : 'active';
    } else if (needed.isEmpty) {
      state = 'pending';
    } else {
      final sts = needed.map(_stepByName).whereType<WorkflowStepState>().toList();
      if (sts.isNotEmpty && sts.any((s) => s.conclusion == 'failure')) {
        state = 'failed';
      } else if (sts.isNotEmpty &&
          sts.every((s) => s.status == 'completed' && (s.conclusion == 'success' || s.conclusion == 'skipped'))) {
        state = 'done';
      } else if (sts.any((s) => s.status == 'in_progress')) {
        state = key == 'windows_running' ? 'done' : 'active';
      } else if (sts.any((s) => s.status == 'completed')) {
        state = 'active';
      } else {
        state = 'pending';
      }
    }

    Widget icon;
    switch (state) {
      case 'done':
        icon = const Icon(Icons.check_circle, color: NovaTheme.ok, size: 21);
        break;
      case 'active':
        icon = const SizedBox(
          width: 19,
          height: 19,
          child: CircularProgressIndicator(strokeWidth: 2.2, color: NovaTheme.neonCyan),
        );
        break;
      case 'failed':
        icon = const Icon(Icons.cancel, color: NovaTheme.danger, size: 21);
        break;
      default:
        icon = const Icon(Icons.radio_button_unchecked, color: NovaTheme.textMuted, size: 20);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.t(key),
              style: TextStyle(
                color: state == 'pending'
                    ? NovaTheme.textDim
                    : state == 'failed'
                        ? NovaTheme.danger
                        : NovaTheme.text,
                fontSize: 13.5,
                fontWeight: state == 'active' || state == 'done' ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Screen #8: Windows Ready & Verified Connection Info Screen.
class ReadyScreen extends StatefulWidget {
  const ReadyScreen({super.key});

  @override
  State<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends State<ReadyScreen> {
  Timer? _timer;
  bool _showPass = false;
  bool _stopping = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _poll());
    _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (!mounted) return;
    final st = context.read<AppState>();
    if (st.runId == null || st.selectedRepo == null || st.api == null) return;
    final repoName = st.selectedRepo!.fullName;
    final run = await st.api!.getRun(repoName, st.runId!);
    if (run != null) {
      st.latestRunData = run;
      final status = run['status'] as String? ?? '';
      if (status != 'in_progress' && status != 'queued' && mounted) {
        Navigator.of(context).maybePop();
        return;
      }
    }
    final needsWebInfo = st.webAccessEnabled && st.sessionInfo?.webUrl == null;
    final needsRdpInfo = st.rdpEnabled && st.hasTailscaleSecret && st.sessionInfo?.tailscaleIp == null;
    if (needsWebInfo || needsRdpInfo) {
      final info = await st.api!.sessionInfo(repoName, st.runId!);
      if (info != null) st.sessionInfo = info;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final info = st.sessionInfo;
    final webUrl = info?.webUrl;
    final tsIp = info?.tailscaleIp;
    final hasWebUrl = webUrl != null && webUrl.isNotEmpty;
    final hasTsIp = tsIp != null && tsIp.isNotEmpty;
    final hasInMemoryPass = st.inMemoryAccessPassword != null && st.inMemoryAccessPassword!.isNotEmpty;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.t('ready_screen')),
          actions: [
            IconButton(
              tooltip: t.t('refresh'),
              icon: const Icon(Icons.refresh, color: NovaTheme.neonCyan),
              onPressed: _poll,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: StatusBadge(
                label: hasWebUrl || hasTsIp ? t.t('connected') : t.t('no_access'),
                color: hasWebUrl || hasTsIp ? NovaTheme.ok : NovaTheme.warn,
                icon: hasWebUrl || hasTsIp ? Icons.check_circle : Icons.link_off_rounded,
              ),
            ),
            if (!hasWebUrl && !hasTsIp) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: NovaTheme.warn.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: NovaTheme.warn.withOpacity(0.48)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_off_rounded, color: NovaTheme.warn, size: 17),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        t.t('session_no_access'),
                        style: const TextStyle(color: NovaTheme.warn, fontSize: 11.5, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              height: 190,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/nova_windows_bloom.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.12),
                            const Color(0xD9050A1B),
                          ],
                        ),
                      ),
                    ),
                    PositionedDirectional(
                      start: 16,
                      end: 16,
                      bottom: 15,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.white.withOpacity(0.24)),
                            ),
                            child: const WindowsMark(size: 30),
                          ),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'Windows 11 Pro',
                                  textDirection: TextDirection.ltr,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  st.selectedRepo?.fullName ?? 'NOVA Windows Cloud',
                                  textDirection: TextDirection.ltr,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFFD5E6FF),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              borderColor: NovaTheme.ok.withOpacity(0.55),
              glowColor: NovaTheme.ok,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.lan_outlined, color: NovaTheme.neonCyan, size: 19),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.t('conn_info'),
                              style: const TextStyle(
                                color: NovaTheme.neonCyan,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (st.runStartedAt != null) ...[
                        const SizedBox(height: 9),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: StatusBadge(
                            label: '${t.t('time_left')}: ${_remaining(st)}',
                            color: NovaTheme.neonBlue,
                            icon: Icons.timer_outlined,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Divider(color: NovaTheme.cardBorder, height: 22),
                  _row(
                    t.t('user'),
                    info?.winUser ?? 'Docker',
                    ltr: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 17, color: NovaTheme.neonCyan),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: info?.winUser ?? 'Docker'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.t('code_copied'))),
                        );
                      },
                    ),
                  ),
                  _row(
                    t.t('password'),
                    hasInMemoryPass
                        ? (_showPass ? st.inMemoryAccessPassword! : '••••••••••••')
                        : t.t('password_in_secrets'),
                    ltr: hasInMemoryPass,
                    trailing: hasInMemoryPass
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off, size: 18),
                                color: NovaTheme.textDim,
                                onPressed: () => setState(() => _showPass = !_showPass),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 17, color: NovaTheme.neonCyan),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: st.inMemoryAccessPassword!));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.t('code_copied'))),
                                  );
                                },
                              ),
                            ],
                          )
                        : null,
                  ),
                  if (hasTsIp)
                    _row(
                      t.t('ip'),
                      tsIp,
                      ltr: true,
                      trailing: IconButton(
                        icon: const Icon(Icons.copy, size: 17, color: NovaTheme.neonCyan),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: tsIp));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(t.t('rdp_copied'))),
                          );
                        },
                      ),
                    )
                  else if (st.rdpEnabled)
                    _row(
                      t.t('ip'),
                      st.hasTailscaleSecret ? t.t('rdp_waiting') : t.t('rdp_secret_hint'),
                    ),
                  _row(
                    t.t('web_link'),
                    !st.webAccessEnabled
                        ? t.t('access_disabled')
                        : hasWebUrl
                            ? webUrl
                            : t.t('waiting_web_link'),
                    ltr: st.webAccessEnabled && hasWebUrl,
                    trailing: !st.webAccessEnabled
                        ? null
                        : hasWebUrl
                            ? IconButton(
                                icon: const Icon(Icons.copy, size: 17, color: NovaTheme.neonCyan),
                                onPressed: () {
                                  Clipboard.setData(ClipboardData(text: webUrl));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(t.t('code_copied'))),
                                  );
                                },
                              )
                            : const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: NovaTheme.neonCyan),
                              ),
                  ),
                  const SizedBox(height: 14),
                  if (hasWebUrl)
                    GradientButton(
                      label: t.t('open_windows'),
                      icon: Icons.open_in_new_rounded,
                      onPressed: () => launchUrl(
                        Uri.parse(webUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  if (hasTsIp) ...[
                    const SizedBox(height: 10),
                    SecondaryNeonButton(
                      label: '${t.t('rdp')} ($tsIp:3389)',
                      icon: Icons.desktop_windows_rounded,
                      color: NovaTheme.neonPurpleSoft,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: '$tsIp:3389'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(t.t('rdp_copied'))),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            SecondaryNeonButton(
              label: t.t('copy_info'),
              icon: Icons.copy_all_rounded,
              color: NovaTheme.neonCyan,
              onPressed: () {
                final buf = StringBuffer()
                  ..writeln('${t.t('user')}: ${info?.winUser ?? 'Docker'}');
                if (hasInMemoryPass) {
                  buf.writeln('${t.t('password')}: ${st.inMemoryAccessPassword}');
                }
                if (hasWebUrl) {
                  buf.writeln('${t.t('web_link')}: $webUrl');
                }
                if (hasTsIp) {
                  buf.writeln('RDP: $tsIp:3389');
                }
                Clipboard.setData(ClipboardData(text: buf.toString()));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(t.t('info_copied'))),
                );
              },
            ),
            const SizedBox(height: 10),
            SecondaryNeonButton(
              label: t.t('stop_save'),
              icon: Icons.stop_circle_outlined,
              color: NovaTheme.danger,
              busy: _stopping,
              onPressed: () => _confirmStop(context, st, t),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmStop(BuildContext context, AppState st, L10n t) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NovaTheme.card,
        title: Text(
          t.t('stop_confirm_title'),
          style: const TextStyle(color: NovaTheme.text, fontSize: 15.5, fontWeight: FontWeight.w800),
        ),
        content: Text(
          t.t('stop_confirm_body'),
          style: const TextStyle(color: NovaTheme.textDim, fontSize: 13, height: 1.45),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.t('cancel'), style: const TextStyle(color: NovaTheme.textDim)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'force'),
            child: Text(t.t('force_cancel'), style: const TextStyle(color: NovaTheme.danger, fontSize: 12)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NovaTheme.neonBlue),
            onPressed: () => Navigator.pop(ctx, 'save'),
            child: Text(t.t('stop_save')),
          ),
        ],
      ),
    );
    if (choice == null) return;
    setState(() => _stopping = true);
    try {
      await st.stopOrCancelCurrentRun(forceCancel: choice == 'force');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.t('stopping_sent'))),
      );
      if (choice == 'force') {
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.t('error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _stopping = false);
    }
  }

  String _remaining(AppState st) {
    final end = st.runStartedAt!.toUtc().add(Duration(hours: st.dispatchedHours));
    final d = end.difference(DateTime.now().toUtc());
    if (d.isNegative) return '0h 0m';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }

  Widget _row(String k, String v, {bool ltr = false, Widget? trailing}) => LayoutBuilder(
        builder: (context, constraints) {
          final label = Text(
            k,
            style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
          );
          final value = SelectableText(
            v,
            textDirection: ltr ? TextDirection.ltr : null,
            textAlign: ltr ? TextAlign.left : TextAlign.start,
            style: const TextStyle(
              color: NovaTheme.text,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          );
          final compact = constraints.maxWidth < 340;

          if (compact) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  label,
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: value),
                      if (trailing != null) trailing,
                    ],
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 110, child: label),
                Expanded(child: value),
                if (trailing != null) trailing,
              ],
            ),
          );
        },
      );
}
