import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/l10n.dart';
import 'core/theme.dart';
import 'core/widgets.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding.dart';
import 'screens/repos.dart';
import 'screens/security.dart';
import 'screens/diagnostics.dart';
import 'screens/notifications.dart';
import 'screens/profile.dart';
import 'screens/minecraft_cloud.dart';
import 'state/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: const NovaApp(),
    ),
  );
}

class NovaApp extends StatefulWidget {
  const NovaApp({super.key});

  @override
  State<NovaApp> createState() => _NovaAppState();
}

class _NovaAppState extends State<NovaApp> {
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    _linkSub = AppLinks().uriLinkStream.listen(_handleLink, onError: (_) {});
    // The stream already replays cold-start links on Android; asking for the
    // initial link as well costs nothing and covers platform differences.
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleInitialLink());
  }

  Future<void> _handleInitialLink() async {
    try {
      final uri = await AppLinks().getInitialLink();
      if (uri != null) await _handleLink(uri);
    } catch (_) {
      // ignored: the stream is the primary source
    }
  }

  Future<void> _handleLink(Uri uri) async {
    if (!mounted || uri.scheme != 'novawindowscloud') return;
    final state = context.read<AppState>();
    final error = await state.handleCallback(uri);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final st = context.watch<AppState>();
    return MaterialApp(
      title: 'NOVA Windows Cloud',
      debugShowCheckedModeBanner: false,
      theme: NovaTheme.build(),
      locale: st.locale,
      supportedLocales: const [Locale('ar'), Locale('en'), Locale('fr')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routes: {
        '/security': (_) => const SecurityScreen(),
        '/repos': (_) => const RepoSelectorScreen(),
        '/notifications': (_) => const NotificationsScreen(),
        '/diagnostics': (_) => const DiagnosticsScreen(),
        '/profile': (_) => const ProfileScreen(),
        '/minecraft': (_) => const MinecraftCloudScreen(),
      },
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1).animate(animation),
            child: child,
          ),
        ),
        child: !st.initialized
            ? const _StartupScreen(key: ValueKey('startup'))
            : st.token == null
                ? const OnboardingScreen(key: ValueKey('onboarding'))
                : st.justLoggedIn
                    ? KeyedSubtree(
                        key: const ValueKey('login-success'),
                        child: LoginSuccessScreen(onContinue: () => st.setJustLoggedIn(false)),
                      )
                    : const HomeShell(key: ValueKey('home')),
      ),
    );
  }
}

/// Branded first-frame loading instead of a blank screen or bare spinner.
class _StartupScreen extends StatelessWidget {
  const _StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 26),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          NovaTheme.neonBlue.withOpacity(0.12),
                          NovaTheme.neonPurple.withOpacity(0.12),
                          NovaTheme.card.withOpacity(0.68),
                        ],
                      ),
                      border: Border.all(color: NovaTheme.cardBorderBright.withOpacity(0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: NovaTheme.neonBlue.withOpacity(0.16),
                          blurRadius: 34,
                          spreadRadius: 1,
                        ),
                        BoxShadow(
                          color: NovaTheme.neonPurple.withOpacity(0.13),
                          blurRadius: 48,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const WindowsCloudLogo(size: 138),
                        const SizedBox(height: 5),
                        const Directionality(
                          textDirection: TextDirection.ltr,
                          child: Column(
                            children: [
                              Text(
                                'NOVA',
                                style: TextStyle(
                                  color: NovaTheme.neonCyan,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4,
                                ),
                              ),
                              Text(
                                'Windows Cloud',
                                style: TextStyle(
                                  color: NovaTheme.neonCyan,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),
                  Text(
                    t.t('app_loading'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: NovaTheme.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    t.t('app_loading_sub'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: NovaTheme.textDim, fontSize: 13, height: 1.5),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 180,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: const LinearProgressIndicator(
                        minHeight: 4,
                        backgroundColor: NovaTheme.bg3,
                        color: NovaTheme.neonCyan,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
