import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color paperBg = Color(0xFFEAE7DD);
  static const Color cardBg = Color(0xFFF5F2EB);
  static const Color carbonText = Color(0xFF211D1A);
  static const Color oceanBlue = Color(0xFF2E6EA6);

  // Semantic Colors (Light)
  static const Color registerGreen = Color(0xFF3F7D58);
  static const Color warningAmber = Color(0xFFC98A3D);
  static const Color inkRed = Color(0xFFA83232);
  static const Color brass = Color(0xFF8C6A3F);

  // Dark Theme Colors
  static const Color midnightBg = Color(0xFF161513);
  static const Color midnightCardBg = Color(0xFF211F1D);
  static const Color carbonTextDark = Color(0xFFE5E2DA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paperBg,
      primaryColor: oceanBlue,
      fontFamily: 'PublicSans',
      colorScheme: const ColorScheme.light(
        primary: oceanBlue,
        surface: cardBg,
        onSurface: carbonText,
        error: inkRed,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: carbonText.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: paperBg,
        foregroundColor: carbonText,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'PublicSans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: carbonText,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 40, color: carbonText, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'PublicSans', fontSize: 24, color: carbonText, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontFamily: 'PublicSans', fontSize: 18, color: carbonText),
        bodyMedium: TextStyle(fontFamily: 'PublicSans', fontSize: 16, color: carbonText),
        bodySmall: TextStyle(fontFamily: 'PublicSans', fontSize: 14, color: carbonText),
        labelSmall: TextStyle(fontFamily: 'PublicSans', fontSize: 11, color: carbonText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: carbonText.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: carbonText.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: oceanBlue, width: 1.5),
        ),
        labelStyle: TextStyle(color: carbonText.withOpacity(0.6), fontFamily: 'PublicSans'),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: midnightBg,
      primaryColor: oceanBlue,
      fontFamily: 'PublicSans',
      colorScheme: const ColorScheme.dark(
        primary: oceanBlue,
        surface: midnightCardBg,
        onSurface: carbonTextDark,
        error: inkRed,
      ),
      cardTheme: CardThemeData(
        color: midnightCardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: carbonTextDark.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: midnightBg,
        foregroundColor: carbonTextDark,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'PublicSans',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: carbonTextDark,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 40, color: carbonTextDark, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'PublicSans', fontSize: 24, color: carbonTextDark, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(fontFamily: 'PublicSans', fontSize: 18, color: carbonTextDark),
        bodyMedium: TextStyle(fontFamily: 'PublicSans', fontSize: 16, color: carbonTextDark),
        bodySmall: TextStyle(fontFamily: 'PublicSans', fontSize: 14, color: carbonTextDark),
        labelSmall: TextStyle(fontFamily: 'PublicSans', fontSize: 11, color: carbonTextDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: midnightCardBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: carbonTextDark.withOpacity(0.15)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: carbonTextDark.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: oceanBlue, width: 1.5),
        ),
        labelStyle: TextStyle(color: carbonTextDark.withOpacity(0.6), fontFamily: 'PublicSans'),
      ),
    );
  }
}
