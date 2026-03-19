class Exercise {
  const Exercise({
    required this.name,
    required this.difficulty,
    required this.muscles,
  });

  final String name;
  final double difficulty;
  final Map<String, double> muscles;
}

class WorkoutSet {
  const WorkoutSet({
    required this.reps,
    required this.rir,
    this.durationInSeconds,
    this.extraWeightKg = 0,
    this.bodyWeightKg,
  });

  final int reps;
  final int rir;
  final int? durationInSeconds;
  final double extraWeightKg;
  final double? bodyWeightKg;

  // Dynamic hareketlerde reps, statik hareketlerde saniye/3 kullanilir.
  double get volume {
    if (durationInSeconds != null) {
      return durationInSeconds! / 3.0;
    }
    return reps.toDouble();
  }

  /// W_m = 1 + (ekstra agirlik / vucut agirligi)
  double get weightMultiplier {
    if (extraWeightKg <= 0) {
      return 1.0;
    }
    final bw = bodyWeightKg;
    if (bw == null || bw <= 0) {
      return 1.0;
    }
    return 1.0 + (extraWeightKg / bw);
  }
}

class ExerciseWorkoutEntry {
  const ExerciseWorkoutEntry({required this.exercise, required this.sets});

  final Exercise exercise;
  final List<WorkoutSet> sets;
}
