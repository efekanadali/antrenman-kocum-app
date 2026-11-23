// test/domain/muscle_recovery_state_test.dart
//
// `muscle_recovery` koleksiyonunun yazım (kompartıman + bölge) ve okuma
// (kompartıman öncelikli, eski bölge dokümanına geri dönüş) mantığı.

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery_state.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/domain/services/recovery_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Map<MuscleCompartment, CompartmentRecoveryRecord> _session(
  List<String> exerciseIds,
  DateTime at, {
  int reps = 10,
  int rir = 2,
}) {
  final entries = [
    for (final id in exerciseIds)
      ExerciseWorkoutEntry(
        exercise: exerciseDatabase[id]!,
        sets: [WorkoutSet(reps: reps, rir: rir)],
      ),
  ];
  return buildCompartmentRecovery(
    compartmentLoad: calculateWorkoutCompartmentLoad(entries),
    compartmentRir: calculateWorkoutCompartmentRir(entries),
    completedAt: at,
  );
}

void main() {
  final t0 = DateTime.utc(2026, 11, 20, 12);

  group('buildRecoveryWrites', () {
    test('writes one doc per compartment and one per region', () {
      final incoming = _session(['standard_push_up'], t0);
      final writes = buildRecoveryWrites(incoming: incoming, existingDocs: {});
      for (final c in incoming.keys) {
        expect(writes[c.firestoreKey]?['compartment'], c.firestoreKey);
        expect(writes[c.firestoreKey]?['schemaVersion'], 2);
      }
      for (final region in ['chest', 'arms', 'shoulders']) {
        expect(writes[region]?['muscle'], region, reason: region);
        expect(writes[region]!.containsKey('compartment'), isFalse);
      }
    });

    test('core is a single doc readable as region AND compartment', () {
      final incoming = _session(['plank'], t0);
      final writes = buildRecoveryWrites(incoming: incoming, existingDocs: {});
      final core = writes['core']!;
      expect(core['muscle'], 'core');
      expect(core['compartment'], 'core');

      // Eski sürüm (bölge) okuyucusu
      final asRegion = MuscleRecoveryRecord.fromMap(core)!;
      expect(asRegion.muscle, MuscleRegion.core);
      // Yeni sürüm (kompartıman) okuyucusu
      final asCompartment = compartmentRecoveryFromMap('core', core)!;
      expect(asCompartment.compartment, MuscleCompartment.core);
      expect(asCompartment.recoveryHours, asRegion.recoveryHours);
      expect(asCompartment.readyAt, asRegion.readyAt);
    });

    test('core merge is consistent for region and compartment logic', () {
      final first = _session(['plank'], t0);
      final docs = buildRecoveryWrites(incoming: first, existingDocs: {});
      final later = t0.add(const Duration(hours: 10));
      final second = _session(['hollow_body_hold'], later, rir: 0);
      final writes = buildRecoveryWrites(incoming: second, existingDocs: docs);

      final regionMerged = mergeRecovery(
        MuscleRecoveryRecord.fromMap(docs['core']!),
        regionRecoveryFromCompartments(second)[MuscleRegion.core]!,
      );
      final written = writes['core']!;
      expect(written['recoveryHours'], regionMerged.recoveryHours);
      expect(written['lastTrainedAt'],
          regionMerged.lastTrainedAt.toIso8601String());
    });

    test('merges with existing compartment and region docs', () {
      final first = _session(['standard_pull_up'], t0);
      final docs = buildRecoveryWrites(incoming: first, existingDocs: {});
      final later = t0.add(const Duration(hours: 12));
      final second = _session(['standard_pull_up'], later);
      final writes = buildRecoveryWrites(incoming: second, existingDocs: docs);

      final lats = compartmentRecoveryFromMap('lats', writes['lats']!)!;
      final expected = mergeCompartmentRecovery(
        compartmentRecoveryFromMap('lats', docs['lats']!),
        second[MuscleCompartment.lats]!,
      );
      expect(lats.recoveryHours, expected.recoveryHours);
      expect(lats.load, closeTo(
        first[MuscleCompartment.lats]!.load +
            second[MuscleCompartment.lats]!.load,
        1e-9,
      ));
      expect(MuscleRecoveryRecord.fromMap(writes['back']!), isNotNull);
    });

    test('ids to pre-read include compartments and their regions', () {
      final incoming = _session(['standard_squat'], t0);
      final ids = recoveryDocIdsFor(incoming);
      expect(ids, containsAll(['quads', 'glutes', 'legs']));
    });
  });

  group('parseRecoveryDocs', () {
    test('compartment docs are used directly', () {
      final incoming = _session(['pike_push_up'], t0);
      final docs = buildRecoveryWrites(incoming: incoming, existingDocs: {});
      final state = parseRecoveryDocs(docs);
      for (final c in incoming.keys) {
        expect(state.compartments[c]!.recoveryHours,
            incoming[c]!.recoveryHours);
      }
      // Yeni sürümün yazdığı bölge dokümanları geri dönüş kaynağı değildir:
      // çalıştırılmamış kompartımanlar (ör. arka omuz) hazır kalır.
      expect(state.legacyFallback, isEmpty);
      expect(state.compartments[MuscleCompartment.posteriorDeltoid], isNull);
    });

    test('region doc rewritten by an old app version becomes a fallback', () {
      final incoming = _session(['pike_push_up'], t0);
      final docs = buildRecoveryWrites(incoming: incoming, existingDocs: {});
      // Eski sürüm `merge: true` ile omuz dokümanını günceller (işaret kalır,
      // zaman değişir).
      final later = t0.add(const Duration(hours: 30));
      docs['shoulders'] = {
        ...docs['shoulders']!,
        'lastTrainedAt': later.toIso8601String(),
        'recoveryHours': 60.0,
      };
      final state = parseRecoveryDocs(docs);
      expect(state.legacyFallback, {MuscleCompartment.posteriorDeltoid});
      expect(
        state.compartments[MuscleCompartment.posteriorDeltoid]!.recoveryHours,
        60.0,
      );
      // Kendi dokümanı olan kompartımanlar etkilenmez.
      expect(
        state.compartments[MuscleCompartment.anteriorDeltoid]!.recoveryHours,
        incoming[MuscleCompartment.anteriorDeltoid]!.recoveryHours,
      );
    });

    test('legacy region docs fill missing compartments (hours copied)', () {
      final docs = {
        'chest': {
          'muscle': 'chest',
          'lastTrainedAt': t0.toIso8601String(),
          'recoveryHours': 48.0,
          'averageRir': 2.0,
          'load': 100.0,
        },
        'legs': {
          'muscle': 'legs',
          'lastTrainedAt': t0.toIso8601String(),
          'recoveryHours': 60.0,
          'averageRir': 1.0,
          'load': 50.0,
        },
        // Yeni biçim yalnızca quads için var → quads doc öncelikli.
        'quads': {
          'compartment': 'quads',
          'region': 'legs',
          'lastTrainedAt': t0.toIso8601String(),
          'recoveryHours': 30.0,
          'averageRir': 3.0,
          'load': 7.0,
        },
      };
      final state = parseRecoveryDocs(docs);
      for (final c in MuscleRegion.chest.compartments) {
        expect(state.compartments[c]!.recoveryHours, 48.0);
        expect(state.legacyFallback, contains(c));
      }
      expect(state.compartments[MuscleCompartment.midChest]!.load, 50.0);
      expect(state.compartments[MuscleCompartment.quads]!.recoveryHours, 30.0);
      expect(state.legacyFallback, isNot(contains(MuscleCompartment.quads)));
      expect(state.compartments[MuscleCompartment.calves]!.recoveryHours, 60.0);
      // Bölge: en geç toparlanan kompartıman (60 sa).
      expect(state.regions[MuscleRegion.legs]!.recoveryHours, 60.0);
    });

    test('an old core region doc is read as the core compartment', () {
      final state = parseRecoveryDocs({
        'core': {
          'muscle': 'core',
          'lastTrainedAt': t0.toIso8601String(),
          'recoveryHours': 36.0,
          'averageRir': 3.0,
          'load': 9.0,
        },
      });
      expect(state.compartments.keys, [MuscleCompartment.core]);
      expect(state.compartments[MuscleCompartment.core]!.recoveryHours, 36.0);
      expect(state.regions[MuscleRegion.core]!.recoveryHours, 36.0);
    });

    test('invalid docs are ignored', () {
      final state = parseRecoveryDocs({
        'chest': {'muscle': 'chest', 'lastTrainedAt': 'bad'},
        'neck': {'compartment': 'neck', 'lastTrainedAt': t0.toIso8601String()},
      });
      expect(state.isEmpty, isTrue);
    });
  });

  group('shoulders do not drop out', () {
    for (final id in ['pike_push_up', 'handstand_push_up']) {
      test('$id session shows the shoulders region', () {
        final incoming = _session([id], t0);
        final state =
            parseRecoveryDocs(buildRecoveryWrites(incoming: incoming, existingDocs: {}));
        expect(state.regions.keys, contains(MuscleRegion.shoulders));
        expect(state.compartmentsOf(MuscleRegion.shoulders), isNotEmpty);
        expect(state.regions[MuscleRegion.shoulders]!.isReadyAt(t0), isFalse);
      });
    }

    test('legacy-key session (pike) also keeps shoulders', () {
      final pike = exerciseDatabase['pike_push_up']!;
      const set = WorkoutSet(reps: 10, rir: 2);
      final records = buildSessionRecovery(
        muscleLoad: calculateMuscleLoad(exercise: pike, set: set),
        muscleRir: const {},
        completedAt: t0,
        compartmentLoad: calculateCompartmentLoad(exercise: pike, set: set),
      );
      expect(records.keys, contains(MuscleRegion.shoulders));
    });
  });
}
