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
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateRepoScreen())),
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

  Widget _buildErrorState(L10n t, AppState st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: NovaErrorState(
            icon: Icons.cloud_off_rounded,
            title: t.t('repos_load_failed'),
            subtitle: st.reposError ?? '',
            subtitleDirection: TextDirection.ltr,
            action: SecondaryNeonButton(
              label: t.t('retry'),
              icon: Icons.refresh,
              onPressed: () => st.loadRepos(),
            ),
          ),
        ),
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
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CreateRepoScreen())),
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
              IconButton(
                tooltip: t.t('repo_details'),
                icon: const Icon(Icons.info_outline_rounded, color: NovaTheme.textDim, size: 20),
                onPressed: () => _showRepoDetails(context, st, t, r),
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
                      onPressed: _installingRepo == r.fullName
                          ? null
                          : () => _confirmWorkflowSetup(context, st, t, r),
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

  Future<void> _confirmWorkflowSetup(BuildContext context, AppState st, L10n t, Repo repo) async {
    if (_installingRepo == repo.fullName) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.account_tree_outlined, color: NovaTheme.warn),
        title: Text(t.t('workflow_confirm_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.t('workflow_confirm_body')),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                repo.fullName,
                textAlign: TextAlign.left,
                style: const TextStyle(color: NovaTheme.neonCyan, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.t('cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(t.t('workflow_confirm_action')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !context.mounted) return;

    setState(() => _installingRepo = repo.fullName);
    try {
      await st.selectRepo(repo, silentLog: true);
      await st.installOrRepairWorkflow(target: repo);
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
  }

  void _showRepoDetails(BuildContext context, AppState st, L10n t, Repo repo) {
    final selected = st.selectedRepo?.fullName == repo.fullName;
    final readiness = st.repoReadiness[repo.fullName];
    final hasWorkflow = selected ? st.hasWorkflowFile : (readiness?.hasWorkflow ?? false);
    final needsRepair = selected ? st.workflowNeedsRepair : (readiness?.workflowNeedsRepair ?? false);
    final hasSecrets = selected ? st.secretsReady : (readiness?.hasRequiredSecrets ?? false);
    final ready = hasWorkflow && !needsRepair && hasSecrets;
    final checking = readiness?.checking == true;
    final readinessLabel = checking
        ? t.t('checking')
        : ready
            ? t.t('ready')
            : needsRepair
                ? t.t('needs_repair')
                : !hasWorkflow
                    ? t.t('not_ready')
                    : t.t('needs_secrets');

    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: NovaTheme.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(NovaTheme.radiusAurora)),
            border: Border.all(color: NovaTheme.cardBorder),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 34,
                    height: 4,
                    decoration: BoxDecoration(color: NovaTheme.textMuted, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.folder_copy_outlined, color: NovaTheme.neonCyan),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        t.t('repo_details'),
                        style: const TextStyle(color: NovaTheme.text, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                    ),
                    if (selected)
                      StatusBadge(label: t.t('selected_badge'), color: NovaTheme.neonCyan, icon: Icons.check),
                  ],
                ),
                const SizedBox(height: 14),
                _repoDetailRow(t.t('repo'), repo.fullName, ltr: true),
                _repoDetailRow(t.t('repo_visibility_label'), t.t(repo.isPrivate ? 'private' : 'public')),
                _repoDetailRow(t.t('default_branch'), repo.defaultBranch, ltr: true),
                if (repo.description?.trim().isNotEmpty == true)
                  _repoDetailRow(t.t('repo_description'), repo.description!.trim()),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusBadge(
                      label: readinessLabel,
                      color: checking ? NovaTheme.neonBlue : (ready ? NovaTheme.ok : NovaTheme.warn),
                      icon: checking
                          ? Icons.sync_rounded
                          : ready
                              ? Icons.check_circle_outline
                              : Icons.pending_outlined,
                      pulsing: checking,
                    ),
                    if (hasWorkflow) StatusBadge(label: t.t('workflow_installed'), color: NovaTheme.neonCyan),
                    if (!hasSecrets && hasWorkflow)
                      StatusBadge(label: t.t('needs_secrets'), color: NovaTheme.warn, icon: Icons.lock_outline),
                  ],
                ),
                const SizedBox(height: 16),
                if (!selected)
                  FilledButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await st.selectRepo(repo);
                      if (!context.mounted) return;
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check_circle_outline),
                    label: Text(t.t('choose_repo')),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    if (!selected) await st.selectRepo(repo, silentLog: true);
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RepoSetupScreen()),
                    );
                  },
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(t.t('setup_repo_title')),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(t.t('cancel')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _repoDetailRow(String label, String value, {bool ltr = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: NovaTheme.textDim, fontSize: 13))),
            const SizedBox(width: 12),
            Expanded(
              child: Directionality(
                textDirection: ltr ? TextDirection.ltr : Directionality.of(context),
                child: SelectableText(
                  value,
                  textAlign: ltr ? TextAlign.left : TextAlign.end,
                  maxLines: 2,
                  style: const TextStyle(color: NovaTheme.text, fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      );
}

/// Dedicated, compact form for creating and optionally configuring a repository.
class CreateRepoScreen extends StatefulWidget {
  const CreateRepoScreen({super.key});

  @override
  State<CreateRepoScreen> createState() => _CreateRepoScreenState();
}

class _CreateRepoScreenState extends State<CreateRepoScreen> {
  final TextEditingController _name = TextEditingController();
  bool _isPrivate = true;
  bool _autoWorkflow = true;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _createRepository() async {
    final t = L10n.of(context);
    final st = context.read<AppState>();
    final name = _name.text.trim();
    if (name.isEmpty || _busy) return;

    setState(() => _busy = true);
    try {
      await st.createAndSetupRepo(
        name,
        isPrivate: _isPrivate,
        installWorkflow: _autoWorkflow,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const RepoSetupScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${t.t('error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmCreateRepository() async {
    final t = L10n.of(context);
    final name = _name.text.trim();
    if (name.isEmpty || _busy) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.create_new_folder_outlined, color: NovaTheme.neonCyan),
        title: Text(t.t('create_repo_confirm_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.t('create_repo_confirm_body')),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: NovaTheme.bg2,
                borderRadius: BorderRadius.circular(NovaTheme.radiusMedium),
                border: Border.all(color: NovaTheme.cardBorder),
              ),
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: SelectableText(
                  name,
                  textAlign: TextAlign.left,
                  style: const TextStyle(color: NovaTheme.text, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                StatusBadge(
                  label: t.t(_isPrivate ? 'private' : 'public'),
                  color: _isPrivate ? NovaTheme.neonPurpleSoft : NovaTheme.neonCyan,
                ),
                if (_autoWorkflow)
                  StatusBadge(label: t.t('workflow_will_install'), color: NovaTheme.ok),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.t('cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.check_rounded),
            label: Text(t.t('create_repo_confirm_action')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _createRepository();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('new_repo'))),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Center(
              child: Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: NovaTheme.purpleGradient,
                  boxShadow: [
                    BoxShadow(color: NovaTheme.neonBlue.withOpacity(0.28), blurRadius: 22),
                    BoxShadow(color: NovaTheme.neonPurple.withOpacity(0.16), blurRadius: 30),
                  ],
                ),
                child: const Icon(Icons.create_new_folder_rounded, color: Colors.white, size: 34),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              t.t('create_repo_sub'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: NovaTheme.textDim, fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: 18),
            GlassCard(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  NeonField(
                    label: t.t('repo_name'),
                    controller: _name,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    prefixIcon: Icons.folder_outlined,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 10),
                  NeonSwitch(
                    label: t.t('private'),
                    sub: t.t('repo_visibility_hint'),
                    icon: Icons.lock_outline_rounded,
                    value: _isPrivate,
                    onChanged: (value) => setState(() => _isPrivate = value),
                  ),
                  const Divider(color: NovaTheme.cardBorder, height: 18),
                  NeonSwitch(
                    label: t.t('auto_setup_workflow'),
                    sub: t.t('auto_workflow_hint'),
                    icon: Icons.account_tree_outlined,
                    value: _autoWorkflow,
                    onChanged: (value) => setState(() => _autoWorkflow = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            GradientButton(
              label: t.t('create'),
              icon: Icons.check_rounded,
              busy: _busy,
              onPressed: _name.text.trim().isNotEmpty && !_busy ? _confirmCreateRepository : null,
            ),
            const SizedBox(height: 6),
            TextButton(
              onPressed: _busy ? null : () => Navigator.of(context).maybePop(),
              child: Text(t.t('cancel'), style: const TextStyle(color: NovaTheme.textDim)),
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
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: NovaEmptyState(
                    icon: Icons.folder_off_outlined,
                    title: t.t('no_repo_selected'),
                    subtitle: t.t('no_repo_selected_sub'),
                    color: NovaTheme.warn,
                    action: GradientButton(
                      label: t.t('choose_repo'),
                      icon: Icons.folder_open_rounded,
                      onPressed: () {
                        st.setTab(1);
                        Navigator.of(context).maybePop();
                      },
                    ),
                  ),
                ),
              )
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
                          onPressed: _wfBusy ? null : () => _confirmAndInstallWorkflow(context, st, t),
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

  Future<void> _confirmAndInstallWorkflow(BuildContext context, AppState st, L10n t) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.account_tree_outlined, color: NovaTheme.warn),
        title: Text(t.t('workflow_confirm_title')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t.t('workflow_confirm_body')),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.ltr,
              child: SelectableText(
                st.selectedRepo?.fullName ?? '',
                textAlign: TextAlign.left,
                style: const TextStyle(color: NovaTheme.neonCyan, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(t.t('cancel')),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.cloud_upload_outlined),
            label: Text(t.t('workflow_confirm_action')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || !context.mounted) return;

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
  }

}
