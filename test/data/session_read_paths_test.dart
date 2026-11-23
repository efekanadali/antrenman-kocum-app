// test/data/session_read_paths_test.dart
//
// Seans kayıtlarının (Firestore `workout_sessions` + yerel özet dosyası) eski
// ve yeni biçimlerinin okunması.

import 'package:calisthenics_app/core/local_storage/workout_summary_storage.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/muscle_load_snapshot.dart';
import 'package:calisthenics_app/domain/models/workout_session_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorkoutSessionSummary.fromFirestore', () {
    test('v2 doc: compartmentWorkloads is read first', () {
      final s = WorkoutSessionSummary.fromFirestore('a', {
        'completedAt': '2026-11-20T10:00:00.000',
        'durationSeconds': 600,
        'totalMliWorkload': 30.0,
        'schemaVersion': 2,
        'compartmentWorkloads': {'mid_chest': 10.0, 'triceps': 6.0, 'core': 2.0},
        'muscleWorkloads': {'chest': 999.0}, // yok sayılır
      });
      expect(s.schemaVersion, 2);
      expect(s.compartmentWorkloads, {
        MuscleCompartment.midChest: 10.0,
        MuscleCompartment.triceps: 6.0,
        MuscleCompartment.core: 2.0,
      });
      expect(s.regionWorkloads[MuscleRegion.chest], 10.0);
      expect(s.regionWorkloads[MuscleRegion.arms], 6.0);
      expect(s.muscleWorkloads, {'chest': 999.0});
    });

    test('v1 doc with English keys is split into compartments', () {
      final s = WorkoutSessionSummary.fromFirestore('b', {
        'completedAt': '2026-11-20T10:00:00.000',
        'totalLoad': 40.0,
        'muscleLoad': {'chest': 20.0, 'triceps': 10.0, 'shoulders': 10.0},
      });
      expect(s.schemaVersion, 1);
      expect(s.totalMliWorkload, 40.0);
      expect(s.compartmentWorkloads[MuscleCompartment.midChest], 10.0);
      expect(s.compartmentWorkloads[MuscleCompartment.triceps], 10.0);
      expect(s.regionWorkloads[MuscleRegion.chest], closeTo(20.0, 1e-9));
      expect(s.regionWorkloads[MuscleRegion.shoulders], closeTo(10.0, 1e-9));
    });

    test('v1 doc with Turkish labels and Genel', () {
      final s = WorkoutSessionSummary.fromFirestore('c', {
        'completedAt': '2026-11-20T10:00:00.000',
        'muscleWorkloads': {
          'Göğüs': 8.0,
          'Biseps': 4.0,
          'Kalça': 3.0,
          'Genel': 50.0,
        },
      });
      expect(s.compartmentWorkloads[MuscleCompartment.biceps], 4.0);
      expect(s.compartmentWorkloads[MuscleCompartment.glutes], 3.0);
      expect(s.regionWorkloads[MuscleRegion.chest], closeTo(8.0, 1e-9));
      expect(s.load.unmapped, {'Genel': 50.0});
      expect(s.load.mappedTotal, closeTo(15.0, 1e-9));
    });

    test('doc with missing muscle fields yields an empty load', () {
      final s = WorkoutSessionSummary.fromFirestore('d', {
        'completedAt': 'not a date',
        'exerciseName': 'Plank',
      });
      expect(s.load.isEmpty, isTrue);
      expect(s.regionWorkloads, isEmpty);
      expect(s.exercisesDone, ['Plank']);
    });

    test('toJson writes compartment keys and schema version', () {
      final s = WorkoutSessionSummary.fromFirestore('e', {
        'completedAt': '2026-11-20T10:00:00.000',
        'compartmentWorkloads': {'lats': 5.0},
        'schemaVersion': 2,
      });
      final json = s.toJson();
      expect(json['compartmentWorkloads'], {'lats': 5.0});
      expect(json['schemaVersion'], 2);
    });
  });

  group('WorkoutSummaryEntry (local file)', () {
    test('old entry without compartmentLoad is split on read', () {
      final e = WorkoutSummaryEntry.fromJson({
        'date': '2026-11-20T10:00:00.000',
        'totalLoad': 30.0,
        'muscleLoad': {'back': 20.0, 'biceps': 10.0},
        'duration': 900,
      });
      expect(e.schemaVersion, 1);
      expect(e.compartmentLoad[MuscleCompartment.lats], closeTo(11.0, 1e-9));
      expect(e.compartmentLoad[MuscleCompartment.biceps], 10.0);
    });

    test('new entry reads compartmentLoad and round-trips', () {
      final entry = WorkoutSummaryEntry(
        date: DateTime(2026, 11, 20),
        totalLoad: 12.0,
        muscleLoad: const {'chest': 7.0, 'arms': 5.0},
        duration: 300,
        load: const MuscleLoadSnapshot(compartments: {
          MuscleCompartment.lowerChest: 7.0,
          MuscleCompartment.triceps: 5.0,
        }),
      );
      final json = entry.toJson();
      expect(json['schemaVersion'], kMuscleDataSchemaVersion);
      expect(json['compartmentLoad'], {'lower_chest': 7.0, 'triceps': 5.0});
      expect(json['muscleLoad'], {'chest': 7.0, 'arms': 5.0});

      final back = WorkoutSummaryEntry.fromJson(json);
      expect(back.compartmentLoad, entry.compartmentLoad);
      expect(back.schemaVersion, 2);
    });
  });

  group('MuscleLoadSnapshot', () {
    test('legacyRegionLoad uses the 6 English region keys plus unmapped', () {
      const snapshot = MuscleLoadSnapshot(
        compartments: {
          MuscleCompartment.biceps: 2.0,
          MuscleCompartment.quads: 3.0,
          MuscleCompartment.calves: 1.0,
        },
        unmapped: {'Genel': 4.0},
      );
      expect(snapshot.legacyRegionLoad, {'arms': 2.0, 'legs': 4.0, 'Genel': 4.0});
    });
  });
}
