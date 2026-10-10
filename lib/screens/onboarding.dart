import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const WindowsCloudLogo(size: 190),
                const SizedBox(height: 18),
                const Text(
                  'NOVA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    shadows: [Shadow(color: NovaTheme.neonBlue, blurRadius: 24)],
                  ),
                ),
                const Text(
                  'Windows Cloud',
                  style: TextStyle(color: NovaTheme.neonCyan, fontSize: 22, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  t.t('tagline'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NovaTheme.textDim, fontSize: 14),
                ),
                const SizedBox(height: 30),
                _feature(Icons.touch_app, t.t('login_github')),
                _feature(Icons.desktop_windows, 'Real Windows 11'),
                _feature(Icons.backup, 'Backup & Restore'),
                _feature(Icons.public, 'Access from Anywhere'),
                const SizedBox(height: 34),
                GradientButton(
                  label: t.t('login_github'),
                  icon: Icons.key,
                  busy: _busy,
                  onPressed: () async {
                    setState(() => _busy = true);
                    try {
                      await context.read<AppState>().startLogin();
                    } finally {
                      if (mounted) setState(() => _busy = false);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: NovaTheme.neonCyan, size: 20),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(color: NovaTheme.text, fontSize: 14)),
          ],
        ),
      );
}

/// Shown right after a successful OAuth callback.
class LoginSuccessScreen extends StatelessWidget {
  final VoidCallback onContinue;
  const LoginSuccessScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final login = st.user?['login'] as String? ?? '';
    final avatar = st.user?['avatar_url'] as String?;
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 56,
                      backgroundColor: NovaTheme.card,
                      backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                      child: avatar == null ? const Icon(Icons.person, size: 60) : null,
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: NovaTheme.ok, shape: BoxShape.circle),
                        child: const Icon(Icons.check, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(t.t('login_ok'),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text('${t.t('welcome')} $login', style: const TextStyle(color: NovaTheme.textDim, fontSize: 14)),
                const SizedBox(height: 26),
                GlassCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        backgroundColor: NovaTheme.bg2,
                        child: avatar == null ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(login, style: const TextStyle(color: NovaTheme.text, fontWeight: FontWeight.w700)),
                            Text('@$login', style: const TextStyle(color: NovaTheme.textDim, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                GradientButton(label: t.t('continue'), onPressed: onContinue),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.read<AppState>().logout(),
                  child: Text(t.t('logout'), style: const TextStyle(color: NovaTheme.textDim)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
