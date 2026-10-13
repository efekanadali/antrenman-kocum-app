// lib/domain/services/exercise_mli_resolver.dart

import 'package:calisthenics_app/core/utils/enum_label.dart';
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/domain/models/exercise.dart' as domain;
import 'package:calisthenics_app/domain/models/exercise_database.dart'
    as library_data;
import 'package:calisthenics_app/domain/models/mli_models.dart' as mli;

/// Bir [CustomProgramExercise] kaydını MLI hesaplamasında kullanılan
/// biyomekanik modele (`leverageFactor`/zorluk katsayısı + kas ağırlıkları)
/// çözümler.
///
/// Çözümleme sırası:
///  1. Egzersiz kataloğundaki detay (id / ad eşleşmesi)
///  2. `exerciseDatabase` kütüphane kaydı
///  3. Ada göre çıkarım (push/pull/squat/core)
class ExerciseMliResolver {
  ExerciseMliResolver({List<domain.Exercise> catalog = const []}) {
    for (final item in catalog) {
      _byId[item.id] = item;
      _byName[item.name] = item;
      _byNormalizedName[_normalize(item.name)] = item;
    }
    for (final entry in library_data.exerciseDatabase.entries) {
      _library[_normalize(entry.key)] = entry.value;
      _library[_normalize(entry.value.name)] = entry.value;
    }
  }

  final Map<String, domain.Exercise> _byId = {};
  final Map<String, domain.Exercise> _byName = {};
  final Map<String, domain.Exercise> _byNormalizedName = {};
  final Map<String, mli.Exercise> _library = {};

  static String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  domain.Exercise? resolveDetail(CustomProgramExercise exercise) {
    return _byId[exercise.exerciseId] ??
        _byName[exercise.exerciseName] ??
        _byNormalizedName[_normalize(exercise.exerciseName)];
  }

  mli.Exercise? _resolveLibrary(CustomProgramExercise exercise) {
    return library_data.exerciseDatabase[exercise.exerciseId] ??
        _library[_normalize(exercise.exerciseId)] ??
        _library[_normalize(exercise.exerciseName)];
  }

  /// MLI hesaplamasında kullanılacak egzersiz modelini üretir.
  mli.Exercise build(
    CustomProgramExercise source, {
    domain.Exercise? detail,
  }) {
    final resolvedDetail = detail ?? resolveDetail(source);
    if (resolvedDetail != null) {
      return _fromDetail(source, resolvedDetail);
    }

    final libraryExercise = _resolveLibrary(source);
    if (libraryExercise != null) {
      return mli.Exercise(
        name: source.exerciseName,
        difficulty: libraryExercise.difficulty,
        muscles: libraryExercise.muscles,
      );
    }

    return _inferFromName(source);
  }

  mli.Exercise _inferFromName(CustomProgramExercise source) {
    final normalized = _normalize(source.exerciseName);

    // omega: Ana kas=1.0, Yardimci=0.5, Stabilizator=0.2
    if (normalized.contains('push') || normalized.contains('dip')) {
      return mli.Exercise(
        name: source.exerciseName,
        difficulty: 1.0,
        muscles: {
          'chest': 1.0,
          'triceps': 0.5,
          'shoulders': 0.5,
          'core': 0.2,
        },
      );
    }

    if (normalized.contains('pull') ||
        normalized.contains('row') ||
        normalized.contains('chin') ||
        normalized.contains('lever')) {
      return mli.Exercise(
        name: source.exerciseName,
        difficulty: 1.0,
        muscles: {
          'back': 1.0,
          'biceps': 0.5,
          'shoulders': 0.5,
          'core': 0.2,
        },
      );
    }

    if (normalized.contains('squat') ||
        normalized.contains('lunge') ||
        normalized.contains('pistol') ||
        normalized.contains('shrimp') ||
        normalized.contains('jump') ||
        normalized.contains('calf') ||
        normalized.contains('bridge') ||
        normalized.contains('curl')) {
      return mli.Exercise(
        name: source.exerciseName,
        difficulty: 1.0,
        muscles: {
          'quads': 1.0,
          'glutes': 0.5,
          'hamstrings': 0.5,
          'calves': 0.2,
        },
      );
    }

    // Genel/core egzersiz
    return mli.Exercise(
      name: source.exerciseName,
      difficulty: 1.0,
      muscles: {'core': 1.0, 'shoulders': 0.5, 'back': 0.5},
    );
  }

  double _difficultyCoefficient(domain.Exercise detail) {
    switch (detail.difficulty) {
      case DifficultyLevel.easy:
        return 1.0;
      case DifficultyLevel.medium:
        return 1.25;
      case DifficultyLevel.hard:
        return 1.5;
    }
  }

  mli.Exercise _fromDetail(
    CustomProgramExercise source,
    domain.Exercise detail,
  ) {
    final muscles = <String, double>{};

    if (detail.muscleRatings.isNotEmpty) {
      // omega ataması: maxRating -> 1.0 (Ana kas)
      //                max/2 ve üstü -> 0.5 (Yardimci kas)
      //                diğerleri     -> 0.2 (Stabilizatör)
      final maxRating =
          detail.muscleRatings.values.fold<int>(0, (m, v) => v > m ? v : m);

      detail.muscleRatings.forEach((group, rating) {
        final double omega;
        if (rating >= maxRating) {
          omega = 1.0;
        } else if (rating * 2 >= maxRating) {
          omega = 0.5;
        } else {
          omega = 0.2;
        }
        muscles[group.label] = omega;
      });
    } else if (detail.targetMuscleGroups.isNotEmpty) {
      // İlk kas birincil (1.0), diğerleri yardimci (0.5)
      final groups = detail.targetMuscleGroups;
      for (var i = 0; i < groups.length; i++) {
        muscles[groups[i].label] = i == 0 ? 1.0 : 0.5;
      }
    }

    return mli.Exercise(
      name: source.exerciseName,
      difficulty: _difficultyCoefficient(detail),
      muscles: muscles,
    );
  }
}
