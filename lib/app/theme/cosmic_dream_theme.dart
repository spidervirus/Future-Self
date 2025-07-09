import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CosmicDreamTheme {
  // Enhanced color palette for bubble interactions
  static const Color deepSpace = Color(0xFF0A0A15); // Darker background
  static const Color background = Color(0xFF19192A); // Original background
  static const Color primary = Color(0xFF8A63D2); // Original primary
  static const Color accent = Color(0xFFF2C94C); // Original accent
  static const Color nebulaPink = Color(0xFFFF6B9D); // New: playful accents
  static const Color cosmicTeal =
      Color(0xFF4ECDC4); // New: interactive elements
  static const Color text = Color(0xFFF1F1F5); // Original text
  static const Color surface = Color(0xFF2A2A3D); // Original surface
  static const Color glowBlue = Color(0xFF00D4FF); // New: selection states
  static const Color stardust = Color(0xFFF1F1F5); // Same as text

  // Bubble-specific color variations
  static const Color bubblePrimary =
      Color(0xFF9B73E3); // Lighter purple for bubbles
  static const Color bubbleSecondary =
      Color(0xFF6B73FF); // Blue-purple for variety
  static const Color bubbleAccent =
      Color(0xFFFFB347); // Warm orange for interaction
  static const Color bubbleHover = Color(0xFFB084E7); // Hover state
  static const Color bubbleSelected = Color(0xFF4ECDC4); // Selected state

  // Gradient definitions for bubbles
  static const LinearGradient questionBubbleGradient = LinearGradient(
    colors: [primary, nebulaPink],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient responseBubbleGradient = LinearGradient(
    colors: [bubblePrimary, bubbleSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient selectedBubbleGradient = LinearGradient(
    colors: [cosmicTeal, glowBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

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
      // Bubble-specific text styles
      labelLarge: GoogleFonts.nunitoSans(
          textStyle: base.labelLarge?.copyWith(
        color: text,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      )),
      labelMedium: GoogleFonts.nunitoSans(
          textStyle: base.labelMedium?.copyWith(
        color: text,
        fontWeight: FontWeight.w500,
        fontSize: 14,
      )),
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

  // Bubble-specific styling methods
  static BoxDecoration bubbleDecoration({
    required Gradient gradient,
    bool isSelected = false,
    bool isHovered = false,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(25),
      boxShadow: [
        if (isSelected || isHovered)
          BoxShadow(
            color: (isSelected ? cosmicTeal : bubbleHover).withOpacity(0.3),
            blurRadius: isSelected ? 12 : 8,
            spreadRadius: isSelected ? 2 : 1,
          ),
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static TextStyle bubbleTextStyle({
    required BuildContext context,
    bool isSelected = false,
    double fontSize = 14,
  }) {
    return GoogleFonts.nunitoSans(
      fontSize: fontSize,
      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      color: text,
    );
  }
}
