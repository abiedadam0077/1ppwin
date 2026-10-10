import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'session.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../services/github_service.dart';
import '../state/app_state.dart';

class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  List<BackupInfo>? _backups;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final st = context.read<AppState>();
    if (st.api == null || st.selectedRepo == null) return;
    setState(() => _busy = true);
    try {
      _backups = await st.api!.backups(st.selectedRepo!.fullName);
    } catch (_) {
      _backups = [];
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _fmtSize(int b) {
    if (b <= 0) return '—';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(0)} MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final latest = _backups?.where((b) => b.complete).toList();
    final first = (latest != null && latest.isNotEmpty) ? latest.first : null;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.t('backups')),
          actions: [
            IconButton(
              tooltip: t.t('refresh'),
              icon: const Icon(Icons.refresh, color: NovaTheme.neonCyan),
              onPressed: _load,
            ),
          ],
        ),
        body: st.selectedRepo == null
            ? Center(child: Text(t.t('need_login'), style: const TextStyle(color: NovaTheme.textDim)))
            : RefreshIndicator(
                onRefresh: _load,
                color: NovaTheme.neonBlue,
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    GlassCard(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(t.t('latest_ok'),
                                    style: const TextStyle(color: NovaTheme.text, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  first == null
                                      ? t.t('no_backups')
                                      : '${_fmtDate(first.createdAt)} • ${_fmtSize(first.totalBytes)}',
                                  style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            first == null ? Icons.hourglass_empty : Icons.check_circle,
                            color: first == null ? NovaTheme.textDim : NovaTheme.ok,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    GradientButton(
                      label: t.t('restore_latest'),
                      icon: Icons.restore,
                      onPressed: first == null
                          ? null
                          : () => _confirmRestore(context, st, t),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(t.t('available'),
                            style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 14, fontWeight: FontWeight.w700)),
                        const Spacer(),
                        if (_busy)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: NovaTheme.neonBlue),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_backups != null && _backups!.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Text(t.t('no_backups'), style: const TextStyle(color: NovaTheme.textDim)),
                        ),
                      ),
                    for (final b in _backups ?? const <BackupInfo>[])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassCard(
                          padding: const EdgeInsets.all(13),
                          borderColor: b.complete ? NovaTheme.ok.withOpacity(0.6) : NovaTheme.warn.withOpacity(0.5),
                          child: Row(
                            children: [
                              Icon(
                                b.complete ? Icons.check_circle : Icons.warning_amber,
                                color: b.complete ? NovaTheme.ok : NovaTheme.warn,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(_fmtDate(b.createdAt),
                                        style: const TextStyle(color: NovaTheme.text, fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text(_fmtSize(b.totalBytes),
                                        style: const TextStyle(color: NovaTheme.textDim, fontSize: 12)),
                                  ],
                                ),
                              ),
                              const Icon(Icons.download_for_offline, color: NovaTheme.textDim, size: 20),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  String _fmtDate(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  void _confirmRestore(BuildContext context, AppState st, L10n t) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: NovaTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(t.t('restore_latest'), style: const TextStyle(color: NovaTheme.text)),
        content: Text(t.t('restore_warn'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: Text('✕', style: const TextStyle(color: NovaTheme.textDim))),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NovaTheme.neonBlue),
            onPressed: () async {
              Navigator.pop(c);
              await st.startRun(hours: st.dispatchedHours, fresh: false);
              if (context.mounted) {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProgressScreen()));
              }
            },
            child: Text(t.t('continue')),
          ),
        ],
      ),
    );
  }
}
