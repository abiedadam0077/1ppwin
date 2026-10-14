import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

/// A notification-style view of real local activity entries. NOVA does not
/// claim to provide push notifications or unread delivery semantics.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _iconForType(String type) {
    switch (type) {
      case 'act_login':
        return Icons.login_rounded;
      case 'act_logout':
        return Icons.logout_rounded;
      case 'act_select_repo':
        return Icons.folder_special_outlined;
      case 'act_create_repo':
        return Icons.create_new_folder_outlined;
      case 'act_install_workflow':
        return Icons.account_tree_outlined;
      case 'act_save_secrets':
        return Icons.enhanced_encryption_outlined;
      case 'act_start_run':
        return Icons.rocket_launch_outlined;
      case 'act_restore_backup':
        return Icons.settings_backup_restore_rounded;
      case 'act_stop_run':
        return Icons.stop_circle_outlined;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  String _formatTime(DateTime value) {
    final time = value.toLocal();
    final date = '${time.year.toString().padLeft(4, '0')}-'
        '${time.month.toString().padLeft(2, '0')}-'
        '${time.day.toString().padLeft(2, '0')}';
    final clock = '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
    return '$date  $clock';
  }

  void _openActivity(BuildContext context, AppState state) {
    state.setTab(3);
    Navigator.of(context).maybePop();
  }

  void _showDetails(BuildContext context, L10n t, ActivityEntry entry) {
    final color = entry.ok ? NovaTheme.ok : NovaTheme.danger;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(_iconForType(entry.type), color: color),
        title: Text(t.t(entry.type)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entry.detail.isNotEmpty) ...[
              Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(
                  entry.detail,
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: NovaTheme.text, fontSize: 13, height: 1.45),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                _formatTime(entry.time),
                textAlign: TextAlign.left,
                style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
              ),
            ),
            const SizedBox(height: 10),
            StatusBadge(
              label: entry.ok ? t.t('status_success') : t.t('status_failed'),
              color: color,
              icon: entry.ok ? Icons.check_circle_outline : Icons.error_outline,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(t.t('cancel')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final state = context.watch<AppState>();
    final entries = List<ActivityEntry>.of(state.activity)
      ..sort((a, b) => b.time.compareTo(a.time));

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.t('notifications')),
          actions: [
            IconButton(
              tooltip: t.t('open_activity'),
              icon: const Icon(Icons.history_rounded, color: NovaTheme.neonCyan),
              onPressed: () => _openActivity(context, state),
            ),
          ],
        ),
        body: entries.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: NovaEmptyState(
                    icon: Icons.notifications_none_rounded,
                    title: t.t('notifications_empty'),
                    subtitle: t.t('notifications_empty_sub'),
                    color: NovaTheme.neonCyan,
                    action: SecondaryNeonButton(
                      label: t.t('open_activity'),
                      icon: Icons.history_rounded,
                      onPressed: () => _openActivity(context, state),
                    ),
                  ),
                ),
              )
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 5, 18, 9),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            t.t('notifications_sub'),
                            style: const TextStyle(
                              color: NovaTheme.textDim,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(
                          label: '${entries.length}',
                          color: NovaTheme.neonCyan,
                          icon: Icons.receipt_long_outlined,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      itemCount: entries.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 9),
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final color = entry.ok ? NovaTheme.ok : NovaTheme.danger;
                        return GlassCard(
                          padding: const EdgeInsets.all(13),
                          borderColor: color.withOpacity(0.28),
                          onTap: () => _showDetails(context, t, entry),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(13),
                                  border: Border.all(color: color.withOpacity(0.38)),
                                ),
                                child: Icon(_iconForType(entry.type), color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.t(entry.type),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: NovaTheme.text,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (entry.detail.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          entry.detail,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.left,
                                          style: const TextStyle(
                                            color: NovaTheme.neonCyan,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 4),
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        _formatTime(entry.time),
                                        textAlign: TextAlign.left,
                                        style: const TextStyle(
                                          color: NovaTheme.textDim,
                                          fontSize: 10.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 7),
                              Icon(
                                entry.ok ? Icons.check_circle_rounded : Icons.error_rounded,
                                color: color,
                                size: 19,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
