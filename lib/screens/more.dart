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
                      selectedColor: NovaTheme.neonPurple,
                      backgroundColor: NovaTheme.card,
                      side: BorderSide(
                        color: _filter == f[0] ? NovaTheme.neonPurpleSoft : NovaTheme.cardBorder,
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
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (c, i) {
                        final e = items[i];
                        final color = e.ok ? NovaTheme.ok : NovaTheme.danger;
                        final title = t.t(e.type);
                        return GlassCard(
                          padding: const EdgeInsets.all(14),
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
    final name = st.user?['name'] as String? ?? login;
    final avatar = st.user?['avatar_url'] as String?;
    final forwardIcon = Directionality.of(context) == TextDirection.rtl
        ? Icons.arrow_back_ios_rounded
        : Icons.arrow_forward_ios_rounded;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('settings'))),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // User Profile Card
            if (st.token != null)
              GlassCard(
                borderColor: NovaTheme.neonBlue.withOpacity(0.55),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundColor: NovaTheme.bg2,
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null ? const Icon(Icons.person, color: NovaTheme.text) : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name.isNotEmpty ? name : (login.isNotEmpty ? login : 'GitHub User'),
                            style: const TextStyle(
                              color: NovaTheme.text,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (login.isNotEmpty)
                            Text(
                              '@$login',
                              style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      label: t.t('connected'),
                      color: NovaTheme.ok,
                      icon: Icons.verified_user,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),

            // Language Selection Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language_rounded, color: NovaTheme.neonCyan, size: 19),
                      const SizedBox(width: 8),
                      Text(
                        t.t('language'),
                        style: const TextStyle(
                          color: NovaTheme.neonCyan,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final l in const [
                    ['ar', 'العربية (Arabic — RTL)'],
                    ['en', 'English (LTR)'],
                    ['fr', 'Français (LTR)'],
                  ])
                    RadioListTile<String>(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        l[1],
                        style: TextStyle(
                          color: st.lang == l[0] ? Colors.white : NovaTheme.textDim,
                          fontSize: 13.5,
                          fontWeight: st.lang == l[0] ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      value: l[0],
                      groupValue: st.lang,
                      activeColor: NovaTheme.neonPurpleSoft,
                      onChanged: (v) => st.setLang(v!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Current repository is visible at a glance and opens the picker.
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              borderColor: st.selectedRepo == null ? NovaTheme.cardBorder : NovaTheme.neonPurple.withOpacity(0.5),
              glowColor: NovaTheme.neonPurple,
              onTap: () => st.setTab(1),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NovaTheme.neonPurple.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.folder_special_rounded, color: NovaTheme.neonPurpleSoft, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.t('settings_current_repo'),
                          style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          st.selectedRepo?.fullName ?? t.t('no_current_repo'),
                          textDirection: st.selectedRepo != null ? TextDirection.ltr : null,
                          textAlign: st.selectedRepo != null ? TextAlign.left : TextAlign.start,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: NovaTheme.text,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(forwardIcon, color: NovaTheme.neonCyan, size: 15),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Management & Configuration Links
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: NovaTheme.neonBlue),
                    title: Text(
                      t.t('security'),
                      style: const TextStyle(color: NovaTheme.text, fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    trailing: Icon(forwardIcon, size: 14, color: NovaTheme.textDim),
                    onTap: () => Navigator.pushNamed(context, '/security'),
                  ),
                  const Divider(color: NovaTheme.cardBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.folder_open_rounded, color: NovaTheme.neonCyan),
                    title: Text(
                      t.t('choose_repo'),
                      style: const TextStyle(color: NovaTheme.text, fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    trailing: Icon(forwardIcon, size: 14, color: NovaTheme.textDim),
                    onTap: () => Navigator.pushNamed(context, '/repos'),
                  ),
                  if (st.selectedRepo != null) ...[
                    const Divider(color: NovaTheme.cardBorder, height: 1),
                    ListTile(
                      leading: const Icon(Icons.tune_rounded, color: NovaTheme.neonPurpleSoft),
                      title: Text(
                        t.t('setup_repo_title'),
                        style: const TextStyle(color: NovaTheme.text, fontSize: 13.5, fontWeight: FontWeight.w700),
                      ),
                      trailing: Icon(forwardIcon, size: 14, color: NovaTheme.textDim),
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RepoSetupScreen()),
                      ),
                    ),
                  ],
                  const Divider(color: NovaTheme.cardBorder, height: 1),
                  ListTile(
                    leading: const Icon(Icons.key_rounded, color: NovaTheme.warn),
                    title: Text(
                      t.t('use_pat_instead'),
                      style: const TextStyle(color: NovaTheme.text, fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                    trailing: Icon(forwardIcon, size: 14, color: NovaTheme.textDim),
                    onTap: () => showPatSignInDialog(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Permissions & GitHub App Guide
            const PermissionsGuideCard(),
            const SizedBox(height: 14),

            // About Card
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: NovaTheme.neonCyan, size: 19),
                      const SizedBox(width: 8),
                      Text(
                        t.t('about'),
                        style: const TextStyle(
                          color: NovaTheme.neonCyan,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'NOVA Windows Cloud v1.2\n'
                    '• Windows 11 Pro VM on GitHub Actions (KVM + Docker)\n'
                    '• Auth: GitHub Device Flow + OAuth PKCE + PAT\n'
                    '• Secrets: On-device Libsodium crypto_box_seal (X25519 + XSalsa20-Poly1305)\n'
                    '• Backups: AES-256-CBC + Zstandard encrypted disk snapshots in GitHub Releases',
                    style: TextStyle(color: NovaTheme.textDim, fontSize: 12, height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

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
}
