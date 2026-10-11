import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final device = st.deviceCode;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(26),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const WindowsCloudLogo(size: 170),
                const SizedBox(height: 14),
                const Text(
                  'NOVA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    shadows: [Shadow(color: NovaTheme.neonBlue, blurRadius: 24)],
                  ),
                ),
                const Text(
                  'Windows Cloud',
                  style: TextStyle(color: NovaTheme.neonCyan, fontSize: 21, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  t.t('tagline'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NovaTheme.textDim, fontSize: 14),
                ),
                const SizedBox(height: 22),
                _feature(Icons.vpn_key, t.t('login_code')),
                _feature(Icons.desktop_windows, 'Real Windows 11'),
                _feature(Icons.backup, 'Backup & Restore'),
                _feature(Icons.public, 'Access from Anywhere'),
                const SizedBox(height: 22),
                if (st.authError != null) _errorCard(t, st),
                if (device != null && st.deviceWaiting) _deviceCard(t, st, device.userCode),
                if (device == null || !st.deviceWaiting) ...[
                  GradientButton(
                    label: t.t('login_code'),
                    icon: Icons.vpn_key,
                    busy: st.authBusy,
                    onPressed: () => context.read<AppState>().startDeviceLogin(),
                  ),
                  const SizedBox(height: 6),
                  TextButton(
                    onPressed: st.authBusy ? null : () => context.read<AppState>().startLogin(),
                    child: Text(
                      t.t('login_browser'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: NovaTheme.textDim, fontSize: 13),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => _showClientSecretDialog(context),
                      child: Text(t.t('advanced'), style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12)),
                    ),
                    TextButton(
                      onPressed: () => _showPasteDialog(context),
                      child: Text(t.t('paste_link'), style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12)),
                    ),
                  ],
                ),
                if (st.clientSecretSaved)
                  Text(t.t('secret_saved'), style: const TextStyle(color: NovaTheme.ok, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String label) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: NovaTheme.neonCyan, size: 18),
            const SizedBox(width: 10),
            Flexible(
              child: Text(label, style: const TextStyle(color: NovaTheme.text, fontSize: 13)),
            ),
          ],
        ),
      );

  Widget _deviceCard(L10n t, AppState st, String userCode) => GlassCard(
        borderColor: NovaTheme.neonBlue,
        child: Column(
          children: [
            Text(
              t.t('device_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: NovaTheme.textDim, fontSize: 13),
            ),
            const SizedBox(height: 10),
            SelectableText(
              userCode,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: NovaTheme.neonCyan),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: userCode));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('code_copied'))));
                    },
                    icon: const Icon(Icons.copy, size: 16, color: NovaTheme.neonCyan),
                    label: Text(t.t('copy_code'), style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NovaTheme.neonBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => st.openDevicePage(),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: Text(t.t('open_github'), style: const TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: NovaTheme.neonBlue),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    t.t('waiting_auth'),
                    style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
                  ),
                ),
              ],
            ),
            TextButton(
              onPressed: () => st.cancelDeviceLogin(),
              child: Text(t.t('cancel'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 12)),
            ),
          ],
        ),
      );

  Widget _errorCard(L10n t, AppState st) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: GlassCard(
          borderColor: NovaTheme.danger,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, color: NovaTheme.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.t('login_failed'),
                      style: const TextStyle(color: NovaTheme.danger, fontSize: 13, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                st.authError ?? '',
                style: const TextStyle(color: NovaTheme.text, fontSize: 12, height: 1.5),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: st.authError ?? ''));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('code_copied'))));
                    },
                    icon: const Icon(Icons.copy, size: 15, color: NovaTheme.textDim),
                    label: Text(t.t('copy_details'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () => context.read<AppState>().retryExchange(),
                    child: Text(t.t('retry'), style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );

  Future<void> _showClientSecretDialog(BuildContext context) async {
    final t = L10n.of(context);
    final st = context.read<AppState>();
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NovaTheme.card,
        title: Text(t.t('client_secret'), style: const TextStyle(color: NovaTheme.text, fontSize: 15)),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          style: const TextStyle(color: NovaTheme.text, fontSize: 13),
          decoration: const InputDecoration(
            hintText: 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
            hintStyle: TextStyle(color: NovaTheme.textDim, fontSize: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(t.t('save'))),
        ],
      ),
    );
    if (value == null) return;
    await st.saveClientSecret(value);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('saved_ok_short'))));
  }

  Future<void> _showPasteDialog(BuildContext context) async {
    final t = L10n.of(context);
    final st = context.read<AppState>();
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NovaTheme.card,
        title: Text(t.t('paste_link'), style: const TextStyle(color: NovaTheme.text, fontSize: 15)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: NovaTheme.text, fontSize: 13),
          decoration: InputDecoration(
            hintText: t.t('paste_link_hint'),
            hintStyle: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.t('cancel'))),
          TextButton(onPressed: () => Navigator.pop(ctx, controller.text), child: Text(t.t('submit'))),
        ],
      ),
    );
    if (value == null || value.trim().isEmpty) return;
    await st.submitManualInput(value);
  }
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
