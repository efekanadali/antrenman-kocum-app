import 'package:calisthenics_app/domain/models/mli_models.dart';

double _dynamicRirFactor(int rir) {
  return 1 + (10 - rir) / 10;
}

double _staticMsirFactor(int secondsInReserve) {
  if (secondsInReserve <= 0) {
    return 1.05;
  }
  if (secondsInReserve <= 3) {
    return 1.0;
  }
  if (secondsInReserve <= 6) {
    return 0.8;
  }
  return 0.6;
}

/// MLI = reps x C x (1 + (10 - RIR) / 10)
///
/// Backward compatibility icin reps parametresi de desteklenir.
double calculateMLI({
  double? volume,
  int? reps,
  required double difficulty,
  required int rir,
  double weightMultiplier = 1.0,
}) {
  final resolvedVolume = volume ?? reps?.toDouble();
  if (resolvedVolume == null) {
    throw ArgumentError('Either volume or reps must be provided.');
  }

  return resolvedVolume *
      difficulty *
      _dynamicRirFactor(rir) *
      weightMultiplier;
}

/// Statik model: (sure / 3) x C x M_SIR
double calculateStaticMLI({
  required int durationInSeconds,
  required double difficulty,
  required int secondsInReserve,
  double weightMultiplier = 1.0,
}) {
  final volume = durationInSeconds / 3.0;
  return volume *
      difficulty *
      _staticMsirFactor(secondsInReserve) *
      weightMultiplier;
}

/// Tek bir setin kas bazli dagilimini hesaplar.
Map<String, double> calculateMuscleLoad({
  required Exercise exercise,
  required WorkoutSet set,
}) {
  final mli = set.durationInSeconds != null
      ? calculateStaticMLI(
          durationInSeconds: set.durationInSeconds!,
          difficulty: exercise.difficulty,
          secondsInReserve: set.rir,
          weightMultiplier: set.weightMultiplier,
        )
      : calculateMLI(
          volume: set.volume,
          difficulty: exercise.difficulty,
          rir: set.rir,
          weightMultiplier: set.weightMultiplier,
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
