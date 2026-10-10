import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class NovaTheme {
  static const Color bg = Color(0xFF050A1E);
  static const Color bg2 = Color(0xFF081228);
  static const Color card = Color(0xFF0A1430);
  static const Color cardBorder = Color(0x552979FF);
  static const Color neonBlue = Color(0xFF2979FF);
  static const Color neonPurple = Color(0xFF7C4DFF);
  static const Color neonCyan = Color(0xFF00E5FF);
  static const Color ok = Color(0xFF00E676);
  static const Color warn = Color(0xFFFFC107);
  static const Color danger = Color(0xFFFF5252);
  static const Color text = Color(0xFFEAF2FF);
  static const Color textDim = Color(0x99AAB8D8);

  static LinearGradient get btnGradient => const LinearGradient(
        colors: [neonBlue, neonPurple],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      );

  static TextStyle fontFamily(TextStyle? s) =>
      s == null ? GoogleFonts.cairo() : GoogleFonts.cairo(textStyle: s);

  static ThemeData build() {
    final base = ThemeData.dark();
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.dark(
        primary: neonBlue,
        secondary: neonPurple,
        surface: card,
        error: danger,
      ),
      textTheme: GoogleFonts.cairoTextTheme(base.textTheme.apply(
        bodyColor: text,
        displayColor: text,
      )),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        iconTheme: IconThemeData(color: text),
        titleTextStyle: TextStyle(color: text, fontSize: 18, fontWeight: FontWeight.w700),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: card,
      ),
    );
  }
}
