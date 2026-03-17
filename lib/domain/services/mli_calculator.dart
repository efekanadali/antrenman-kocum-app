import 'package:calisthenics_app/domain/models/mli_models.dart';

/// MLI: set bazli basit yuk metriği.
double calculateMLI({
  required int reps,
  required double difficulty,
  required int rir,
}) {
  return reps * difficulty * (1 + (1 / (rir + 1)));
}

/// Tek bir setin kas bazli dagilimini hesaplar.
Map<String, double> calculateMuscleLoad({
  required Exercise exercise,
  required WorkoutSet set,
}) {
  final mli = calculateMLI(
    reps: set.reps,
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
