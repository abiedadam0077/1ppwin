import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import 'backups.dart';
import 'more.dart';
import 'repos.dart';
import 'session.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final screens = const [
      HomeFlowScreen(),
      RepoSelectorScreen(),
      BackupsScreen(),
      ActivityScreen(),
      SettingsScreen(),
    ];
    return Scaffold(
      backgroundColor: NovaTheme.bg,
      body: screens[_tab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: NovaTheme.card.withOpacity(0.95),
          border: Border(top: BorderSide(color: NovaTheme.cardBorder, width: 1)),
          boxShadow: [BoxShadow(color: NovaTheme.neonBlue.withOpacity(0.15), blurRadius: 18)],
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: _tab,
          onDestinationSelected: (i) => setState(() => _tab = i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(Icons.home, color: Colors.white),
              label: t.t('home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder_outlined),
              selectedIcon: const Icon(Icons.folder, color: Colors.white),
              label: t.t('repos'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.backup_outlined),
              selectedIcon: const Icon(Icons.backup, color: Colors.white),
              label: t.t('backups'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history, color: Colors.white),
              label: t.t('activity'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings, color: Colors.white),
              label: t.t('settings'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smart home: guides the user repo → workflow → secrets → session.
class HomeFlowScreen extends StatefulWidget {
  const HomeFlowScreen({super.key});

  @override
  State<HomeFlowScreen> createState() => _HomeFlowScreenState();
}

class _HomeFlowScreenState extends State<HomeFlowScreen> {
  bool _setupBusy = false;
  Map<String, dynamic>? _liveRun;

  @override
  void initState() {
    super.initState();
    _checkLive();
  }

  Future<void> _checkLive() async {
    final st = context.read<AppState>();
    if (st.api == null || st.selectedRepo == null) return;
    try {
      final run = await st.api!.latestRun(st.selectedRepo!.fullName);
      final status = run?['status'] as String? ?? '';
      if (status == 'in_progress' || status == 'queued') {
        st.runId = run!['id'] as int;
        if (st.sessionInfo == null) {
          st.sessionInfo = await st.api!.sessionInfo(st.selectedRepo!.fullName, st.runId!);
        }
        if (mounted) setState(() => _liveRun = run);
      }
    } catch (_) {}
  }

  Future<void> _setupRepo() async {
    final st = context.read<AppState>();
    final t = L10n.of(context);
    setState(() => _setupBusy = true);
    try {
      final yaml = await rootBundle.loadString('assets/windows11.yml');
      await st.api!.createWorkflowFile(st.selectedRepo!.fullName, st.selectedRepo!.defaultBranch, yaml);
      await st.selectRepo(st.selectedRepo!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workflow ✓')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.t('error')}: $e')));
      }
    } finally {
      if (mounted) setState(() => _setupBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();

    Widget body;
    if (st.selectedRepo == null) {
      body = _card(
        icon: Icons.folder_open,
        text: t.t('choose_repo'),
        button: t.t('repos'),
        onPressed: null, // user picks from the repos tab
      );
    } else if (!st.repoReady) {
      body = _card(
        icon: Icons.account_tree,
        text: t.t('workflow_missing'),
        button: t.t('ready'),
        busy: _setupBusy,
        onPressed: _setupRepo,
      );
    } else if (!st.secretsReady) {
      body = _card(
        icon: Icons.lock_outline,
        text: t.t('security_sub'),
        button: t.t('security'),
        onPressed: () => Navigator.pushNamed(context, '/security'),
      );
    } else {
      return const SessionSetupScreen();
    }

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('NOVA', style: TextStyle(letterSpacing: 3, fontWeight: FontWeight.w800)),
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (_liveRun != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GlassCard(
                  borderColor: NovaTheme.ok,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      const Icon(Icons.play_circle, color: NovaTheme.ok, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(t.t('session_live'),
                            style: const TextStyle(color: NovaTheme.text, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: NovaTheme.neonBlue),
                        onPressed: () {
                          final hasInfo = st.sessionInfo != null;
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => hasInfo ? const ReadyScreen() : const ProgressScreen(),
                          ));
                        },
                        child: Text(t.t('view_run'), style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            const Center(child: WindowsCloudLogo(size: 140)),
            const SizedBox(height: 18),
            body,
          ],
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String text,
    required String button,
    VoidCallback? onPressed,
    bool busy = false,
  }) =>
      GlassCard(
        child: Column(
          children: [
            Icon(icon, color: NovaTheme.neonBlue, size: 34),
            const SizedBox(height: 10),
            Text(text, textAlign: TextAlign.center, style: const TextStyle(color: NovaTheme.text, fontSize: 14)),
            const SizedBox(height: 14),
            if (onPressed == null)
              Text('↳ ${button}', style: const TextStyle(color: NovaTheme.textDim, fontSize: 12))
            else
              GradientButton(label: button, busy: busy, onPressed: onPressed),
          ],
        ),
      );
}
