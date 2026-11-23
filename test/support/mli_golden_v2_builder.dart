// test/support/mli_golden_v2_builder.dart
//
// 17 kompartımanlı model için MLI / Recovery golden verisini (v2) üretir.
// `tool/generate_mli_golden.dart` fixture'ı yazar,
// `test/domain/mli_golden_v2_test.dart` fixture ile karşılaştırır.
//
// v1 (test/fixtures/mli_golden_v1.json) göç öncesi modelin DONDURULMUŞ
// tarihsel referansıdır ve artık üretilmez.

import 'package:calisthenics_app/core/utils/exercise_unit.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';
import 'package:calisthenics_app/domain/services/recovery_calculator.dart';

const String kMliGoldenV1FixturePath = 'test/fixtures/mli_golden_v1.json';
const String kMliGoldenV2FixturePath = 'test/fixtures/mli_golden_v2.json';
const int kMliGoldenV2SchemaVersion = 2;

/// Recovery hesaplarında kullanılan sabit tamamlanma zamanı (v1 ile aynı).
final DateTime kGoldenCompletedAt = DateTime.utc(2026, 1, 1, 12);

class GoldenSetVariant {
  const GoldenSetVariant(this.id, this.set);

  final String id;
  final WorkoutSet set;
}

const GoldenSetVariant kDynamicVariant = GoldenSetVariant(
  'reps10_rir2',
  WorkoutSet(reps: 10, rir: 2),
);

const GoldenSetVariant kStaticVariant = GoldenSetVariant(
  'hold30s_sir3',
  WorkoutSet(reps: 0, rir: 3, durationInSeconds: 30),
);

/// Golden JSON'daki `set` alanından [WorkoutSet] oluşturur.
WorkoutSet workoutSetFromJson(Map<String, dynamic> json) => WorkoutSet(
      reps: json['reps'] as int,
      rir: json['rir'] as int,
      durationInSeconds: json['durationInSeconds'] as int?,
    );

/// Bölge → yük haritasında en yüklü bölge(ler). Eşitlikte birden fazla döner.
Set<String> primaryRegions(Map<String, num> regionLoad, {double eps = 1e-9}) {
  if (regionLoad.isEmpty) return const {};
  final maxLoad =
      regionLoad.values.map((v) => v.toDouble()).reduce((a, b) => a > b ? a : b);
  return {
    for (final e in regionLoad.entries)
      if ((e.value - maxLoad).abs() <= eps) e.key,
  };
}

Map<String, double> _byFirestoreKey(Map<MuscleCompartment, double> source) {
  final keys = source.keys.toList()
    ..sort((a, b) => a.firestoreKey.compareTo(b.firestoreKey));
  return {for (final c in keys) c.firestoreKey: source[c]!};
}

Map<String, double> _sorted(Map<String, double> source) {
  final keys = source.keys.toList()..sort();
  return {for (final k in keys) k: source[k]!};
}

Map<String, dynamic> _regionRecoveryJson(
  Map<RecoveryMuscle, MuscleRecoveryRecord> records,
) {
  final names = records.keys.map((m) => m.name).toList()..sort();
  return {
    for (final name in names)
      name: () {
        final r = records.entries.firstWhere((e) => e.key.name == name).value;
        return {
          'recoveryHours': r.recoveryHours,
          'averageRir': r.averageRir,
          'load': r.load,
          'lastTrainedAt': r.lastTrainedAt.toIso8601String(),
        };
      }(),
  };
}

