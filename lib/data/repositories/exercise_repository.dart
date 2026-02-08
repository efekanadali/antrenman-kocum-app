// lib/data/repositories/exercise_repository.dart

// BU DOĞRU SATIRLARI EKLEYİN
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';


/// Defines the contract for fetching exercise data.
///
/// This abstract class acts as an interface that the rest of the application
/// will depend on. It decouples the application from the concrete data source
/// implementation (e.g., fake, API, database).
abstract class ExerciseRepository {
  /// Fetches a list of all available exercises.
  Future<List<Exercise>> getAllExercises();

  /// Fetches exercises filtered by a specific level.
  Future<List<Exercise>> getExercisesByLevel(ExerciseLevel level);

  /// Fetches exercises filtered by a specific primary muscle group.
  Future<List<Exercise>> getExercisesByMuscleGroup(MuscleGroup muscleGroup);

  /// Fetches exercises with a combination of filters.
  ///
  /// Both parameters are optional. If a parameter is null, it's not used for filtering.
  Future<List<Exercise>> getFilteredExercises({
    ExerciseLevel? level,
    MuscleGroup? muscleGroup,
  });
}
