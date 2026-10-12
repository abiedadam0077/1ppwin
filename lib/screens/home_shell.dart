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
    final idx = st.currentTab.clamp(0, screens.length - 1).toInt();
    final destinations = [
      NovaNavigationItem(
        icon: Icons.home_outlined,
        selectedIcon: Icons.home_rounded,
        label: t.t('home'),
      ),
      NovaNavigationItem(
        icon: Icons.folder_outlined,
        selectedIcon: Icons.folder_rounded,
        label: t.t('nav_repos'),
      ),
      NovaNavigationItem(
        icon: Icons.backup_outlined,
        selectedIcon: Icons.backup_rounded,
        label: t.t('nav_backups'),
      ),
      NovaNavigationItem(
        icon: Icons.history_outlined,
        selectedIcon: Icons.history_rounded,
        label: t.t('nav_activity'),
      ),
      NovaNavigationItem(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings_rounded,
        label: t.t('nav_settings'),
      ),
    ];

    return Scaffold(
      backgroundColor: NovaTheme.bg,
      body: IndexedStack(index: idx, children: screens),
      bottomNavigationBar: NovaBottomNavigationBar(
        selectedIndex: idx,
        items: destinations,
        onSelected: st.setTab,
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
      if (!st.secretsReady) {
        Navigator.pushNamed(context, '/security');
      }
      return;
    }
    if (!st.secretsReady) {
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
    final rawName = st.user?['name'] as String? ?? '';
    final displayName = rawName.trim().isNotEmpty ? rawName.trim() : login;
    final avatar = st.user?['avatar_url'] as String?;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.t('home')),
          leading: Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: NovaTheme.card,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NovaTheme.cardBorder),
              ),
              child: const WindowsMark(size: 20),
            ),
          ),
          actions: [
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
              if (login.isNotEmpty) ...[
                _buildProfileGreeting(
                  t: t,
                  name: displayName,
                  login: login,
                  avatar: avatar,
                  onTap: () => st.setTab(4),
                ),
                const SizedBox(height: 14),
              ],
              _buildWindowsHeroCard(context, st, t),
              if (st.selectedRepo != null) ...[
                const SizedBox(height: 12),
                _buildSelectedRepoCard(context, st, t),
              ],
              const SizedBox(height: 12),
              _buildLatestBackupCard(context, st, t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileGreeting({
    required L10n t,
    required String name,
    required String login,
    required String? avatar,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: NovaTheme.btnGradient,
                boxShadow: [
                  BoxShadow(
                    color: NovaTheme.neonBlue.withOpacity(0.38),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 22,
                backgroundColor: NovaTheme.bg2,
                backgroundImage: avatar != null ? NetworkImage(avatar) : null,
                child: avatar == null ? const Icon(Icons.person, color: NovaTheme.textDim) : null,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${t.t('welcome')} $name',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NovaTheme.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      '@$login',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NovaTheme.textDim,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_left_rounded, color: NovaTheme.neonBlue, size: 23),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowsHeroCard(BuildContext context, AppState st, L10n t) {
    final isLive = st.isLiveRunActive;
    final webUrl = st.sessionInfo?.webUrl;
    final tailscaleIp = st.sessionInfo?.tailscaleIp;
    final hasSessionInfo = (webUrl?.isNotEmpty ?? false) || (tailscaleIp?.isNotEmpty ?? false);
    final expectsAccessRoute = st.webAccessEnabled || (st.rdpEnabled && st.hasTailscaleSecret);
    final isReadyToStart = st.selectedRepo != null && st.repoReady && st.secretsReady;
    final remaining = _remainingTime(st);

    Color stateColor;
    String stateLabel;
    IconData stateIcon;

    if (isLive && hasSessionInfo) {
      stateColor = NovaTheme.ok;
      stateLabel = t.t('win_state_running');
      stateIcon = Icons.check_circle;
    } else if (isLive && (st.sessionInfo != null || !expectsAccessRoute)) {
      stateColor = NovaTheme.warn;
      stateLabel = t.t('no_access');
      stateIcon = Icons.link_off_rounded;
    } else if (isLive) {
      stateColor = NovaTheme.neonCyan;
      stateLabel = t.t('win_state_starting');
      stateIcon = Icons.sync;
    } else if (st.statusBusy && st.selectedRepo != null) {
      stateColor = NovaTheme.neonBlue;
      stateLabel = t.t('checking');
      stateIcon = Icons.sync_rounded;
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
    } else if (!st.secretsReady) {
      primaryButtonLabel = t.t('security');
      primaryButtonIcon = Icons.lock_outline_rounded;
    } else {
      primaryButtonLabel = t.t('start_windows');
      primaryButtonIcon = Icons.rocket_launch_rounded;
    }

    return GlassCard(
      borderColor: isLive ? NovaTheme.ok.withOpacity(0.75) : NovaTheme.cardBorderBright.withOpacity(0.55),
      glowColor: isLive ? NovaTheme.ok : NovaTheme.neonPurple,
      padding: const EdgeInsets.all(14),
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
                pulsing: (isLive && expectsAccessRoute && !hasSessionInfo) || (st.statusBusy && st.selectedRepo != null),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 132,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/nova_windows_bloom.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Color(0xB3132E55)],
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: 13,
                    end: 13,
                    bottom: 11,
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: NovaTheme.btnGradient,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: NovaTheme.neonCyan.withOpacity(0.75)),
                            boxShadow: [
                              BoxShadow(
                                color: NovaTheme.neonBlue.withOpacity(0.45),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const WindowsMark(size: 26),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                'Windows 11 Pro',
                                textDirection: TextDirection.ltr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  shadows: [Shadow(color: Color(0x66000000), blurRadius: 8)],
                                ),
                              ),
                              if (st.selectedRepo != null)
                                Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    st.selectedRepo!.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFF0F5FF),
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
                  Row(
                    children: [
                      Expanded(
                        child: _sessionMetric(
                          Icons.timer_outlined,
                          t.t('time_left'),
                          remaining ?? '—',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _sessionMetric(
                          Icons.lock_outline_rounded,
                          t.t('duration'),
                          '${st.dispatchedHours} ${t.t('hours')}',
                        ),
                      ),
                    ],
                  ),
                  if (st.sessionInfo?.webUrl != null && st.sessionInfo!.webUrl!.isNotEmpty)
                    _infoLine(Icons.public, t.t('web_link'), st.sessionInfo!.webUrl!),
                  if (st.sessionInfo?.tailscaleIp != null && st.sessionInfo!.tailscaleIp!.isNotEmpty)
                    _infoLine(Icons.desktop_windows_outlined, t.t('ip'), st.sessionInfo!.tailscaleIp!),
                  if (expectsAccessRoute && st.sessionInfo == null)
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
                    )
                  else if (!hasSessionInfo)
                    Row(
                      children: [
                        const Icon(Icons.link_off_rounded, color: NovaTheme.warn, size: 15),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            t.t('session_no_access'),
                            style: const TextStyle(color: NovaTheme.warn, fontSize: 11.5, height: 1.3),
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

  Widget _sessionMetric(IconData icon, String label, String value) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        decoration: BoxDecoration(
          color: NovaTheme.bg2.withOpacity(0.82),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NovaTheme.neonBlue.withOpacity(0.34)),
        ),
        child: Row(
          children: [
            Icon(icon, color: NovaTheme.neonCyan, size: 17),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: NovaTheme.textDim, fontSize: 9.5),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NovaTheme.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

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
    if (repo == null) return const SizedBox.shrink();

    final workflowReady = st.repoReady;
    final secretsReady = st.secretsReady;
    final overallReady = workflowReady && secretsReady;
    final secretsLabel = st.secretsPermissionDenied
        ? t.t('permissions_needed')
        : secretsReady
            ? t.t('ready')
            : t.t('needs_secrets');

    return GlassCard(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.folder_special_rounded, color: NovaTheme.neonCyan, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.t('selected_repo_card'),
                      style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5),
                    ),
                    Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        repo.fullName,
                        textAlign: TextAlign.left,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: NovaTheme.text, fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusBadge(
                label: st.statusBusy ? t.t('checking') : (overallReady ? t.t('ready') : t.t('not_ready')),
                color: overallReady ? NovaTheme.ok : NovaTheme.warn,
                icon: overallReady ? Icons.check_circle : Icons.info_outline,
                pulsing: st.statusBusy,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              StatusBadge(
                label: '${t.t('workflow')}: ${workflowReady ? t.t('ready') : t.t('not_ready')}',
                color: workflowReady ? NovaTheme.ok : NovaTheme.warn,
                icon: workflowReady ? Icons.account_tree_rounded : Icons.build_circle_outlined,
              ),
              StatusBadge(
                label: '${t.t('secrets_status')}: $secretsLabel',
                color: secretsReady ? NovaTheme.ok : NovaTheme.warn,
                icon: secretsReady ? Icons.lock_rounded : Icons.lock_clock_outlined,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () => st.setTab(1),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 17, color: NovaTheme.neonCyan),
                  label: Text(
                    t.t('manage_repos'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/security'),
                  icon: const Icon(Icons.vpn_key_outlined, size: 16, color: NovaTheme.neonPurpleSoft),
                  label: Text(
                    t.t('security'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: NovaTheme.neonPurpleSoft, fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLatestBackupCard(BuildContext context, AppState st, L10n t) {
    final backup = st.latestCompleteBackup;
    final backupState = st.selectedRepo == null
        ? t.t('no_repo_selected')
        : st.backupsError != null
            ? t.t('backups_load_failed')
            : st.backupsBusy || st.backupsList == null
                ? t.t('loading_backups')
                : backup == null
                    ? (st.backupsList!.isEmpty ? t.t('no_backups') : t.t('backup_incomplete'))
                    : '${_fmtSize(backup.totalBytes)} · ${_fmtDate(backup.createdAt)}';

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      borderColor: backup != null ? NovaTheme.ok.withOpacity(0.42) : NovaTheme.cardBorder,
      glowColor: backup != null ? NovaTheme.ok : NovaTheme.neonCyan,
      onTap: () => st.setTab(2),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: (backup != null ? NovaTheme.ok : NovaTheme.neonCyan).withOpacity(0.13),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: (backup != null ? NovaTheme.ok : NovaTheme.neonCyan).withOpacity(0.3)),
            ),
            child: Icon(
              backup != null ? Icons.cloud_done_rounded : Icons.backup_outlined,
              color: backup != null ? NovaTheme.ok : NovaTheme.neonCyan,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.t('last_backup_card'),
                  style: const TextStyle(color: NovaTheme.text, fontSize: 13, fontWeight: FontWeight.w800),
                ),
                Text(
                  backupState,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textDirection: backup != null ? TextDirection.ltr : null,
                  textAlign: backup != null ? TextAlign.left : TextAlign.start,
                  style: TextStyle(
                    color: backup != null ? NovaTheme.textDim : (st.backupsError != null ? NovaTheme.danger : NovaTheme.textDim),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: NovaTheme.neonCyan, size: 22),
        ],
      ),
    );
  }

}
