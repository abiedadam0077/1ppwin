import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared visual language for every NOVA screen.
///
/// Cairo is bundled locally so Arabic typography is available immediately on
/// first launch and does not depend on a network font request.
class NovaTheme {
  static const Color bg = Color(0xFF05091B);
  static const Color bg2 = Color(0xFF09152E);
  static const Color bg3 = Color(0xFF102044);
  static const Color card = Color(0xFF0B1630);
  static const Color cardElevated = Color(0xFF12234A);
  static const Color cardBorder = Color(0x553B78E8);
  static const Color cardBorderBright = Color(0xAA4D8BFF);
  static const Color neonBlue = Color(0xFF3478FF);
  static const Color neonPurple = Color(0xFF8057FF);
  static const Color neonPurpleSoft = Color(0xFFA48BFF);
  static const Color neonCyan = Color(0xFF42D9FF);
  static const Color ok = Color(0xFF36D99A);
  static const Color warn = Color(0xFFFFC857);
  static const Color danger = Color(0xFFFF667A);
  static const Color text = Color(0xFFF1F5FF);
  static const Color textDim = Color(0xFFB2C0DD);
  static const Color textMuted = Color(0xFF7789AE);

  static const String fontFamilyName = 'Cairo';

  static const LinearGradient btnGradient = LinearGradient(
    colors: [Color(0xFF3183FF), Color(0xFF685BFF)],
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8A5CFF), Color(0xFF526BFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xF20D1A38), Color(0xE609142B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static TextStyle fontFamily(TextStyle? style) =>
      (style ?? const TextStyle()).copyWith(fontFamily: fontFamilyName);

  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = base.textTheme.apply(
      fontFamily: fontFamilyName,
      bodyColor: text,
      displayColor: text,
    );

    return base.copyWith(
      fontFamily: fontFamilyName,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: neonBlue,
        secondary: neonPurple,
        tertiary: neonCyan,
        surface: card,
        error: danger,
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 60,
        titleSpacing: 12,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        iconTheme: const IconThemeData(color: text, size: 22),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamilyName,
          color: text,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        indicatorColor: neonPurple.withOpacity(0.32),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: neonPurple, width: 1.2),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white, size: 22);
          }
          return const IconThemeData(color: textDim, size: 21);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontFamily: fontFamilyName,
            color: states.contains(WidgetState.selected) ? Colors.white : textDim,
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardElevated,
        contentTextStyle: const TextStyle(
          fontFamily: fontFamilyName,
          color: text,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: cardBorder),
        ),
        titleTextStyle: const TextStyle(
          fontFamily: fontFamilyName,
          color: text,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
        contentTextStyle: const TextStyle(
          fontFamily: fontFamilyName,
          color: textDim,
          fontSize: 13,
          height: 1.5,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: cardBorder,
        thickness: 1,
        space: 1,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) =>
            states.contains(WidgetState.selected) ? Colors.white : textDim),
        trackColor: WidgetStateProperty.resolveWith((states) => states.contains(WidgetState.selected)
            ? neonPurple.withOpacity(0.62)
            : cardElevated),
        trackOutlineColor: WidgetStateProperty.all(cardBorder),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: neonBlue,
        inactiveTrackColor: cardElevated,
        thumbColor: Colors.white,
        overlayColor: neonBlue.withOpacity(0.16),
        valueIndicatorColor: neonPurple,
      ),
    );
  }
}
