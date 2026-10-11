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
  bool _restore = true;
  bool _fresh = false;
  bool _rdp = true;
  bool _web = true;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final h = _hours.round();
    final latestBackup = st.latestCompleteBackup;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('session'))),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                t.t('session_sub'),
                style: const TextStyle(color: NovaTheme.textDim, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 16),

              // Duration & Boot Options Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.timer_outlined, color: NovaTheme.neonCyan, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              t.t('duration'),
                              style: const TextStyle(
                                color: NovaTheme.text,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        StatusBadge(
                          label: '$h ${t.t('hours')} (${h * 60} ${t.t('minutes')})',
                          color: NovaTheme.neonCyan,
                          icon: Icons.schedule,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Slider.adaptive(
                      value: _hours,
                      min: 1,
                      max: Const.maxSessionHours.toDouble(),
                      divisions: Const.maxSessionHours - 1,
                      activeColor: NovaTheme.neonBlue,
                      onChanged: (v) => setState(() => _hours = v),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        for (var i = 1; i <= Const.maxSessionHours; i++)
                          InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => setState(() => _hours = i.toDouble()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: h == i ? NovaTheme.neonPurple : NovaTheme.bg2,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: h == i ? NovaTheme.neonPurpleSoft : NovaTheme.cardBorder,
                                ),
                              ),
                              child: Text(
                                '${i}h',
                                style: TextStyle(
                                  color: h == i ? Colors.white : NovaTheme.textDim,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const Divider(color: NovaTheme.cardBorder, height: 24),
                    NeonSwitch(
                      label: t.t('restore_prev'),
                      icon: Icons.restore_rounded,
                      value: _restore,
                      onChanged: (v) => setState(() {
                        _restore = v;
                        _fresh = !v;
                      }),
                    ),
                    NeonSwitch(
                      label: t.t('fresh_install'),
                      icon: Icons.cleaning_services_outlined,
                      value: _fresh,
                      onChanged: (v) => setState(() {
                        _fresh = v;
                        _restore = !v;
                      }),
                    ),
                    if (_fresh)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: NovaTheme.warn.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: NovaTheme.warn.withOpacity(0.6)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, color: NovaTheme.warn, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  t.t('fresh_warn'),
                                  style: const TextStyle(color: NovaTheme.warn, fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const Divider(color: NovaTheme.cardBorder, height: 22),
                    NeonSwitch(
                      label: t.t('web_access'),
                      sub: 'Cloudflare HTTPS Tunnel',
                      icon: Icons.public,
                      value: _web,
                      onChanged: (v) => setState(() => _web = v),
                    ),
                    NeonSwitch(
                      label: t.t('enable_rdp'),
                      sub: st.hasTailscaleSecret ? 'TAILSCALE_AUTHKEY ✓' : 'TAILSCALE_AUTHKEY (${t.t('secret_optional')})',
                      icon: Icons.desktop_windows_outlined,
                      value: _rdp,
                      onChanged: (v) => setState(() => _rdp = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Summary Card
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fact_check_outlined, color: NovaTheme.neonCyan, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          t.t('summary'),
                          style: const TextStyle(
                            color: NovaTheme.neonCyan,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _sumRow(t.t('repo'), st.selectedRepo?.fullName ?? '—', ltr: st.selectedRepo != null),
                    _sumRow(t.t('duration'), '$h ${t.t('hours')} (${h * 60} ${t.t('minutes')})'),
                    _sumRow(t.t('type'), _fresh ? t.t('fresh_install') : t.t('restore_session')),
                    _sumRow(
                      t.t('last_backup_card'),
                      latestBackup != null ? latestBackup.tag : t.t('no_backups'),
                      ltr: latestBackup != null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              GradientButton(
                label: t.t('start_windows'),
                icon: Icons.rocket_launch_rounded,
                busy: _busy,
                onPressed: st.selectedRepo == null
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          await st.startRun(hours: h, fresh: _fresh);
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _sumRow(String k, String v, {bool ltr = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 115,
              child: Text(k, style: const TextStyle(color: NovaTheme.textDim, fontSize: 12)),
            ),
            Expanded(
              child: Text(
                v,
                textDirection: ltr ? TextDirection.ltr : null,
                textAlign: ltr ? TextAlign.left : TextAlign.start,
                style: const TextStyle(color: NovaTheme.text, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
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
        if (st.sessionInfo == null || st.sessionInfo?.webUrl == null) {
          final info = await st.api!.sessionInfo(repoName, id);
          if (info != null) st.sessionInfo = info;
        }
      }

      _error = null;
      if (mounted) setState(() {});

      if (_isRunning && st.sessionInfo != null && !_navigatedToReady) {
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

  int get _completedStepCount => _steps.where((step) => step.status == 'completed').length;

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
            const Center(child: WindowsCloudLogo(size: 130)),
            const SizedBox(height: 8),
            Center(
              child: StatusBadge(
                label: _isRunFailed
                    ? '${t.t('run_failed_title')} (${conclusion ?? ''})'
                    : _isRunning
                        ? t.t('windows_running')
                        : status == 'queued'
                            ? t.t('session_queued')
                            : t.t('monitor_sub'),
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
            const SizedBox(height: 14),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: NovaTheme.neonBlue.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(Icons.timeline_rounded, color: NovaTheme.neonCyan, size: 19),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t.t('workflow_progress'),
                          style: const TextStyle(
                            color: NovaTheme.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (_steps.isNotEmpty)
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            '$_completedStepCount / ${_steps.length}',
                            style: const TextStyle(
                              color: NovaTheme.neonCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: _stepProgress,
                      minHeight: 7,
                      backgroundColor: NovaTheme.bg3,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _isRunFailed ? NovaTheme.danger : NovaTheme.neonBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    _steps.isEmpty
                        ? t.t(status == 'queued' || status == 'waiting' ? 'session_queued' : 'monitor_sub')
                        : t.t('steps_complete'),
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5),
                  ),
                ],
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
                          await st.startRun(hours: st.dispatchedHours, fresh: false);
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
    if (st.sessionInfo == null || st.sessionInfo?.webUrl == null) {
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
                label: t.t('connected'),
                color: NovaTheme.ok,
                icon: Icons.check_circle,
              ),
            ),
            const SizedBox(height: 14),
            const Center(child: WindowsCloudLogo(size: 145)),
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
                    ),
                  _row(
                    t.t('web_link'),
                    hasWebUrl ? webUrl : t.t('waiting_web_link'),
                    ltr: hasWebUrl,
                    trailing: hasWebUrl
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

  Widget _row(String k, String v, {bool ltr = false, Widget? trailing}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(k, style: const TextStyle(color: NovaTheme.textDim, fontSize: 12)),
            ),
            Expanded(
              child: SelectableText(
                v,
                textDirection: ltr ? TextDirection.ltr : null,
                textAlign: ltr ? TextAlign.left : TextAlign.start,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: NovaTheme.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );
}
