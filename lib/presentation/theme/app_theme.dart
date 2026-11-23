// lib/presentation/theme/app_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:calisthenics_app/presentation/theme/app_spacing.dart';
import 'package:calisthenics_app/presentation/theme/app_typography.dart';

export 'package:calisthenics_app/presentation/theme/app_spacing.dart';
export 'package:calisthenics_app/presentation/theme/app_typography.dart';

/// Bir temanın tüm renk tokenları.
///
/// Uygulama açık ([AppPalette.light], varsayılan) ve koyu ([AppPalette.dark])
/// olmak üzere iki palet taşır. Ekranlar renkleri doğrudan değil, her zaman
/// [AppColors] üzerinden okur; tema değiştiğinde [AppColors.apply] aktif
/// paleti değiştirir ve ağaç yeniden çizilir.
@immutable
class AppPalette {
  const AppPalette({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.hairline,
    required this.hairlineStrong,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
    required this.activation,
    required this.onActivation,
    required this.ring,
    required this.emerald,
    required this.emeraldSoft,
    required this.amber,
    required this.danger,
    required this.nordicIce,
    required this.textHigh,
    required this.textMid,
    required this.textMuted,
    required this.chartNeutral,
    required this.heroTop,
    required this.heroGlow,
    required this.shadow,
    required this.anatomyMuscle,
    required this.anatomyBase,
    required this.chartSteps,
  });

  final Brightness brightness;
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color hairline;
  final Color hairlineStrong;
  final Color accent;
  final Color accentSoft;
  final Color onAccent;
  final Color activation;
  final Color onActivation;
  final Color ring;
  final Color emerald;
  final Color emeraldSoft;
  final Color amber;
  final Color danger;
  final Color nordicIce;
  final Color textHigh;
  final Color textMid;
  final Color textMuted;
  final Color chartNeutral;
  final Color heroTop;
  final Color heroGlow;
  final Color shadow;
  final Color anatomyMuscle;
  final Color anatomyBase;
  final List<Color> chartSteps;

  bool get isDark => brightness == Brightness.dark;

  /// Açık tema (varsayılan): kırık beyaz zemin, beyaz kartlar, obsidyen
  /// CTA, zümrüt hazırlık ve mercan kas aktivasyonu.
  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    background: Color(0xFFF5F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF1F3F6),
    hairline: Color(0xFFE2E8F0),
    hairlineStrong: Color(0xFFCBD5E1),
    accent: Color(0xFF111827),
    accentSoft: Color(0xFF374151),
    onAccent: Color(0xFFFFFFFF),
    activation: Color(0xFFFF5533),
    onActivation: Color(0xFFFFFFFF),
    ring: Color(0xFF10B981),
    emerald: Color(0xFF10B981),
    emeraldSoft: Color(0xFF34D399),
    amber: Color(0xFFD97706),
    danger: Color(0xFFDC2626),
    nordicIce: Color(0xFF0284C7),
    textHigh: Color(0xFF111827),
    textMid: Color(0xFF4B5563),
    textMuted: Color(0xFF6B7280),
    chartNeutral: Color(0xFFD1D5DB),
    heroTop: Color(0xFFFFFFFF),
    heroGlow: Color(0x00FFFFFF),
    shadow: Color(0x0F111827),
    anatomyMuscle: Color(0xFFE5E7EB),
    anatomyBase: Color(0xFFD1D5DB),
    chartSteps: [
      Color(0xFF111827),
      Color(0xFF4B5563),
      Color(0xFF9CA3AF),
      Color(0xFFD1D5DB),
      Color(0xFFE5E7EB),
    ],
  );

  /// Koyu tema: derin mat obsidyen ve atletik yeşil vurgu.
  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    background: Color(0xFF0B0D10),
    surface: Color(0xFF13161C),
    surfaceRaised: Color(0xFF1A1E26),
    hairline: Color(0x14FFFFFF),
    hairlineStrong: Color(0x1FFFFFFF),
    accent: Color(0xFFA3E635),
    accentSoft: Color(0xFFBEF264),
    onAccent: Color(0xFF0B0D10),
    activation: Color(0xFFA3E635),
    onActivation: Color(0xFF0B0D10),
    ring: Color(0xFFA3E635),
    emerald: Color(0xFF10B981),
    emeraldSoft: Color(0xFF34D399),
    amber: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    nordicIce: Color(0xFF38BDF8),
    textHigh: Color(0xFFF2F4F7),
    textMid: Color(0xFF9BA3AF),
    textMuted: Color(0xFF6B7280),
    chartNeutral: Color(0x38FFFFFF),
    heroTop: Color(0xFF20242E),
    heroGlow: Color(0x14FFFFFF),
    shadow: Color(0x66000000),
    anatomyMuscle: Color(0xFF242934),
    anatomyBase: Color(0xFF1C2029),
    chartSteps: [
      Color(0xFFF2F4F7),
      Color(0x99FFFFFF),
      Color(0x61FFFFFF),
      Color(0x38FFFFFF),
      Color(0x1FFFFFFF),
    ],
  );
}

