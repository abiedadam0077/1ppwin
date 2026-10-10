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
    _linkSub = AppLinks().uriLinkStream.listen((uri) async {
      if (uri.scheme != 'novawindowscloud') return;
      final st = context.read<AppState>();
      final err = await st.handleCallback(uri);
      if (mounted) {
        if (err != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
        } else {
          st.setJustLoggedIn(true);
        }
      }
    });
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
