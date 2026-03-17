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
  const WorkoutSet({required this.reps, required this.rir});

  final int reps;
  final int rir;
}

class ExerciseWorkoutEntry {
  const ExerciseWorkoutEntry({required this.exercise, required this.sets});

  final Exercise exercise;
  final List<WorkoutSet> sets;
}
