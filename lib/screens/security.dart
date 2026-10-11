import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/const.dart';
import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../services/github_service.dart';
import '../state/app_state.dart';
import 'onboarding.dart';

class PermissionsGuideCard extends StatelessWidget {
  final String? errorDetail;
  final VoidCallback? onRetry;

  const PermissionsGuideCard({
    super.key,
    this.errorDetail,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    return GlassCard(
      borderColor: NovaTheme.warn,
      glowColor: NovaTheme.warn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.admin_panel_settings_outlined, color: NovaTheme.warn, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  t.t('permissions_missing_title'),
                  style: const TextStyle(
                    color: NovaTheme.warn,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            t.t('permissions_missing_sub'),
            style: const TextStyle(color: NovaTheme.text, fontSize: 12.5, height: 1.45),
          ),
          if (errorDetail != null && errorDetail!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: NovaTheme.bg.withOpacity(0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: NovaTheme.danger.withOpacity(0.5)),
              ),
              child: Text(
                errorDetail!,
                style: const TextStyle(color: NovaTheme.danger, fontSize: 11.5),
              ),
            ),
          ],
          const SizedBox(height: 10),
          _stepText(t.t('perm_step_1')),
          _stepText(t.t('perm_step_2')),
          _stepText(t.t('perm_step_3')),
          const SizedBox(height: 14),
          SecondaryNeonButton(
            label: t.t('open_installations'),
            icon: Icons.open_in_new,
            color: NovaTheme.warn,
            onPressed: () => launchUrl(
              Uri.parse('https://github.com/settings/installations'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 8),
          SecondaryNeonButton(
            label: t.t('use_pat_instead'),
            icon: Icons.key_rounded,
            color: NovaTheme.neonCyan,
            onPressed: () => showPatSignInDialog(context),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 6),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16, color: NovaTheme.neonBlue),
              label: Text(t.t('retry'), style: const TextStyle(color: NovaTheme.neonBlue, fontSize: 12.5)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepText(String s) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Text(
          s,
          style: const TextStyle(color: NovaTheme.textDim, fontSize: 12, height: 1.4),
        ),
      );
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _access = TextEditingController();
  final _backup = TextEditingController();
  final _ts = TextEditingController();
  bool _busy = false;
  bool _showA = false;
  bool _showB = false;
  bool _showTs = false;
  String? _localError;

  @override
  void dispose() {
    _access.dispose();
    _backup.dispose();
    _ts.dispose();
    super.dispose();
  }

  String _strong() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#\$%&*';
    final r = Random.secure();
    return List.generate(20, (_) => chars[r.nextInt(chars.length)]).join();
  }

  bool _canSave(AppState st) {
    if (st.selectedRepo == null || _busy) return false;
    final hasA = _access.text.trim().isNotEmpty || st.hasAccessSecret;
    final hasB = _backup.text.trim().isNotEmpty || st.hasBackupSecret;
    final anyEntered = _access.text.trim().isNotEmpty ||
        _backup.text.trim().isNotEmpty ||
        _ts.text.trim().isNotEmpty;
    return hasA && hasB && anyEntered;
  }

  Future<void> _save(AppState st, L10n t) async {
    setState(() {
      _busy = true;
      _localError = null;
    });
    try {
      await st.saveSecrets(
        access: _access.text,
        backup: _backup.text,
        tailscale: _ts.text.trim().isEmpty ? null : _ts.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: NovaTheme.cardElevated,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: NovaTheme.ok, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(t.t('saved_ok'))),
            ],
          ),
        ),
      );
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } on GhException catch (e) {
      if (mounted) {
        setState(() => _localError = e.friendlyMessage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.t('save_fail')}: ${e.friendlyMessage}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _localError = '$e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${t.t('save_fail')}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    final repo = st.selectedRepo;

    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.t('security')),
          actions: [
            if (repo != null)
              IconButton(
                tooltip: t.t('refresh'),
                icon: const Icon(Icons.refresh, color: NovaTheme.neonCyan),
                onPressed: st.statusBusy ? null : () => st.refreshSelectedRepoStatus(),
              ),
          ],
        ),
        body: repo == null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: GlassCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.folder_off_outlined, color: NovaTheme.warn, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          t.t('no_repo_selected'),
                          style: const TextStyle(color: NovaTheme.text, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          t.t('no_repo_selected_sub'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: NovaTheme.textDim, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        GradientButton(
                          label: t.t('choose_repo'),
                          icon: Icons.folder_open,
                          onPressed: () => Navigator.pushReplacementNamed(context, '/repos'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (st.secretsPermissionDenied || _localError != null) ...[
                      PermissionsGuideCard(
                        errorDetail: _localError ?? st.secretsError,
                        onRetry: () => st.refreshSelectedRepoStatus(),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Repository context, live secret status, and editor share one form card.
                    GlassCard(
                      padding: const EdgeInsets.all(14),
                      borderColor: st.secretsReady ? NovaTheme.ok.withOpacity(0.55) : NovaTheme.cardBorder,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined, color: NovaTheme.neonCyan, size: 19),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: Text(
                                    repo.fullName,
                                    textAlign: TextAlign.left,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: NovaTheme.text,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              StatusBadge(
                                label: st.secretsReady ? t.t('ready') : t.t('needs_secrets'),
                                color: st.secretsReady ? NovaTheme.ok : NovaTheme.warn,
                                icon: st.secretsReady ? Icons.verified_user : Icons.lock_clock,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            t.t('security_sub'),
                            style: const TextStyle(color: NovaTheme.textDim, fontSize: 12, height: 1.35),
                          ),
                          const Divider(color: NovaTheme.cardBorder, height: 20),
                          _secretStatusRow(
                            Const.secretAccess,
                            st.hasAccessSecret,
                            requiredSecret: true,
                            t: t,
                          ),
                          const SizedBox(height: 5),
                          _secretStatusRow(
                            Const.secretBackup,
                            st.hasBackupSecret,
                            requiredSecret: true,
                            t: t,
                          ),
                          const SizedBox(height: 5),
                          _secretStatusRow(
                            Const.secretTailscale,
                            st.hasTailscaleSecret,
                            requiredSecret: false,
                            t: t,
                          ),
                          const Divider(color: NovaTheme.cardBorder, height: 20),
                          NeonField(
                            label: t.t('access_password'),
                            hint: st.hasAccessSecret ? t.t('keep_existing_hint') : t.t('required_secret_hint'),
                            controller: _access,
                            obscure: !_showA,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.visiblePassword,
                            prefixIcon: Icons.lock_person_outlined,
                            onChanged: (_) => setState(() {}),
                            suffix: IconButton(
                              icon: Icon(_showA ? Icons.visibility : Icons.visibility_off, size: 19),
                              color: NovaTheme.textDim,
                              onPressed: () => setState(() => _showA = !_showA),
                            ),
                          ),
                          const SizedBox(height: 12),
                          NeonField(
                            label: t.t('backup_password'),
                            hint: st.hasBackupSecret ? t.t('keep_existing_hint') : t.t('required_secret_hint'),
                            controller: _backup,
                            obscure: !_showB,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.visiblePassword,
                            prefixIcon: Icons.enhanced_encryption_outlined,
                            onChanged: (_) => setState(() {}),
                            suffix: IconButton(
                              icon: Icon(_showB ? Icons.visibility : Icons.visibility_off, size: 19),
                              color: NovaTheme.textDim,
                              onPressed: () => setState(() => _showB = !_showB),
                            ),
                          ),
                          const SizedBox(height: 12),
                          NeonField(
                            label: t.t('tailscale_key'),
                            hint: 'tskey-auth-...',
                            controller: _ts,
                            obscure: !_showTs,
                            textDirection: TextDirection.ltr,
                            keyboardType: TextInputType.visiblePassword,
                            prefixIcon: Icons.router_outlined,
                            onChanged: (_) => setState(() {}),
                            suffix: IconButton(
                              icon: Icon(_showTs ? Icons.visibility : Icons.visibility_off, size: 19),
                              color: NovaTheme.textDim,
                              onPressed: () => setState(() => _showTs = !_showTs),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              TextButton.icon(
                                onPressed: () => setState(() {
                                  final p = _strong();
                                  _access.text = p;
                                  _backup.text = p;
                                  _showA = true;
                                  _showB = true;
                                }),
                                icon: const Icon(Icons.auto_fix_high, size: 17, color: NovaTheme.neonCyan),
                                label: Text(
                                  t.t('gen_strong'),
                                  style: const TextStyle(
                                    color: NovaTheme.neonCyan,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (_access.text.isNotEmpty || _backup.text.isNotEmpty)
                                TextButton.icon(
                                  onPressed: () {
                                    final buf = StringBuffer();
                                    if (_access.text.isNotEmpty) {
                                      buf.writeln('ACCESS_PASSWORD=${_access.text}');
                                    }
                                    if (_backup.text.isNotEmpty) {
                                      buf.writeln('BACKUP_PASSWORD=${_backup.text}');
                                    }
                                    Clipboard.setData(ClipboardData(text: buf.toString()));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(t.t('passwords_copied'))),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 16, color: NovaTheme.textDim),
                                  label: Text(
                                    t.t('copy_passwords'),
                                    style: const TextStyle(color: NovaTheme.textDim, fontSize: 12.5),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GradientButton(
                      label: t.t('save_settings'),
                      icon: Icons.cloud_upload_rounded,
                      busy: _busy,
                      onPressed: _canSave(st) ? () => _save(st, t) : null,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _secretStatusRow(
    String name,
    bool present, {
    required bool requiredSecret,
    required L10n t,
  }) {
    final color = present
        ? NovaTheme.ok
        : requiredSecret
            ? NovaTheme.warn
            : NovaTheme.textDim;
    final label = present
        ? t.t('secret_present')
        : requiredSecret
            ? t.t('secret_missing')
            : t.t('secret_optional');

    return Row(
      children: [
        Icon(
          present
              ? Icons.check_circle
              : requiredSecret
                  ? Icons.error_outline
                  : Icons.radio_button_unchecked,
          color: color,
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Text(
              name,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: NovaTheme.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        StatusBadge(label: label, color: color),
      ],
    );
  }
}
