import 'package:flutter/material.dart';

import 'theme.dart';

/// Light, softly elevated surface used across the NOVA screens.
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
    this.radius = 18,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor ?? NovaTheme.cardBorder;
    final effectiveGlow = glowColor ?? NovaTheme.neonBlue;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: NovaTheme.cardGradient,
        border: Border.all(color: effectiveBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142644).withOpacity(0.055),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
          if (glowColor != null)
            BoxShadow(
              color: effectiveGlow.withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 4),
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

    return content;
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.22), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulsing)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.7, color: color),
            )
          else if (icon != null)
            Icon(icon, color: color, size: 12)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
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
        color: enabled ? null : NovaTheme.bg3,
        border: enabled ? null : Border.all(color: NovaTheme.cardBorder),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: NovaTheme.neonBlue.withOpacity(0.18),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
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
  final bool stars;

  const GlowBackground({super.key, required this.child, this.stars = false});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFF8F9FC),
                Color(0xFFF0F2F7),
                Color(0xFFF7F8FB),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SizedBox.expand(),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(painter: _NovaAuroraPainter(stars: stars)),
          ),
        ),
        Positioned(
          top: -150,
          left: -140,
          child: _glow(NovaTheme.neonPurple, 330),
        ),
        Positioned(
          top: 110,
          right: -180,
          child: _glow(NovaTheme.neonBlue, 320),
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
              colors: [c.withOpacity(0.055), c.withOpacity(0.0)],
            ),
          ),
        ),
      );
}

class _NovaAuroraPainter extends CustomPainter {
  final bool stars;

  const _NovaAuroraPainter({this.stars = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (stars) {
      for (var i = 0; i < 50; i++) {
        final x = ((i * 47 + 13) % 101) / 101 * size.width;
        final y = ((i * 29 + 7) % 100) / 100 * size.height * 0.66;
        final radius = i % 7 == 0 ? 1.05 : 0.55;
        final opacity = i % 4 == 0 ? 0.62 : 0.30;
        canvas.drawCircle(
          Offset(x, y),
          radius,
          Paint()..color = const Color(0xFFC9D9FF).withOpacity(opacity),
        );
      }
    }

    const colors = [
      Color(0x193E8EFF),
      Color(0x1635B8F5),
      Color(0x127B62FF),
    ];
    for (var i = 0; i < colors.length; i++) {
      final baseY = size.height * (0.79 + i * 0.045);
      final path = Path()
        ..moveTo(-size.width * 0.08, baseY)
        ..cubicTo(
          size.width * 0.16,
          baseY - size.height * 0.16,
          size.width * 0.28,
          baseY + size.height * 0.10,
          size.width * 0.48,
          baseY - size.height * 0.015,
        )
        ..cubicTo(
          size.width * 0.68,
          baseY - size.height * 0.14,
          size.width * 0.81,
          baseY + size.height * 0.11,
          size.width * 1.08,
          baseY - size.height * 0.045,
        );
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = i == 1 ? 1.5 : 1.0
          ..strokeCap = StrokeCap.round
          ..color = colors[i],
      );
    }

    final bloom = Path()
      ..moveTo(-size.width * 0.06, size.height * 0.88)
      ..cubicTo(
        size.width * 0.20,
        size.height * 0.75,
        size.width * 0.31,
        size.height * 0.94,
        size.width * 0.50,
        size.height * 0.86,
      )
      ..cubicTo(
        size.width * 0.69,
        size.height * 0.76,
        size.width * 0.85,
        size.height * 0.95,
        size.width * 1.06,
        size.height * 0.82,
      );
    canvas.drawPath(
      bloom,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..color = NovaTheme.neonBlue.withOpacity(0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
  }

  @override
  bool shouldRepaint(covariant _NovaAuroraPainter oldDelegate) => stars != oldDelegate.stars;
}

class WindowsMark extends StatelessWidget {
  final double size;

  const WindowsMark({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    const colors = [
      Color(0xFF8FE6FF),
      Color(0xFF36C7FF),
      Color(0xFF32A9FF),
      Color(0xFF286EFF),
    ];
    return SizedBox(
      width: size,
      height: size,
      child: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: size * 0.07,
        crossAxisSpacing: size * 0.07,
        children: [
          for (var i = 0; i < colors.length; i++)
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors[i],
                borderRadius: BorderRadius.circular(size * 0.035),
                boxShadow: [
                  BoxShadow(color: colors[i].withOpacity(0.3), blurRadius: size * 0.1),
                ],
              ),
            ),
        ],
      ),
    );
  }
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
                  color: NovaTheme.text,
                  fontSize: compact ? 15 : 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: compact ? 2.1 : 3.2,
                  height: 1.05,
                ),
              ),
              Text(
                'Windows Cloud',
                style: TextStyle(
                  color: NovaTheme.neonBlue,
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
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      decoration: BoxDecoration(
        color: NovaTheme.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NovaTheme.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140E2344),
            blurRadius: 16,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var index = 0; index < items.length; index++)
                  Expanded(child: _item(items[index], index)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _item(NovaNavigationItem item, int index) {
    final selected = selectedIndex == index;
    return Semantics(
      button: true,
      selected: selected,
      label: item.label.replaceAll('\n', ' '),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => onSelected(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: selected ? NovaTheme.neonPurple.withOpacity(0.08) : Colors.transparent,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 34,
                    height: 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(9),
                      color: selected ? NovaTheme.neonPurple.withOpacity(0.12) : Colors.transparent,
                    ),
                    child: Icon(
                      selected ? item.selectedIcon : item.icon,
                      size: selected ? 19 : 18,
                      color: selected ? NovaTheme.neonPurple : NovaTheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected ? NovaTheme.neonPurple : NovaTheme.textDim,
                      fontSize: 8.5,
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
