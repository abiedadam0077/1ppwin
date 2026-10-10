import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('activity'))),
        body: st.activity.isEmpty
            ? const Center(child: Icon(Icons.history, color: NovaTheme.textDim, size: 50))
            : ListView.separated(
                padding: const EdgeInsets.all(18),
                itemCount: st.activity.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (c, i) {
                  final e = st.activity[i];
                  return GlassCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          e.ok ? Icons.check_circle : Icons.error,
                          color: e.ok ? NovaTheme.ok : NovaTheme.danger,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.text, style: const TextStyle(color: NovaTheme.text, fontSize: 13)),
                              Text(
                                '${e.time.year.toString().padLeft(4, '0')}-${e.time.month.toString().padLeft(2, '0')}-${e.time.day.toString().padLeft(2, '0')} ${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(color: NovaTheme.textDim, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('settings'))),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.t('language'), style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  for (final l in const [
                    ['ar', 'العربية'],
                    ['en', 'English'],
                    ['fr', 'Français'],
                  ])
                    RadioListTile<String>(
                      title: Text(l[1], style: const TextStyle(color: NovaTheme.text, fontSize: 14)),
                      value: l[0],
                      groupValue: st.lang,
                      activeColor: NovaTheme.neonBlue,
                      onChanged: (v) => st.setLang(v!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_outline, color: NovaTheme.neonBlue),
                    title: Text(t.t('security'), style: const TextStyle(color: NovaTheme.text, fontSize: 14)),
                    onTap: () => Navigator.pushNamed(context, '/security'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.swap_horiz, color: NovaTheme.neonCyan),
                    title: Text(t.t('choose_repo'), style: const TextStyle(color: NovaTheme.text, fontSize: 14)),
                    onTap: () => Navigator.pushNamed(context, '/repos'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.t('about'), style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 13, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'NOVA Windows Cloud v1.0\nWindows 11 Pro on GitHub Actions\nOAuth: GitHub App + PKCE\nSecrets: AES-256 (crypto_box_seal)',
                    style: TextStyle(color: NovaTheme.textDim, fontSize: 12, height: 1.7),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: NovaTheme.danger),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () => st.logout(),
              icon: const Icon(Icons.logout, color: NovaTheme.danger, size: 18),
              label: Text(t.t('logout'), style: const TextStyle(color: NovaTheme.danger)),
            ),
          ],
        ),
      ),
    );
  }
}
