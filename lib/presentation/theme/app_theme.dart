// lib/presentation/theme/app_theme.dart

import 'package:flutter/material.dart';

import 'package:calisthenics_app/presentation/theme/app_spacing.dart';
import 'package:calisthenics_app/presentation/theme/app_typography.dart';

export 'package:calisthenics_app/presentation/theme/app_spacing.dart';
export 'package:calisthenics_app/presentation/theme/app_typography.dart';

/// Premium minimal (obsidyen) renk paleti.
///
/// Kurallar:
/// - Bölümler kalın çerçevelerle değil, 0.5px [hairline] çizgiler ve geniş
///   boşluklarla ayrılır.
/// - [accent] (atletik yeşil) yalnızca ana CTA butonlarında ve aktif/seçili öğelerde
///   kullanılır.
/// - [emerald] / [amber] yalnızca durum (hazır / toparlanıyor) bildirir.
class AppColors {
  AppColors._();

  // ─── Yüzey Hiyerarşisi ─────────────────────────────────────────────────────
  static const Color background = Color(0xFF0B0D10); // Derin mat obsidyen
  static const Color surface = Color(0xFF13161C); // Birincil yüzey
  static const Color surfaceRaised = Color(0xFF1A1E26); // İkincil yüzey

  // ─── İnce Çizgiler (beyaz, düşük opaklık) ──────────────────────────────────
  static const Color hairline = Color(0x14FFFFFF); // %8
  static const Color hairlineStrong = Color(0x1FFFFFFF); // %12

  // ─── Geriye Dönük Takma Adlar ──────────────────────────────────────────────
  static const Color surfaceSoft = surfaceRaised;
  static const Color surfaceSubtle = surfaceRaised;
  static const Color border = hairline;
  static const Color borderSubtle = hairlineStrong;

  // ─── Vurgu & Durum ─────────────────────────────────────────────────────────
  /// Ana vurgu: ferah atletik yeşil. YALNIZCA ana CTA ve aktif/seçili öğeler.
  static const Color accent = Color(0xFFA3E635);
  static const Color accentSoft = Color(0xFFBEF264);

  /// Dolu [accent] yüzeylerin üzerindeki metin/ikon (koyu mat obsidyen).
  static const Color onAccent = Color(0xFF0B0D10);

  /// Eski ad; [accent] ile aynıdır (geriye dönük uyumluluk).
  static const Color volcanic = accent;
  static const Color volcanicSoft = accentSoft;
  static const Color emerald = Color(0xFF10B981); // Hazır / artış
  static const Color emeraldSoft = Color(0xFF34D399);
  static const Color amber = Color(0xFFF59E0B); // Toparlanıyor
  static const Color danger = Color(0xFFEF4444);

  // ─── Yardımcı Metrik Renkleri (ikincil ekranlar) ───────────────────────────
  static const Color nordicIce = Color(0xFF38BDF8);
  static const Color iceBlue = nordicIce;

  // ─── Metin ─────────────────────────────────────────────────────────────────
  static const Color textHigh = Color(0xFFF2F4F7);
  static const Color textMid = Color(0xFF9BA3AF);
  static const Color textMuted = Color(0xFF6B7280);

  // ─── Grafik ────────────────────────────────────────────────────────────────
  static const Color chartNeutral = Color(0x38FFFFFF); // %22

  // Hero kart derinliği (üstten ışık sızıntısı)
  static const Color heroTop = Color(0xFF20242E);
  static const Color heroGlow = Color(0x14FFFFFF);
  static const Color shadow = Color(0x66000000);

  // Anatomik kas haritası
  static const Color anatomyMuscle = Color(0xFF242934); // Yüksüz kas
  static const Color anatomyBase = Color(0xFF1C2029); // Baş, el, eklem

