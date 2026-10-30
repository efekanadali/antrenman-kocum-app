// lib/presentation/providers/favorite_provider.dart

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'favorite_provider.g.dart';

const _favoritesStorageKey = 'favorite_exercise_ids';

@Riverpod(keepAlive: true)
class Favorite extends _$Favorite {
  bool _loaded = false;

  @override
  Set<String> build() {
    _loaded = false;
    Future.microtask(_loadFromStorage);
    return <String>{};
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_favoritesStorageKey);
      if (saved != null && !_loaded) {
        _loaded = true;
        state = {...saved, ...state};
      }
    } catch (_) {
      // Yerel depolama okuma hatası: mevcut bellek içi durum korunur.
    }
  }

  Future<void> _saveToStorage(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _favoritesStorageKey,
        ids.toList(growable: false),
      );
    } catch (_) {
      // Yerel depolama yazma hatası: bellek içi durum güncel kalır.
    }
  }

  Future<void> toggle(String exerciseId) async {
    _loaded = true;
    final updated = state.contains(exerciseId)
        ? (Set<String>.from(state)..remove(exerciseId))
        : (Set<String>.from(state)..add(exerciseId));
    state = updated;
    await _saveToStorage(updated);
  }

  // Backwards-compatible API for existing call sites
  Future<void> toggleFavorite(String exerciseId) => toggle(exerciseId);

  bool contains(String exerciseId) => state.contains(exerciseId);
}
