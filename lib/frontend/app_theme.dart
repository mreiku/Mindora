import 'package:flutter/material.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFFC84D4D),
    scaffoldBackgroundColor: const Color(0xFFFFEAD3), // Your peach color
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFC84D4D),
      foregroundColor: Colors.white,
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark, // Essential for flipping text colors
    scaffoldBackgroundColor: const Color(0xFF121212), // Dark grey/black
    primaryColor: const Color(0xFFC84D4D),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1A1A1A), // Darker app bar
      foregroundColor: Colors.white,
    ),
    // This ensures your cards and dialogs also turn dark
    cardColor: const Color(0xFF1E1E1E), 
  );
}

