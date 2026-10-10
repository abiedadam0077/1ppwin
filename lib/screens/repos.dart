import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../services/github_service.dart';
import '../state/app_state.dart';

class RepoSelectorScreen extends StatefulWidget {
  const RepoSelectorScreen({super.key});

  @override
  State<RepoSelectorScreen> createState() => _RepoSelectorScreenState();
}

class _RepoSelectorScreenState extends State<RepoSelectorScreen> {
  String _q = '';
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final st = context.read<AppState>();
    if (st.repos.isEmpty) st.loadRepos();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final list = st.repos.where((r) {
      if (_filter == 'private' && !r.isPrivate) return false;
      if (_filter == 'public' && r.isPrivate) return false;
      return r.fullName.toLowerCase().contains(_q.toLowerCase());
    }).toList();

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('choose_repo'))),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
              child: NeonField(
                label: t.t('search_repo'),
                onChanged: (v) => setState(() => _q = v),
                suffix: const Icon(Icons.search, color: NovaTheme.textDim),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  for (final f in ['all', 'public', 'private'])
                    Padding(
                      padding: const EdgeInsets.only(left: 4, right: 4),
                      child: ChoiceChip(
                        label: Text(f == 'all' ? t.t('all') : t.t(f), style: const TextStyle(fontSize: 12)),
                        selected: _filter == f,
                        selectedColor: NovaTheme.neonBlue,
                        backgroundColor: NovaTheme.card,
                        side: BorderSide(color: NovaTheme.cardBorder),
                        labelStyle: TextStyle(color: _filter == f ? Colors.white : NovaTheme.textDim),
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    tooltip: t.t('new_repo'),
                    icon: const Icon(Icons.add_circle_outline, color: NovaTheme.neonCyan),
                    onPressed: () => _createDialog(context, st),
                  ),
                ],
              ),
            ),
            Expanded(
              child: st.busy
                  ? const Center(child: CircularProgressIndicator(color: NovaTheme.neonBlue))
                  : ListView.separated(
                      padding: const EdgeInsets.all(18),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (c, i) {
                        final r = list[i];
                        final selected = st.selectedRepo?.fullName == r.fullName;
                        return GlassCard(
                          borderColor: selected ? NovaTheme.ok : null,
                          padding: const EdgeInsets.all(14),
                          child: InkWell(
                            onTap: () async {
                              await st.selectRepo(r);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('${r.fullName} ✓')),
                                );
                              }
                            },
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: NovaTheme.bg2,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: NovaTheme.cardBorder),
                                  ),
                                  child: const Icon(Icons.inventory_2, color: NovaTheme.neonBlue, size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(r.name,
                                          style: const TextStyle(color: NovaTheme.text, fontWeight: FontWeight.w700)),
                                      Text(r.description ?? (r.isPrivate ? t.t('private') : t.t('public')),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(color: NovaTheme.textDim, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (r.isPrivate) const Icon(Icons.lock, size: 15, color: NovaTheme.textDim),
                                const SizedBox(width: 8),
                                if (selected)
                                  Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(color: NovaTheme.ok, shape: BoxShape.circle),
                                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                                  )
                                else
                                  Text(t.t('ready'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 11)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _createDialog(BuildContext context, AppState st) {
    final t = L10n.of(context);
    final name = TextEditingController();
    var isPrivate = true;
    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          backgroundColor: NovaTheme.card,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(t.t('new_repo'), style: const TextStyle(color: NovaTheme.text)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              NeonField(label: t.t('repo_name'), controller: name),
              const SizedBox(height: 10),
              NeonSwitch(label: t.t('private'), value: isPrivate, onChanged: (v) => set(() => isPrivate = v)),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: Text('✕', style: const TextStyle(color: NovaTheme.textDim))),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: NovaTheme.neonBlue),
              onPressed: () async {
                final n = name.text.trim();
                if (n.isEmpty) return;
                Navigator.pop(c);
                try {
                  final repo = await st.api!.createRepo(n, isPrivate: isPrivate);
                  await st.loadRepos();
                  await st.selectRepo(repo);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${t.t('error')}: $e')));
                  }
                }
              },
              child: Text(t.t('create')),
            ),
          ],
        ),
      ),
    );
  }
}
