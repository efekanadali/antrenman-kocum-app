// lib/domain/services/exercise_mli_resolver.dart

import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_type.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/domain/models/exercise.dart' as domain;
import 'package:calisthenics_app/domain/models/exercise_database.dart'
    as library_data;
import 'package:calisthenics_app/domain/models/mli_models.dart' as mli;
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';

/// Bir [CustomProgramExercise] kaydını MLI hesaplamasında kullanılan
/// biyomekanik modele (`leverageFactor`/zorluk katsayısı + kas ağırlıkları)
/// çözümler.
///
/// Çözümleme sırası:
///  1. Egzersiz kataloğundaki detay (id / ad eşleşmesi)
///  2. `exerciseCatalog` kütüphane kaydı (80 hareket)
///  3. Ada göre çıkarım (push/pull/squat/core)
class ExerciseMliResolver {
  ExerciseMliResolver({List<domain.Exercise> catalog = const []}) {
    for (final item in catalog) {
      _byId[item.id] = item;
      _byName[item.name] = item;
      _byNormalizedName[_normalize(item.name)] = item;
    }
    for (final entry in library_data.exerciseCatalog.entries) {
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
    return library_data.exerciseCatalog[exercise.exerciseId] ??
        _library[_normalize(exercise.exerciseId)] ??
        _library[_normalize(exercise.exerciseName)];
  }

  /// MLI hesaplamasında kullanılacak egzersiz modelini üretir.
  mli.Exercise build(
    CustomProgramExercise source, {
    domain.Exercise? detail,
  }) {
    final libraryExercise = _resolveLibrary(source);
    final resolvedDetail = detail ?? resolveDetail(source);
    if (resolvedDetail != null) {
      return _fromDetail(
        source,
        resolvedDetail,
        libraryFallback: libraryExercise,
      );
    }

    if (libraryExercise != null) {
      return mli.Exercise(
        name: source.exerciseName,
        difficulty: libraryExercise.difficulty,
        compartments: libraryExercise.compartments,
        type: libraryExercise.type,
      );
    }

    return _inferFromName(source);
  }

  static mli.Exercise _template(
    String name,
    Map<MuscleCompartment, double> compartments,
  ) {
    return mli.Exercise(name: name, difficulty: 1.0, compartments: compartments);
  }

  /// Kütüphanede bulunmayan hareketler için ada göre 17 kompartımanlı şablon
  /// (her şablonun toplamı 1.00).
  mli.Exercise _inferFromName(CustomProgramExercise source) {
    final normalized = _normalize(source.exerciseName);

    if (normalized.contains('push') || normalized.contains('dip')) {
      // Yatay/dikey itiş: standart şınav dağılımı.
      return _template(source.exerciseName, const {
        MuscleCompartment.midChest: 0.35,
        MuscleCompartment.upperChest: 0.10,
        MuscleCompartment.lowerChest: 0.10,
        MuscleCompartment.triceps: 0.20,
        MuscleCompartment.anteriorDeltoid: 0.15,
        MuscleCompartment.core: 0.10,
      });
    }

    if (normalized.contains('pull') ||
        normalized.contains('row') ||
        normalized.contains('chin') ||
        normalized.contains('lever')) {
      // Çekiş: standart barfiks dağılımı.
      return _template(source.exerciseName, const {
        MuscleCompartment.lats: 0.40,
        MuscleCompartment.upperBackTraps: 0.10,
        MuscleCompartment.biceps: 0.20,
        MuscleCompartment.forearms: 0.08,
        MuscleCompartment.posteriorDeltoid: 0.10,
        MuscleCompartment.core: 0.12,
      });
    }

    if (normalized.contains('squat') ||
        normalized.contains('lunge') ||
        normalized.contains('pistol') ||
        normalized.contains('shrimp') ||
        normalized.contains('jump') ||
        normalized.contains('calf') ||
        normalized.contains('bridge') ||
        normalized.contains('curl')) {
      // Bacak: standart squat dağılımı.
      return _template(source.exerciseName, const {
        MuscleCompartment.quads: 0.50,
        MuscleCompartment.glutes: 0.25,
        MuscleCompartment.hamstrings: 0.08,
        MuscleCompartment.calves: 0.05,
        MuscleCompartment.lowerBack: 0.05,
        MuscleCompartment.core: 0.07,
      });
    }

    // Genel/core egzersiz
    return _template(source.exerciseName, const {
      MuscleCompartment.core: 0.60,
      MuscleCompartment.anteriorDeltoid: 0.15,
      MuscleCompartment.lats: 0.10,
      MuscleCompartment.lowerBack: 0.15,
    });
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
    domain.Exercise detail, {
    mli.Exercise? libraryFallback,
  }) {
    var compartments = normalizeCompartmentWeights(detail.compartmentWeights);

    if (compartments.isEmpty && detail.muscleRatings.isNotEmpty) {
      // omega ataması: maxRating -> 1.0 (Ana kas)
      //                max/2 ve üstü -> 0.5 (Yardimci kas)
      //                diğerleri     -> 0.2 (Stabilizatör)
      // Ardından kompartımanlara bölünüp toplam 1.00'a normalize edilir.
      final maxRating =
          detail.muscleRatings.values.fold<int>(0, (m, v) => v > m ? v : m);
      final omegas = <String, double>{};
      detail.muscleRatings.forEach((group, rating) {
        final double omega;
        if (rating >= maxRating) {
          omega = 1.0;
        } else if (rating * 2 >= maxRating) {
          omega = 0.5;
        } else {
          omega = 0.2;
        }
        omegas[group.name] = omega;
      });
      compartments = compartmentWeightsFromLegacy(omegas);
    }

    if (compartments.isEmpty && detail.targetMuscleGroups.isNotEmpty) {
      // İlk kas birincil (1.0), diğerleri yardimci (0.5); toplam 1.00'a normalize.
      final groups = detail.targetMuscleGroups;
      final omegas = <String, double>{};
      for (var i = 0; i < groups.length; i++) {
        omegas[groups[i].name] = i == 0 ? 1.0 : 0.5;
      }
      compartments = compartmentWeightsFromLegacy(omegas);
    }

    final resolvedLibrary =
        libraryFallback ??
        library_data.exerciseCatalog[detail.id] ??
        _library[_normalize(detail.id)] ??
        _library[_normalize(detail.name)];

    if (compartments.isEmpty && resolvedLibrary != null) {
      compartments = resolvedLibrary.compartments;
    }
    if (compartments.isEmpty) {
      compartments = _inferFromName(source).compartments;
    }

    final leverageFactor =
        resolvedLibrary?.difficulty ?? _difficultyCoefficient(detail);

    return mli.Exercise(
      name: source.exerciseName,
      difficulty: leverageFactor,
      compartments: compartments,
      type: resolvedLibrary?.type ?? ExerciseType.calisthenics,
    );
  }
}
