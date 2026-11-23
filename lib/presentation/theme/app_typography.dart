// lib/presentation/theme/app_typography.dart

import 'package:flutter/painting.dart';

import 'package:calisthenics_app/presentation/theme/app_theme.dart';

/// Tipografi ölçeği. Sistem fontu (Roboto / SF Pro) kullanılır.
///
/// Sayısal metrikler her zaman [tabular] rakamlarla yazılır; böylece değer
/// değiştikçe genişlik oynamaz.
class AppText {
  AppText._();

  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Ekran başlığı: 28 / SemiBold / -0.5.
  static TextStyle get pageTitle => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    height: 1.15,
    color: AppColors.textHigh,
    fontFeatures: tabular,
  );

  /// Bölüm etiketi: 11 / büyük harf / 1.2 aralık / soluk gri.
  /// Metni çağıran taraf büyük harfe çevirir.
  static TextStyle get sectionLabel => TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.2,
    height: 1.3,
    color: AppColors.textMuted,
    fontFeatures: tabular,
  );

  static TextStyle get cardTitle => TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.25,
    color: AppColors.textHigh,
    fontFeatures: tabular,
  );

  static TextStyle get body => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textHigh,
    fontFeatures: tabular,
  );

  static TextStyle get bodyMuted => TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.textMid,
    fontFeatures: tabular,
  );

  static TextStyle get caption => TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.textMuted,
    fontFeatures: tabular,
  );

  static TextStyle get button => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    fontFeatures: tabular,
  );

  // ─── Metrikler (hepsi tabular) ─────────────────────────────────────────────
  static TextStyle get metricXL => TextStyle(
    fontSize: 44,
    fontWeight: FontWeight.w600,
    letterSpacing: -1.0,
    height: 1.05,
    color: AppColors.textHigh,
    fontFeatures: tabular,
  );

  static TextStyle get metricL => TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.6,
    height: 1.1,
    color: AppColors.textHigh,
    fontFeatures: tabular,
  );

  static TextStyle get metricM => TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.3,
    height: 1.15,
    color: AppColors.textHigh,
    fontFeatures: tabular,
  );

  static TextStyle get metricS => TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    color: AppColors.textHigh,
    fontFeatures: tabular,
  );

  /// Değerin yanındaki birim ("MLI", "sa", "%").
  static TextStyle get unit => TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textMid,
    fontFeatures: tabular,
  );
}

/// Türkçe kurallara uygun büyük harf dönüşümü (i → İ, ı → I).
String trUpper(String text) =>
    text.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
