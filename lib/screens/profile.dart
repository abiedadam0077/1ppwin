import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _openGitHub(BuildContext context, String? rawUrl, L10n t) async {
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    if (uri == null ||
        uri.scheme != 'https' ||
        (uri.host != 'github.com' && uri.host != 'www.github.com')) {
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.t('profile_open_failed'))),
      );
    }
  }

  Future<void> _confirmSignOut(BuildContext context, AppState state, L10n t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded, color: NovaTheme.warn),
        title: Text(t.t('logout_confirm_title')),
        content: Text(t.t('logout_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.t('cancel')),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: NovaTheme.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout_rounded),
            label: Text(t.t('logout_confirm_action')),
          ),
        ],
      ),
    );
    if (confirmed == true) await state.logout();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final state = context.watch<AppState>();
    final user = state.user ?? const <String, dynamic>{};
    final login = (user['login'] as String? ?? '').trim();
    final rawName = (user['name'] as String? ?? '').trim();
    final displayName = rawName.isNotEmpty
        ? rawName
        : login.isNotEmpty
            ? login
            : t.t('github_user');
    final avatarUrl = user['avatar_url'] as String?;
    final profileUrl = user['html_url'] as String?;
    final readyRepos = state.repoReadiness.values.where((repo) => repo.isFullyReady).length;
    final readyCount = state.repoReadiness.isEmpty ? '—' : '$readyRepos';
    final repoCount = state.busy && state.repos.isEmpty ? '—' : '${state.repos.length}';

    return GlowBackground(
      aurora: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('profile'))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            GlassCard(
              aurora: true,
              borderColor: NovaTheme.neonBlue.withOpacity(0.52),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: NovaTheme.btnGradient,
                      boxShadow: [
                        BoxShadow(
                          color: NovaTheme.neonBlue.withOpacity(0.25),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: NovaTheme.bg2,
                      backgroundImage: avatarUrl == null ? null : NetworkImage(avatarUrl),
                      child: avatarUrl == null
                          ? const Icon(Icons.person_rounded, color: NovaTheme.textDim, size: 34)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: NovaTheme.text, fontSize: 19, fontWeight: FontWeight.w900),
                  ),
                  if (login.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        '@$login',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  StatusBadge(
                    label: state.token == null ? t.t('not_ready') : t.t('connected'),
                    color: state.token == null ? NovaTheme.warn : NovaTheme.ok,
                    icon: state.token == null ? Icons.link_off_rounded : Icons.verified_user_rounded,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _ProfileMetric(value: repoCount, label: t.t('profile_repositories'))),
                const SizedBox(width: 8),
                Expanded(child: _ProfileMetric(value: readyCount, label: t.t('profile_ready_repositories'))),
                const SizedBox(width: 8),
                Expanded(
                  child: _ProfileMetric(
                    value: state.isLiveRunActive ? '1' : '0',
                    label: t.t('profile_active_sessions'),
                    accent: state.isLiveRunActive ? NovaTheme.ok : NovaTheme.neonCyan,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.selectedRepo != null)
              GlassCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                onTap: () {
                  state.setTab(1);
                  Navigator.of(context).maybePop();
                },
                child: Row(
                  children: [
                    const Icon(Icons.folder_special_rounded, color: NovaTheme.neonCyan, size: 21),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(t.t('settings_current_repo'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5)),
                          const SizedBox(height: 3),
                          Directionality(
                            textDirection: TextDirection.ltr,
                            child: Text(
                              state.selectedRepo!.fullName,
                              textAlign: TextAlign.left,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: NovaTheme.text, fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: NovaTheme.neonCyan),
                  ],
                ),
              ),
            const SizedBox(height: 10),
            if (profileUrl != null)
              GradientButton(
                label: t.t('profile_open_github'),
                icon: Icons.open_in_new_rounded,
                onPressed: () => _openGitHub(context, profileUrl, t),
              ),
            const SizedBox(height: 10),
            SecondaryNeonButton(
              label: t.t('manage_repos'),
              icon: Icons.folder_open_rounded,
              color: NovaTheme.neonCyan,
              onPressed: () {
                state.setTab(1);
                Navigator.of(context).maybePop();
              },
            ),
            const SizedBox(height: 8),
            SecondaryNeonButton(
              label: t.t('security'),
              icon: Icons.lock_outline_rounded,
              color: NovaTheme.neonPurpleSoft,
              onPressed: () => Navigator.pushNamed(context, '/security'),
            ),
            const SizedBox(height: 8),
            SecondaryNeonButton(
              label: t.t('logout'),
              icon: Icons.logout_rounded,
              color: NovaTheme.danger,
              onPressed: () => _confirmSignOut(context, state, t),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetric extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;

  const _ProfileMetric({
    required this.value,
    required this.label,
    this.accent = NovaTheme.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
      borderColor: accent.withOpacity(0.3),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: TextStyle(color: accent, fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: NovaTheme.textDim, fontSize: 10.5, height: 1.15),
          ),
        ],
      ),
    );
  }
}
