import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shared NOVA design tokens. Keep product state/colors semantic; screen code
/// should use these tokens rather than adding one-off neon values.
class NovaTheme {
  static const Color bg = Color(0xFF040817);
  static const Color bg2 = Color(0xFF081128);
  static const Color bg3 = Color(0xFF101D3B);
  static const Color card = Color(0xFF0A1530);
  static const Color cardElevated = Color(0xFF122143);
  static const Color cardBorder = Color(0xFF27365F);
  static const Color cardBorderBright = Color(0xFF4655A0);
  static const Color neonBlue = Color(0xFF2478FF);
  static const Color neonPurple = Color(0xFF8044F5);
  static const Color neonPurpleSoft = Color(0xFFAA8CFF);
  static const Color neonCyan = Color(0xFF20D7FF);
  static const Color ok = Color(0xFF26D889);
  static const Color warn = Color(0xFFFFBD3F);
  static const Color danger = Color(0xFFFF5574);
  static const Color text = Color(0xFFF3F6FF);
  static const Color textDim = Color(0xFFBAC6E0);
  static const Color textMuted = Color(0xFF8390AD);

  static const String fontFamilyName = 'Cairo';

  // An 8 px spacing rhythm shared by forms, cards, and screen gutters.
  static const double space4 = 4;
  static const double space8 = 8;
  static const double space12 = 12;
  static const double space16 = 16;
  static const double space20 = 20;
  static const double space24 = 24;
  static const double minTouchTarget = 48;
  static const double radiusSmall = 10;
  static const double radiusMedium = 14;
  static const double radiusLarge = 18;
  static const double radiusAurora = 22;

  static const LinearGradient btnGradient = LinearGradient(
    colors: [Color(0xFF09AFFF), Color(0xFF326BFF), Color(0xFF713EFF)],
    stops: [0, 0.58, 1],
    begin: AlignmentDirectional.centerStart,
    end: AlignmentDirectional.centerEnd,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [Color(0xFF8144F5), Color(0xFF385FFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Reserved for the few Aurora hero surfaces; standard cards stay solid.
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xF2162854), Color(0xEF0A1530)],
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
    final primaryTextTheme = base.primaryTextTheme.apply(
      fontFamily: fontFamilyName,
      bodyColor: text,
      displayColor: text,
    );

    return base.copyWith(
      primaryTextTheme: primaryTextTheme,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: neonBlue,
        secondary: neonPurple,
        tertiary: neonCyan,
        surface: card,
        error: danger,
      ),
      textTheme: textTheme.copyWith(
        titleLarge: textTheme.titleLarge?.copyWith(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: text, fontSize: 15),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: textDim, fontSize: 13),
        bodySmall: textTheme.bodySmall?.copyWith(color: textDim, fontSize: 12),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 60,
        titleSpacing: 12,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: bg,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
        iconTheme: IconThemeData(color: text, size: 22),
        titleTextStyle: TextStyle(
          fontFamily: fontFamilyName,
          color: text,
          fontSize: 17,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardTheme(
        color: card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bg2,
        labelStyle: const TextStyle(color: textDim, fontSize: 13),
        hintStyle: const TextStyle(color: textMuted, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: neonCyan, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
          borderSide: const BorderSide(color: danger, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: neonBlue.withOpacity(0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusMedium),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected) ? neonCyan : textDim,
            size: 22,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          return TextStyle(
            fontFamily: fontFamilyName,
            color: states.contains(WidgetState.selected) ? text : textDim,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          textStyle: const TextStyle(fontFamily: fontFamilyName, fontSize: 14, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          backgroundColor: neonBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: cardElevated,
          disabledForegroundColor: textMuted,
          textStyle: const TextStyle(fontFamily: fontFamilyName, fontSize: 13, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: neonCyan,
          side: const BorderSide(color: cardBorderBright),
          textStyle: const TextStyle(fontFamily: fontFamilyName, fontSize: 13, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radiusMedium)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(minTouchTarget, minTouchTarget),
          foregroundColor: neonCyan,
          textStyle: const TextStyle(fontFamily: fontFamilyName, fontSize: 13, fontWeight: FontWeight.w700),
        ),
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
          borderRadius: BorderRadius.circular(radiusMedium),
          side: const BorderSide(color: cardBorder),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLarge),
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
          height: 1.55,
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
            ? neonBlue.withOpacity(0.65)
            : cardElevated),
        trackOutlineColor: WidgetStateProperty.all(cardBorder),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: neonBlue,
        inactiveTrackColor: cardElevated,
        thumbColor: Colors.white,
        overlayColor: neonBlue.withOpacity(0.16),
        valueIndicatorColor: neonBlue,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: neonCyan,
        linearTrackColor: cardElevated,
        circularTrackColor: cardElevated,
      ),
    );
  }
}
