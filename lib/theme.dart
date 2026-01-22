
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Deep Blue/Purple Palette for a professional night/tech event vibe
  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color accentColor = Color(0xFF00E5FF);
  static const Color darkBackground = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color surfaceColor = Color(0xFF2A2A2A);
  static const Color textColor = Color(0xFFEEEEEE);
  static const Color subTextColor = Color(0xFFAAAAAA);

  static ThemeData get darkTheme {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBackground,
      primaryColor: primaryColor,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accentColor,
        surface: surfaceColor,
        // background: darkBackground, // Deprecated
      ),
      // cardTheme: CardTheme(
      //   color: cardColor,
      //   elevation: 8,
      //   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      //   shadowColor: Colors.black45,
      // ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkBackground,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: textColor,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: textColor),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          color: textColor,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.poppins(
            color: textColor, fontSize: 24, fontWeight: FontWeight.bold),
        titleLarge: GoogleFonts.inter(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: textColor,
          fontSize: 16,
        ),
        bodyMedium: GoogleFonts.inter(
          color: subTextColor,
          fontSize: 14,
        ),
      ),
    );
  }
}
