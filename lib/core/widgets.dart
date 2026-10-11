import 'dart:ui';

import 'package:flutter/material.dart';

import 'theme.dart';

/// Frosted dark Glassmorphism card with luminous neon border.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;
  final Color? glowColor;
  final double radius;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
    this.glowColor,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor ?? NovaTheme.cardBorder;
    final effectiveGlow = glowColor ?? NovaTheme.neonBlue;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: NovaTheme.cardGradient,
        border: Border.all(
          color: effectiveBorder,
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: effectiveGlow.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: content,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: content,
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool pulsing;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.pulsing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.65), width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.22),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulsing)
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.8, color: color),
            )
          else if (icon != null)
            Icon(icon, color: color, size: 14)
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final Gradient? gradient;
  final double height;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.busy = false,
    this.gradient,
    this.height = 56,
  });

  @override
  Widget build(BuildContext context) {
    final IconData? ic = icon;
    final enabled = onPressed != null && !busy;
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: enabled ? (gradient ?? NovaTheme.btnGradient) : null,
        color: enabled ? null : NovaTheme.cardElevated.withOpacity(0.65),
        border: enabled ? null : Border.all(color: NovaTheme.cardBorder.withOpacity(0.4)),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: NovaTheme.neonBlue.withOpacity(0.42),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: NovaTheme.neonPurple.withOpacity(0.25),
                  blurRadius: 24,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: enabled ? onPressed : null,
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
                    Icon(ic, color: enabled ? Colors.white : NovaTheme.textMuted, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: height >= 54 ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: enabled ? Colors.white : NovaTheme.textMuted,
                        fontSize: 14,
                        height: 1.04,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class SecondaryNeonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color color;
  final bool busy;

  const SecondaryNeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color = NovaTheme.neonCyan,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: color.withOpacity(0.08),
          side: BorderSide(color: color.withOpacity(0.65), width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 14),
        ),
        onPressed: busy ? null : onPressed,
        child: busy
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: color, size: 18),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontSize: 12.5,
                        height: 1.05,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class QuickShortcutTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const QuickShortcutTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.color = NovaTheme.neonBlue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      borderColor: color.withOpacity(0.38),
      glowColor: color,
      radius: 16,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.16),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: color.withOpacity(0.45)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NovaTheme.text,
                    fontSize: 12,
                    height: 1.08,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NovaTheme.textDim,
                      fontSize: 10.5,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, size: 13, color: color.withOpacity(0.8)),
        ],
      ),
    );
  }
}

class NeonField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final bool obscure;
  final ValueChanged<String>? onChanged;
  final Widget? suffix;
  final IconData? prefixIcon;
  final TextDirection? textDirection;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const NeonField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.obscure = false,
    this.onChanged,
    this.suffix,
    this.prefixIcon,
    this.textDirection,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: NovaTheme.bg2.withOpacity(0.85),
        border: Border.all(color: NovaTheme.cardBorder, width: 1.1),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        onChanged: onChanged,
        textDirection: textDirection,
        textAlign: TextAlign.start,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        style: const TextStyle(color: NovaTheme.text, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: NovaTheme.textDim, fontSize: 12.5),
          hintStyle: const TextStyle(color: NovaTheme.textMuted, fontSize: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: NovaTheme.neonBlue, size: 19) : null,
          suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
  final IconData? icon;

  const NeonSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.sub,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: value ? NovaTheme.neonCyan : NovaTheme.textDim, size: 20),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: NovaTheme.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: const TextStyle(color: NovaTheme.textDim, fontSize: 11.5),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: NovaTheme.neonPurpleSoft,
            activeTrackColor: NovaTheme.neonPurple.withOpacity(0.5),
            onChanged: onChanged,
          ),
        ],
      ),
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF040818),
                Color(0xFF07102A),
                Color(0xFF050A1E),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned(
          top: -110,
          left: -70,
          child: _glow(NovaTheme.neonPurple, 340),
        ),
        Positioned(
          top: 140,
          right: -120,
          child: _glow(NovaTheme.neonBlue, 300),
        ),
        Positioned(
          bottom: -130,
          left: -60,
          child: _glow(NovaTheme.neonBlue, 360),
        ),
        SafeArea(child: child),
      ],
    );
  }

  Widget _glow(Color c, double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [c.withOpacity(0.28), c.withOpacity(0.0)],
            ),
          ),
        ),
      );
}

/// Compact wordmark used in the dashboard and the launch screen.
class NovaBrandLockup extends StatelessWidget {
  final bool compact;
  final double logoSize;

