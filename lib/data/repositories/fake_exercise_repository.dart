// lib/data/repositories/fake_exercise_repository.dart

// BU DOĞRU SATIRLARI EKLEYİN
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart' as mli;
import 'package:calisthenics_app/data/repositories/exercise_repository.dart';

/// A fake implementation of [ExerciseRepository] for development and testing.
///
/// This class returns a hardcoded list of exercises and simulates an async
/// data fetch using `Future.delayed`. This allows the UI to be developed
/// without needing a real backend.
class FakeExerciseRepository implements ExerciseRepository {
  static final List<Exercise> _fakeExercises = exerciseDatabase.entries
      .map((entry) => _toDomainExercise(entry.key, entry.value))
      .toList();

  static const Map<String, List<String>> _prerequisiteExerciseIds = {
    'standard_push_up': ['incline_push_up', 'knee_push_up'],
    'wide_push_up': ['standard_push_up'],
    'diamond_push_up': ['knee_push_up', 'standard_push_up'],
    'decline_push_up': ['standard_push_up', 'pike_push_up'],
    'pike_push_up': ['decline_push_up', 'dips_parallel_bar'],
    'dips_parallel_bar': ['standard_push_up', 'diamond_push_up'],
    'pseudo_planche_push_up': ['pike_push_up', 'dips_parallel_bar'],
    'handstand_push_up': ['pike_push_up', 'pseudo_planche_push_up'],
    '90_degree_push_up': ['handstand_push_up', 'pseudo_planche_push_up'],
    'standard_pull_up': ['australian_row', 'chin_up_hold_top'],
    'chin_up': ['australian_row', 'chin_up_hold_top'],
    'wide_grip_pull_up': ['standard_pull_up', 'pull_up_hold_top'],
    'archer_pull_up': ['wide_grip_pull_up', 'chin_up'],
    'muscle_up': ['standard_pull_up', 'dips_parallel_bar', 'archer_pull_up'],
    'front_lever_raise': ['tuck_front_lever', 'pull_up_hold_top'],
    'one_arm_pull_up': ['archer_pull_up', 'front_lever_raise'],
    'standard_squat': ['wall_sit', 'glute_bridge'],
    'lunge': ['standard_squat', 'wall_sit'],
    'bulgarian_split_squat': ['standard_squat', 'lunge'],
    'box_jump': ['standard_squat', 'calf_raise'],
    'nordic_curl': ['glute_bridge', 'lunge'],
    'pistol_squat': ['bulgarian_split_squat', 'box_jump'],
    'shrimp_squat': ['bulgarian_split_squat', 'lunge'],
    'chin_up_hold_top': ['australian_row'],
    'pull_up_hold_top': ['australian_row', 'chin_up_hold_top'],
    'l_sit_hold': ['plank', 'support_hold_parallel_bar'],
    'tuck_front_lever': ['pull_up_hold_top', 'hollow_body_hold'],
    'tuck_planche': ['support_hold_parallel_bar', 'pike_push_up'],
  };

  static Exercise _toDomainExercise(String id, mli.Exercise source) {
    final ratings = <MuscleGroup, int>{};
    final targetMuscles = <MuscleGroup>[];
    final level = _levelFromCoefficient(source.difficulty);

    source.muscles.forEach((key, value) {
      final group = _muscleFromKey(key);
      if (group == null) {
        return;
      }

      final rating = (value * 5).round().clamp(0, 5);
      ratings[group] = rating;
      if (!targetMuscles.contains(group)) {
        targetMuscles.add(group);
      }
    });

    return Exercise(
      id: id,
      name: source.name,
      level: level,
      difficulty: _difficultyFromCoefficient(source.difficulty),
      targetMuscleGroups: targetMuscles,
      muscleRatings: ratings,
      description: '${source.name} hareketi icin kas aktivasyon dagilimi.',
      prerequisiteExercises: _buildPrerequisites(id: id, level: level),
    );
  }

  static List<String> _buildPrerequisites({
    required String id,
    required ExerciseLevel level,
  }) {
    if (level == ExerciseLevel.beginner) {
      return const <String>[];
    }

    final prerequisiteNames = (_prerequisiteExerciseIds[id] ?? const <String>[])
        .map((exerciseId) => exerciseDatabase[exerciseId]?.name)
        .whereType<String>()
        .toList();

    if (prerequisiteNames.isEmpty) {
      return const <String>[
        'Standard Push-up',
        'Standard Pull-up',
        'Standard Squat',
      ];
    }

    return prerequisiteNames;
  }

  static MuscleGroup? _muscleFromKey(String key) {
    switch (key) {
      case 'chest':
        return MuscleGroup.chest;
      case 'back':
        return MuscleGroup.back;
      case 'shoulders':
        return MuscleGroup.shoulders;
      case 'rear_shoulders':
        return MuscleGroup.shoulders;
      case 'biceps':
        return MuscleGroup.biceps;
      case 'triceps':
        return MuscleGroup.triceps;
      case 'core':
        return MuscleGroup.core;
      case 'quads':
        return MuscleGroup.quads;
      case 'hamstrings':
        return MuscleGroup.hamstrings;
      case 'glutes':
        return MuscleGroup.glutes;
      case 'calves':
        return MuscleGroup.calves;
      default:
        return null;
    }
  }

  static DifficultyLevel _difficultyFromCoefficient(double coefficient) {
    if (coefficient < 1.0) {
      return DifficultyLevel.easy;
    }
    if (coefficient < 2.0) {
      return DifficultyLevel.medium;
    }
    return DifficultyLevel.hard;
  }

  static ExerciseLevel _levelFromCoefficient(double coefficient) {
    if (coefficient < 1.0) {
      return ExerciseLevel.beginner;
    }
    if (coefficient < 2.5) {
      return ExerciseLevel.intermediate;
    }
    return ExerciseLevel.advanced;
  }

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
  Future<List<Exercise>> getExercisesByMuscleGroup(
    MuscleGroup muscleGroup,
  ) async {
    await _simulateNetworkDelay();
    return _fakeExercises
        .where((ex) => ex.targetMuscleGroups.contains(muscleGroup))
        .toList();
  }

  @override
  Future<List<Exercise>> getFilteredExercises({
    ExerciseLevel? level,
    MuscleGroup? muscleGroup,
  }) async {
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
