// lib/data/repositories/firestore_exercise_repository.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/data/repositories/exercise_repository.dart';
import 'package:calisthenics_app/data/repositories/fake_exercise_repository.dart';

/// Firestore implementation of [ExerciseRepository].
///
/// Fetches exercise data from the 'exercises' collection in Cloud Firestore.
/// Converts raw document fields (id, name, difficulty, leverageFactor, muscles, etc.)
/// into domain [Exercise] entities.
///
/// If network is down, Firestore returns empty, or any error occurs,
/// it safely falls back to [FakeExerciseRepository] and in-memory cache.
class FirestoreExerciseRepository implements ExerciseRepository {
  final FirebaseFirestore _firestore;
  final FakeExerciseRepository _fallbackRepository;
  List<Exercise>? _cachedExercises;

  FirestoreExerciseRepository({
    FirebaseFirestore? firestore,
    FakeExerciseRepository? fallbackRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _fallbackRepository = fallbackRepository ?? FakeExerciseRepository();

  @override
  Future<List<Exercise>> getAllExercises() async {
    try {
      final snapshot = await _firestore.collection('exercises').get();
      if (snapshot.docs.isEmpty) {
        return await _fallbackRepository.getAllExercises();
      }

      final exercises = snapshot.docs.map((doc) {
        return _mapDocToExercise(doc.id, doc.data());
      }).toList();

      if (exercises.isEmpty) {
        return await _fallbackRepository.getAllExercises();
      }

      _cachedExercises = exercises;
      return exercises;
    } catch (_) {
      // Ağ hatası veya istisna durumunda bellek önbelleği veya Fake repository fallback
      if (_cachedExercises != null && _cachedExercises!.isNotEmpty) {
        return _cachedExercises!;
      }
      return await _fallbackRepository.getAllExercises();
    }
  }

  @override
  Future<List<Exercise>> getExercisesByLevel(ExerciseLevel level) async {
    try {
      final exercises = await getAllExercises();
      return exercises.where((ex) => ex.level == level).toList();
    } catch (_) {
      return await _fallbackRepository.getExercisesByLevel(level);
    }
  }

  @override
  Future<List<Exercise>> getExercisesByMuscleGroup(
    MuscleGroup muscleGroup,
  ) async {
    try {
      final exercises = await getAllExercises();
      return exercises
          .where((ex) => ex.targetMuscleGroups.contains(muscleGroup))
          .toList();
    } catch (_) {
      return await _fallbackRepository.getExercisesByMuscleGroup(muscleGroup);
    }
  }

  @override
  Future<List<Exercise>> getFilteredExercises({
    ExerciseLevel? level,
    MuscleGroup? muscleGroup,
  }) async {
    try {
      var exercises = await getAllExercises();

      if (level != null) {
        exercises = exercises.where((ex) => ex.level == level).toList();
      }

      if (muscleGroup != null) {
        exercises = exercises
            .where((ex) => ex.targetMuscleGroups.contains(muscleGroup))
            .toList();
      }

      return exercises;
    } catch (_) {
      return await _fallbackRepository.getFilteredExercises(
        level: level,
        muscleGroup: muscleGroup,
      );
    }
  }

  /// Converts Firestore document data into domain [Exercise] entity.
  Exercise _mapDocToExercise(String docId, Map<String, dynamic> data) {
    final id = (data['id'] as String?)?.isNotEmpty == true
        ? data['id'] as String
        : docId;

    final name = (data['name'] as String?)?.isNotEmpty == true
        ? data['name'] as String
        : docId;

    // Difficulty & Level conversion
    final difficultyRaw = data['difficulty'];
    final leverageRaw = data['leverageFactor'];
    final double coeff = (difficultyRaw is num)
        ? difficultyRaw.toDouble()
        : (leverageRaw is num)
            ? leverageRaw.toDouble()
            : 1.0;

    final DifficultyLevel difficulty = _parseDifficulty(difficultyRaw, coeff);
    final ExerciseLevel level = _parseLevel(data['level'], coeff);

    // Muscles & Ratings
    final ratings = <MuscleGroup, int>{};
    final targetMuscles = <MuscleGroup>[];

    final musclesRaw = data['muscles'];
    if (musclesRaw is Map) {
      musclesRaw.forEach((key, val) {
        final group = FakeExerciseRepository.muscleFromKey(key.toString());
        if (group != null) {
          final double numVal = (val is num) ? val.toDouble() : 0.0;
          final rating = (numVal > 1.0)
              ? numVal.round().clamp(0, 5)
              : (numVal * 5).round().clamp(0, 5);
          ratings[group] = rating;
          if (rating > 0 && !targetMuscles.contains(group)) {
            targetMuscles.add(group);
          }
        }
      });
    }

    // Explicit targetMuscleGroups if present
    final explicitTargetMuscles = data['targetMuscleGroups'];
    if (explicitTargetMuscles is List) {
      for (final item in explicitTargetMuscles) {
        final group = FakeExerciseRepository.muscleFromKey(item.toString());
        if (group != null && !targetMuscles.contains(group)) {
          targetMuscles.add(group);
        }
      }
    }

    // Description fallback
    final description = (data['description'] as String?)?.isNotEmpty == true
        ? data['description'] as String
        : (FakeExerciseRepository.exerciseDescriptions[id] ??
            '$name hareketi icin kas aktivasyon dagilimi.');

    // Prerequisites fallback
    List<String> prerequisites = const [];
    final prereqRaw = data['prerequisiteExercises'];
    if (prereqRaw is List) {
      prerequisites = prereqRaw.map((e) => e.toString()).toList();
    } else {
      prerequisites = FakeExerciseRepository.buildPrerequisites(
        id: id,
        level: level,
      );
    }

    return Exercise(
      id: id,
      name: name,
      level: level,
      difficulty: difficulty,
      targetMuscleGroups: targetMuscles,
      muscleRatings: ratings,
      description: description,
      prerequisiteExercises: prerequisites,
    );
  }

  DifficultyLevel _parseDifficulty(dynamic raw, double coeff) {
    if (raw is String) {
      for (final value in DifficultyLevel.values) {
        if (value.name.toLowerCase() == raw.toLowerCase()) {
          return value;
        }
      }
    }
    return FakeExerciseRepository.difficultyFromCoefficient(coeff);
  }

  ExerciseLevel _parseLevel(dynamic raw, double coeff) {
    if (raw is String) {
      for (final value in ExerciseLevel.values) {
        if (value.name.toLowerCase() == raw.toLowerCase()) {
          return value;
        }
      }
    }
    return FakeExerciseRepository.levelFromCoefficient(coeff);
  }
}
