// test/domain/compartment_recovery_test.dart

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/services/recovery_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 1, 1, 12);

  group('compartmentRecoveryHours', () {
    test('applies the size factor after the RIR band', () {
      // RIR 2 → 48 sa
      expect(compartmentRecoveryHours(MuscleCompartment.biceps, 2),
          closeTo(48 * 0.85, 1e-9));
      expect(compartmentRecoveryHours(MuscleCompartment.quads, 2),
          closeTo(48 * 1.10, 1e-9));
      expect(compartmentRecoveryHours(MuscleCompartment.midChest, 2), 48);
      // RIR 0 → 72 sa, RIR 5 → 24 sa (band sınırları)
      expect(compartmentRecoveryHours(MuscleCompartment.lowerBack, 0),
          closeTo(79.2, 1e-9));
      expect(compartmentRecoveryHours(MuscleCompartment.calves, 5),
          closeTo(20.4, 1e-9));
    });
  });

  group('buildCompartmentRecovery', () {
    test('applies kPrimaryMuscleShare at compartment level', () {
      final records = buildCompartmentRecovery(
        compartmentLoad: const {
          MuscleCompartment.lats: 100,
          MuscleCompartment.biceps: 25, // tam %25 → dahil
          MuscleCompartment.forearms: 24.9, // %25 altı → hariç
          MuscleCompartment.core: 0,
        },
        compartmentRir: const {MuscleCompartment.lats: 1},
        completedAt: t0,
      );
      expect(records.keys.toSet(),
          {MuscleCompartment.lats, MuscleCompartment.biceps});
      expect(records[MuscleCompartment.lats]!.recoveryHours, 60);
      expect(records[MuscleCompartment.lats]!.averageRir, 1);
      // biceps: RIR bilgisi yok → varsayılan 2 → 48 × 0.85
      expect(records[MuscleCompartment.biceps]!.recoveryHours,
          closeTo(40.8, 1e-9));
      expect(records[MuscleCompartment.biceps]!.averageRir, kDefaultRir);
    });

    test('empty / zero load gives no records', () {
      expect(
        buildCompartmentRecovery(compartmentLoad: const {}, completedAt: t0),
        isEmpty,
      );
      expect(
        buildCompartmentRecovery(
          compartmentLoad: const {MuscleCompartment.core: 0},
          completedAt: t0,
        ),
        isEmpty,
      );
    });
  });

  group('regionRecoveryFromCompartments', () {
    test('region ready time is the latest-ready compartment', () {
      final records = buildCompartmentRecovery(
        compartmentLoad: const {
          MuscleCompartment.quads: 50,
          MuscleCompartment.calves: 30,
          MuscleCompartment.glutes: 20,
        },
        compartmentRir: const {
          MuscleCompartment.quads: 2,
          MuscleCompartment.calves: 0,
          MuscleCompartment.glutes: 2,
        },
        completedAt: t0,
      );
      final regions = regionRecoveryFromCompartments(records);
      expect(regions.keys, [MuscleRegion.legs]);
      final legs = regions[MuscleRegion.legs]!;
      // quads: 48 × 1.10 = 52.8 ; calves: 72 × 0.85 = 61.2 ; glutes 48
      expect(legs.recoveryHours, closeTo(61.2, 1e-9));
      expect(legs.readyAt, records[MuscleCompartment.calves]!.readyAt);
      expect(legs.load, closeTo(100, 1e-9));
      expect(legs.averageRir, closeTo((50 * 2 + 30 * 0 + 20 * 2) / 100, 1e-9));
    });
  });

  group('buildSessionRecovery', () {
    test('legacy region keys are split before compartment recovery', () {
      final records = buildSessionRecovery(
        muscleLoad: const {'legs': 100, 'Genel': 50},
        muscleRir: const {'legs': 2},
        completedAt: t0,
      );
      // legs → quads 40 / glutes 25 / hamstrings 25 / calves 10;
      // en büyük 40 → eşik 10 → hepsi dahil, en geç: quads/hamstrings 52.8 sa
      expect(records.keys, [MuscleRegion.legs]);
      expect(records[MuscleRegion.legs]!.recoveryHours, closeTo(52.8, 1e-9));
      expect(records[MuscleRegion.legs]!.load, closeTo(100, 1e-9));
    });

    test('explicit compartment data takes precedence over legacy keys', () {
      final records = buildSessionRecovery(
        muscleLoad: const {'chest': 100},
        muscleRir: const {},
        completedAt: t0,
        compartmentLoad: const {MuscleCompartment.biceps: 10},
        compartmentRir: const {MuscleCompartment.biceps: 2},
      );
      expect(records.keys, [MuscleRegion.arms]);
      expect(records[MuscleRegion.arms]!.recoveryHours, closeTo(40.8, 1e-9));
    });

    test('Firestore doc ids (region names) are unchanged', () {
      final records = buildSessionRecovery(
        muscleLoad: const {'chest': 10, 'arms': 10},
        muscleRir: const {},
        completedAt: t0,
      );
      expect(records.keys.map((m) => m.name).toSet(), {'chest', 'arms'});
    });
  });

  group('mergeCompartmentRecovery', () {
    test('returns incoming when nothing exists or already recovered', () {
      final incoming = CompartmentRecoveryRecord(
        compartment: MuscleCompartment.biceps,
        lastTrainedAt: t0,
        recoveryHours: 40.8,
        averageRir: 2,
        load: 10,
      );
      expect(mergeCompartmentRecovery(null, incoming), same(incoming));
      final old = CompartmentRecoveryRecord(
        compartment: MuscleCompartment.biceps,
        lastTrainedAt: t0.subtract(const Duration(hours: 100)),
        recoveryHours: 40.8,
        averageRir: 1,
        load: 5,
      );
      expect(mergeCompartmentRecovery(old, incoming), same(incoming));
    });

    test('matches region merge logic for overlapping sessions', () {
      final existingAt = t0.subtract(const Duration(hours: 12));
      const hours = 40.8;
      final existing = CompartmentRecoveryRecord(
        compartment: MuscleCompartment.biceps,
        lastTrainedAt: existingAt,
        recoveryHours: hours,
        averageRir: 2,
        load: 10,
      );
      final incoming = CompartmentRecoveryRecord(
        compartment: MuscleCompartment.biceps,
        lastTrainedAt: t0,
        recoveryHours: hours,
        averageRir: 1,
        load: 8,
      );
      final merged = mergeCompartmentRecovery(existing, incoming);

      final regionMerged = mergeRecovery(
        MuscleRecoveryRecord(
          muscle: MuscleRegion.arms,
          lastTrainedAt: existingAt,
          recoveryHours: hours,
          averageRir: 2,
          load: 10,
        ),
        MuscleRecoveryRecord(
          muscle: MuscleRegion.arms,
          lastTrainedAt: t0,
          recoveryHours: hours,
          averageRir: 1,
          load: 8,
        ),
      );
      expect(merged.recoveryHours, regionMerged.recoveryHours);
      expect(merged.lastTrainedAt, regionMerged.lastTrainedAt);
      expect(merged.averageRir, 1);
      expect(merged.load, 18);
      expect(merged.recoveryHours, inInclusiveRange(24, 96));
    });
  });
}
