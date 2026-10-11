import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';
import 'backups.dart';
import 'more.dart';
import 'repos.dart';
import 'session.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    const screens = [
      HomeFlowScreen(),
      RepoSelectorScreen(),
      BackupsScreen(),
      ActivityScreen(),
      SettingsScreen(),
    ];
    final idx = st.currentTab.clamp(0, screens.length - 1);

    return Scaffold(
      backgroundColor: NovaTheme.bg,
      body: screens[idx],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: NovaTheme.card.withOpacity(0.96),
          border: const Border(top: BorderSide(color: NovaTheme.cardBorder, width: 1.2)),
          boxShadow: [
            BoxShadow(
              color: NovaTheme.neonPurple.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedIndex: idx,
          onDestinationSelected: (i) => st.setTab(i),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.dashboard_outlined),
              selectedIcon: const Icon(Icons.dashboard_rounded),
              label: t.t('home'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.folder_outlined),
              selectedIcon: const Icon(Icons.folder_rounded),
              label: t.t('repos'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.backup_outlined),
              selectedIcon: const Icon(Icons.backup_rounded),
              label: t.t('backups'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.history_outlined),
              selectedIcon: const Icon(Icons.history_rounded),
              label: t.t('activity'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.settings_outlined),
              selectedIcon: const Icon(Icons.settings_rounded),
              label: t.t('settings'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen #1: Rich NOVA Windows Cloud Control Dashboard.
class HomeFlowScreen extends StatefulWidget {
  const HomeFlowScreen({super.key});

  @override
  State<HomeFlowScreen> createState() => _HomeFlowScreenState();
}

class _HomeFlowScreenState extends State<HomeFlowScreen> {
  bool _setupBusy = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final st = context.read<AppState>();
      if (st.selectedRepo != null) {
        st.refreshSelectedRepoStatus();
      } else if (st.repos.isEmpty && !st.busy) {
        st.loadRepos();
      }
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) return;
      final st = context.read<AppState>();
      if (st.selectedRepo != null && st.isLiveRunActive) {
        st.refreshSelectedRepoStatus();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  String _fmtSize(int b) {
    if (b <= 0) return '—';
    if (b < 1024 * 1024) return '${(b / 1024).toStringAsFixed(0)} KB';
    if (b < 1024 * 1024 * 1024) return '${(b / 1024 / 1024).toStringAsFixed(1)} MB';
    return '${(b / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  String _fmtDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  String? _remainingTime(AppState st) {
    if (!st.isLiveRunActive || st.runStartedAt == null) return null;
    final end = st.runStartedAt!.toUtc().add(Duration(hours: st.dispatchedHours));
    final d = end.difference(DateTime.now().toUtc());
    if (d.isNegative) return '0h 0m';
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }

  Future<void> _installOrRepairWorkflow(AppState st, L10n t) async {
    setState(() => _setupBusy = true);
    try {
      await st.installOrRepairWorkflow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(t.t('workflow_installed_ok'))),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.t('error')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _setupBusy = false);
    }
  }

  Future<void> _handlePrimaryAction(AppState st, L10n t) async {
    if (st.selectedRepo == null) {
      st.setTab(1);
      return;
    }
    if (!st.repoReady) {
      await _installOrRepairWorkflow(st, t);
      if (!mounted) return;
      if (!st.secretsReady && !st.secretsPermissionDenied) {
        Navigator.pushNamed(context, '/security');
      }
      return;
    }
    if (!st.secretsReady && !st.secretsPermissionDenied) {
      Navigator.pushNamed(context, '/security');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SessionSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final login = st.user?['login'] as String? ?? '';
    final avatar = st.user?['avatar_url'] as String?;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_queue_rounded, color: NovaTheme.neonCyan, size: 22),
              const SizedBox(width: 8),
              const Text(
                'NOVA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'Cloud',
                style: TextStyle(
                  color: NovaTheme.neonCyan,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          actions: [
            if (login.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => st.setTab(4),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: NovaTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: NovaTheme.cardBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 11,
                          backgroundColor: NovaTheme.bg2,
                          backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null ? const Icon(Icons.person, size: 13) : null,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          login,
                          style: const TextStyle(
                            color: NovaTheme.text,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            IconButton(
              tooltip: t.t('refresh'),
              icon: const Icon(Icons.refresh, color: NovaTheme.neonCyan),
              onPressed: st.statusBusy
                  ? null
                  : () {
                      st.loadRepos();
                      st.refreshSelectedRepoStatus();
                    },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await st.loadRepos();
            await st.refreshSelectedRepoStatus();
          },
          color: NovaTheme.neonBlue,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
            children: [
              // 1. HERO WINDOWS 11 STATUS PANEL
              _buildWindowsHeroCard(context, st, t),
              const SizedBox(height: 14),

              // 2. SELECTED REPOSITORY CARD
              _buildSelectedRepoCard(context, st, t),
              const SizedBox(height: 14),

              // 3. GITHUB ACTIONS & SECRETS STATUS CARD
              _buildActionsAndSecretsCard(context, st, t),
              const SizedBox(height: 14),

              // 4. LATEST BACKUP CARD
              _buildLatestBackupCard(context, st, t),
              const SizedBox(height: 18),

              // 5. QUICK CONTROL SHORTCUTS GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Text(
                  t.t('quick_shortcuts'),
                  style: const TextStyle(
                    color: NovaTheme.neonCyan,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _buildShortcutsGrid(context, st, t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWindowsHeroCard(BuildContext context, AppState st, L10n t) {
    final isLive = st.isLiveRunActive;
    final hasSessionInfo = st.sessionInfo != null && (st.sessionInfo?.webUrl != null || st.sessionInfo?.tailscaleIp != null);
    final isReadyToStart = st.selectedRepo != null && st.repoReady && (st.secretsReady || st.secretsPermissionDenied);
    final remaining = _remainingTime(st);

    Color stateColor;
    String stateLabel;
    IconData stateIcon;

    if (isLive && hasSessionInfo) {
      stateColor = NovaTheme.ok;
      stateLabel = t.t('win_state_running');
      stateIcon = Icons.check_circle;
    } else if (isLive) {
      stateColor = NovaTheme.neonCyan;
      stateLabel = t.t('win_state_starting');
      stateIcon = Icons.sync;
    } else if (isReadyToStart) {
      stateColor = NovaTheme.neonCyan;
      stateLabel = t.t('win_state_ready');
      stateIcon = Icons.verified_rounded;
    } else {
      stateColor = NovaTheme.warn;
      stateLabel = t.t('win_state_needs_setup');
      stateIcon = Icons.tune_rounded;
    }

    String primaryButtonLabel;
    IconData primaryButtonIcon;
    if (st.selectedRepo == null) {
      primaryButtonLabel = t.t('choose_repo');
      primaryButtonIcon = Icons.folder_open_rounded;
    } else if (!st.repoReady) {
      primaryButtonLabel = st.hasWorkflowFile ? t.t('repair_workflow') : t.t('install_workflow');
      primaryButtonIcon = Icons.auto_fix_high_rounded;
    } else if (!st.secretsReady && !st.secretsPermissionDenied) {
      primaryButtonLabel = t.t('security');
      primaryButtonIcon = Icons.lock_outline_rounded;
    } else {
      primaryButtonLabel = t.t('start_windows');
      primaryButtonIcon = Icons.rocket_launch_rounded;
    }

    return GlassCard(
      borderColor: isLive ? NovaTheme.ok.withOpacity(0.75) : NovaTheme.cardBorderBright.withOpacity(0.55),
      glowColor: isLive ? NovaTheme.ok : NovaTheme.neonPurple,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  t.t('win_status_title'),
                  style: const TextStyle(
                    color: NovaTheme.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusBadge(
                label: stateLabel,
                color: stateColor,
                icon: stateIcon,
                pulsing: isLive && !hasSessionInfo,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Center(child: WindowsCloudLogo(size: 135)),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Windows 11 Pro Cloud VM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (st.selectedRepo != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Center(
                child: Text(
                  st.selectedRepo!.fullName,
                  style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ),

          // Verified real session metrics when a live run is active
          if (isLive) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NovaTheme.bg.withOpacity(0.65),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: NovaTheme.ok.withOpacity(0.45)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (remaining != null)
                    _infoLine(Icons.timer_outlined, t.t('time_left'), remaining),
                  if (st.sessionInfo?.webUrl != null && st.sessionInfo!.webUrl!.isNotEmpty)
                    _infoLine(Icons.public, t.t('web_link'), st.sessionInfo!.webUrl!),
                  if (st.sessionInfo?.tailscaleIp != null && st.sessionInfo!.tailscaleIp!.isNotEmpty)
                    _infoLine(Icons.desktop_windows_outlined, t.t('ip'), st.sessionInfo!.tailscaleIp!),
                  if (st.sessionInfo == null)
                    Row(
                      children: [
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: NovaTheme.neonCyan),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            t.t('session_preparing'),
                            style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: GradientButton(
                    height: 50,
                    label: hasSessionInfo ? t.t('access_windows') : t.t('view_run'),
                    icon: hasSessionInfo ? Icons.desktop_windows_rounded : Icons.analytics_outlined,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => hasSessionInfo ? const ReadyScreen() : const ProgressScreen(),
                        ),
                      );
                    },
                  ),
                ),
                if (hasSessionInfo) ...[
                  const SizedBox(width: 8),
                  SecondaryNeonButton(
                    label: t.t('monitor'),
                    icon: Icons.timeline_rounded,
                    color: NovaTheme.neonCyan,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProgressScreen()),
                      );
                    },
                  ),
                ],
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            GradientButton(
              label: primaryButtonLabel,
              icon: primaryButtonIcon,
              busy: _setupBusy,
              onPressed: () => _handlePrimaryAction(st, t),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Icon(icon, color: NovaTheme.neonCyan, size: 15),
            const SizedBox(width: 6),
            Text('$label: ', style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5)),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: NovaTheme.text, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );

  Widget _buildSelectedRepoCard(BuildContext context, AppState st, L10n t) {
    final repo = st.selectedRepo;
    final isReady = repo != null && st.repoReady && st.secretsReady;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_special_rounded, color: NovaTheme.neonBlue, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.t('selected_repo_card'),
                  style: const TextStyle(
                    color: NovaTheme.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (repo != null)
                StatusBadge(
                  label: isReady
                      ? t.t('ready')
                      : !st.repoReady
                          ? (st.hasWorkflowFile ? t.t('needs_repair') : t.t('not_ready'))
                          : t.t('needs_secrets'),
                  color: isReady ? NovaTheme.ok : NovaTheme.warn,
                  icon: isReady ? Icons.check_circle : Icons.info_outline,
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (repo == null)
            Text(
              t.t('no_repo_selected_sub'),
              style: const TextStyle(color: NovaTheme.textDim, fontSize: 12.5, height: 1.4),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        repo.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${repo.isPrivate ? t.t('private') : t.t('public')} • ${repo.defaultBranch}',
                        style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SecondaryNeonButton(
                  label: t.t('manage_repos'),
                  icon: Icons.swap_horiz_rounded,
                  color: NovaTheme.neonCyan,
                  onPressed: () => st.setTab(1),
                ),
              ),
              if (repo != null && !st.repoReady) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: SecondaryNeonButton(
                    label: st.hasWorkflowFile ? t.t('repair_workflow') : t.t('install_workflow'),
                    icon: Icons.auto_fix_high_rounded,
                    color: NovaTheme.warn,
                    busy: _setupBusy,
                    onPressed: () => _installOrRepairWorkflow(st, t),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionsAndSecretsCard(BuildContext context, AppState st, L10n t) {
    final run = st.latestRunData;
    final runStatus = run?['status'] as String?;
    final runConclusion = run?['conclusion'] as String?;

    String runLabel;
    Color runColor;
    if (run == null) {
      runLabel = t.t('run_status_none');
      runColor = NovaTheme.textDim;
    } else if (runStatus == 'in_progress') {
      runLabel = t.t('run_status_in_progress');
      runColor = NovaTheme.ok;
    } else if (runStatus == 'queued' || runStatus == 'waiting') {
      runLabel = t.t('run_status_queued');
      runColor = NovaTheme.neonCyan;
    } else if (runConclusion == 'success') {
      runLabel = t.t('run_status_success');
      runColor = NovaTheme.ok;
    } else if (runConclusion == 'cancelled') {
      runLabel = t.t('run_status_cancelled');
      runColor = NovaTheme.warn;
    } else {
      runLabel = t.t('run_status_failure');
      runColor = NovaTheme.danger;
    }

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt_rounded, color: NovaTheme.neonPurpleSoft, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.t('actions_status_card'),
                  style: const TextStyle(
                    color: NovaTheme.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusBadge(label: runLabel, color: runColor),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusBadge(
                label: 'Workflow: ${st.repoReady ? t.t('ready') : (st.hasWorkflowFile ? t.t('needs_repair') : t.t('not_ready'))}',
                color: st.repoReady ? NovaTheme.ok : NovaTheme.warn,
                icon: st.repoReady ? Icons.check_circle : Icons.account_tree_outlined,
              ),
              StatusBadge(
                label: 'ACCESS_PASSWORD ${st.hasAccessSecret ? '✓' : '✗'}',
                color: st.hasAccessSecret ? NovaTheme.ok : NovaTheme.warn,
              ),
              StatusBadge(
                label: 'BACKUP_PASSWORD ${st.hasBackupSecret ? '✓' : '✗'}',
                color: st.hasBackupSecret ? NovaTheme.ok : NovaTheme.warn,
              ),
              StatusBadge(
                label: 'TAILSCALE ${st.hasTailscaleSecret ? '✓' : t.t('secret_optional')}',
                color: st.hasTailscaleSecret ? NovaTheme.ok : NovaTheme.neonCyan,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SecondaryNeonButton(
                  label: t.t('security'),
                  icon: Icons.vpn_key_outlined,
                  color: st.secretsReady ? NovaTheme.neonCyan : NovaTheme.warn,
                  onPressed: () => Navigator.pushNamed(context, '/security'),
                ),
              ),
              if (run != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: SecondaryNeonButton(
                    label: t.t('monitor'),
                    icon: Icons.timeline_rounded,
                    color: NovaTheme.neonBlue,
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ProgressScreen()),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestBackupCard(BuildContext context, AppState st, L10n t) {
    final backup = st.latestCompleteBackup;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done_outlined, color: NovaTheme.neonCyan, size: 21),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t.t('last_backup_card'),
                  style: const TextStyle(
                    color: NovaTheme.text,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusBadge(
                label: backup != null ? _fmtSize(backup.totalBytes) : t.t('no_backups'),
                color: backup != null ? NovaTheme.ok : NovaTheme.textDim,
                icon: backup != null ? Icons.verified_rounded : Icons.hourglass_empty,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            backup != null
                ? '${_fmtDate(backup.createdAt)} • ${backup.tag}'
                : t.t('no_backups_sub'),
            style: const TextStyle(color: NovaTheme.textDim, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          SecondaryNeonButton(
            label: t.t('backups'),
            icon: Icons.settings_backup_restore_rounded,
            color: NovaTheme.neonCyan,
            onPressed: () => st.setTab(2),
          ),
        ],
      ),
    );
  }

  Widget _buildShortcutsGrid(BuildContext context, AppState st, L10n t) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 520;
        final itemWidth = wide ? (constraints.maxWidth - 12) / 3 : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            SizedBox(
              width: itemWidth,
              child: QuickShortcutTile(
                icon: Icons.rocket_launch_rounded,
                title: t.t('session'),
                subtitle: '${st.dispatchedHours} ${t.t('hours')}',
                color: NovaTheme.neonBlue,
                onTap: () => _handlePrimaryAction(st, t),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: QuickShortcutTile(
                icon: Icons.folder_open_rounded,
                title: t.t('repos'),
                subtitle: st.selectedRepo?.name ?? t.t('choose_repo'),
                color: NovaTheme.neonPurpleSoft,
                onTap: () => st.setTab(1),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: QuickShortcutTile(
                icon: Icons.enhanced_encryption_rounded,
                title: t.t('security'),
                subtitle: st.secretsReady ? t.t('ready') : t.t('needs_secrets'),
                color: st.secretsReady ? NovaTheme.ok : NovaTheme.warn,
                onTap: () => Navigator.pushNamed(context, '/security'),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: QuickShortcutTile(
                icon: Icons.backup_rounded,
                title: t.t('backups'),
                subtitle: st.latestCompleteBackup != null
                    ? _fmtSize(st.latestCompleteBackup!.totalBytes)
                    : t.t('no_backups'),
                color: NovaTheme.neonCyan,
                onTap: () => st.setTab(2),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: QuickShortcutTile(
                icon: Icons.history_rounded,
                title: t.t('activity'),
                subtitle: '${st.activity.length}',
                color: NovaTheme.neonBlue,
                onTap: () => st.setTab(3),
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: QuickShortcutTile(
                icon: Icons.settings_rounded,
                title: t.t('settings'),
                subtitle: st.lang.toUpperCase(),
                color: NovaTheme.neonPurpleSoft,
                onTap: () => st.setTab(4),
              ),
            ),
          ],
        );
      },
    );
  }
}
