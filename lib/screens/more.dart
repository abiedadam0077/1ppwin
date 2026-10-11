import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import 'onboarding.dart';
import 'repos.dart';
import 'security.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  String _filter = 'all'; // all | ok | fail

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
        return Icons.history_rounded;
    }
  }

  String _fmtTime(DateTime t) =>
      '${t.year.toString().padLeft(4, '0')}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final items = st.activity.where((e) {
      if (_filter == 'ok') return e.ok;
      if (_filter == 'fail') return !e.ok;
      return true;
    }).toList();

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.t('activity')),
          actions: [
            if (st.activity.isNotEmpty)
              IconButton(
                tooltip: t.t('clear_activity'),
                icon: const Icon(Icons.delete_sweep_outlined, color: NovaTheme.textDim),
                onPressed: () => st.clearActivity(),
              ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final f in [
                    ['all', t.t('all')],
                    ['ok', t.t('filter_success')],
                    ['fail', t.t('filter_failed')],
                  ])
                    ChoiceChip(
                      label: Text(f[1], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      selected: _filter == f[0],
                      selectedColor: NovaTheme.neonBlue,
                      backgroundColor: NovaTheme.card,
                      side: BorderSide(
                        color: _filter == f[0] ? NovaTheme.neonBlue : NovaTheme.cardBorder,
                      ),
                      labelStyle: TextStyle(
                        color: _filter == f[0] ? Colors.white : NovaTheme.textDim,
                      ),
                      onSelected: (_) => setState(() => _filter = f[0]),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 1, 20, 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      t.t('activity_sub'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5, height: 1.3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(label: '${items.length}', color: NovaTheme.neonCyan, icon: Icons.receipt_long_outlined),
                ],
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: NovaEmptyState(
                          icon: Icons.history_toggle_off_rounded,
                          title: t.t('activity_empty'),
                          subtitle: t.t('activity_empty_sub'),
                          color: NovaTheme.neonCyan,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (c, i) {
                        final e = items[i];
                        final color = e.ok ? NovaTheme.ok : NovaTheme.danger;
                        final title = t.t(e.type);
                        return GlassCard(
                          padding: const EdgeInsets.all(12),
                          borderColor: color.withOpacity(0.45),
                          glowColor: color,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(color: color.withOpacity(0.4)),
                                ),
                                child: Icon(_iconForType(e.type), color: color, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        color: NovaTheme.text,
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    if (e.detail.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Directionality(
                                        textDirection: TextDirection.ltr,
                                        child: Text(
                                          e.detail,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.left,
                                          style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 3),
                                    Directionality(
                                      textDirection: TextDirection.ltr,
                                      child: Text(
                                        _fmtTime(e.time),
                                        maxLines: 1,
                                        textAlign: TextAlign.start,
                                        style: const TextStyle(color: NovaTheme.textDim, fontSize: 11),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusBadge(
                                label: e.ok ? t.t('status_success') : t.t('status_failed'),
                                color: color,
                                icon: e.ok ? Icons.check_circle : Icons.error_outline,
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

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final login = st.user?['login'] as String? ?? '';
    final name = (st.user?['name'] as String? ?? '').trim();
    final avatar = st.user?['avatar_url'] as String?;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('settings'))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
          children: [
            if (st.token != null) ...[
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                borderColor: NovaTheme.neonBlue.withOpacity(0.48),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: NovaTheme.bg2,
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null ? const Icon(Icons.person, color: NovaTheme.textDim) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : (login.isNotEmpty ? login : t.t('github_user')),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textDirection: login.isNotEmpty && name.isEmpty ? TextDirection.ltr : null,
                            style: const TextStyle(color: NovaTheme.text, fontSize: 14, fontWeight: FontWeight.w800),
                          ),
                          if (login.isNotEmpty)
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '@$login',
                                textAlign: TextAlign.left,
                                style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 11.5),
                              ),
                            ),
                        ],
                      ),
                    ),
                    StatusBadge(label: t.t('connected'), color: NovaTheme.ok, icon: Icons.verified_user_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, color: NovaTheme.neonCyan, size: 19),
                      const SizedBox(width: 8),
                      Text(
                        t.t('language'),
                        style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final language in const [
                        ['ar', 'العربية'],
                        ['en', 'English'],
                        ['fr', 'Français'],
                      ])
                        ChoiceChip(
                          label: Text(language[1], style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                          selected: st.lang == language[0],
                          selectedColor: NovaTheme.neonBlue.withOpacity(0.72),
                          backgroundColor: NovaTheme.bg2,
                          side: BorderSide(
                            color: st.lang == language[0] ? NovaTheme.neonCyan.withOpacity(0.8) : NovaTheme.cardBorder,
                          ),
                          labelStyle: TextStyle(
                            color: st.lang == language[0] ? Colors.white : NovaTheme.textDim,
                          ),
                          onSelected: (_) => st.setLang(language[0]),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              borderColor: st.selectedRepo == null ? NovaTheme.cardBorder : NovaTheme.neonPurple.withOpacity(0.5),
              glowColor: NovaTheme.neonPurple,
              onTap: () => st.setTab(1),
              child: Row(
                children: [
                  const Icon(Icons.folder_special_rounded, color: NovaTheme.neonPurpleSoft, size: 21),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.t('settings_current_repo'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 11)),
                        const SizedBox(height: 2),
                        Text(
                          st.selectedRepo?.fullName ?? t.t('no_current_repo'),
                          textDirection: st.selectedRepo != null ? TextDirection.ltr : null,
                          textAlign: st.selectedRepo != null ? TextAlign.left : TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: NovaTheme.text, fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: NovaTheme.neonCyan, size: 22),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              child: Column(
                children: [
                  _settingsItem(
                    icon: Icons.lock_outline_rounded,
                    color: NovaTheme.neonBlue,
                    label: t.t('security'),
                    onTap: () => Navigator.pushNamed(context, '/security'),
                  ),
                  const Divider(color: NovaTheme.cardBorder, height: 1),
                  _settingsItem(
                    icon: Icons.folder_open_rounded,
                    color: NovaTheme.neonCyan,
                    label: t.t('choose_repo'),
                    onTap: () => st.setTab(1),
                  ),
                  if (st.selectedRepo != null) ...[
                    const Divider(color: NovaTheme.cardBorder, height: 1),
                    _settingsItem(
                      icon: Icons.tune_rounded,
                      color: NovaTheme.neonPurpleSoft,
                      label: t.t('setup_repo_title'),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RepoSetupScreen()),
                      ),
                    ),
                  ],
                  const Divider(color: NovaTheme.cardBorder, height: 1),
                  _settingsItem(
                    icon: Icons.key_rounded,
                    color: NovaTheme.warn,
                    label: t.t('use_pat_instead'),
                    onTap: () => showPatSignInDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
                  iconColor: NovaTheme.warn,
                  collapsedIconColor: NovaTheme.textDim,
                  leading: const Icon(Icons.admin_panel_settings_outlined, color: NovaTheme.warn, size: 20),
                  title: Text(
                    t.t('permissions_title'),
                    style: const TextStyle(color: NovaTheme.text, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  children: const [PermissionsGuideCard()],
                ),
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: EdgeInsets.zero,
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  iconColor: NovaTheme.neonCyan,
                  collapsedIconColor: NovaTheme.textDim,
                  leading: const Icon(Icons.info_outline_rounded, color: NovaTheme.neonCyan, size: 20),
                  title: Text(
                    t.t('about'),
                    style: const TextStyle(color: NovaTheme.text, fontSize: 12.5, fontWeight: FontWeight.w700),
                  ),
                  children: [
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        t.t('about_sub'),
                        style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SecondaryNeonButton(
              label: t.t('logout'),
              icon: Icons.logout_rounded,
              color: NovaTheme.danger,
              onPressed: () => st.logout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) => ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: -1, vertical: -3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        minLeadingWidth: 28,
        horizontalTitleGap: 8,
        leading: Icon(icon, color: color, size: 19),
        title: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: NovaTheme.text, fontSize: 12.5, fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, size: 19, color: NovaTheme.textDim),
        onTap: onTap,
      );
}
