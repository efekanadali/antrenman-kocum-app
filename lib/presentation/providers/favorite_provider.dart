// lib/presentation/providers/favorite_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorite_provider.g.dart';

@riverpod
class Favorite extends _$Favorite {
  @override
  Set<String> build() => <String>{};

  void toggle(String exerciseId) {
    state = state.contains(exerciseId)
        ? (Set<String>.from(state)..remove(exerciseId))
        : (Set<String>.from(state)..add(exerciseId));
  }

  // Backwards-compatible API for existing call sites
  void toggleFavorite(String exerciseId) => toggle(exerciseId);

  bool contains(String exerciseId) => state.contains(exerciseId);
}
