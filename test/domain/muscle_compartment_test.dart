// test/domain/muscle_compartment_test.dart

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MuscleRegion', () {
    test('keeps the legacy RecoveryMuscle order, names and labels', () {
      expect(
        MuscleRegion.values.map((r) => r.name).toList(),
        ['chest', 'back', 'shoulders', 'arms', 'core', 'legs'],
      );
      expect(
        MuscleRegion.values.map((r) => r.label).toList(),
        ['Göğüs', 'Sırt', 'Omuz', 'Kol', 'Karın', 'Bacak'],
      );
    });

    test('RecoveryMuscle is an alias of MuscleRegion', () {
      expect(RecoveryMuscle.values, same(MuscleRegion.values));
      const RecoveryMuscle legs = MuscleRegion.legs;
      expect(legs.label, 'Bacak');
    });

    test('every region has at least one compartment', () {
      for (final region in MuscleRegion.values) {
        expect(region.compartments, isNotEmpty, reason: region.name);
      }
    });
  });

  group('MuscleCompartment', () {
    test('has exactly 17 values', () {
      expect(MuscleCompartment.values, hasLength(17));
    });

    test('firestoreKey values match the plan and are unique', () {
      const expected = {
        MuscleCompartment.upperChest: 'upper_chest',
        MuscleCompartment.midChest: 'mid_chest',
        MuscleCompartment.lowerChest: 'lower_chest',
        MuscleCompartment.anteriorDeltoid: 'anterior_deltoid',
        MuscleCompartment.lateralDeltoid: 'lateral_deltoid',
        MuscleCompartment.posteriorDeltoid: 'posterior_deltoid',
        MuscleCompartment.lats: 'lats',
        MuscleCompartment.upperBackTraps: 'upper_back_traps',
        MuscleCompartment.lowerBack: 'lower_back',
        MuscleCompartment.biceps: 'biceps',
        MuscleCompartment.triceps: 'triceps',
        MuscleCompartment.forearms: 'forearms',
        MuscleCompartment.quads: 'quads',
        MuscleCompartment.hamstrings: 'hamstrings',
        MuscleCompartment.glutes: 'glutes',
        MuscleCompartment.calves: 'calves',
        MuscleCompartment.core: 'core',
      };
      for (final c in MuscleCompartment.values) {
        expect(c.firestoreKey, expected[c], reason: c.name);
      }
      final keys = MuscleCompartment.values.map((c) => c.firestoreKey);
      expect(keys.toSet(), hasLength(17));
      final labels = MuscleCompartment.values.map((c) => c.label);
      expect(labels.toSet(), hasLength(17));
    });

    test('fromFirestoreKey round-trips and rejects unknown keys', () {
      for (final c in MuscleCompartment.values) {
        expect(MuscleCompartment.fromFirestoreKey(c.firestoreKey), c);
      }
      expect(MuscleCompartment.fromFirestoreKey('chest'), isNull);
      expect(MuscleCompartment.fromFirestoreKey('upperChest'), isNull);
      expect(MuscleCompartment.fromFirestoreKey(''), isNull);
    });

    test('region membership matches the plan table', () {
      const expected = {
        MuscleRegion.chest: [
          MuscleCompartment.upperChest,
          MuscleCompartment.midChest,
          MuscleCompartment.lowerChest,
        ],
        MuscleRegion.back: [
          MuscleCompartment.lats,
          MuscleCompartment.upperBackTraps,
          MuscleCompartment.lowerBack,
        ],
        MuscleRegion.shoulders: [
          MuscleCompartment.anteriorDeltoid,
          MuscleCompartment.lateralDeltoid,
          MuscleCompartment.posteriorDeltoid,
        ],
        MuscleRegion.arms: [
          MuscleCompartment.biceps,
          MuscleCompartment.triceps,
          MuscleCompartment.forearms,
        ],
        MuscleRegion.core: [MuscleCompartment.core],
        MuscleRegion.legs: [
          MuscleCompartment.quads,
          MuscleCompartment.hamstrings,
          MuscleCompartment.glutes,
          MuscleCompartment.calves,
        ],
      };
      for (final region in MuscleRegion.values) {
        expect(
          region.compartments.toSet(),
          expected[region]!.toSet(),
          reason: region.name,
        );
      }
    });

    test('recoverySizeFactor matches the approved values', () {
      const small = {
        MuscleCompartment.biceps,
        MuscleCompartment.forearms,
        MuscleCompartment.calves,
        MuscleCompartment.lateralDeltoid,
      };
      const large = {
        MuscleCompartment.quads,
        MuscleCompartment.hamstrings,
        MuscleCompartment.lowerBack,
      };
      for (final c in MuscleCompartment.values) {
        final expected = small.contains(c)
            ? 0.85
            : large.contains(c)
                ? 1.10
                : 1.0;
        expect(c.recoverySizeFactor, expected, reason: c.name);
      }
    });
  });
}
