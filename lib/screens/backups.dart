import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../services/github_service.dart';
import '../state/app_state.dart';
import 'security.dart';
import 'session.dart';

class BackupsScreen extends StatefulWidget {
  const BackupsScreen({super.key});

  @override
  State<BackupsScreen> createState() => _BackupsScreenState();
}

class _BackupsScreenState extends State<BackupsScreen> {
  String? _lastRepoName;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
  }

  void _ensureLoaded() {
    if (!mounted) return;
    final st = context.read<AppState>();
    final repoName = st.selectedRepo?.fullName;
    if (repoName != null &&
        (_lastRepoName != repoName || (st.backupsList == null && !st.backupsBusy && st.backupsError == null))) {
      _lastRepoName = repoName;
      st.loadBackups();
    }
  }

  String _fmtSize(int b) {
    if (b <= 0) return '—';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String _relativeTime(DateTime d, L10n t) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${t.t('ago_min')} ${diff.inMinutes}m';
    if (diff.inHours < 24) return '${t.t('ago_min')} ${diff.inHours}h';
    return '${t.t('ago_min')} ${diff.inDays}d';
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();

    // Trigger load if repo was just selected
    if (st.selectedRepo != null &&
        _lastRepoName != st.selectedRepo!.fullName &&
        !st.backupsBusy) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ensureLoaded());
    }

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.t('backups')),
          actions: [
            if (st.token != null && st.selectedRepo != null)
              IconButton(
                tooltip: t.t('refresh'),
                icon: const Icon(Icons.refresh, color: NovaTheme.neonCyan),
                onPressed: st.backupsBusy ? null : () => st.loadBackups(),
              ),
          ],
        ),
        body: _buildBody(context, st, t),
      ),
    );
  }

  Widget _buildBody(BuildContext context, AppState st, L10n t) {
    // State 1: User is not signed in
    if (st.token == null || st.api == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            borderColor: NovaTheme.warn,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_off_outlined, color: NovaTheme.warn, size: 46),
                const SizedBox(height: 12),
                Text(
                  t.t('need_login'),
                  style: const TextStyle(color: NovaTheme.text, fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  t.t('need_login_sub'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NovaTheme.textDim, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: t.t('login_github'),
                  icon: Icons.login_rounded,
                  onPressed: () => st.logout(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // State 2: User is signed in, but no repository is selected yet
    if (st.selectedRepo == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            borderColor: NovaTheme.neonCyan,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.folder_special_outlined, color: NovaTheme.neonCyan, size: 46),
                const SizedBox(height: 12),
                Text(
                  t.t('no_repo_selected'),
                  style: const TextStyle(color: NovaTheme.text, fontSize: 17, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  t.t('no_repo_selected_sub'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NovaTheme.textDim, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                GradientButton(
                  label: t.t('choose_repo'),
                  icon: Icons.folder_open_rounded,
                  onPressed: () => st.setTab(1),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // State 3: Permission denied accessing releases/backups
    if (st.backupsPermissionDenied) {
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassCard(
            borderColor: NovaTheme.danger,
            child: Row(
              children: [
                const Icon(Icons.lock_person_outlined, color: NovaTheme.danger, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t.t('backups_no_permission'),
                    style: const TextStyle(color: NovaTheme.text, fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          PermissionsGuideCard(
            errorDetail: st.backupsError,
            onRetry: () => st.loadBackups(),
          ),
        ],
      );
    }

    // State 4: Network or API error loading backups
    if (st.backupsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            borderColor: NovaTheme.danger,
            glowColor: NovaTheme.danger,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_rounded, color: NovaTheme.danger, size: 44),
                const SizedBox(height: 12),
                Text(
                  t.t('backups_load_failed'),
                  style: const TextStyle(color: NovaTheme.text, fontSize: 16, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  st.backupsError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
                ),
                const SizedBox(height: 16),
                GradientButton(
                  label: t.t('retry'),
                  icon: Icons.refresh,
                  onPressed: () => st.loadBackups(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (st.backupsBusy && st.backupsList == null) {
      return const Center(child: CircularProgressIndicator(color: NovaTheme.neonBlue));
    }

    final backups = st.backupsList ?? const <BackupInfo>[];
    final firstComplete = st.latestCompleteBackup;

    return RefreshIndicator(
      onRefresh: () => st.loadBackups(),
      color: NovaTheme.neonBlue,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Repository context pill
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: NovaTheme.neonCyan, size: 17),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  st.selectedRepo!.fullName,
                  style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              if (st.backupsBusy)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: NovaTheme.neonBlue),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Latest Complete Backup Hero Card
          GlassCard(
            borderColor: firstComplete != null ? NovaTheme.ok.withOpacity(0.65) : NovaTheme.cardBorder,
            glowColor: firstComplete != null ? NovaTheme.ok : NovaTheme.neonBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (firstComplete != null ? NovaTheme.ok : NovaTheme.neonBlue).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        firstComplete != null ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                        color: firstComplete != null ? NovaTheme.ok : NovaTheme.neonCyan,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.t('latest_ok'),
                            style: const TextStyle(
                              color: NovaTheme.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            firstComplete == null
                                ? t.t('no_backups')
                                : '${_fmtDate(firstComplete.createdAt)} (${_relativeTime(firstComplete.createdAt, t)})',
                            style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (firstComplete != null)
                      StatusBadge(
                        label: _fmtSize(firstComplete.totalBytes),
                        color: NovaTheme.ok,
                        icon: Icons.storage_rounded,
                      ),
                  ],
                ),
                if (firstComplete != null) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      StatusBadge(
                        label: firstComplete.tag,
                        color: NovaTheme.neonCyan,
                        icon: Icons.sell_outlined,
                      ),
                      if (firstComplete.partCount > 0)
                        StatusBadge(
                          label: '${firstComplete.partCount} ${t.t('backup_parts')}',
                          color: NovaTheme.neonPurpleSoft,
                          icon: Icons.enhanced_encryption_outlined,
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GradientButton(
                    label: t.t('restore_latest'),
                    icon: Icons.settings_backup_restore_rounded,
                    busy: _restoring,
                    onPressed: () => _confirmRestore(context, st, t, firstComplete),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text(
            t.t('available'),
            style: const TextStyle(
              color: NovaTheme.neonCyan,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),

          // State 5: No backups exist yet in this repository
          if (backups.isEmpty)
            GlassCard(
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  const Icon(Icons.backup_table_rounded, color: NovaTheme.textDim, size: 42),
                  const SizedBox(height: 10),
                  Text(
                    t.t('no_backups'),
                    style: const TextStyle(color: NovaTheme.text, fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t.t('no_backups_sub'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: NovaTheme.textDim, fontSize: 12.5, height: 1.45),
                  ),
                  const SizedBox(height: 16),
                  SecondaryNeonButton(
                    label: t.t('start_windows'),
                    icon: Icons.rocket_launch_rounded,
                    color: NovaTheme.neonCyan,
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SessionSetupScreen()),
                    ),
                  ),
                ],
              ),
            ),

          // State 6: Available backups list
          for (final b in backups)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(15),
                borderColor: b.complete ? NovaTheme.ok.withOpacity(0.55) : NovaTheme.warn.withOpacity(0.55),
                glowColor: b.complete ? NovaTheme.ok : NovaTheme.warn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          b.complete ? Icons.verified_rounded : Icons.warning_amber_rounded,
                          color: b.complete ? NovaTheme.ok : NovaTheme.warn,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _fmtDate(b.createdAt),
                                style: const TextStyle(
                                  color: NovaTheme.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                b.tag,
                                style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(
                          label: _fmtSize(b.totalBytes),
                          color: b.complete ? NovaTheme.ok : NovaTheme.warn,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        StatusBadge(
                          label: b.complete ? t.t('backup_complete') : t.t('backup_incomplete'),
                          color: b.complete ? NovaTheme.ok : NovaTheme.warn,
                        ),
                        if (b.partCount > 0) ...[
                          const SizedBox(width: 8),
                          Text(
                            '${b.partCount} ${t.t('backup_parts')}',
                            style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5),
                          ),
                        ],
                        const Spacer(),
                        if (b.complete)
                          TextButton.icon(
                            onPressed: _restoring ? null : () => _confirmRestore(context, st, t, b),
                            icon: const Icon(Icons.restore, size: 17, color: NovaTheme.neonCyan),
                            label: Text(
                              t.t('restore_this'),
                              style: const TextStyle(
                                color: NovaTheme.neonCyan,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmRestore(BuildContext context, AppState st, L10n t, BackupInfo backup) {
    if (!st.secretsReady && !st.secretsPermissionDenied) {
      Navigator.pushNamed(context, '/security');
      return;
    }
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: NovaTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Row(
          children: [
            const Icon(Icons.settings_backup_restore_rounded, color: NovaTheme.neonCyan, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.t('restore_latest'),
                style: const TextStyle(color: NovaTheme.text, fontSize: 15.5, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.t('restore_warn'),
              style: const TextStyle(color: NovaTheme.textDim, fontSize: 13, height: 1.45),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NovaTheme.bg2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NovaTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.archive_outlined, color: NovaTheme.ok, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${backup.tag}\n${_fmtSize(backup.totalBytes)}',
                      style: const TextStyle(color: NovaTheme.text, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(t.t('cancel'), style: const TextStyle(color: NovaTheme.textDim)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: NovaTheme.neonBlue),
            onPressed: () async {
              Navigator.pop(c);
              setState(() => _restoring = true);
              try {
                await st.startRun(
                  hours: st.dispatchedHours,
                  fresh: false,
                  isRestore: true,
                );
                if (context.mounted) {
                  Navigator.of(context).push(
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
                if (mounted) setState(() => _restoring = false);
              }
            },
            icon: const Icon(Icons.play_arrow_rounded, size: 18),
            label: Text(t.t('restore_this')),
          ),
        ],
      ),
    );
  }
}
