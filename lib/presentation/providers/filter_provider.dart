// lib/presentation/providers/filter_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';

// 1. Filtre durumunu tutan, değişmez (immutable) state sınıfı.
//    Kas filtresi 6 bölge + 17 kompartıman üzerinden çalışır
//    (bkz. domain/services/muscle_filter.dart).
class FilterState {
  final ExerciseLevel? level;
  final Set<MuscleRegion> regions;
  final Set<MuscleCompartment> compartments;

  const FilterState({
    this.level,
    this.regions = const {},
    this.compartments = const {},
  });

  bool get hasMuscleFilter => regions.isNotEmpty || compartments.isNotEmpty;

  FilterState copyWith({
    ValueGetter<ExerciseLevel?>? level,
    Set<MuscleRegion>? regions,
    Set<MuscleCompartment>? compartments,
  }) {
    return FilterState(
      level: level != null ? level() : this.level,
      regions: regions ?? this.regions,
      compartments: compartments ?? this.compartments,
    );
  }
}

// FilterState için provider
final filterStateNotifierProvider =
    StateNotifierProvider<FilterNotifier, FilterState>((ref) {
  return FilterNotifier();
});

class FilterNotifier extends StateNotifier<FilterState> {
  FilterNotifier() : super(const FilterState());

  void setLevel(ExerciseLevel? level) {
    state = state.copyWith(level: () => level);
  }

  void toggleRegion(MuscleRegion region) {
    final regions = Set<MuscleRegion>.from(state.regions);
    final compartments = Set<MuscleCompartment>.from(state.compartments);
    if (!regions.remove(region)) {
      regions.add(region);
    } else {
      compartments.removeWhere((c) => c.region == region);
    }
    state = state.copyWith(regions: regions, compartments: compartments);
  }

  void toggleCompartment(MuscleCompartment compartment) {
    final compartments = Set<MuscleCompartment>.from(state.compartments);
    if (!compartments.remove(compartment)) compartments.add(compartment);
    state = state.copyWith(compartments: compartments);
  }
}
