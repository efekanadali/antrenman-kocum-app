// lib/domain/models/exercise.dart

// Doğru import'lar:
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_type.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';

/// Represents the core concept of an exercise in the domain.
class Exercise {
  final String id;
  final String name;
  final ExerciseLevel level;
  final DifficultyLevel difficulty;
  final List<MuscleGroup> targetMuscleGroups; // Doğru alan adı ve tipi
  final Map<MuscleGroup, int> muscleRatings;
  final String description;
  final List<String> prerequisiteExercises;

  /// 17 kas kompartımanı üzerindeki ağırlıklar (toplam 1.00; bilinmiyorsa
  /// boş). [muscleRatings] ve [targetMuscleGroups] repository katmanında
  /// buradan türetilir.
  final Map<MuscleCompartment, double> compartmentWeights;

  /// Kalistenik mi, vücut geliştirme mi (MLI formülünü ve kütüphane
  /// sekmesini belirler).
  final ExerciseType type;

  const Exercise({
    required this.id,
    required this.name,
    required this.level,
    required this.difficulty,
    required this.targetMuscleGroups,
    required this.muscleRatings,
    required this.description,
    this.prerequisiteExercises = const <String>[],
    this.compartmentWeights = const <MuscleCompartment, double>{},
    this.type = ExerciseType.calisthenics,
  });
}
