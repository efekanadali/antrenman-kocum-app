// lib/presentation/providers/muscle_recovery_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/data/services/firestore_service.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/services/exercise_mli_resolver.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';

/// `users/{uid}/muscle_recovery` koleksiyonunu canlı dinler.
final muscleRecoveryProvider =
    StreamProvider<List<MuscleRecoveryRecord>>((ref) {
  return ref.watch(firestoreServiceProvider).getMuscleRecoveryStream();
});

/// Egzersiz kataloğundan biyomekanik (kaldıraç + kas ağırlığı) çözümleyici.
final exerciseMliResolverProvider =
    FutureProvider<ExerciseMliResolver>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  final exercises = await repository.getAllExercises();
  return ExerciseMliResolver(catalog: exercises);
});
