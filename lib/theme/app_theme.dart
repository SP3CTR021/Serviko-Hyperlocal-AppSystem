import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF0D9488); // Teal
  static const Color primaryDark = Color(0xFF0F766E);
  static const Color primaryLight = Color(0xFFCCFBF1);
  static const Color secondaryColor = Color(0xFFF59E0B); // Amber
  static const Color scaffoldBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF64748B); // Slate 500
  static const Color borderColor = Color(0xFFE2E8F0); // Slate 200

  // -------------------------------------------------------------
  // SerbisyoKo Prototype Tokens
  // -------------------------------------------------------------
  static const Color sbBg = Color(0xFFF3F6F4);
  static const Color sbInk = Color(0xFF10140F);
  static const Color sbInk2 = Color(0xFF232B22);
  static const Color sbInk3 = Color(0xFF5B6459);
  static const Color sbInkSoft = Color(0xFF5B655C);
  static const Color sbInk4 = Color(0xFF8B958A);
  static const Color sbInkFaint = Color(0xFF94A096);
  static const Color sbLine = Color(0xFFE3E9E4);
  static const Color sbLine2 = Color(0xFFEEF3EF);
  static const Color sbField = Color(0xFFF1F5F2);
  static const Color sbSurface = Color(0xFFF5F8F6);
  static const Color sbCard = Color(0xFFFFFFFF);
  static const Color sbBlue = Color(0xFF1B9457); // Primary emerald
  static const Color sbBlue2 = Color(0xFF20A863);
  static const Color sbSky = Color(0xFF3FD483);
  static const Color sbBlueSoft = Color(0xFFE7F7EE);
  static const Color sbAmber = Color(0xFFFFB020);
  static const Color sbAmber2 = Color(0xFFFF8A3C);
  static const Color sbAmberSoft = Color(0xFFFFF4E2);
  static const Color sbGreen = Color(0xFF12331F);
  static const Color sbGreenSoft = Color(0xFFE6F6EE);
  static const Color sbRed = Color(0xFFD0453A);
  static const Color sbRedSoft = Color(0xFFFDECEA);
  static const Color sbViolet = Color(0xFF6B4BD8);

  static const LinearGradient gBlue = LinearGradient(
    begin: Alignment(-0.7, -0.7),
    end: Alignment(0.7, 0.7),
    colors: [Color(0xFF0A0F0A), Color(0xFF123422), Color(0xFF28B26A)],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient gWarm = LinearGradient(
    begin: Alignment(-0.7, -0.7),
    end: Alignment(0.7, 0.7),
    colors: [Color(0xFF20A863), Color(0xFF6FE3A0)],
  );

  static const LinearGradient gHero = LinearGradient(
    begin: Alignment(-0.5, -0.9),
    end: Alignment(0.5, 0.9),
    colors: [Color(0xFF0A0F0A), Color(0xFF123422), Color(0xFF1E8E4F)],
    stops: [0.0, 0.46, 1.0],
  );

  // V2 Backward-compatible aliases
  static const Color v2Bg = Color(0xFF080B08);
  static const Color v2Surface = Color(0xFF10140F);
  static const Color v2Surface2 = Color(0xFF171D16);
  static const Color v2Field = Color(0xFF1B231A);
  static const Color v2Green = Color(0xFF3FD483);
  static const Color v2GreenDeep = Color(0xFF123422);
  static const Color v2InkSoft = Color(0x9EFFFFFF);
  static const Color v2InkFaint = Color(0x61FFFFFF);
  static const Color v2Line = Color(0x1AFFFFFF);
  static const LinearGradient v2Grad = gBlue;

  // -------------------------------------------------------------
  // Serviko V3 Design Tokens
  // -------------------------------------------------------------
  static const Color v3Bg = Color(0xFFF3F6F4);
  static const Color v3White = Color(0xFFFFFFFF);
  static const Color v3Ink = Color(0xFF10140F);
  static const Color v3InkSoft = Color(0xFF5B655C);
  static const Color v3InkFaint = Color(0xFF94A096);
  static const Color v3Line = Color(0xFFE4EAE5);
  static const Color v3Field = Color(0xFFF1F5F2);
  static const Color v3Green = Color(0xFF1B9457);
  static const LinearGradient v3Grad = LinearGradient(
    begin: Alignment(-0.7, -0.7),
    end: Alignment(0.7, 0.7),
    colors: [Color(0xFF0A0F0A), Color(0xFF123422), Color(0xFF28B26A)],
    stops: [0.0, 0.48, 1.0],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        surface: cardColor,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 1.8),
        ),
        labelStyle: const TextStyle(color: textSecondary, fontSize: 14),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      ),
    );
  }
}
