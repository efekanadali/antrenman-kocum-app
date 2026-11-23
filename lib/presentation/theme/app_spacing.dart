// lib/presentation/theme/app_spacing.dart

/// 4'lük ızgaraya dayalı boşluk ölçeği.
class AppSpace {
  AppSpace._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double section = 32;

  /// Sayfa yatay kenar boşluğu.
  static const double page = 20;

  /// Kart iç boşluğu (hero kartlarda [xxl]).
  static const double card = 20;

  /// Bölüm ayırıcı çizgi kalınlığı.
  static const double hairline = 0.5;
}

/// Köşe yarıçapları.
class AppRadius {
  AppRadius._();

  static const double card = 16;
  static const double control = 12;
  static const double chip = 6;
  static const double sheet = 24;
}
