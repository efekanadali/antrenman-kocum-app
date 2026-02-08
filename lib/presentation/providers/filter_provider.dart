// lib/presentation/providers/filter_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';

import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';

// 1. Filtre durumunu tutan, değişmez (immutable) state sınıfı.
class FilterState {
  final ExerciseLevel? level;
  final Set<MuscleGroup> muscleGroups;

  const FilterState({this.level, this.muscleGroups = const {}});

  FilterState copyWith({
    ValueGetter<ExerciseLevel?>? level,
    Set<MuscleGroup>? muscleGroups,
  }) {
    return FilterState(
      level: level != null ? level() : this.level,
      muscleGroups: muscleGroups ?? this.muscleGroups,
    );
  }
}

// FilterState için provider ekleyin
final filterStateNotifierProvider = StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});

// StateNotifier sınıfı ekleyin (FilterState'i yönetmek için)
class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void setLevel(ExerciseLevel? level) {
    state = state.copyWith(level: () => level);
  }

  void toggleMuscleGroup(MuscleGroup muscleGroup) {
    final newGroups = Set<MuscleGroup>.from(state.muscleGroups);
    if (newGroups.contains(muscleGroup)) {
      newGroups.remove(muscleGroup);
    } else {
      newGroups.add(muscleGroup);
    }
    state = state.copyWith(muscleGroups: newGroups);
  }
}