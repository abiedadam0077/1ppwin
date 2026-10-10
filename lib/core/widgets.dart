import 'dart:ui';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Frosted dark card with soft neon border (matches the design reference).
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final double radius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: padding ?? const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              colors: [
                NovaTheme.card.withOpacity(0.92),
                NovaTheme.bg2.withOpacity(0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: borderColor ?? NovaTheme.cardBorder,
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: NovaTheme.neonBlue.withOpacity(0.12),
                blurRadius: 22,
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final IconData? ic = icon;
    return Container(
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: onPressed == null ? null : NovaTheme.btnGradient,
        color: onPressed == null ? NovaTheme.card : null,
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: NovaTheme.neonBlue.withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (ic != null) ...[
                    Icon(ic, color: Colors.white, size: 21),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class NeonField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;

  const NeonField({
    super.key,
    this.controller,
    required this.label,
    this.obscure = false,
    this.onChanged,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: NovaTheme.bg2.withOpacity(0.8),
        border: Border.all(color: NovaTheme.cardBorder, width: 1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        style: const TextStyle(color: NovaTheme.text),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: NovaTheme.textDim, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        ),
      ),
    );
  }
}

class NeonSwitch extends StatelessWidget {
  final String label;
  final String? sub;
  final bool value;
  final ValueChanged<bool> onChanged;

  const NeonSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: NovaTheme.text, fontSize: 14, fontWeight: FontWeight.w600)),
              if (sub != null)
                Text(sub!, style: const TextStyle(color: NovaTheme.textDim, fontSize: 12)),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          activeColor: NovaTheme.neonBlue,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class GlowBackground extends StatelessWidget {
  final Widget child;
  const GlowBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(color: NovaTheme.bg),
          child: SizedBox.expand(),
        ),
        Positioned(
          top: -120,
          left: -80,
          child: _glow(NovaTheme.neonPurple, 340),
        ),
        Positioned(
          bottom: -140,
          right: -90,
          child: _glow(NovaTheme.neonBlue, 380),
        ),
        SafeArea(child: child),
      ],
    );
  }

  Widget _glow(Color c, double size) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [c.withOpacity(0.32), c.withOpacity(0.0)],
          ),
        ),
      );
}

class WindowsCloudLogo extends StatelessWidget {
  final double size;
  const WindowsCloudLogo({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final glow = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    // Cloud outline
    final cloud = Path()
      ..addRRect(RRect.fromLTRBR(w * 0.08, h * 0.30, w * 0.92, h * 0.78, const Radius.circular(40)));
    canvas.drawPath(
      cloud,
      glow..style = PaintingStyle.stroke..strokeWidth = 5..color = NovaTheme.neonPurple.withOpacity(0.7),
    );
    canvas.drawPath(
      cloud,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..shader = const LinearGradient(colors: [NovaTheme.neonBlue, NovaTheme.neonPurple])
            .createShader(Offset.zero & size),
    );

    // Windows flag (four glowing panes)
    final pane = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF4FC3F7), NovaTheme.neonBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;
    final gap = w * 0.03;
    final pw = w * 0.20;
    final left = w * 0.30;
    final top = h * 0.40;
    canvas.drawRRect(RRect.fromLTRBR(left, top, left + pw, top + pw, const Radius.circular(4)), pane);
    canvas.drawRRect(RRect.fromLTRBR(left + pw + gap, top, left + 2 * pw + gap, top + pw, const Radius.circular(4)), pane);
    canvas.drawRRect(RRect.fromLTRBR(left, top + pw + gap, left + pw, top + 2 * pw + gap, const Radius.circular(4)), pane);
    canvas.drawRRect(
        RRect.fromLTRBR(left + pw + gap, top + pw + gap, left + 2 * pw + gap, top + 2 * pw + gap, const Radius.circular(4)),
        pane);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
