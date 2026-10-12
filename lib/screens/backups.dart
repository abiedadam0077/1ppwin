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
    if (diff.inMinutes < 1) return t.t('just_now');
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
          child: NovaEmptyState(
            icon: Icons.person_off_outlined,
            title: t.t('need_login'),
            subtitle: t.t('need_login_sub'),
            color: NovaTheme.warn,
            action: GradientButton(
              label: t.t('login_github'),
              icon: Icons.login_rounded,
              onPressed: () => st.logout(),
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
          child: NovaEmptyState(
            icon: Icons.folder_special_outlined,
            title: t.t('no_repo_selected'),
            subtitle: t.t('no_repo_selected_sub'),
            color: NovaTheme.neonCyan,
            action: GradientButton(
              label: t.t('choose_repo'),
              icon: Icons.folder_open_rounded,
              onPressed: () => st.setTab(1),
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
          child: NovaErrorState(
            icon: Icons.cloud_off_rounded,
            title: t.t('backups_load_failed'),
            subtitle: st.backupsError!,
            subtitleDirection: TextDirection.ltr,
            action: SecondaryNeonButton(
              label: t.t('retry'),
              icon: Icons.refresh,
              onPressed: () => st.loadBackups(),
            ),
          ),
        ),
      );
    }

    if (st.backupsBusy && st.backupsList == null) {
      return NovaLoadingState(
        title: t.t('loading_backups'),
        subtitle: t.t('available'),
        icon: Icons.backup_rounded,
      );
    }

    final backups = st.backupsList ?? const <BackupInfo>[];
    final firstComplete = st.latestCompleteBackup;
    final leadingChildren = <Widget>[
      GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.inventory_2_outlined, color: NovaTheme.neonCyan, size: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Text(
                  st.selectedRepo!.fullName,
                  textAlign: TextAlign.left,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: NovaTheme.text, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            if (st.backupsBusy)
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: NovaTheme.neonCyan),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      if (backups.isNotEmpty)
        _buildLatestBackupCard(context, st, t, backups, firstComplete),
      if (backups.isNotEmpty) ...[
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 2, bottom: 8),
          child: Text(
            t.t('available'),
            style: const TextStyle(color: NovaTheme.text, fontSize: 15, fontWeight: FontWeight.w800),
          ),
        ),
      ],
      if (backups.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: NovaEmptyState(
            icon: Icons.backup_table_rounded,
            title: t.t('no_backups'),
            subtitle: t.t('no_backups_sub'),
            color: NovaTheme.neonCyan,
            action: SecondaryNeonButton(
              label: t.t('start_windows'),
              icon: Icons.rocket_launch_rounded,
              color: NovaTheme.neonCyan,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SessionSetupScreen()),
              ),
            ),
          ),
        ),
    ];

    return RefreshIndicator(
      onRefresh: () => st.loadBackups(),
      color: NovaTheme.neonBlue,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: leadingChildren.length + backups.length,
        itemBuilder: (context, index) {
          if (index < leadingChildren.length) return leadingChildren[index];
          final backup = backups[index - leadingChildren.length];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildBackupCard(context, st, t, backup),
          );
        },
      ),
    );
  }

  Widget _buildLatestBackupCard(
    BuildContext context,
    AppState st,
    L10n t,
    List<BackupInfo> backups,
    BackupInfo? firstComplete,
  ) {
    final latest = firstComplete ?? backups.first;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderColor: firstComplete == null ? NovaTheme.warn.withOpacity(0.36) : NovaTheme.ok.withOpacity(0.34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (firstComplete == null ? NovaTheme.warn : NovaTheme.ok).withOpacity(0.10),
                  borderRadius: BorderRadius.circular(NovaTheme.radiusMedium),
                ),
                child: Icon(
                  firstComplete == null ? Icons.cloud_queue_rounded : Icons.cloud_done_rounded,
                  color: firstComplete == null ? NovaTheme.warn : NovaTheme.ok,
                  size: 23,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstComplete == null ? t.t('backup_incomplete') : t.t('latest_ok'),
                      style: const TextStyle(color: NovaTheme.text, fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_fmtDate(latest.createdAt)} · ${_relativeTime(latest.createdAt, t)}',
                      style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: _fmtSize(latest.totalBytes),
                color: firstComplete == null ? NovaTheme.warn : NovaTheme.ok,
                icon: Icons.storage_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              latest.tag,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: const TextStyle(color: NovaTheme.textDim, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          if (latest.partCount > 0) ...[
            const SizedBox(height: 8),
            StatusBadge(
              label: '${latest.partCount} ${t.t('backup_parts')}',
              color: NovaTheme.neonCyan,
              icon: Icons.enhanced_encryption_outlined,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              OutlinedButton.icon(
                onPressed: () => _showBackupDetails(context, st, t, latest),
                icon: const Icon(Icons.info_outline_rounded, size: 17),
                label: Text(t.t('backup_details')),
              ),
              if (firstComplete != null)
                FilledButton.icon(
                  onPressed: _restoring ? null : () => _confirmRestore(context, st, t, firstComplete),
                  icon: const Icon(Icons.settings_backup_restore_rounded, size: 18),
                  label: Text(t.t('restore_latest')),
                )
              else
                Text(
                  t.t('backup_restore_disabled'),
                  style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackupCard(BuildContext context, AppState st, L10n t, BackupInfo backup) {
    final color = backup.complete ? NovaTheme.ok : NovaTheme.warn;
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderColor: NovaTheme.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                backup.complete ? Icons.verified_outlined : Icons.warning_amber_rounded,
                color: color,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      backup.title.trim().isNotEmpty ? backup.title : _fmtDate(backup.createdAt),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: NovaTheme.text, fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        backup.tag,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                        style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(label: _fmtSize(backup.totalBytes), color: color),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(
                label: backup.complete ? t.t('backup_complete') : t.t('backup_incomplete'),
                color: color,
                icon: backup.complete ? Icons.check_circle_outline : Icons.error_outline,
              ),
              if (backup.partCount > 0)
                StatusBadge(
                  label: '${backup.partCount} ${t.t('backup_parts')}',
                  color: NovaTheme.neonCyan,
                ),
              OutlinedButton.icon(
                onPressed: () => _showBackupDetails(context, st, t, backup),
                icon: const Icon(Icons.info_outline_rounded, size: 17),
                label: Text(t.t('backup_details')),
              ),
              if (backup.complete)
                TextButton.icon(
                  onPressed: _restoring ? null : () => _confirmRestore(context, st, t, backup),
                  icon: const Icon(Icons.settings_backup_restore_rounded, size: 17),
                  label: Text(t.t('restore_this')),
                ),
            ],
          ),
        ],
      ),
    );
  }

  void _showBackupDetails(BuildContext context, AppState st, L10n t, BackupInfo backup) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: NovaTheme.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(NovaTheme.radiusAurora)),
            border: Border.all(color: NovaTheme.cardBorder),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(color: NovaTheme.textMuted, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      backup.complete ? Icons.verified_outlined : Icons.warning_amber_rounded,
                      color: backup.complete ? NovaTheme.ok : NovaTheme.warn,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        t.t('backup_details'),
                        style: const TextStyle(color: NovaTheme.text, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    StatusBadge(
                      label: backup.complete ? t.t('backup_complete') : t.t('backup_incomplete'),
                      color: backup.complete ? NovaTheme.ok : NovaTheme.warn,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (backup.title.trim().isNotEmpty) ...[
                  Text(t.t('backup_release_title'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 12)),
                  const SizedBox(height: 3),
                  Text(backup.title, style: const TextStyle(color: NovaTheme.text, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                ],
                _detailRow(t.t('repo'), backup.tag, ltr: true),
                _detailRow(t.t('backup_date'), _fmtDate(backup.createdAt)),
                _detailRow(t.t('backup_size'), _fmtSize(backup.totalBytes)),
                _detailRow(t.t('backup_parts'), '${backup.partCount}'),
                if (!backup.complete) ...[
                  const SizedBox(height: 10),
                  Text(
                    t.t('backup_restore_disabled'),
                    style: const TextStyle(color: NovaTheme.warn, fontSize: 12.5, height: 1.45),
                  ),
                ],
                const SizedBox(height: 14),
                if (backup.complete)
                  GradientButton(
                    label: t.t('restore_this'),
                    icon: Icons.settings_backup_restore_rounded,
                    onPressed: _restoring
                        ? null
                        : () {
                            Navigator.pop(sheetContext);
                            _confirmRestore(context, st, t, backup);
                          },
                  ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(t.t('cancel')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool ltr = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: NovaTheme.textDim, fontSize: 13))),
            const SizedBox(width: 12),
            Expanded(
              child: Directionality(
                textDirection: ltr ? TextDirection.ltr : Directionality.of(context),
                child: SelectableText(
                  value,
                  textAlign: ltr ? TextAlign.left : TextAlign.end,
                  maxLines: ltr ? 2 : 1,
                  style: const TextStyle(color: NovaTheme.text, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: SelectableText(
                            backup.tag,
                            textAlign: TextAlign.left,
                            style: const TextStyle(color: NovaTheme.text, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (backup.title.trim().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            backup.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5),
                          ),
                        ],
                        const SizedBox(height: 3),
                        Text(
                          '${_fmtDate(backup.createdAt)} · ${_fmtSize(backup.totalBytes)}',
                          style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5),
                        ),
                      ],
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
                  hours: st.sessionHours,
                  fresh: false,
                  isRestore: true,
                  webAccess: st.webAccessEnabled,
                  enableRdp: st.rdpEnabled,
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