/// Aktif temanın renk tokenları.
///
/// Kurallar:
/// - Bölümler kalın çerçevelerle değil, 0.5px [hairline] çizgiler ve geniş
///   boşluklarla ayrılır.
/// - [accent] yalnızca ana CTA butonlarında ve aktif/seçili öğelerde
///   kullanılır (açık temada obsidyen, koyu temada atletik yeşil); üzerindeki
///   metin/ikon her zaman [onAccent].
/// - [activation] kas aktivasyonu / seçili kas (açıkta mercan, koyuda yeşil).
/// - [ring] hazırlık halkası ve ilerleme (açıkta zümrüt, koyuda yeşil).
/// - [emerald] / [amber] yalnızca durum (hazır / toparlanıyor) bildirir.
class AppColors {
  AppColors._();

  static AppPalette _p = AppPalette.light;

  /// Aktif palet.
  static AppPalette get palette => _p;

  /// Aktif paleti değiştirir (yalnızca tema kökü çağırır).
  static void apply(AppPalette palette) => _p = palette;

  static bool get isDark => _p.isDark;

  // ─── Yüzey Hiyerarşisi ─────────────────────────────────────────────────────
  static Color get background => _p.background;
  static Color get surface => _p.surface;
  static Color get surfaceRaised => _p.surfaceRaised;

  // ─── İnce Çizgiler ─────────────────────────────────────────────────────────
  static Color get hairline => _p.hairline;
  static Color get hairlineStrong => _p.hairlineStrong;

  // ─── Geriye Dönük Takma Adlar ──────────────────────────────────────────────
  static Color get surfaceSoft => _p.surfaceRaised;
  static Color get surfaceSubtle => _p.surfaceRaised;
  static Color get border => _p.hairline;
  static Color get borderSubtle => _p.hairlineStrong;

  // ─── Vurgu & Durum ─────────────────────────────────────────────────────────
  static Color get accent => _p.accent;
  static Color get accentSoft => _p.accentSoft;
  static Color get onAccent => _p.onAccent;
  static Color get activation => _p.activation;
  static Color get onActivation => _p.onActivation;
  static Color get ring => _p.ring;

  /// Eski ad; [accent] ile aynıdır (geriye dönük uyumluluk).
  static Color get volcanic => _p.accent;
  static Color get volcanicSoft => _p.accentSoft;
  static Color get emerald => _p.emerald;
  static Color get emeraldSoft => _p.emeraldSoft;
  static Color get amber => _p.amber;
  static Color get danger => _p.danger;

  // ─── Yardımcı Metrik Renkleri (ikincil ekranlar) ───────────────────────────
  static Color get nordicIce => _p.nordicIce;
  static Color get iceBlue => _p.nordicIce;

  // ─── Metin ─────────────────────────────────────────────────────────────────
  static Color get textHigh => _p.textHigh;
  static Color get textMid => _p.textMid;
  static Color get textMuted => _p.textMuted;

  // ─── Grafik ────────────────────────────────────────────────────────────────
  static Color get chartNeutral => _p.chartNeutral;

  // Hero kart derinliği
  static Color get heroTop => _p.heroTop;
  static Color get heroGlow => _p.heroGlow;
  static Color get shadow => _p.shadow;

  // Anatomik kas haritası
  static Color get anatomyMuscle => _p.anatomyMuscle;
  static Color get anatomyBase => _p.anatomyBase;

  /// Yığılmış barlarda sıralı payları ayırmak için tek tonlu basamaklar.
  static List<Color> get chartSteps => _p.chartSteps;
}

class AppTheme {
  AppTheme._();

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  static TextStyle _t(TextStyle s) => s.copyWith(fontFeatures: _tabular);

  static ThemeData get darkTheme => themeFor(AppPalette.dark);

  static ThemeData get lightTheme => themeFor(AppPalette.light);

  /// [palette] için ThemeData. [AppColors] aktif paleti okuduğundan önce
  /// palet uygulanır.
  static ThemeData themeFor(AppPalette palette) {
    final previous = AppColors.palette;
    AppColors.apply(palette);
    try {
      return _build(palette);
    } finally {
      AppColors.apply(previous);
    }
  }

  static ThemeData _build(AppPalette palette) {
    final hairlineSide = BorderSide(
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
      brightness: palette.brightness,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.surface,
      splashFactory: InkSparkle.splashFactory,
      colorScheme: ColorScheme(
        brightness: palette.brightness,
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
      iconTheme: IconThemeData(color: AppColors.textMid, size: 20),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textHigh,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: _t(AppText.cardTitle),
        systemOverlayStyle: palette.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        iconTheme: IconThemeData(color: AppColors.textHigh, size: 22),
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
      dividerTheme: DividerThemeData(
        color: AppColors.hairline,
        thickness: AppSpace.hairline,
        space: AppSpace.hairline,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
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
          backgroundColor: AppColors.accent,
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
          side: BorderSide(
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
          borderSide: BorderSide(
            color: AppColors.hairlineStrong,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          borderSide: BorderSide(color: AppColors.danger, width: 1),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
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
      progressIndicatorTheme: ProgressIndicatorThemeData(
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
      listTileTheme: ListTileThemeData(
        iconColor: AppColors.textMid,
        textColor: AppColors.textHigh,
      ),
    );
  }

}
