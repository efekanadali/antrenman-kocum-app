// lib/presentation/providers/theme_mode_provider.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _themeModeStorageKey = 'app_theme_mode';

/// Uygulama teması. Varsayılan [ThemeMode.light]; Profil ekranındaki
/// "Koyu Tema" anahtarıyla [ThemeMode.dark]'a geçilir ve seçim
/// `SharedPreferences`'ta saklanır.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  bool _userChanged = false;

  @override
  ThemeMode build() {
    Future.microtask(_loadFromStorage);
    return ThemeMode.light;
  }

  bool get isDark => state == ThemeMode.dark;

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_themeModeStorageKey);
      if (_userChanged) return;
      if (saved == 'dark') state = ThemeMode.dark;
    } catch (_) {
      // Okuma hatası: varsayılan açık tema korunur.
    }
  }

  Future<void> setDark(bool dark) async {
    _userChanged = true;
    state = dark ? ThemeMode.dark : ThemeMode.light;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeStorageKey, dark ? 'dark' : 'light');
    } catch (_) {
      // Yazma hatası: seçim bu oturum için bellekte kalır.
    }
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