  const NovaBrandLockup({super.key, this.compact = false, this.logoSize = 46});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        WindowsCloudLogo(size: logoSize),
        SizedBox(width: compact ? 5 : 9),
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NOVA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 15 : 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compact ? 2.1 : 3.2,
                  height: 1.05,
                ),
              ),
              Text(
                'Windows Cloud',
                style: TextStyle(
                  color: NovaTheme.neonCyan,
                  fontSize: compact ? 9.5 : 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: compact ? 0.2 : 0.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class NovaNavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const NovaNavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Five-slot navigation bar sized specifically for compact Arabic layouts.
class NovaBottomNavigationBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final List<NovaNavigationItem> items;

  const NovaBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onSelected,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xF20D1833), Color(0xFF070D20)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(top: BorderSide(color: NovaTheme.cardBorder.withOpacity(0.85))),
        boxShadow: [
          BoxShadow(
            color: NovaTheme.neonPurple.withOpacity(0.16),
            blurRadius: 22,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var index = 0; index < items.length; index++)
                Expanded(child: _item(items[index], index)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(NovaNavigationItem item, int index) {
    final selected = selectedIndex == index;
    final accent = NovaTheme.neonPurpleSoft;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label.replaceAll('\n', ' '),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: selected
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          accent.withOpacity(0.22),
                          NovaTheme.neonPurple.withOpacity(0.08),
                        ],
                      )
                    : null,
                border: Border.all(
                  color: selected ? accent.withOpacity(0.5) : Colors.transparent,
                ),
                boxShadow: selected
                    ? [BoxShadow(color: NovaTheme.neonPurple.withOpacity(0.16), blurRadius: 12)]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 35,
                    height: 25,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: selected ? accent.withOpacity(0.2) : Colors.transparent,
                    ),
                    child: Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: selected ? 20 : 19,
                      color: selected ? Colors.white : NovaTheme.textDim,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? Colors.white : NovaTheme.textDim,
                      fontSize: 9,
                      height: 1.02,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NovaLoadingState extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const NovaLoadingState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.cloud_sync_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 58,
                height: 58,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const SizedBox.expand(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.3,
                        color: NovaTheme.neonBlue,
                      ),
                    ),
                    Icon(icon, color: NovaTheme.neonCyan, size: 25),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NovaTheme.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NovaTheme.textDim,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NovaEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget? action;

  const NovaEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.color = NovaTheme.neonCyan,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 27),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: NovaTheme.text,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: NovaTheme.textDim, fontSize: 12.5, height: 1.45),
          ),
          if (action != null) ...[
            const SizedBox(height: 16),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Signature NOVA Windows Cloud emblem: Windows 11 4-pane logo inside a glowing cloud.
class WindowsCloudLogo extends StatelessWidget {
  final double size;
  const WindowsCloudLogo({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.78,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Build a smooth, authentic cloud silhouette path
    final cloud = Path();
    final baseBottom = h * 0.84;
    final baseLeft = w * 0.16;
    final baseRight = w * 0.84;

    cloud.moveTo(baseLeft + w * 0.06, baseBottom);
    cloud.lineTo(baseRight - w * 0.04, baseBottom);
    // Right lobe
    cloud.cubicTo(
      w * 0.94, baseBottom,
      w * 0.96, h * 0.54,
      w * 0.80, h * 0.50,
    );
    // Upper-right dome
    cloud.cubicTo(
      w * 0.78, h * 0.24,
      w * 0.56, h * 0.14,
      w * 0.44, h * 0.28,
    );
    // Upper-left lobe
    cloud.cubicTo(
      w * 0.33, h * 0.20,
      w * 0.19, h * 0.30,
      w * 0.21, h * 0.48,
    );
    // Left lobe back to base
    cloud.cubicTo(
      w * 0.05, h * 0.50,
      w * 0.06, baseBottom,
      baseLeft + w * 0.06, baseBottom,
    );
    cloud.close();

    // Ambient outer glow
    canvas.drawPath(
      cloud,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.055
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20)
        ..shader = const LinearGradient(
          colors: [NovaTheme.neonCyan, NovaTheme.neonBlue, NovaTheme.neonPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );

    // Subtle frosted interior fill
    canvas.drawPath(
      cloud,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = LinearGradient(
          colors: [
            NovaTheme.neonBlue.withOpacity(0.18),
            NovaTheme.neonPurple.withOpacity(0.12),
            NovaTheme.card.withOpacity(0.55),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Offset.zero & size),
    );

    // Crisp neon cloud border
    canvas.drawPath(
      cloud,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..shader = const LinearGradient(
          colors: [NovaTheme.neonCyan, NovaTheme.neonBlue, NovaTheme.neonPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(Offset.zero & size),
    );

    // Windows 11 four glowing panes centered inside the cloud
    final paneSize = w * 0.115;
    final gap = w * 0.022;
    final totalGrid = paneSize * 2 + gap;
    final startX = (w - totalGrid) / 2;
    final startY = h * 0.43;

    final paneGlow = Paint()
      ..color = NovaTheme.neonCyan.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final paneFill = Paint()
      ..shader = LinearGradient(
        colors: const [Color(0xFF40C4FF), NovaTheme.neonBlue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(startX, startY, totalGrid, totalGrid));

    final r = Radius.circular(w * 0.02);
    final rects = [
      RRect.fromRectAndRadius(Rect.fromLTWH(startX, startY, paneSize, paneSize), r),
      RRect.fromRectAndRadius(Rect.fromLTWH(startX + paneSize + gap, startY, paneSize, paneSize), r),
      RRect.fromRectAndRadius(Rect.fromLTWH(startX, startY + paneSize + gap, paneSize, paneSize), r),
      RRect.fromRectAndRadius(Rect.fromLTWH(startX + paneSize + gap, startY + paneSize + gap, paneSize, paneSize), r),
    ];

    for (final rect in rects) {
      canvas.drawRRect(rect, paneGlow);
      canvas.drawRRect(rect, paneFill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
