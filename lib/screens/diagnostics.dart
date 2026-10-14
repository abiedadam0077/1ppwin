import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import 'repos.dart';

/// Read-only diagnostics built from live AppState/GitHub API results.
/// It intentionally avoids synthetic CPU, RAM, storage, or network metrics.
class DiagnosticsScreen extends StatelessWidget {
  const DiagnosticsScreen({super.key});

  List<_DiagnosticItem> _items(L10n t, AppState state) {
    final repo = state.selectedRepo;
    final connected = state.token != null && state.api != null;
    final items = <_DiagnosticItem>[
      _DiagnosticItem(
        icon: Icons.hub_outlined,
        title: t.t('diag_github'),
        detail: (state.user?['login'] as String? ?? '').isNotEmpty
            ? '@${state.user!['login']}'
            : (connected ? t.t('connected') : t.t('login_github')),
        value: connected ? t.t('connected') : t.t('not_ready'),
        tone: connected ? _DiagnosticTone.good : _DiagnosticTone.warning,
        ltrDetail: (state.user?['login'] as String? ?? '').isNotEmpty,
      ),
      _DiagnosticItem(
        icon: Icons.folder_special_outlined,
        title: t.t('diag_repository'),
        detail: repo?.fullName ?? t.t('diag_no_repo'),
        value: repo == null ? t.t('diag_not_checked') : t.t('selected_badge'),
        tone: repo == null ? _DiagnosticTone.neutral : _DiagnosticTone.good,
        ltrDetail: repo != null,
      ),
    ];

    if (repo == null) {
      items.addAll([
        _DiagnosticItem(
          icon: Icons.account_tree_outlined,
          title: t.t('diag_workflow'),
          detail: t.t('diag_no_repo'),
          value: t.t('diag_not_checked'),
          tone: _DiagnosticTone.neutral,
        ),
        _DiagnosticItem(
          icon: Icons.lock_outline_rounded,
          title: t.t('diag_secrets'),
          detail: t.t('diag_no_repo'),
          value: t.t('diag_not_checked'),
          tone: _DiagnosticTone.neutral,
        ),
        _DiagnosticItem(
          icon: Icons.backup_outlined,
          title: t.t('diag_backups'),
          detail: t.t('diag_no_repo'),
          value: t.t('diag_not_checked'),
          tone: _DiagnosticTone.neutral,
        ),
      ]);
    } else {
      final workflowTone = state.statusBusy
          ? _DiagnosticTone.progress
          : state.workflowNeedsRepair
              ? _DiagnosticTone.warning
              : state.hasWorkflowFile
                  ? _DiagnosticTone.good
                  : _DiagnosticTone.warning;
      final workflowDetail = state.statusBusy
          ? t.t('checking')
          : state.workflowNeedsRepair
              ? t.t('workflow_status_repair')
              : state.hasWorkflowFile
                  ? t.t('workflow_status_ok')
                  : t.t('workflow_status_missing');
      items.add(
        _DiagnosticItem(
          icon: Icons.account_tree_outlined,
          title: t.t('diag_workflow'),
          detail: workflowDetail,
          value: state.statusBusy
              ? t.t('checking')
              : state.workflowNeedsRepair
                  ? t.t('needs_repair')
                  : state.hasWorkflowFile
                      ? t.t('ready')
                      : t.t('not_ready'),
          tone: workflowTone,
        ),
      );

      final secretsTone = state.statusBusy
          ? _DiagnosticTone.progress
          : state.secretsPermissionDenied || state.secretsError != null
              ? _DiagnosticTone.error
              : state.secretsReady
                  ? _DiagnosticTone.good
                  : _DiagnosticTone.warning;
      items.add(
        _DiagnosticItem(
          icon: Icons.enhanced_encryption_outlined,
          title: t.t('diag_secrets'),
          detail: state.statusBusy
              ? t.t('checking')
              : state.secretsPermissionDenied
                  ? t.t('permissions_missing_title')
                  : state.secretsError != null
                      ? t.t('save_fail')
                      : state.secretsReady
                          ? t.t('secret_present')
                          : t.t('security_sub'),
          value: state.statusBusy
              ? t.t('checking')
              : state.secretsPermissionDenied
                  ? t.t('permissions_needed')
                  : state.secretsReady
                      ? t.t('ready')
                      : t.t('needs_secrets'),
          tone: secretsTone,
        ),
      );

      final backupTone = state.backupsBusy
          ? _DiagnosticTone.progress
          : state.backupsPermissionDenied || state.backupsError != null
              ? _DiagnosticTone.error
              : state.backupsList == null
                  ? _DiagnosticTone.neutral
                  : state.latestCompleteBackup != null
                      ? _DiagnosticTone.good
                      : state.backupsList!.isEmpty
                          ? _DiagnosticTone.neutral
                          : _DiagnosticTone.warning;
      final backupDetail = state.backupsBusy
          ? t.t('loading_backups')
          : state.backupsPermissionDenied
              ? t.t('backups_no_permission')
              : state.backupsError != null
                  ? t.t('backups_load_failed')
                  : state.backupsList == null
                      ? t.t('diag_not_checked')
                      : state.latestCompleteBackup != null
                          ? state.latestCompleteBackup!.tag
                          : state.backupsList!.isEmpty
                              ? t.t('no_backups')
                              : t.t('backup_incomplete');
      items.add(
        _DiagnosticItem(
          icon: Icons.backup_outlined,
          title: t.t('diag_backups'),
          detail: backupDetail,
          value: state.backupsBusy
              ? t.t('checking')
              : state.backupsPermissionDenied || state.backupsError != null
                  ? t.t('error')
                  : state.latestCompleteBackup != null
                      ? t.t('backup_complete')
                      : state.backupsList?.isEmpty == true
                          ? t.t('no_backups')
                          : state.backupsList == null
                              ? t.t('diag_not_checked')
                              : t.t('backup_incomplete'),
          tone: backupTone,
          ltrDetail: backupDetail == state.latestCompleteBackup?.tag,
        ),
      );
    }

    final run = state.latestRunData;
    final runStatus = run?['status'] as String? ?? '';
    final conclusion = run?['conclusion'] as String? ?? '';
    final runTone = run == null
        ? _DiagnosticTone.neutral
        : runStatus == 'in_progress'
            ? _DiagnosticTone.progress
            : runStatus == 'queued' || runStatus == 'waiting'
                ? _DiagnosticTone.progress
                : conclusion == 'success'
                    ? _DiagnosticTone.good
                    : conclusion == 'failure' || conclusion == 'startup_failure'
                        ? _DiagnosticTone.error
                        : conclusion == 'cancelled'
                            ? _DiagnosticTone.warning
                            : _DiagnosticTone.neutral;
    final runDetail = run == null
        ? t.t('run_status_none')
        : runStatus == 'in_progress'
            ? t.t('run_status_in_progress')
            : runStatus == 'queued' || runStatus == 'waiting'
                ? t.t('run_status_queued')
                : conclusion == 'success'
                    ? t.t('run_status_success')
                    : conclusion == 'cancelled'
                        ? t.t('run_status_cancelled')
                        : conclusion == 'failure' || conclusion == 'startup_failure'
                            ? t.t('run_status_failure')
                            : t.t('diag_not_checked');
    items.add(
      _DiagnosticItem(
        icon: Icons.bolt_rounded,
        title: t.t('diag_latest_run'),
        detail: runDetail,
        value: run == null
            ? t.t('diag_not_checked')
            : runStatus == 'in_progress'
                ? t.t('run_status_in_progress')
                : runStatus == 'queued' || runStatus == 'waiting'
                    ? t.t('run_status_queued')
                    : conclusion == 'success'
                        ? t.t('status_success')
                        : conclusion == 'cancelled'
                            ? t.t('run_status_cancelled')
                            : conclusion == 'failure' || conclusion == 'startup_failure'
                                ? t.t('status_failed')
                                : t.t('diag_not_checked'),
        tone: runTone,
      ),
    );

    final rdpTone = !state.rdpEnabled
        ? _DiagnosticTone.neutral
        : state.hasTailscaleSecret
            ? _DiagnosticTone.good
            : _DiagnosticTone.warning;
    items.add(
      _DiagnosticItem(
        icon: Icons.desktop_windows_outlined,
        title: t.t('diag_rdp'),
        detail: !state.rdpEnabled
            ? t.t('access_disabled')
            : state.hasTailscaleSecret
                ? 'TAILSCALE_AUTHKEY ✓'
                : t.t('rdp_secret_hint'),
        value: !state.rdpEnabled
            ? t.t('diag_optional')
            : state.hasTailscaleSecret
                ? t.t('ready')
                : t.t('diag_optional'),
        tone: rdpTone,
        ltrDetail: state.rdpEnabled && state.hasTailscaleSecret,
      ),
    );
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final state = context.watch<AppState>();
    final checks = _items(t, state);
    final coreReady = state.token != null &&
        state.selectedRepo != null &&
        state.repoReady &&
        state.secretsReady;
    final isChecking = state.statusBusy || state.backupsBusy;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.t('diagnostics')),
          actions: [
            IconButton(
              tooltip: t.t('diagnostic_run'),
              icon: const Icon(Icons.refresh_rounded, color: NovaTheme.neonCyan),
              onPressed: isChecking
                  ? null
                  : () {
                      if (state.selectedRepo == null) {
                        if (state.api != null) state.loadRepos();
                      } else {
                        state.refreshSelectedRepoStatus();
                      }
                    },
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Text(
              t.t('diagnostics_sub'),
              style: const TextStyle(color: NovaTheme.textDim, fontSize: 12, height: 1.45),
            ),
            const SizedBox(height: 12),
            GlassCard(
              aurora: true,
              borderColor: (coreReady ? NovaTheme.ok : NovaTheme.warn).withOpacity(0.52),
              glowColor: coreReady ? NovaTheme.ok : NovaTheme.neonBlue,
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: (coreReady ? NovaTheme.ok : NovaTheme.neonCyan).withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: (coreReady ? NovaTheme.ok : NovaTheme.neonCyan).withOpacity(0.38),
                      ),
                    ),
                    child: Icon(
                      isChecking
                          ? Icons.sync_rounded
                          : coreReady
                              ? Icons.verified_rounded
                              : Icons.tune_rounded,
                      color: isChecking
                          ? NovaTheme.neonCyan
                          : coreReady
                              ? NovaTheme.ok
                              : NovaTheme.warn,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.t('diagnostics'),
                          style: const TextStyle(color: NovaTheme.text, fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          state.selectedRepo?.fullName ?? t.t('diag_no_repo'),
                          textDirection: state.selectedRepo != null ? TextDirection.ltr : null,
                          textAlign: state.selectedRepo != null ? TextAlign.left : TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: isChecking
                        ? t.t('checking')
                        : coreReady
                            ? t.t('ready')
                            : t.t('not_ready'),
                    color: isChecking
                        ? NovaTheme.neonCyan
                        : coreReady
                            ? NovaTheme.ok
                            : NovaTheme.warn,
                    pulsing: isChecking,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            for (final item in checks) _DiagnosticRow(item: item),
            const SizedBox(height: 8),
            GradientButton(
              label: isChecking ? t.t('checking') : t.t('diagnostic_run'),
              icon: isChecking ? Icons.sync_rounded : Icons.health_and_safety_outlined,
              busy: isChecking,
              onPressed: isChecking
                  ? null
                  : () {
                      if (state.selectedRepo == null) {
                        state.setTab(1);
                        Navigator.of(context).maybePop();
                      } else {
                        state.refreshSelectedRepoStatus();
                      }
                    },
            ),
            const SizedBox(height: 8),
            if (state.selectedRepo != null)
              Row(
                children: [
                  Expanded(
                    child: SecondaryNeonButton(
                      label: t.t('security'),
                      icon: Icons.lock_outline_rounded,
                      color: NovaTheme.neonCyan,
                      onPressed: () => Navigator.pushNamed(context, '/security'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SecondaryNeonButton(
                      label: t.t('setup_repo_title'),
                      icon: Icons.account_tree_outlined,
                      color: NovaTheme.neonPurpleSoft,
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RepoSetupScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              t.t('diagnostics_truth_note'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: NovaTheme.textMuted, fontSize: 10.5, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

enum _DiagnosticTone { good, warning, error, progress, neutral }

class _DiagnosticItem {
  final IconData icon;
  final String title;
  final String detail;
  final String value;
  final _DiagnosticTone tone;
  final bool ltrDetail;

  const _DiagnosticItem({
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
    required this.tone,
    this.ltrDetail = false,
  });
}

class _DiagnosticRow extends StatelessWidget {
  final _DiagnosticItem item;
  const _DiagnosticRow({required this.item});

  Color get _color {
    switch (item.tone) {
      case _DiagnosticTone.good:
        return NovaTheme.ok;
      case _DiagnosticTone.warning:
        return NovaTheme.warn;
      case _DiagnosticTone.error:
        return NovaTheme.danger;
      case _DiagnosticTone.progress:
        return NovaTheme.neonCyan;
      case _DiagnosticTone.neutral:
        return NovaTheme.textDim;
    }
  }

  IconData get _stateIcon {
    switch (item.tone) {
      case _DiagnosticTone.good:
        return Icons.check_circle_outline_rounded;
      case _DiagnosticTone.warning:
        return Icons.warning_amber_rounded;
      case _DiagnosticTone.error:
        return Icons.error_outline_rounded;
      case _DiagnosticTone.progress:
        return Icons.sync_rounded;
      case _DiagnosticTone.neutral:
        return Icons.remove_circle_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        borderColor: _color.withOpacity(0.3),
        child: Row(
          children: [
            Container(
              width: 37,
              height: 37,
              decoration: BoxDecoration(
                color: _color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: _color.withOpacity(0.26)),
              ),
              child: Icon(item.icon, color: _color, size: 19),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: NovaTheme.text, fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Directionality(
                    textDirection: item.ltrDetail ? TextDirection.ltr : Directionality.of(context),
                    child: Text(
                      item.detail,
                      textAlign: item.ltrDetail ? TextAlign.left : TextAlign.start,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: NovaTheme.textDim, fontSize: 11, height: 1.3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  StatusBadge(label: item.value, color: _color, icon: _stateIcon),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