  /// Yığılmış barlarda sıralı payları ayırmak için tek tonlu basamaklar.
  static const List<Color> chartSteps = [
    textHigh,
    Color(0x99FFFFFF), // %60
    Color(0x61FFFFFF), // %38
    Color(0x38FFFFFF), // %22
    Color(0x1FFFFFFF), // %12
  ];
}

class AppTheme {
  AppTheme._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle _t(TextStyle s) => s.copyWith(fontFeatures: _tabular);

  static ThemeData get darkTheme {
    const hairlineSide = BorderSide(
      color: AppColors.hairline,
      width: AppSpace.hairline,
    );

    final textTheme = TextTheme(
      displaySmall: _t(AppText.metricL),
      headlineLarge: _t(AppText.pageTitle),
      headlineMedium: _t(AppText.pageTitle.copyWith(fontSize: 26)),
      headlineSmall: _t(AppText.pageTitle.copyWith(fontSize: 22)),
      titleLarge: _t(AppText.cardTitle.copyWith(fontSize: 20)),
      titleMedium: _t(AppText.cardTitle.copyWith(fontSize: 16)),
      titleSmall: _t(AppText.cardTitle.copyWith(fontSize: 14)),
      bodyLarge: _t(AppText.body.copyWith(fontSize: 15)),
      bodyMedium: _t(AppText.body.copyWith(color: AppColors.textMid)),
      bodySmall: _t(AppText.caption),
      labelLarge: _t(AppText.button),
      labelMedium: _t(AppText.caption.copyWith(color: AppColors.textMid)),
      labelSmall: _t(AppText.sectionLabel),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.accent,
        onPrimary: AppColors.onAccent,
        secondary: AppColors.emerald,
        onSecondary: Colors.white,
        error: AppColors.danger,
        onError: Colors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textHigh,
        onSurfaceVariant: AppColors.textMid,
        surfaceContainerHighest: AppColors.surfaceRaised,
        surfaceContainerHigh: AppColors.surfaceRaised,
        surfaceContainer: AppColors.surface,
        outline: AppColors.hairlineStrong,
        outlineVariant: AppColors.hairline,
      ),
      textTheme: textTheme,
      iconTheme: const IconThemeData(color: AppColors.textMid, size: 20),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textHigh,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _t(AppText.cardTitle),
        iconTheme: const IconThemeData(color: AppColors.textHigh, size: 22),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: hairlineSide,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: AppSpace.hairline,
        space: AppSpace.hairline,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.volcanic,
          foregroundColor: AppColors.onAccent,
          elevation: 0,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.volcanic,
          foregroundColor: AppColors.onAccent,
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textHigh,
          side: const BorderSide(
            color: AppColors.hairlineStrong,
            width: AppSpace.hairline,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.control),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: AppColors.textHigh),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceRaised,
        hintStyle: AppText.body.copyWith(color: AppColors.textMuted),
        labelStyle: AppText.body.copyWith(color: AppColors.textMid),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(
            color: AppColors.hairlineStrong,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: const BorderSide(color: AppColors.danger, width: 1),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        modalBackgroundColor: AppColors.surface,
        elevation: 0,
        showDragHandle: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        elevation: 0,
        titleTextStyle: _t(AppText.cardTitle),
        contentTextStyle: _t(AppText.bodyMuted),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sheet),
          side: hairlineSide,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceRaised,
        contentTextStyle: _t(AppText.body),
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceRaised,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: _t(AppText.caption.copyWith(color: AppColors.textHigh)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.accent,
        linearTrackColor: AppColors.hairlineStrong,
        circularTrackColor: Colors.transparent,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceRaised,
        selectedColor: AppColors.accent,
        checkmarkColor: AppColors.onAccent,
        side: BorderSide.none,
        labelStyle: _t(AppText.caption.copyWith(color: AppColors.textHigh)),
        secondaryLabelStyle: _t(
          AppText.caption.copyWith(color: AppColors.onAccent),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.textMid,
        textColor: AppColors.textHigh,
      ),
    );
  }

  static ThemeData get lightTheme => darkTheme;
}
