import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF0A0A0A);
  static const Color foreground = Color(0xFFFFFFFF);
  
  static const Color card = Color(0xFF1A1A1A);
  static const Color cardForeground = Color(0xFFFFFFFF);
  
  static const Color primary = Color(0xFFC9A84C);
  static const Color primaryForeground = Color(0xFF0A0A0A);
  
  static const Color secondary = Color(0xFF1E1E1E);
  static const Color secondaryForeground = Color(0xFFCCCCCC);
  
  static const Color muted = Color(0xFF2A2A2A);
  static const Color mutedForeground = Color(0xFF888888);
  
  static const Color border = Color(0xFF2A2A2A);
  static const Color input = Color(0xFF1E1E1E);
  
  static const Color success = Color(0xFF10B981);
  static const Color destructive = Color(0xFFEF4444);
  
  static const double radius = 12.0;

  static ThemeData get themeData {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      cardColor: card,
      dividerColor: border,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: primary,
        background: background,
        surface: card,
        onPrimary: primaryForeground,
        onSecondary: foreground,
        onBackground: foreground,
        onSurface: cardForeground,
        error: destructive,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: foreground),
        bodyMedium: TextStyle(color: secondaryForeground),
        titleLarge: TextStyle(color: foreground, fontWeight: FontWeight.bold),
      ),
    );
  }
}
