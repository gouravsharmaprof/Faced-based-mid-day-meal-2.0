import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Hume-inspired Palette ─────────────────────────────────────────────────
  static const Color background   = Color(0xFF0E0E0F);   // near-black warm
  static const Color surface      = Color(0xFF161618);   // card base
  static const Color surfaceLight = Color(0xFF1F1F22);   // elevated surface
  static const Color cardColor    = Color(0xFF1A1A1D);   // card fill
  static const Color border       = Color(0xFF2A2A2E);   // subtle border
  static const Color borderFocus  = Color(0xFF444449);   // focused border

  // Typography
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textMuted     = Color(0xFF48484C);

  // Orange-centric accent palette  (Hume uses #FF5500-range orange)
  static const Color primary     = Color(0xFFFF5500);   // main orange
  static const Color primaryDark = Color(0xFFD94400);   // pressed orange
  static const Color secondary   = Color(0xFF00C896);   // teal keep
  static const Color accent      = Color(0xFFFF5C5C);   // red accent

  // Semantic (keep secondary/success teal, warnings orange)
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error   = Color(0xFFFF3B30);
  static const Color info    = Color(0xFF636366);

  // ── Gradients ─────────────────────────────────────────────────────────────
  // Orange gradient (Hume's primary CTA color)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFFF5500), Color(0xFFFF8C00)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF34C759), Color(0xFF30D158)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Background is flat near-black
  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0E0E0F), Color(0xFF0E0E0F)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Theme ─────────────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        error: error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge:  GoogleFonts.inter(color: textPrimary,   fontWeight: FontWeight.w700),
        displayMedium: GoogleFonts.inter(color: textPrimary,   fontWeight: FontWeight.w600),
        titleLarge:    GoogleFonts.inter(color: textPrimary,   fontWeight: FontWeight.w600, fontSize: 18),
        bodyLarge:     GoogleFonts.inter(color: textPrimary,   fontSize: 15),
        bodyMedium:    GoogleFonts.inter(color: textSecondary, fontSize: 13),
        bodySmall:     GoogleFonts.inter(color: textMuted,     fontSize: 11),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: GoogleFonts.inter(
          color: textPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error),
        ),
        labelStyle: GoogleFonts.inter(color: textSecondary, fontSize: 13),
        hintStyle: GoogleFonts.inter(color: textMuted, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: border),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surfaceLight,
        contentTextStyle: GoogleFonts.inter(color: textPrimary, fontSize: 13),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
      ),
      useMaterial3: true,
    );
  }
}
