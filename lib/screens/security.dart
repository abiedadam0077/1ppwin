import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/l10n.dart';
import '../core/theme.dart';
import '../core/widgets.dart';
import '../state/app_state.dart';

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

  String _strong() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789!@#\$%&*';
    final r = Random.secure();
    return List.generate(20, (_) => chars[r.nextInt(chars.length)]).join();
  }

  @override
  Widget build(BuildContext context) {
    final t = L10n.of(context);
    final st = context.watch<AppState>();
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(title: Text(t.t('security'))),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.t('security_sub'), style: const TextStyle(color: NovaTheme.textDim, fontSize: 13)),
              const SizedBox(height: 18),
              GlassCard(
                child: Column(
                  children: [
                    NeonField(
                      label: t.t('access_password'),
                      controller: _access,
                      obscure: !_showA,
                      suffix: IconButton(
                        icon: Icon(_showA ? Icons.visibility : Icons.visibility_off, size: 19),
                        color: NovaTheme.textDim,
                        onPressed: () => setState(() => _showA = !_showA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeonField(
                      label: t.t('backup_password'),
                      controller: _backup,
                      obscure: !_showB,
                      suffix: IconButton(
                        icon: Icon(_showB ? Icons.visibility : Icons.visibility_off, size: 19),
                        color: NovaTheme.textDim,
                        onPressed: () => setState(() => _showB = !_showB),
                      ),
                    ),
                    const SizedBox(height: 12),
                    NeonField(label: t.t('tailscale_key'), controller: _ts),
                    const SizedBox(height: 14),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: () => setState(() {
                          final p = _strong();
                          _access.text = p;
                          _backup.text = p;
                        }),
                        icon: const Icon(Icons.vpn_key, size: 17, color: NovaTheme.neonCyan),
                        label: Text(t.t('gen_strong'), style: const TextStyle(color: NovaTheme.neonCyan, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                label: t.t('save_settings'),
                icon: Icons.lock_outline,
                busy: _busy,
                onPressed: (_access.text.isEmpty || _backup.text.isEmpty)
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
                          await st.saveSecrets(
                            access: _access.text,
                            backup: _backup.text,
                            tailscale: _ts.text.isEmpty ? null : _ts.text,
                          );
                          // keep access password in memory for the Ready screen only
                          st.inMemoryAccessPassword = _access.text;
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text(t.t('saved_ok'))));
                            Navigator.pop(context);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(SnackBar(content: Text('${t.t('save_fail')}: $e')));
                          }
                        } finally {
                          if (mounted) setState(() => _busy = false);
                        }
                      },
              ),
              const SizedBox(height: 14),
              if (st.secretsReady)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.check_circle, color: NovaTheme.ok, size: 16),
                    SizedBox(width: 6),
                    Text('Secrets ✓', style: TextStyle(color: NovaTheme.ok, fontSize: 12)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
