// lib/presentation/theme/app_theme.dart

import 'package:flutter/material.dart';

/// Premium Nordic & Cyber-Athlete Tasarım Sistemi Renk Paleti
class AppColors {
  // ─── Temel Yüzeyler (Obsidian & Mat Grafit) ──────────────────────────────
  static const Color background = Color(0xFF0A0C0E); // Derin Obsidian Siyahı
  static const Color surface = Color(0xFF13171C); // Koyu Mat Grafit / Kömür
  static const Color surfaceSoft = Color(0xFF181D24); // Yükseltilmiş / Yumuşak Yüzey
  static const Color surfaceSubtle = Color(0xFF1E232B); // İkincil Bölme Yüzeyi
  static const Color border = Color(0xFF1E232A); // 1px İnce Mat Sınır
  static const Color borderSubtle = Color(0xFF262E38); // Vurgulu Mat Sınır

  // ─── İki Ana Vurgu Rengi ──────────────────────────────────────────────────
  static const Color volcanic = Color(0xFFFF5533); // Volkanik Turuncu (Orange-Red)
  static const Color volcanicSoft = Color(0xFFFF7733); // Volkanik Açık Gradyan Bitişi
  static const Color emerald = Color(0xFF10B981); // Doğal Toparlanma Yeşili (Recovery)
  static const Color emeraldSoft = Color(0xFF34D399); // Açık Zümrüt Yeşili

  // ─── Yardımcı İkincil Metrik Renkleri ──────────────────────────────────────
  static const Color nordicIce = Color(0xFF38BDF8); // Buz Mavisi (Süre / Su)
  static const Color amber = Color(0xFFF59E0B); // Kehribar (Orta Yük)

  // ─── Tipografi & Kontrast ────────────────────────────────────────────────
  static const Color textHigh = Color(0xFFF1F5F9); // Yüksek Kontrastlı Kırık Beyaz
  static const Color textMid = Color(0xFF94A3B8); // Soğuk Gümüş / Arduvaz Gri
  static const Color textMuted = Color(0xFF64748B); // Bastırılmış Gri
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.volcanic,
        onPrimary: Colors.white,
        secondary: AppColors.emerald,
        onSecondary: Colors.white,
        error: Color(0xFFEF4444),
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textHigh,
        surfaceContainerHighest: AppColors.surfaceSoft,
        outline: AppColors.border,
        outlineVariant: AppColors.borderSubtle,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textHigh,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textHigh,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.textHigh),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
          side: const BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1.0,
        space: 1.0,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16.0)),
          side: BorderSide(color: AppColors.border, width: 1.0),
        ),
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(
          fontSize: 26.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textHigh,
          letterSpacing: -0.5,
        ),
        titleLarge: TextStyle(
          fontSize: 20.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textHigh,
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w600,
          color: AppColors.textHigh,
        ),
        bodyLarge: TextStyle(
          fontSize: 15.0,
          color: AppColors.textHigh,
        ),
        bodyMedium: TextStyle(
          fontSize: 14.0,
          color: AppColors.textMid,
        ),
        bodySmall: TextStyle(
          fontSize: 12.0,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}