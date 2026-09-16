import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors matching reference screenshots
  static const Color darkGreen = Color(0xFF1E4D2B);
  static const Color primaryGreen = Color(0xFF2E6B3E);
  static const Color limeGreen = Color(0xFFB5ED66);
  static const Color lightGreenBadge = Color(0xFFE3F6D4);
  static const Color accentGreen = Color(0xFF70C638);
  static const Color backgroundColor = Color(0xFFF9FAF8);
  static const Color surfaceColor = Colors.white;
  static const Color textDark = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color pillUnselected = Color(0xFFF2F4F1);
  static const Color borderLight = Color(0xFFE5E7EB);
  static const Color deleteRed = Color(0xFFEF4444);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: darkGreen,
        primary: darkGreen,
        secondary: limeGreen,
        surface: surfaceColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme().copyWith(
        titleLarge: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: darkGreen,
        ),
        titleMedium: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textDark,
        ),
        bodyLarge: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textDark,
        ),
        bodyMedium: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: darkGreen),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: darkGreen,
        ),
      ),
    );
  }
}
