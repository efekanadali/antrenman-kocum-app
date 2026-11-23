// test/support/mli_golden_builder.dart
//
// MLI / Recovery "golden" referans verisini üretir. Hem
// `tool/generate_mli_golden.dart` (fixture yazar) hem de
// `test/domain/mli_golden_test.dart` (fixture ile karşılaştırır) bu dosyayı
// kullanır. Sadece saf Dart domain koduna bağlıdır (Flutter gerektirmez).

import 'package:calisthenics_app/core/utils/exercise_unit.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/domain/services/recovery_calculator.dart';

/// Fixture dosyasının proje köküne göre yolu.
const String kMliGoldenFixturePath = 'test/fixtures/mli_golden_v1.json';

/// Fixture şema sürümü.
const int kMliGoldenSchemaVersion = 1;

/// Recovery hesaplarında kullanılan sabit tamamlanma zamanı.
final DateTime kGoldenCompletedAt = DateTime.utc(2026, 1, 1, 12);

/// Golden senaryolarındaki set varyantları.
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

Map<String, double> _sortedMap(Map<String, double> source) {
  final keys = source.keys.toList()..sort();
  return {for (final k in keys) k: source[k]!};
}

Map<String, dynamic> _buildCase({
  required String exerciseId,
  required Exercise exercise,
  required bool isTimed,
  required GoldenSetVariant variant,
}) {
  final set = variant.set;
  final setMli = calculateSetMli(exercise: exercise, set: set);
  final muscleLoad = calculateMuscleLoad(exercise: exercise, set: set);
  final entries = [
    ExerciseWorkoutEntry(exercise: exercise, sets: [set]),
  ];
  final muscleRir = calculateWorkoutMuscleRir(entries);

  final regionLoad = <String, double>{};
  var unmappedLoad = 0.0;
  muscleLoad.forEach((key, load) {
    final region = recoveryMuscleFromKey(key);
    if (region == null) {
      unmappedLoad += load;
    } else {
      regionLoad[region.name] = (regionLoad[region.name] ?? 0) + load;
    }
  });

  final recovery = buildSessionRecovery(
    muscleLoad: muscleLoad,
    muscleRir: muscleRir,
    completedAt: kGoldenCompletedAt,
  );
  final recoveryJson = <String, dynamic>{};
  final regionNames = recovery.keys.map((m) => m.name).toList()..sort();
  for (final name in regionNames) {
    final record = recovery.entries.firstWhere((e) => e.key.name == name).value;
    recoveryJson[name] = {
      'recoveryHours': record.recoveryHours,
      'averageRir': record.averageRir,
      'load': record.load,
      'lastTrainedAt': record.lastTrainedAt.toIso8601String(),
    };
  }

  return {
    'exerciseId': exerciseId,
    'name': exercise.name,
    'difficulty': exercise.difficulty,
    'isTimed': isTimed,
    'variant': variant.id,
    'set': {
      'reps': set.reps,
      'rir': set.rir,
      'durationInSeconds': set.durationInSeconds,
    },
    'muscles': _sortedMap(exercise.muscles),
    'muscleWeightSum': exercise.muscles.values.fold<double>(0, (a, b) => a + b),
    'setMli': setMli,
    'muscleLoad': _sortedMap(muscleLoad),
    'muscleLoadSum': muscleLoad.values.fold<double>(0, (a, b) => a + b),
    'muscleRir': _sortedMap(muscleRir),
    'regionLoad': _sortedMap(regionLoad),
    'unmappedLoad': unmappedLoad,
    'recovery': recoveryJson,
  };
}

/// Mevcut koddan tüm golden verisini hesaplar.
///
/// Her egzersiz için `reps: 10, rir: 2` dinamik varyantı; süreli (izometrik)
/// egzersizler için ek olarak `30 sn, SIR 3` statik varyantı üretilir.
Map<String, dynamic> buildMliGolden() {
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
    'schemaVersion': kMliGoldenSchemaVersion,
    'description':
        'Golden reference of MLI / muscle load / recovery output per exercise '
            '(pre 17-compartment migration). Also baseline data for '
            're-calibrating the 80/220 MLI thresholds.',
    'completedAt': kGoldenCompletedAt.toIso8601String(),
    'exerciseCount': exerciseDatabase.length,
    'exerciseIds': ids,
    'cases': cases,
  };
}
