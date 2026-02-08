// lib/data/repositories/fake_exercise_repository.dart

// BU DOĞRU SATIRLARI EKLEYİN
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/data/repositories/exercise_repository.dart';


/// A fake implementation of [ExerciseRepository] for development and testing.
///
/// This class returns a hardcoded list of exercises and simulates an async
/// data fetch using `Future.delayed`. This allows the UI to be developed
/// without needing a real backend.
class FakeExerciseRepository implements ExerciseRepository {
  // A static, hardcoded list of exercises. In a real app, this would
  // come from a database or an API.
  static final List<Exercise> _fakeExercises = [
    const Exercise(
      id: 'ex-01',
      name: 'Push Up',
      level: ExerciseLevel.beginner,
      difficulty: DifficultyLevel.medium,
      targetMuscleGroups: [MuscleGroup.chest, MuscleGroup.shoulders],
      description: 'A classic bodyweight exercise for upper body strength.',
    ),
    const Exercise(
      id: 'ex-02',
      name: 'Bodyweight Squat',
      level: ExerciseLevel.beginner,
      difficulty: DifficultyLevel.easy,
      targetMuscleGroups: [MuscleGroup.legs],
      description: 'A fundamental lower body exercise that targets quads and glutes.',
    ),
    const Exercise(
      id: 'ex-03',
      name: 'Plank',
      level: ExerciseLevel.beginner,
      difficulty: DifficultyLevel.medium,
      targetMuscleGroups: [MuscleGroup.core],
      description: 'An isometric core strength exercise.',
    ),
    const Exercise(
      id: 'ex-04',
      name: 'Pull Up',
      level: ExerciseLevel.intermediate,
      difficulty: DifficultyLevel.hard,
      targetMuscleGroups: [MuscleGroup.back],
      description: 'A challenging upper-body exercise for back and biceps.',
    ),
    const Exercise(
      id: 'ex-05',
      name: 'Lunges',
      level: ExerciseLevel.intermediate,
      difficulty: DifficultyLevel.medium,
      targetMuscleGroups: [MuscleGroup.legs],
      description: 'Excellent for targeting each leg individually.',
    ),
    const Exercise(
      id: 'ex-06',
      name: 'Dips',
      level: ExerciseLevel.intermediate,
      difficulty: DifficultyLevel.hard,
      targetMuscleGroups: [MuscleGroup.chest, MuscleGroup.shoulders],
      description: 'Builds powerful chest and triceps. Requires parallel bars.',
    ),
    const Exercise(
      id: 'ex-07',
      name: 'Hanging Leg Raises',
      level: ExerciseLevel.intermediate,
      difficulty: DifficultyLevel.hard,
      targetMuscleGroups: [MuscleGroup.core],
      description: 'An advanced core exercise for lower abs.',
    ),
    const Exercise(
      id: 'ex-08',
      name: 'Pistol Squat',
      level: ExerciseLevel.advanced,
      difficulty: DifficultyLevel.hard,
      targetMuscleGroups: [MuscleGroup.legs],
      description: 'A single-leg squat that requires significant strength and balance.',
    ),
    const Exercise(
      id: 'ex-09',
      name: 'Handstand Push Up',
      level: ExerciseLevel.advanced,
      difficulty: DifficultyLevel.hard,
      targetMuscleGroups: [MuscleGroup.shoulders],
      description: 'An advanced pressing movement for building shoulder strength.',
    ),
    const Exercise(
      id: 'ex-10',
      name: 'Muscle Up',
      level: ExerciseLevel.advanced,
      difficulty: DifficultyLevel.hard,
      targetMuscleGroups: [MuscleGroup.back, MuscleGroup.chest],
      description: 'A combination of a pull-up and a dip.',
    ),
  ];

  /// Simulates a network delay.
  Future<void> _simulateNetworkDelay() {
    return Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<List<Exercise>> getAllExercises() async {
    await _simulateNetworkDelay();
    return _fakeExercises;
  }

  @override
  Future<List<Exercise>> getExercisesByLevel(ExerciseLevel level) async {
    await _simulateNetworkDelay();
    return _fakeExercises.where((ex) => ex.level == level).toList();
  }

  @override
  Future<List<Exercise>> getExercisesByMuscleGroup(MuscleGroup muscleGroup) async {
    await _simulateNetworkDelay();
    return _fakeExercises
        .where((ex) => ex.targetMuscleGroups.contains(muscleGroup))
        .toList();
  }

  @override
  Future<List<Exercise>> getFilteredExercises(
      {ExerciseLevel? level, MuscleGroup? muscleGroup}) async {
    await _simulateNetworkDelay();
    var exercises = _fakeExercises;

    if (level != null) {
      exercises = exercises.where((ex) => ex.level == level).toList();
    }

    if (muscleGroup != null) {
      exercises = exercises
          .where((ex) => ex.targetMuscleGroups.contains(muscleGroup))
          .toList();
    }

    return exercises;
  }
}
