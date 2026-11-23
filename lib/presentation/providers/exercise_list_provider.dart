// lib/presentation/providers/exercise_list_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/services/muscle_filter.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/providers/filter_provider.dart';

final exerciseListProvider = FutureProvider<List<Exercise>>((ref) async {
  final exerciseRepository = ref.watch(exerciseRepositoryProvider);
  return exerciseRepository.getAllExercises();
});

final filteredExerciseListProvider =
    FutureProvider.autoDispose<List<Exercise>>((ref) async {
  final allExercises = await ref.watch(exerciseListProvider.future);
  final filter = ref.watch(filterStateNotifierProvider);

  if (filter.level == null && !filter.hasMuscleFilter) {
    return allExercises;
  }

  return allExercises.where((exercise) {
    final levelMatch = filter.level == null || exercise.level == filter.level;

    // Seçili bölge / kompartımanlardan HERHANGİ BİRİ hedefleniyor mu?
    final muscleMatch = matchesMuscleFilter(
      exercise.compartmentWeights,
      regions: filter.regions,
      compartments: filter.compartments,
      matchAll: false,
    );

    return levelMatch && muscleMatch;
  }).toList();
});