Map<String, dynamic> _buildCase({
  required String exerciseId,
  required Exercise exercise,
  required bool isTimed,
  required GoldenSetVariant variant,
}) {
  final set = variant.set;
  final entries = [
    ExerciseWorkoutEntry(exercise: exercise, sets: [set]),
  ];
  final setMli = calculateSetMli(exercise: exercise, set: set);
  final compartmentLoad = calculateCompartmentLoad(exercise: exercise, set: set);
  final compartmentRir = calculateWorkoutCompartmentRir(entries);
  final regionLoad = {
    for (final e in aggregateToRegions(compartmentLoad).entries)
      e.key.name: e.value,
  };
  final muscleLoad = calculateMuscleLoad(exercise: exercise, set: set);
  final muscleRir = calculateWorkoutMuscleRir(entries);

  final compartmentRecovery = buildCompartmentRecovery(
    compartmentLoad: compartmentLoad,
    compartmentRir: compartmentRir,
    completedAt: kGoldenCompletedAt,
  );
  final compartmentRecoveryKeys = compartmentRecovery.keys.toList()
    ..sort((a, b) => a.firestoreKey.compareTo(b.firestoreKey));

  return {
    'exerciseId': exerciseId,
    'name': exercise.name,
    'difficulty': exercise.difficulty,
    'type': exercise.type.name,
    'isTimed': isTimed,
    'variant': variant.id,
    'set': {
      'reps': set.reps,
      'rir': set.rir,
      'durationInSeconds': set.durationInSeconds,
    },
    'compartments': _byFirestoreKey(exercise.compartments),
    'compartmentWeightSum':
        exercise.compartments.values.fold<double>(0, (a, b) => a + b),
    'setMli': setMli,
    'compartmentLoad': _byFirestoreKey(compartmentLoad),
    'regionLoad': _sorted(regionLoad),
    'primaryRegions': (primaryRegions(regionLoad).toList()..sort()),
    'legacyMuscleLoad': _sorted(muscleLoad),
    'evaluation': {
      for (final e in _sorted(regionLoad).entries)
        e.key: evaluateMuscleLoad(e.value).level.name,
    },
    'compartmentRecovery': {
      for (final c in compartmentRecoveryKeys)
        c.firestoreKey: {
          'recoveryHours': compartmentRecovery[c]!.recoveryHours,
          'averageRir': compartmentRecovery[c]!.averageRir,
          'load': compartmentRecovery[c]!.load,
        },
    },
    // Kompartıman verisi doğrudan verildiğinde (en doğru yol).
    'regionRecovery': _regionRecoveryJson(
      buildSessionRecovery(
        muscleLoad: muscleLoad,
        muscleRir: muscleRir,
        completedAt: kGoldenCompletedAt,
        compartmentLoad: compartmentLoad,
        compartmentRir: compartmentRir,
      ),
    ),
    // Uygulamanın bugün kullandığı yol: yalnızca eski bölge anahtarları
    // (kompartımanlara kLegacyRegionSplit ile bölünür).
    'regionRecoveryFromLegacyKeys': _regionRecoveryJson(
      buildSessionRecovery(
        muscleLoad: muscleLoad,
        muscleRir: muscleRir,
        completedAt: kGoldenCompletedAt,
      ),
    ),
  };
}

/// Mevcut koddan tüm v2 golden verisini hesaplar.
Map<String, dynamic> buildMliGoldenV2() {
  final ids = exerciseDatabase.keys.toList()..sort();
  final cases = <Map<String, dynamic>>[];
  for (final id in ids) {
    final exercise = exerciseDatabase[id]!;
    final isTimed = isTimedExercise(exerciseName: exercise.name, exerciseId: id);
    cases.add(_buildCase(
      exerciseId: id,
      exercise: exercise,
      isTimed: isTimed,
      variant: kDynamicVariant,
    ));
    if (isTimed) {
      cases.add(_buildCase(
        exerciseId: id,
        exercise: exercise,
        isTimed: isTimed,
        variant: kStaticVariant,
      ));
    }
  }

  return {
    'schemaVersion': kMliGoldenV2SchemaVersion,
    'description':
        'Golden reference of the 17-compartment model: set MLI, compartment / '
            'region load, stimulus evaluation and compartment / region '
            'recovery per exercise.',
    'completedAt': kGoldenCompletedAt.toIso8601String(),
    'thresholds': {
      'understimulated': kMliUnderstimulatedThreshold,
      'overload': kMliOverloadThreshold,
      'calibrationScale': kMliCalibrationScale,
    },
    'recoverySizeFactors': {
      for (final c in MuscleCompartment.values)
        c.firestoreKey: c.recoverySizeFactor,
    },
    'exerciseCount': exerciseDatabase.length,
    'exerciseIds': ids,
    'cases': cases,
  };
}
