import 'package:calisthenics_app/domain/models/mli_models.dart';

/// MLI = reps x C x (1 + (10 - RIR) / 10)
///
/// Backward compatibility icin reps parametresi de desteklenir.
double calculateMLI({
  double? volume,
  int? reps,
  required double difficulty,
  required int rir,
}) {
  final resolvedVolume = volume ?? reps?.toDouble();
  if (resolvedVolume == null) {
    throw ArgumentError('Either volume or reps must be provided.');
  }

  final rirFactor = 1 + (10 - rir) / 10;
  return resolvedVolume * difficulty * rirFactor;
}

/// Tek bir setin kas bazli dagilimini hesaplar.
Map<String, double> calculateMuscleLoad({
  required Exercise exercise,
  required WorkoutSet set,
}) {
  final mli = calculateMLI(
    volume: set.volume,
    difficulty: exercise.difficulty,
    rir: set.rir,
  );

  final result = <String, double>{};
  exercise.muscles.forEach((muscleName, weight) {
    result[muscleName] = mli * weight;
  });
  return result;
}

/// Tum antrenmandaki setleri kas bazinda toplar.
Map<String, double> calculateWorkoutLoad(List<ExerciseWorkoutEntry> entries) {
  final totals = <String, double>{};

  for (final entry in entries) {
    for (final set in entry.sets) {
      final setLoad = calculateMuscleLoad(exercise: entry.exercise, set: set);
      setLoad.forEach((muscleName, value) {
        totals[muscleName] = (totals[muscleName] ?? 0) + value;
      });
    }
  }

  return totals;
}
