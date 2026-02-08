// lib/domain/models/exercise.dart

// Doğru import'lar:
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';

/// Represents the core concept of an exercise in the domain.
class Exercise {
  final String id;
  final String name;
  final ExerciseLevel level;
  final DifficultyLevel difficulty;
  final List<MuscleGroup> targetMuscleGroups; // Doğru alan adı ve tipi
  final String description;

  const Exercise({
    required this.id,
    required this.name,
    required this.level,
    required this.difficulty,
    required this.targetMuscleGroups,
    required this.description,
  });
}
