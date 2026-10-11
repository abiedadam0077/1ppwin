import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

Future<void> showPatSignInDialog(BuildContext context) async {
  final t = L10n.of(context);
  final st = context.read<AppState>();
  final controller = TextEditingController();
  var obscure = true;

  final value = await showDialog<String>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) => AlertDialog(
        backgroundColor: NovaTheme.card,
        title: Row(
          children: [
            const Icon(Icons.key, color: NovaTheme.neonCyan, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t.t('pat_title'),
                style: const TextStyle(color: NovaTheme.text, fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t.t('pat_hint'),
              style: const TextStyle(color: NovaTheme.textDim, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 12),
            NeonField(
              controller: controller,
              label: 'ghp_... / github_pat_...',
              obscure: obscure,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.visiblePassword,
              suffix: IconButton(
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, size: 18, color: NovaTheme.textDim),
                onPressed: () => setModal(() => obscure = !obscure),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(
                  'https://github.com/settings/tokens/new?scopes=repo,workflow&description=NOVA+Windows+Cloud',
                ),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new, size: 16, color: NovaTheme.neonCyan),
              label: Text(
                t.t('create_pat_github'),
                style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.t('cancel'), style: const TextStyle(color: NovaTheme.textDim)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: NovaTheme.neonBlue),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(t.t('submit')),
          ),
        ],
      ),
    ),
  );
  if (value == null || value.trim().isEmpty) return;
  final err = await st.signInWithPersonalToken(value);
  if (!context.mounted) return;
  if (err != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('login_ok'))));
  }
}

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
      stars: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Top language switcher bar
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: NovaTheme.card.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: NovaTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final l in const [
                          ['ar', 'عربي'],
                          ['en', 'EN'],
                          ['fr', 'FR'],
                        ])
                          InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => st.setLang(l[0]),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: st.lang == l[0] ? NovaTheme.neonPurple : Colors.transparent,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                l[1],
                                style: TextStyle(
                                  color: st.lang == l[0] ? Colors.white : NovaTheme.textDim,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const WindowsCloudLogo(size: 165),
                const SizedBox(height: 10),
                const Text(
                  'NOVA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.5,
                    shadows: [
                      Shadow(color: NovaTheme.neonBlue, blurRadius: 24),
                      Shadow(color: NovaTheme.neonPurple, blurRadius: 36),
                    ],
                  ),
                ),
                const Text(
                  'Windows Cloud',
                  style: TextStyle(
                    color: NovaTheme.neonCyan,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  t.t('tagline'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NovaTheme.textDim, fontSize: 13.5),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      _feature(Icons.desktop_windows_rounded, t.t('feature_vm')),
                      const SizedBox(height: 11),
                      _feature(Icons.enhanced_encryption_rounded, t.t('feature_backup')),
                      const SizedBox(height: 11),
                      _feature(Icons.lock_outline_rounded, t.t('feature_secrets')),
                      const SizedBox(height: 11),
                      _feature(Icons.public_rounded, t.t('feature_access')),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (st.authError != null) _errorCard(t, st),
                if (device != null && st.deviceWaiting) _deviceCard(t, st, device.userCode),
                if (device == null || !st.deviceWaiting) ...[
                  GradientButton(
                    label: t.t('login_code'),
                    icon: Icons.vpn_key_rounded,
                    busy: st.authBusy,
                    onPressed: () => context.read<AppState>().startDeviceLogin(),
                  ),
                  const SizedBox(height: 10),
                  SecondaryNeonButton(
                    label: t.t('login_pat'),
                    icon: Icons.key_rounded,
                    color: NovaTheme.neonCyan,
                    busy: st.authBusy,
                    onPressed: () => showPatSignInDialog(context),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: st.authBusy ? null : () => context.read<AppState>().startLogin(),
                    icon: const Icon(Icons.open_in_browser, size: 17, color: NovaTheme.textDim),
                    label: Text(
                      t.t('login_browser'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: NovaTheme.textDim, fontSize: 12.5),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
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
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: StatusBadge(
                      label: t.t('secret_saved'),
                      color: NovaTheme.ok,
                      icon: Icons.check_circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _feature(IconData icon, String label) => Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: NovaTheme.neonBlue.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: NovaTheme.neonBlue.withOpacity(0.4)),
            ),
            child: Icon(icon, color: NovaTheme.neonCyan, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: NovaTheme.text,
                fontSize: 13,
                height: 1.18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      );

  Widget _deviceCard(L10n t, AppState st, String userCode) => GlassCard(
        borderColor: NovaTheme.neonBlue,
        glowColor: NovaTheme.neonPurple,
        child: Column(
          children: [
            Text(
              t.t('device_hint'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: NovaTheme.textDim, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: NovaTheme.bg.withOpacity(0.75),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NovaTheme.neonPurple),
              ),
              child: SelectableText(
                userCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SecondaryNeonButton(
                    label: t.t('copy_code'),
                    icon: Icons.copy,
                    color: NovaTheme.neonCyan,
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: userCode));
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t.t('code_copied'))));
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: GradientButton(
                    height: 48,
                    label: t.t('open_github'),
                    icon: Icons.open_in_new,
                    onPressed: () => st.openDevicePage(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 15,
                  height: 15,
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
          glowColor: NovaTheme.danger,
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.error_outline, color: NovaTheme.danger, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      t.t('login_failed'),
                      style: const TextStyle(color: NovaTheme.danger, fontSize: 13.5, fontWeight: FontWeight.w700),
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

/// Shown right after a successful GitHub sign-in.
class LoginSuccessScreen extends StatelessWidget {
  final VoidCallback onContinue;
  const LoginSuccessScreen({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final login = st.user?['login'] as String? ?? '';
    final name = st.user?['name'] as String? ?? login;
    final avatar = st.user?['avatar_url'] as String?;

    return GlowBackground(
      stars: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 124,
                      height: 124,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: NovaTheme.btnGradient,
                        boxShadow: [
                          BoxShadow(
                            color: NovaTheme.neonBlue.withOpacity(0.45),
                            blurRadius: 28,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 108,
                      height: 108,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: const Icon(Icons.code_rounded, size: 66, color: NovaTheme.bg),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: NovaTheme.ok,
                          shape: BoxShape.circle,
                          border: Border.all(color: NovaTheme.bg, width: 2.5),
                        ),
                        child: const Icon(Icons.check, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                StatusBadge(label: t.t('login_ok'), color: NovaTheme.ok, icon: Icons.verified_user),
                const SizedBox(height: 12),
                Text(
                  '${t.t('welcome')} ${name.isNotEmpty ? name : login}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 22),
                GlassCard(
                  borderColor: NovaTheme.ok.withOpacity(0.5),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                        backgroundColor: NovaTheme.bg2,
                        child: avatar == null ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name.isNotEmpty ? name : login,
                              style: const TextStyle(color: NovaTheme.text, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              '@$login',
                              style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: NovaTheme.ok, size: 22),
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                GradientButton(
                  label: t.t('continue'),
                  icon: Icons.dashboard_customize_rounded,
                  onPressed: onContinue,
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => context.read<AppState>().logout(),
                  icon: const Icon(Icons.logout, size: 16, color: NovaTheme.textDim),
                  label: Text(t.t('logout'), style: const TextStyle(color: NovaTheme.textDim)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
