import 'package:flutter/material.dart';

/// Human Contact brand colors — dark theme with blue accents
class HCColors {
  HCColors._();

  // Backgrounds
  static const Color bgDark = Color(0xFF0A0E27);
  static const Color bgLight = Color(0xFF1A1D3A);
  static const Color bgCard = Color(0xFF151933);
  static const Color bgInput = Color(0xFF1E2145);

  // Primary — Blue
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);

  // Accent — Orange (CTAs)
  static const Color accent = Color(0xFFF59E0B);
  static const Color accentLight = Color(0xFFFB923C);

  // Borders
  static const Color border = Color(0x4D3B82F6); // rgba(59,130,246,0.3)
  static const Color borderLight = Color(0x663B82F6); // rgba(59,130,246,0.4)

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xCCFFFFFF); // 80% opacity
  static const Color textMuted = Color(0x99FFFFFF); // 60% opacity

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFFBBF24);
  static const Color error = Color(0xFFEF4444);

  // Gradients
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [bgDark, bgLight],
  );

  static const LinearGradient accentBoxGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E40AF), Color(0xFF1E3A8A)],
  );

  static const LinearGradient primaryButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryDark],
  );
}

/// Human Contact spacing constants
class HCSpacing {
  HCSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// Human Contact border radius
class HCRadius {
  HCRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;
}

/// Build the app theme
ThemeData buildHCTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: HCColors.bgDark,
    primaryColor: HCColors.primary,
    colorScheme: const ColorScheme.dark(
      primary: HCColors.primary,
      secondary: HCColors.accent,
      surface: HCColors.bgCard,
      error: HCColors.error,
      onPrimary: HCColors.textPrimary,
      onSecondary: HCColors.bgDark,
      onSurface: HCColors.textPrimary,
      onError: HCColors.textPrimary,
    ),

    // Typography
    fontFamily: null, // System font (SF Pro on iOS, Roboto on Android)
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: HCColors.textPrimary,
      ),
      headlineMedium: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: HCColors.textPrimary,
      ),
      headlineSmall: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: HCColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: HCColors.textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: HCColors.textPrimary,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: HCColors.textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: HCColors.textSecondary,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: HCColors.textMuted,
      ),
      labelLarge: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: HCColors.textPrimary,
      ),
    ),

    // App Bar
    appBarTheme: const AppBarTheme(
      backgroundColor: HCColors.bgDark,
      foregroundColor: HCColors.textPrimary,
      elevation: 0,
      centerTitle: true,
    ),

    // Cards
    cardTheme: CardThemeData(
      color: HCColors.bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HCRadius.md),
        side: const BorderSide(color: HCColors.border),
      ),
    ),

    // Elevated Buttons
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: HCColors.primary,
        foregroundColor: HCColors.textPrimary,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HCRadius.md),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),

    // Outlined Buttons
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: HCColors.primary,
        minimumSize: const Size(double.infinity, 52),
        side: const BorderSide(color: HCColors.border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(HCRadius.md),
        ),
      ),
    ),

    // Text Buttons
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: HCColors.primary,
      ),
    ),

    // Input Fields
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: HCColors.bgInput,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: HCSpacing.md,
        vertical: HCSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HCRadius.md),
        borderSide: const BorderSide(color: HCColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HCRadius.md),
        borderSide: const BorderSide(color: HCColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HCRadius.md),
        borderSide: const BorderSide(color: HCColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(HCRadius.md),
        borderSide: const BorderSide(color: HCColors.error),
      ),
      hintStyle: const TextStyle(color: HCColors.textMuted),
      labelStyle: const TextStyle(color: HCColors.textSecondary),
    ),

    // Bottom Navigation
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: HCColors.bgDark,
      selectedItemColor: HCColors.primary,
      unselectedItemColor: HCColors.textMuted,
      type: BottomNavigationBarType.fixed,
    ),

    // Chips (for interest tags)
    chipTheme: ChipThemeData(
      backgroundColor: HCColors.bgInput,
      selectedColor: HCColors.primary.withValues(alpha: 0.3),
      labelStyle: const TextStyle(color: HCColors.textPrimary, fontSize: 14),
      side: const BorderSide(color: HCColors.border),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HCRadius.xl),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Dividers
    dividerTheme: const DividerThemeData(
      color: HCColors.border,
      thickness: 1,
    ),

    // Snackbars
    snackBarTheme: SnackBarThemeData(
      backgroundColor: HCColors.bgCard,
      contentTextStyle: const TextStyle(color: HCColors.textPrimary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(HCRadius.sm),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
