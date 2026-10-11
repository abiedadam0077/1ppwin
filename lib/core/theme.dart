import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class NovaTheme {
  static const Color bg = Color(0xFF050A1E);
  static const Color bg2 = Color(0xFF081228);
  static const Color bg3 = Color(0xFF0D1B3E);
  static const Color card = Color(0xFF0A1430);
  static const Color cardElevated = Color(0xFF101F46);
  static const Color cardBorder = Color(0x552979FF);
  static const Color cardBorderBright = Color(0xAA448AFF);
  static const Color neonBlue = Color(0xFF2979FF);
  static const Color neonPurple = Color(0xFF7C4DFF);
  static const Color neonPurpleSoft = Color(0xFF9E7BFF);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color ok = Color(0xFF00E676);
  static const Color warn = Color(0xFFFFC107);
  static const Color danger = Color(0xFFFF5252);
  static const Color text = Color(0xFFEAF2FF);
  static const Color textDim = Color(0xFFAAB8D8);
  static const Color textMuted = Color(0xFF6E80A8);

  static LinearGradient get btnGradient => const LinearGradient(
        colors: [Color(0xFF2979FF), Color(0xFF7C4DFF)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static LinearGradient get purpleGradient => const LinearGradient(
        colors: [Color(0xFF7C4DFF), Color(0xFF536DFE)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get cardGradient => LinearGradient(
        colors: [
          card.withOpacity(0.92),
          bg2.withOpacity(0.86),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static TextStyle fontFamily(TextStyle? s) =>
      s == null ? GoogleFonts.cairo() : GoogleFonts.cairo(textStyle: s);

  static ThemeData build() {
    final base = ThemeData.dark(useMaterial3: true);
    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme.apply(
      bodyColor: text,
      displayColor: text,
    ));
    return base.copyWith(
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
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: const IconThemeData(color: text),
        titleTextStyle: GoogleFonts.cairo(
          color: text,
          fontSize: 18,
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
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            );
          }
          return GoogleFonts.cairo(
            color: textDim,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardElevated,
        contentTextStyle: GoogleFonts.cairo(color: text, fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
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
      ),
    );
  }
}
