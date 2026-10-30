// lib/presentation/providers/exercise_list_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
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

  if (filter.level == null && filter.muscleGroups.isEmpty) {
    return allExercises;
  }

  return allExercises.where((exercise) {
    final levelMatch = filter.level == null || exercise.level == filter.level;

    // Egzersizin hedef kas gruplarından HERHANGİ BİRİ,
    // seçili filtre kas gruplarında var mı diye kontrol edilir.
    final muscleGroupMatch = filter.muscleGroups.isEmpty ||
        exercise.targetMuscleGroups
            .any((muscle) => filter.muscleGroups.contains(muscle));

    return levelMatch && muscleGroupMatch;
  }).toList();
});
