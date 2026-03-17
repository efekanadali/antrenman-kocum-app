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
  });

  final int reps;
  final int rir;
  final int? durationInSeconds;

  // Dynamic hareketlerde reps, statik hareketlerde saniye/3 kullanilir.
  double get volume {
    if (durationInSeconds != null) {
      return durationInSeconds! / 3.0;
    }
    return reps.toDouble();
  }
}

class ExerciseWorkoutEntry {
  const ExerciseWorkoutEntry({required this.exercise, required this.sets});

  final Exercise exercise;
  final List<WorkoutSet> sets;
}
