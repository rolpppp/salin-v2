import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color paperBg = Color(0xFFFFFFFF);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color carbonText = Color(0xFF1C1B1B);
  static const Color oceanBlue = Color(0xFF1D6299);

  // Semantic Colors (Light)
  static const Color registerGreen = Color(0xFF2E7D32);
  static const Color warningAmber = Color(0xFFC98A3D);
  static const Color inkRed = Color(0xFFBA1A1A);
  static const Color brass = Color(0xFF8C6A3F);

  // Dark Theme Colors
  static const Color midnightBg = Color(0xFF161513);
  static const Color midnightCardBg = Color(0xFF211F1D);
  static const Color carbonTextDark = Color(0xFFE5E2DA);

  // Fallback Fonts Lists
  static const List<String> monoFallbacks = ['RobotoMono', 'monospace'];
  static const List<String> sansFallbacks = ['Roboto', 'sans-serif'];

  // Typography tokens from DESIGN.md
  static const TextStyle displayHero = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontFamilyFallback: monoFallbacks,
    fontSize: 40,
    fontWeight: FontWeight.w500,
    letterSpacing: -0.8,
  );
  
  static const TextStyle headlineLg = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontFamilyFallback: monoFallbacks,
    fontSize: 24,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontFamilyFallback: monoFallbacks,
    fontSize: 20,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle bodyLg = TextStyle(
    fontFamily: 'PublicSans',
    fontFamilyFallback: sansFallbacks,
    fontSize: 18,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: 'PublicSans',
    fontFamilyFallback: sansFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySm = TextStyle(
    fontFamily: 'PublicSans',
    fontFamilyFallback: sansFallbacks,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle labelCaps = TextStyle(
    fontFamily: 'PublicSans',
    fontFamilyFallback: sansFallbacks,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.88,
  );

  static const TextStyle dataMono = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontFamilyFallback: monoFallbacks,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle dataMonoSm = TextStyle(
    fontFamily: 'IBMPlexMono',
    fontFamilyFallback: monoFallbacks,
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: paperBg,
      primaryColor: oceanBlue,
      fontFamily: 'PublicSans',
      fontFamilyFallback: sansFallbacks,
      colorScheme: const ColorScheme.light(
        primary: oceanBlue,
        surface: cardBg,
        onSurface: carbonText,
        error: inkRed,
        background: paperBg,
        onBackground: carbonText,
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
          fontFamilyFallback: sansFallbacks,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: carbonText,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'IBMPlexMono', fontFamilyFallback: monoFallbacks, fontSize: 40, color: carbonText, fontWeight: FontWeight.w500, letterSpacing: -0.8),
        headlineLarge: TextStyle(fontFamily: 'IBMPlexMono', fontFamilyFallback: monoFallbacks, fontSize: 24, color: carbonText, fontWeight: FontWeight.w500),
        headlineMedium: TextStyle(fontFamily: 'IBMPlexMono', fontFamilyFallback: monoFallbacks, fontSize: 20, color: carbonText, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks, fontSize: 18, color: carbonText, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks, fontSize: 16, color: carbonText, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks, fontSize: 14, color: carbonText, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks, fontSize: 11, color: carbonText, fontWeight: FontWeight.w600, letterSpacing: 0.88),
        labelSmall: TextStyle(fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks, fontSize: 11, color: carbonText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: carbonText.withOpacity(0.15)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: carbonText.withOpacity(0.1)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: oceanBlue, width: 1.5),
        ),
        labelStyle: TextStyle(color: carbonText.withOpacity(0.6), fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: midnightBg,
      primaryColor: oceanBlue,
      fontFamily: 'PublicSans',
      fontFamilyFallback: sansFallbacks,
      colorScheme: const ColorScheme.dark(
        primary: oceanBlue,
        surface: midnightCardBg,
        onSurface: carbonTextDark,
        error: inkRed,
        background: midnightBg,
        onBackground: carbonTextDark,
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
          fontFamilyFallback: sansFallbacks,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: carbonTextDark,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontFamily: 'IBMPlexMono', fontFamilyFallback: monoFallbacks, fontSize: 40, color: carbonTextDark, fontWeight: FontWeight.w500, letterSpacing: -0.8),
        headlineLarge: TextStyle(fontFamily: 'IBMPlexMono', fontFamilyFallback: monoFallbacks, fontSize: 24, color: carbonTextDark, fontWeight: FontWeight.w500),
        headlineMedium: TextStyle(fontFamily: 'IBMPlexMono', fontFamilyFallback: monoFallbacks, fontSize: 20, color: carbonTextDark, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks, fontSize: 18, color: carbonTextDark, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks, fontSize: 16, color: carbonTextDark, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks, fontSize: 14, color: carbonTextDark, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks, fontSize: 11, color: carbonTextDark, fontWeight: FontWeight.w600, letterSpacing: 0.88),
        labelSmall: TextStyle(fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks, fontSize: 11, color: carbonTextDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(color: carbonTextDark.withOpacity(0.15)),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: carbonTextDark.withOpacity(0.1)),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: oceanBlue, width: 1.5),
        ),
        labelStyle: TextStyle(color: carbonTextDark.withOpacity(0.6), fontFamily: 'PublicSans', fontFamilyFallback: sansFallbacks),
      ),
    );
  }
}
