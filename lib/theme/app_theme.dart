import 'package:flutter/material.dart';

/// Color palette for Alliance One 4.0
class AppColors {
  // Primary gradient colors
  static const Color deepIndigo = Color(0xFF1A1A2E);
  static const Color royalPurple = Color(0xFF4A3078);
  static const Color midPurple = Color(0xFF6C63FF);
  
  // Accent colors
  static const Color brightCyan = Color(0xFF00D9FF);
  static const Color vibrantOrange = Color(0xFFFF6B35);
  static const Color pureWhite = Color(0xFFFFFFFF);
  
  // Utility colors
  static const Color glassWhite = Color(0x33FFFFFF);
  static const Color darkBackground = Color(0xFF0D0D14);
}

/// Gradient presets
class AppGradients {
  static const LinearGradient cyanButton = LinearGradient(
    colors: [Color(0xFF00D9FF), Color(0xFF00B4D8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient purpleBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.deepIndigo,
      AppColors.royalPurple,
      AppColors.midPurple,
    ],
  );
}

