import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MaeveColors {
  static const charcoal = Color(0xFF2B2B2B);
  static const ink = Color(0xFF1E1E1E);
  static const muted = Color(0xFF8A8A8A);
  static const card = Color(0xFFF1F1F1);
  static const cardDark = Color(0xFF242424);
  static const green = Color(0xFF34C77B);
  static const proGreen = Color(0xFF1F5E46);
  static const blue = Color(0xFF3B8EEA);
  static const red = Color(0xFFE5484D);
}

class MaeveTheme {
  static TextTheme _text(Color c) =>
      GoogleFonts.spaceGroteskTextTheme().apply(bodyColor: c, displayColor: c);

  static ThemeData light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MaeveColors.charcoal,
          brightness: Brightness.light,
          surface: Colors.white,
          primary: MaeveColors.charcoal,
        ),
        textTheme: _text(MaeveColors.ink),
      );

  static ThemeData dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF141414),
        colorScheme: ColorScheme.fromSeed(
          seedColor: MaeveColors.charcoal,
          brightness: Brightness.dark,
          surface: const Color(0xFF141414),
          primary: Colors.white,
        ),
        textTheme: _text(Colors.white),
      );
}

extension ThemeX on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get fg => isDark ? Colors.white : MaeveColors.ink;
  Color get cardColor => isDark ? MaeveColors.cardDark : MaeveColors.card;
}
