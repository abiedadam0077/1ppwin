import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../services/github_service.dart';
import '../state/app_state.dart';
import 'session.dart';

class RepoSelectorScreen extends StatefulWidget {
  const RepoSelectorScreen({super.key});

  @override
  State<RepoSelectorScreen> createState() => _RepoSelectorScreenState();
}

class _RepoSelectorScreenState extends State<RepoSelectorScreen> {
  final _searchCtrl = TextEditingController();
  String _q = '';
  String _filter = 'all';
  String? _installingRepo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final st = context.read<AppState>();
      if (st.repos.isEmpty && !st.busy) {
        st.loadRepos();
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool _matchesFilter(Repo r, RepoReadiness? rd) {
    final isReady = rd?.isFullyReady ?? false;
    final hasWf = rd?.hasWorkflow ?? false;
    switch (_filter) {
      case 'ready':
        return isReady || hasWf;
      case 'not_ready':
        return !isReady;
      case 'private':
        return r.isPrivate;
      case 'public':
        return !r.isPrivate;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final list = st.repos.where((r) {
      final rd = st.repoReadiness[r.fullName];
      if (!_matchesFilter(r, rd)) return false;
      if (_q.trim().isEmpty) return true;
      final qLower = _q.toLowerCase();
      return r.fullName.toLowerCase().contains(qLower) ||
          (r.description?.toLowerCase().contains(qLower) ?? false);
    }).toList();

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.t('repos')),
          actions: [
            IconButton(
              tooltip: t.t('refresh'),
              icon: const Icon(Icons.refresh, color: NovaTheme.neonCyan),
              onPressed: st.busy ? null : () => st.loadRepos(),
            ),
            IconButton(
              tooltip: t.t('new_repo'),
              icon: const Icon(Icons.add_circle_outline, color: NovaTheme.neonBlue),
              onPressed: () => _createDialog(context, st),
            ),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 5, 18, 7),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: NovaTheme.neonBlue.withOpacity(0.13),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: NovaTheme.neonBlue.withOpacity(0.32)),
                    ),
                    child: const Icon(Icons.folder_copy_outlined, color: NovaTheme.neonCyan, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.t('choose_repo'),
                          style: const TextStyle(
                            color: NovaTheme.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          st.selectedRepo?.fullName ?? t.t('repo_pick_hint'),
                          textDirection: st.selectedRepo != null ? TextDirection.ltr : null,
                          textAlign: st.selectedRepo != null ? TextAlign.left : TextAlign.start,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5, height: 1.08),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  StatusBadge(
                    label: '${st.repos.length}',
                    color: NovaTheme.neonCyan,
                    icon: Icons.folder_outlined,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 8),
              child: NeonField(
                controller: _searchCtrl,
                label: t.t('search_repo'),
                prefixIcon: Icons.search,
                onChanged: (v) => setState(() => _q = v),
                suffix: _q.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18, color: NovaTheme.textDim),
                        onPressed: () => setState(() {
                          _searchCtrl.clear();
                          _q = '';
                        }),
                      )
                    : null,
              ),
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  for (final f in const ['all', 'ready', 'not_ready', 'private', 'public'])
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(t.t(f), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        selected: _filter == f,
                        selectedColor: NovaTheme.neonBlue,
                        backgroundColor: NovaTheme.card,
                        side: BorderSide(
                          color: _filter == f ? NovaTheme.neonBlue : NovaTheme.cardBorder,
                        ),
                        labelStyle: TextStyle(
                          color: _filter == f ? Colors.white : NovaTheme.textDim,
                        ),
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: st.busy && st.repos.isEmpty
                  ? NovaLoadingState(
                      title: t.t('loading_repos'),
                      subtitle: t.t('loading_repos_sub'),
                      icon: Icons.folder_copy_outlined,
                    )
                  : st.reposError != null
                      ? _buildErrorState(t, st)
                      : list.isEmpty
                          ? _buildEmptyState(t, st)
                          : RefreshIndicator(
                              onRefresh: () => st.loadRepos(),
                              color: NovaTheme.neonBlue,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                                itemCount: list.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (c, i) => _buildRepoCard(context, st, t, list[i]),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(L10n t, AppState st) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          GlassCard(
            borderColor: NovaTheme.danger,
            glowColor: NovaTheme.danger,
            child: Column(
              children: [
                const Icon(Icons.cloud_off, color: NovaTheme.danger, size: 42),
                const SizedBox(height: 10),
                Text(
                  t.t('repos_load_failed'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NovaTheme.text, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  st.reposError ?? '',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
                ),
                const SizedBox(height: 14),
                GradientButton(
                  label: t.t('retry'),
                  icon: Icons.refresh,
                  onPressed: () => st.loadRepos(),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildEmptyState(L10n t, AppState st) {
    final hasNoRepos = st.repos.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: NovaEmptyState(
          icon: hasNoRepos ? Icons.folder_open_rounded : Icons.search_off_rounded,
          title: t.t(hasNoRepos ? 'repos_empty_title' : 'no_repos_match'),
          subtitle: t.t(hasNoRepos ? 'repos_empty_sub' : 'no_repo_results_sub'),
          color: hasNoRepos ? NovaTheme.neonCyan : NovaTheme.neonPurpleSoft,
          action: hasNoRepos
              ? GradientButton(
                  label: t.t('new_repo'),
                  icon: Icons.add,
                  onPressed: () => _createDialog(context, st),
                )
              : SecondaryNeonButton(
                  label: t.t('clear_search_filter'),
                  icon: Icons.filter_alt_off_rounded,
                  onPressed: () => setState(() {
                    _searchCtrl.clear();
                    _q = '';
                    _filter = 'all';
                  }),
                ),
        ),
      ),
    );
  }

  Widget _buildRepoCard(BuildContext context, AppState st, L10n t, Repo r) {
    final selected = st.selectedRepo?.fullName == r.fullName;
    final rd = st.repoReadiness[r.fullName];
    final checking = rd?.checking ?? false;
    final hasWf = selected ? st.hasWorkflowFile : (rd?.hasWorkflow ?? false);
    final needsRepair = selected ? st.workflowNeedsRepair : (rd?.workflowNeedsRepair ?? false);
    final hasSecrets = selected ? st.secretsReady : (rd?.hasRequiredSecrets ?? false);
    final isReady = hasWf && !needsRepair && hasSecrets;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (checking) {
      statusColor = NovaTheme.neonBlue;
      statusLabel = t.t('checking');
      statusIcon = Icons.sync;
    } else if (isReady) {
      statusColor = NovaTheme.ok;
      statusLabel = t.t('ready');
      statusIcon = Icons.check_circle;
    } else if (hasWf && needsRepair) {
      statusColor = NovaTheme.warn;
      statusLabel = t.t('needs_repair');
      statusIcon = Icons.build_circle_outlined;
    } else if (hasWf && !hasSecrets) {
      statusColor = NovaTheme.warn;
      statusLabel = t.t('needs_secrets');
      statusIcon = Icons.lock_clock_outlined;
    } else {
      statusColor = NovaTheme.textDim;
      statusLabel = t.t('not_ready');
      statusIcon = Icons.pending_outlined;
    }

    return GlassCard(
      borderColor: selected
          ? NovaTheme.neonBlue
          : isReady
              ? NovaTheme.ok.withOpacity(0.38)
              : NovaTheme.cardBorder,
      glowColor: selected ? NovaTheme.neonBlue : (isReady ? NovaTheme.ok : NovaTheme.neonBlue),
      padding: const EdgeInsets.all(12),
      onTap: () async {
        await st.selectRepo(r);
        if (!context.mounted) return;
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: selected ? NovaTheme.btnGradient : null,
                  color: selected ? null : NovaTheme.bg2,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: selected ? NovaTheme.neonBlue.withOpacity(0.75) : NovaTheme.cardBorder,
                  ),
                ),
                child: Icon(
                  isReady ? Icons.cloud_done_rounded : Icons.inventory_2_outlined,
                  color: selected ? Colors.white : (isReady ? NovaTheme.ok : NovaTheme.neonBlue),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            r.name,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: NovaTheme.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (selected) ...[
                          const SizedBox(width: 6),
                          StatusBadge(
                            label: t.t('selected_badge'),
                            color: NovaTheme.neonCyan,
                            icon: Icons.check,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      r.description?.trim().isNotEmpty == true ? r.description! : r.fullName,
                      textDirection: r.description?.trim().isNotEmpty == true ? null : TextDirection.ltr,
                      textAlign: r.description?.trim().isNotEmpty == true ? TextAlign.start : TextAlign.left,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 6,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              StatusBadge(
                label: statusLabel,
                color: statusColor,
                icon: statusIcon,
                pulsing: checking,
              ),
              StatusBadge(
                label: r.isPrivate ? t.t('private') : t.t('public'),
                color: r.isPrivate ? NovaTheme.neonPurpleSoft : NovaTheme.neonCyan,
                icon: r.isPrivate ? Icons.lock_outline : Icons.public,
              ),
              StatusBadge(
                label: r.defaultBranch,
                color: NovaTheme.textDim,
                icon: Icons.call_split,
              ),
            ],
          ),
          if (selected || !isReady) ...[
            const Divider(color: NovaTheme.cardBorder, height: 20),
            Row(
              children: [
                if (!hasWf || needsRepair)
                  Expanded(
                    child: SecondaryNeonButton(
                      label: needsRepair ? t.t('repair_workflow') : t.t('install_workflow'),
                      icon: Icons.auto_fix_high,
                      color: NovaTheme.neonCyan,
                      busy: _installingRepo == r.fullName,
                      onPressed: () async {
                        setState(() => _installingRepo = r.fullName);
                        try {
                          await st.selectRepo(r, silentLog: true);
                          await st.installOrRepairWorkflow(target: r);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(t.t('workflow_installed_ok'))),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${t.t('error')}: $e')),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => _installingRepo = null);
                        }
                      },
                    ),
                  )
                else if (!hasSecrets)
                  Expanded(
                    child: SecondaryNeonButton(
                      label: t.t('security'),
                      icon: Icons.lock_outline,
                      color: NovaTheme.warn,
                      onPressed: () async {
                        await st.selectRepo(r, silentLog: true);
                        if (context.mounted) {
                          Navigator.pushNamed(context, '/security');
                        }
                      },
                    ),
                  )
                else
                  Expanded(
                    child: SecondaryNeonButton(
                      label: t.t('start_windows'),
                      icon: Icons.rocket_launch,
                      color: NovaTheme.ok,
                      onPressed: () async {
                        await st.selectRepo(r, silentLog: true);
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const SessionSetupScreen()),
                          );
                        }
                      },
                    ),
                  ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: t.t('setup_repo_title'),
                  icon: const Icon(Icons.tune_rounded, color: NovaTheme.neonBlue),
                  onPressed: () async {
                    await st.selectRepo(r, silentLog: true);
                    if (context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const RepoSetupScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _createDialog(BuildContext context, AppState st) {
    final t = L10n.of(context);
    final name = TextEditingController();
    var isPrivate = true;
    var autoWorkflow = true;
    var creating = false;

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          backgroundColor: NovaTheme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          title: Row(
            children: [
              const Icon(Icons.create_new_folder_outlined, color: NovaTheme.neonCyan, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.t('new_repo'),
                  style: const TextStyle(color: NovaTheme.text, fontSize: 16, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeonField(
                label: t.t('repo_name'),
                controller: name,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                prefixIcon: Icons.folder_outlined,
              ),
              const SizedBox(height: 12),
              NeonSwitch(
                label: t.t('private'),
                icon: Icons.lock_outline,
                value: isPrivate,
                onChanged: (v) => set(() => isPrivate = v),
              ),
              NeonSwitch(
                label: t.t('auto_setup_workflow'),
                icon: Icons.account_tree_outlined,
                value: autoWorkflow,
                onChanged: (v) => set(() => autoWorkflow = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: creating ? null : () => Navigator.pop(c),
              child: Text(t.t('cancel'), style: const TextStyle(color: NovaTheme.textDim)),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: NovaTheme.neonBlue),
              onPressed: creating
                  ? null
                  : () async {
                      final n = name.text.trim();
                      if (n.isEmpty) return;
                      set(() => creating = true);
                      try {
                        await st.createAndSetupRepo(
                          n,
                          isPrivate: isPrivate,
                          installWorkflow: autoWorkflow,
                        );
                        if (c.mounted) Navigator.pop(c);
                        if (context.mounted) {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const RepoSetupScreen()),
                          );
                        }
                      } catch (e) {
                        set(() => creating = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${t.t('error')}: $e')),
                          );
                        }
                      }
                    },
              icon: creating
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 17),
              label: Text(t.t('create')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Screen #4: Dedicated Repository Setup & Verification screen.
class RepoSetupScreen extends StatefulWidget {
  const RepoSetupScreen({super.key});

  @override
  State<RepoSetupScreen> createState() => _RepoSetupScreenState();
}

class _RepoSetupScreenState extends State<RepoSetupScreen> {
  bool _wfBusy = false;

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final repo = st.selectedRepo;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('setup_repo_title'))),
        body: repo == null
            ? Center(child: Text(t.t('no_repo_selected'), style: const TextStyle(color: NovaTheme.textDim)))
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    t.t('setup_repo_sub'),
                    style: const TextStyle(color: NovaTheme.textDim, fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Step 1: Repository info
                  GlassCard(
                    borderColor: NovaTheme.ok.withOpacity(0.5),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: NovaTheme.ok, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                repo.fullName,
                                style: const TextStyle(
                                  color: NovaTheme.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${repo.isPrivate ? t.t('private') : t.t('public')} • ${repo.defaultBranch}',
                                style: const TextStyle(color: NovaTheme.textDim, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Step 2: Workflow file status
                  GlassCard(
                    borderColor: st.repoReady ? NovaTheme.ok.withOpacity(0.5) : NovaTheme.warn,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              st.repoReady ? Icons.check_circle : Icons.warning_amber_rounded,
                              color: st.repoReady ? NovaTheme.ok : NovaTheme.warn,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                st.repoReady
                                    ? t.t('workflow_status_ok')
                                    : st.hasWorkflowFile
                                        ? t.t('workflow_status_repair')
                                        : t.t('workflow_status_missing'),
                                style: const TextStyle(
                                  color: NovaTheme.text,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SecondaryNeonButton(
                          label: st.hasWorkflowFile ? t.t('repair_workflow') : t.t('install_workflow'),
                          icon: Icons.cloud_upload_outlined,
                          color: st.repoReady ? NovaTheme.neonCyan : NovaTheme.warn,
                          busy: _wfBusy,
                          onPressed: () async {
                            setState(() => _wfBusy = true);
                            try {
                              await st.installOrRepairWorkflow();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(t.t('workflow_installed_ok'))),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${t.t('error')}: $e')),
                                );
                              }
                            } finally {
                              if (mounted) setState(() => _wfBusy = false);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Step 3: Secrets status
                  GlassCard(
                    borderColor: st.secretsReady ? NovaTheme.ok.withOpacity(0.5) : NovaTheme.warn,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(
                              st.secretsReady ? Icons.check_circle : Icons.lock_outline,
                              color: st.secretsReady ? NovaTheme.ok : NovaTheme.warn,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                t.t('security'),
                                style: const TextStyle(
                                  color: NovaTheme.text,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            StatusBadge(
                              label: st.secretsReady ? t.t('ready') : t.t('needs_secrets'),
                              color: st.secretsReady ? NovaTheme.ok : NovaTheme.warn,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SecondaryNeonButton(
                          label: t.t('security'),
                          icon: Icons.vpn_key_outlined,
                          color: st.secretsReady ? NovaTheme.neonCyan : NovaTheme.warn,
                          onPressed: () => Navigator.pushNamed(context, '/security'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  GradientButton(
                    label: t.t('start_windows'),
                    icon: Icons.rocket_launch_rounded,
                    onPressed: (st.repoReady && st.secretsReady)
                        ? () => Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const SessionSetupScreen()),
                            )
                        : null,
                  ),
                ],
              ),
      ),
    );
  }
}
