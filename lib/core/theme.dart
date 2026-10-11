import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared light NOVA visual language, based on the selected Windows Cloud concept.
/// Cairo is bundled locally so Arabic typography is available on first launch.
class NovaTheme {
  static const Color bg = Color(0xFFF4F5F9);
  static const Color bg2 = Color(0xFFF0F2F6);
  static const Color bg3 = Color(0xFFE5E9F1);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardElevated = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFE2E6EE);
  static const Color cardBorderBright = Color(0xFFBBC9E2);
  static const Color neonBlue = Color(0xFF2D78E8);
  static const Color neonPurple = Color(0xFF7652E9);
  static const Color neonPurpleSoft = Color(0xFF815FEA);
  static const Color neonCyan = Color(0xFF187F9F);
  static const Color ok = Color(0xFF16845D);
  static const Color warn = Color(0xFFAA6B08);
  static const Color danger = Color(0xFFC64458);
  static const Color text = Color(0xFF1A2232);
  static const Color textDim = Color(0xFF596579);
  static const Color textMuted = Color(0xFF8590A2);

  static const String fontFamilyName = 'Cairo';

  static const LinearGradient btnGradient = LinearGradient(
    colors: [Color(0xFF347FF0), Color(0xFF526FE7)],
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF845FEA), Color(0xFF647BE6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFFBFCFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static TextStyle fontFamily(TextStyle? style) =>
      (style ?? const TextStyle()).copyWith(fontFamily: fontFamilyName);

  static ThemeData build() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme.apply(
      fontFamily: fontFamilyName,
      bodyColor: text,
      displayColor: text,
    );
    final primaryTextTheme = base.primaryTextTheme.apply(
      fontFamily: fontFamilyName,
      bodyColor: text,
      displayColor: text,
    );

    return base.copyWith(
      primaryTextTheme: primaryTextTheme,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        primary: neonBlue,
        secondary: neonPurple,
        tertiary: neonCyan,
        surface: card,
        error: danger,
        onSurface: text,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        toolbarHeight: 60,
        titleSpacing: 12,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: text, size: 22),
        titleTextStyle: TextStyle(
          fontFamily: fontFamilyName,
          color: text,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: neonPurple.withOpacity(0.10),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0x337652E9), width: 1),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: neonPurple, size: 22);
          }
          return const IconThemeData(color: textMuted, size: 21);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontFamily: fontFamilyName,
            color: states.contains(WidgetState.selected) ? neonPurple : textDim,
            fontSize: 10,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: card,
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
        thumbColor: WidgetStateProperty.all(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? neonPurple : bg3,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? neonPurple : cardBorderBright,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: neonBlue,
        inactiveTrackColor: bg3,
        thumbColor: neonBlue,
        overlayColor: neonBlue.withOpacity(0.12),
        valueIndicatorColor: neonPurple,
      ),
    );
  }
}
