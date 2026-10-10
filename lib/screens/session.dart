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
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('session'))),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.t('session_sub'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 13)),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  children: [
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
                        const Text('1h', style: TextStyle(color: NovaTheme.textDim, fontSize: 12)),
                        Text(
                          '$h ${t.t('hours')}  (${h * 60} ${t.t('minutes')})',
                          style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                        Text('${Const.maxSessionHours}h', style: const TextStyle(color: NovaTheme.textDim, fontSize: 12)),
                      ],
                    ),
                    const Divider(color: NovaTheme.cardBorder),
                    NeonSwitch(label: t.t('restore_prev'), value: _restore, onChanged: (v) => setState(() {
                      _restore = v;
                      if (v) _fresh = false;
                    })),
                    NeonSwitch(label: t.t('fresh_install'), value: _fresh, onChanged: (v) => setState(() {
                      _fresh = v;
                      if (v) _restore = false;
                    })),
                    NeonSwitch(label: t.t('enable_rdp'), sub: 'Tailscale', value: _rdp, onChanged: (v) => setState(() => _rdp = v)),
                    NeonSwitch(label: t.t('web_access'), value: _web, onChanged: (v) => setState(() => _web = v)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.t('summary'), style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _sumRow(t.t('repo'), st.selectedRepo?.fullName ?? '—'),
                    _sumRow(t.t('duration'), '$h ${t.t('hours')}'),
                    _sumRow(t.t('type'), _fresh ? 'Fresh' : t.t('restore_session')),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              GradientButton(
                label: t.t('start_windows'),
                icon: Icons.rocket_launch,
                busy: _busy,
                onPressed: () async {
                  setState(() => _busy = true);
                  try {
                    await st.startRun(hours: h, fresh: _fresh);
                    if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressScreen()));
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.t('error')}: $e')));
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

  Widget _sumRow(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            SizedBox(width: 110, child: Text(k, style: const TextStyle(color: NovaTheme.textDim, fontSize: 12))),
            Expanded(
              child: Text(v, style: const TextStyle(color: NovaTheme.text, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}

/// Live workflow progress driven by REAL job steps from the GitHub API.
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

  static const _stageToStep = <String, List<String>>{
    'checking_permissions': [],
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
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _poll());
    _poll();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final st = context.read<AppState>();
    if (st.api == null || st.selectedRepo == null) return;
    try {
      _run ??= await st.api!.latestRun(st.selectedRepo!.fullName);
      if (_run == null) return;
      final createdAt = DateTime.tryParse(_run!['created_at'] as String? ?? '') ?? DateTime.now();
      final mine = st.runStartedAt == null || !createdAt.isBefore(st.runStartedAt!.subtract(const Duration(minutes: 2)));
      if (!mine) return;
      final id = _run!['id'] as int;
      if (st.runId != id) {
        st.runId = id;
      }
      final status = _run!['status'] as String? ?? '';
      if (status == 'queued' || status == 'waiting') {
        if (mounted) setState(() {});
        return;
      }
      _steps = await st.api!.runSteps(st.selectedRepo!.fullName, id);
      if (st.sessionInfo == null) {
        st.sessionInfo = await st.api!.sessionInfo(st.selectedRepo!.fullName, id);
      }
      if (mounted) setState(() {});
      if (_isRunning && st.sessionInfo != null) {
        _goReady();
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  bool get _isRunning {
    final s = _stepByName('Windows is running (open the link in the step above)');
    return s != null && s.status == 'in_progress';
  }

  WorkflowStepState? _stepByName(String n) {
    for (final s in _steps) {
      if (s.name == n) return s;
    }
    return null;
  }

  void _goReady() {
    final nav = Navigator.of(context);
    if (nav.mounted) {
      _timer?.cancel();
      nav.pushReplacement(MaterialPageRoute(builder: (_) => const ReadyScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final stages = _stageToStep.keys.toList();
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('monitor')), automaticallyImplyLeading: false),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Center(child: WindowsCloudLogo(size: 120)),
            const SizedBox(height: 8),
            Center(
              child: Text(t.t('monitor_sub'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 13)),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: NovaTheme.danger, fontSize: 12)),
              ),
            const SizedBox(height: 22),
            for (var i = 0; i < stages.length; i++) _stageRow(t, stages, i),
            const SizedBox(height: 26),
            GlassCard(
              padding: const EdgeInsets.all(14),
              child: Text(t.t('dont_close'),
                  textAlign: TextAlign.center, style: const TextStyle(color: NovaTheme.textDim, fontSize: 12)),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.read<AppState>().cancelCurrentRun(),
              child: Text(t.t('cancel_run'), style: const TextStyle(color: NovaTheme.danger)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stageRow(L10n t, List<String> stages, int i) {
    final key = stages[i];
    final needed = _stageToStep[key]!;
    String state; // done | active | pending
    if (key == 'checking_permissions') {
      state = _run != null ? 'done' : 'active';
    } else if (needed.isEmpty) {
      state = 'pending';
    } else {
      final sts = needed.map(_stepByName).whereType<WorkflowStepState>().toList();
      if (sts.isNotEmpty && sts.every((s) => s.status == 'completed' && s.conclusion == 'success')) {
        state = 'done';
      } else if (sts.any((s) => s.status == 'in_progress') || (sts.any((s) => s.status == 'completed'))) {
        state = 'active';
      } else {
        state = 'pending';
      }
      // skipped steps (e.g. Tailscale) count as done
      if (sts.isNotEmpty && sts.every((s) => s.conclusion == 'skipped')) state = 'done';
      if (sts.isNotEmpty && sts.any((s) => s.conclusion == 'failure')) state = 'pending';
    }
    final icon = state == 'done'
        ? const Icon(Icons.check_circle, color: NovaTheme.ok, size: 20)
        : state == 'active'
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: NovaTheme.neonBlue))
            : const Icon(Icons.radio_button_unchecked, color: NovaTheme.textDim, size: 20);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          icon,
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              t.t(key),
              style: TextStyle(
                color: state == 'pending' ? NovaTheme.textDim : NovaTheme.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReadyScreen extends StatefulWidget {
  const ReadyScreen({super.key});

  @override
  State<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends State<ReadyScreen> {
  Timer? _timer;
  bool _showPass = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    final st = context.read<AppState>();
    if (st.runId == null) return;
    final run = await st.api!.getRun(st.selectedRepo!.fullName, st.runId!);
    final status = run?['status'] as String? ?? '';
    if (status != 'in_progress' && status != 'queued' && mounted) {
      Navigator.of(context).maybePop();
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final info = st.sessionInfo;
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('ready_screen')), automaticallyImplyLeading: false),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: NovaTheme.ok.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: NovaTheme.ok),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: NovaTheme.ok, size: 16),
                    const SizedBox(width: 6),
                    Text(t.t('connected'), style: const TextStyle(color: NovaTheme.ok, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(child: WindowsCloudLogo(size: 150)),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t.t('conn_info'), style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  _row(t.t('user'), info?.winUser ?? 'Docker'),
                  _row(
                    t.t('password'),
                    _showPass ? (st.inMemoryAccessPassword ?? '—') : '••••••••••',
                    trailing: IconButton(
                      icon: Icon(_showPass ? Icons.visibility : Icons.visibility_off, size: 18),
                      color: NovaTheme.textDim,
                      onPressed: () => setState(() => _showPass = !_showPass),
                    ),
                  ),
                  if (info?.tailscaleIp != null) _row(t.t('ip'), info!.tailscaleIp!),
                  _row(t.t('web_link'), info?.webUrl ?? '…'),
                  const SizedBox(height: 12),
                  if (info?.webUrl != null)
                    GradientButton(
                      label: t.t('open_windows'),
                      icon: Icons.open_in_new,
                      onPressed: () => launchUrl(Uri.parse(info!.webUrl!), mode: LaunchMode.externalApplication),
                    ),
                  const SizedBox(height: 10),
                  if (info?.tailscaleIp != null)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: NovaTheme.neonPurple),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () => Clipboard.setData(ClipboardData(text: '${info!.tailscaleIp!}:3389')),
                      icon: const Icon(Icons.desktop_windows, color: NovaTheme.neonPurple, size: 18),
                      label: Text(t.t('rdp'), style: const TextStyle(color: NovaTheme.neonPurple)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (st.runStartedAt != null)
              Center(
                child: Text(
                  '${t.t('time_left')}: ~${_remaining(st)}',
                  style: const TextStyle(color: NovaTheme.textDim, fontSize: 13),
                ),
              ),
            const SizedBox(height: 10),
            GradientButton(
              label: t.t('copy_info'),
              icon: Icons.copy,
              onPressed: () {
                final buf = StringBuffer()
                  ..writeln('${t.t('user')}: ${info?.winUser ?? 'Docker'}')
                  ..writeln('${t.t('password')}: ${st.inMemoryAccessPassword ?? '-'}')
                  ..writeln('${t.t('web_link')}: ${info?.webUrl ?? '-'}');
                if (info?.tailscaleIp != null) buf.writeln('RDP: ${info!.tailscaleIp!}:3389');
                Clipboard.setData(ClipboardData(text: buf.toString()));
              },
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: NovaTheme.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => st.cancelCurrentRun(),
              icon: const Icon(Icons.stop_circle, color: NovaTheme.danger, size: 18),
              label: Text(t.t('stop_save'), style: const TextStyle(color: NovaTheme.danger)),
            ),
          ],
        ),
      ),
    );
  }

  String _remaining(AppState st) {
    final end = st.runStartedAt!.add(Duration(hours: st.dispatchedHours));
    final d = end.difference(DateTime.now().toUtc());
    if (d.isNegative) return '0:00';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }

  Widget _row(String k, String v, {Widget? trailing}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            SizedBox(width: 105, child: Text(k, style: const TextStyle(color: NovaTheme.textDim, fontSize: 12))),
            Expanded(
              child: Text(
                v,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: NovaTheme.text, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            trailing ?? const SizedBox(),
          ],
        ),
      );
}
