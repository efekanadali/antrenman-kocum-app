import 'package:calisthenics_app/domain/models/mli_models.dart';

double _rirMultiplier(int rir) {
  if (rir <= 0) {
    return 1.05;
  }
  if (rir == 1) {
    return 1.0;
  }
  if (rir == 2) {
    return 0.9;
  }
  if (rir == 3) {
    return 0.8;
  }
  if (rir == 4) {
    return 0.6;
  }
  return 0.3;
}

/// MLI = volume x difficulty x RIR_multiplier
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

  return resolvedVolume * difficulty * _rirMultiplier(rir);
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
