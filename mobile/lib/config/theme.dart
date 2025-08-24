import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors from Logo
  static const Color brandBlue = Color(0xFF2E5266);
  static const Color brandOrange = Color(0xFFFF8A56);
  static const Color brandLightBlue = Color(0xFF4A7C95);
  static const Color brandDarkBlue = Color(0xFF1E3A47);

  // Light Theme Colors
  static const Color primaryLight = brandBlue;
  static const Color secondaryLight = brandOrange;
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF8F9FA);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color errorLight = Color(0xFFDC3545);
  static const Color successLight = Color(0xFF28A745);

  // Dark Theme Colors
  static const Color primaryDark = brandLightBlue;
  static const Color secondaryDark = brandOrange;
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2A2A2A);
  static const Color errorDark = Color(0xFFFF6B6B);
  static const Color successDark = Color(0xFF4AE54A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryLight,
        secondary: secondaryLight,
        tertiary: brandOrange,
        background: backgroundLight,
        surface: surfaceLight,
        error: errorLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onBackground: brandDarkBlue,
        onSurface: brandDarkBlue,
        onError: Colors.white,
        surfaceVariant: surfaceLight,
        onSurfaceVariant: Color(0xFF6C6C6C),
        outline: Color(0xFFE0E0E0),
      ),
      scaffoldBackgroundColor: backgroundLight,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: brandDarkBlue,
        displayColor: brandDarkBlue,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: brandDarkBlue,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: brandDarkBlue,
        ),
        iconTheme: const IconThemeData(color: brandDarkBlue),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLight,
          side: const BorderSide(color: primaryLight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLight,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: cardLight,
        elevation: 2,
        shadowColor: Color(0x1A000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorLight, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.poppins(
          color: Color(0xFF6C6C6C),
        ),
        labelStyle: GoogleFonts.poppins(
          color: primaryLight,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundLight,
        selectedItemColor: primaryLight,
        unselectedItemColor: Color(0xFF6C6C6C),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryLight,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceLight,
        selectedColor: primaryLight,
        labelStyle: GoogleFonts.poppins(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryDark,
        secondary: secondaryDark,
        tertiary: brandOrange,
        background: backgroundDark,
        surface: surfaceDark,
        error: errorDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onBackground: Colors.white,
        onSurface: Colors.white,
        onError: backgroundDark,
        surfaceVariant: surfaceDark,
        onSurfaceVariant: Color(0xFFB0B0B0),
        outline: Color(0xFF404040),
      ),
      scaffoldBackgroundColor: backgroundDark,
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryDark,
          side: const BorderSide(color: primaryDark),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryDark,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: const CardThemeData(
        color: cardDark,
        elevation: 4,
        shadowColor: Color(0x4D000000),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorDark, width: 1),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: GoogleFonts.poppins(
          color: Color(0xFFB0B0B0),
        ),
        labelStyle: GoogleFonts.poppins(
          color: primaryDark,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: backgroundDark,
        selectedItemColor: primaryDark,
        unselectedItemColor: Color(0xFFB0B0B0),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryDark,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: primaryDark,
        labelStyle: GoogleFonts.poppins(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF404040),
        thickness: 1,
      ),
    );
  }

  // Gradient definitions for special UI elements
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [brandBlue, brandLightBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [brandOrange, Color(0xFFFF9966)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [brandDarkBlue, brandBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
