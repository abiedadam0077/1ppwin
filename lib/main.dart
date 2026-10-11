import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding.dart';
import 'screens/repos.dart';
import 'screens/security.dart';
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
      },
      home: !st.initialized
          ? const Scaffold(
              backgroundColor: NovaTheme.bg,
              body: Center(child: CircularProgressIndicator(color: NovaTheme.neonBlue)),
            )
          : st.token == null
              ? const OnboardingScreen()
                  : st.justLoggedIn
                  ? LoginSuccessScreen(onContinue: () => st.setJustLoggedIn(false))
                  : const HomeShell(),
    );
  }
}
