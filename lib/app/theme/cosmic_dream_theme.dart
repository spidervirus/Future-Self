import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CosmicDreamTheme {
  static const Color background = Color(0xFF19192A);
  static const Color primary = Color(0xFF8A63D2);
  static const Color accent = Color(0xFFF2C94C);
  static const Color text = Color(0xFFF1F1F5);
  static const Color surface = Color(0xFF2A2A3D);

  static ThemeData get themeData {
    final baseTheme = ThemeData.dark();
    final textTheme = _buildTextTheme(baseTheme.textTheme);

    return baseTheme.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: primary,
        secondary: accent,
        surface: surface,
        onSurface: text,
        background: background,
        onBackground: text,
      ),
      textTheme: textTheme,
      appBarTheme: _buildAppBarTheme(textTheme),
      elevatedButtonTheme: _buildElevatedButtonTheme(),
      inputDecorationTheme: _buildInputDecorationTheme(),
      textButtonTheme: _buildTextButtonTheme(),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge:
          GoogleFonts.lora(textStyle: base.displayLarge?.copyWith(color: text)),
      displayMedium: GoogleFonts.lora(
          textStyle: base.displayMedium?.copyWith(color: text)),
      displaySmall:
          GoogleFonts.lora(textStyle: base.displaySmall?.copyWith(color: text)),
      headlineMedium: GoogleFonts.lora(
          textStyle: base.headlineMedium?.copyWith(color: text, fontSize: 28)),
      headlineSmall: GoogleFonts.lora(
          textStyle: base.headlineSmall?.copyWith(color: text)),
      titleLarge:
          GoogleFonts.lora(textStyle: base.titleLarge?.copyWith(color: text)),
      bodyLarge: GoogleFonts.nunitoSans(
          textStyle: base.bodyLarge?.copyWith(color: text)),
      bodyMedium: GoogleFonts.nunitoSans(
          textStyle: base.bodyMedium?.copyWith(color: text)),
    );
  }

  static AppBarTheme _buildAppBarTheme(TextTheme textTheme) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: textTheme.titleLarge,
      centerTitle: true,
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme() {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: text,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: surface,
      hintStyle: TextStyle(color: text.withOpacity(0.5)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    );
  }

  static TextButtonThemeData _buildTextButtonTheme() {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: text,
      ),
    );
  }
}
