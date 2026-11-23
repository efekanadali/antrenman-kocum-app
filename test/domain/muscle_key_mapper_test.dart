// test/domain/muscle_key_mapper_test.dart

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/legacy_recovery_keys.dart';

void main() {
  group('regionFromKey', () {
    test('agrees with the old switch for every old key', () {
      kLegacyRecoveryKeys.forEach((key, region) {
        expect(regionFromKey(key), region, reason: key);
      });
    });

    test('maps every compartment key, name and label to its region', () {
      for (final c in MuscleCompartment.values) {
        expect(regionFromKey(c.firestoreKey), c.region, reason: c.firestoreKey);
        expect(regionFromKey(c.name), c.region, reason: c.name);
        expect(regionFromKey(c.label), c.region, reason: c.label);
        expect(
          regionFromKey(' ${c.label.toUpperCase()} '),
          c.region,
          reason: c.label.toUpperCase(),
        );
      }
    });

    test('maps region names and labels', () {
      for (final r in MuscleRegion.values) {
        expect(regionFromKey(r.name), r);
        expect(regionFromKey(r.label), r);
      }
    });

    test('handles labels with and without diacritics', () {
      expect(regionFromKey('Üst Göğüs'), MuscleRegion.chest);
      expect(regionFromKey('ust gogus'), MuscleRegion.chest);
      expect(regionFromKey('Ön Kol'), MuscleRegion.arms);
      expect(regionFromKey('onkol'), MuscleRegion.arms);
      expect(regionFromKey('Üst Sırt / Trapez'), MuscleRegion.back);
      expect(regionFromKey('BEL'), MuscleRegion.back);
      expect(regionFromKey('KALÇA'), MuscleRegion.legs);
      expect(regionFromKey('SIRT'), MuscleRegion.back);
    });

    test('Genel and unknown keys return null', () {
      expect(regionFromKey('Genel'), isNull);
      expect(regionFromKey('genel'), isNull);
      expect(regionFromKey(''), isNull);
      expect(regionFromKey('neck'), isNull);
    });
  });

  group('compartmentFromKey', () {
    test('compartment keys, names and labels map 1:1', () {
      for (final c in MuscleCompartment.values) {
        expect(compartmentFromKey(c.firestoreKey), c);
        expect(compartmentFromKey(c.name), c);
        expect(compartmentFromKey(c.label), c);
      }
    });

    test('direct synonyms', () {
      const expected = {
        'biceps': MuscleCompartment.biceps,
        'biseps': MuscleCompartment.biceps,
        'Biseps': MuscleCompartment.biceps,
        'triceps': MuscleCompartment.triceps,
        'triseps': MuscleCompartment.triceps,
        'quads': MuscleCompartment.quads,
        'quadriceps': MuscleCompartment.quads,
        'hamstrings': MuscleCompartment.hamstrings,
        'glutes': MuscleCompartment.glutes,
        'kalça': MuscleCompartment.glutes,
        'kalca': MuscleCompartment.glutes,
        'calves': MuscleCompartment.calves,
        'baldır': MuscleCompartment.calves,
        'baldir': MuscleCompartment.calves,
        'core': MuscleCompartment.core,
        'abs': MuscleCompartment.core,
        'karın': MuscleCompartment.core,
        'karin': MuscleCompartment.core,
        'rear_shoulders': MuscleCompartment.posteriorDeltoid,
        'rear_delts': MuscleCompartment.posteriorDeltoid,
        'forearms': MuscleCompartment.forearms,
        'ön kol': MuscleCompartment.forearms,
        'onkol': MuscleCompartment.forearms,
        'traps': MuscleCompartment.upperBackTraps,
      };
      expected.forEach((key, c) {
        expect(compartmentFromKey(key), c, reason: key);
      });
    });

    test('legacy region keys and unknown keys are not direct', () {
      for (final key in [
        'chest',
        'Göğüs',
        'back',
        'sırt',
        'shoulders',
        'omuz',
        'arms',
        'kol',
        'legs',
        'bacak',
        'Genel',
      ]) {
        expect(compartmentFromKey(key), isNull, reason: key);
      }
    });
  });

  group('kLegacyRegionSplit', () {
    test('every row sums to 1.0 and stays inside its region', () {
      kLegacyRegionSplit.forEach((region, row) {
        final sum = row.values.fold<double>(0, (a, b) => a + b);
        expect(sum, closeTo(1.0, 1e-12), reason: region.name);
        for (final c in row.keys) {
          expect(c.region, region, reason: '${region.name}/${c.name}');
        }
      });
    });

    test('covers every multi-compartment region', () {
      for (final region in MuscleRegion.values) {
        if (region.compartments.length > 1) {
          expect(
            kLegacyRegionSplit[region]!.keys.toSet(),
            region.compartments.toSet(),
            reason: region.name,
          );
        }
      }
    });

    test('uses the approved ratios', () {
      expect(kLegacyRegionSplit[MuscleRegion.chest], {
        MuscleCompartment.midChest: 0.50,
        MuscleCompartment.upperChest: 0.30,
        MuscleCompartment.lowerChest: 0.20,
      });
      expect(kLegacyRegionSplit[MuscleRegion.shoulders], {
        MuscleCompartment.anteriorDeltoid: 0.50,
        MuscleCompartment.lateralDeltoid: 0.30,
        MuscleCompartment.posteriorDeltoid: 0.20,
      });
      expect(kLegacyRegionSplit[MuscleRegion.back], {
        MuscleCompartment.lats: 0.55,
        MuscleCompartment.upperBackTraps: 0.30,
        MuscleCompartment.lowerBack: 0.15,
      });
      expect(kLegacyRegionSplit[MuscleRegion.arms], {
        MuscleCompartment.biceps: 0.45,
        MuscleCompartment.triceps: 0.45,
        MuscleCompartment.forearms: 0.10,
      });
      expect(kLegacyRegionSplit[MuscleRegion.legs], {
        MuscleCompartment.quads: 0.40,
        MuscleCompartment.glutes: 0.25,
        MuscleCompartment.hamstrings: 0.25,
        MuscleCompartment.calves: 0.10,
      });
    });
  });

  group('splitLoad', () {
    test('preserves totals for a mixed English / Turkish / Genel map', () {
      const input = {
        'chest': 37.3,
        'Sırt': 21.7,
        'omuz': 13.1,
        'kol': 9.9,
        'Bacak': 44.4,
        'triceps': 5.5,
        'Biseps': 4.4,
        'Karın': 3.3,
        'Kalça': 2.2,
        'quadriceps': 1.1,
        'upper_chest': 0.7,
        'Genel': 6.6,
      };
      final split = splitLoad(input);
      final inputTotal = input.values.fold<double>(0, (a, b) => a + b);
      expect(split.total, closeTo(inputTotal, 1e-9));
      expect(split.unmappedTotal, closeTo(6.6, 1e-12));
      expect(split.unmapped.keys, ['Genel']);
      expect(split.mappedTotal, closeTo(inputTotal - 6.6, 1e-9));

      final regions = aggregateToRegions(split.loads);
      expect(regions[MuscleRegion.chest], closeTo(37.3 + 0.7, 1e-9));
      expect(regions[MuscleRegion.back], closeTo(21.7, 1e-9));
      expect(regions[MuscleRegion.shoulders], closeTo(13.1, 1e-9));
      expect(regions[MuscleRegion.arms], closeTo(9.9 + 5.5 + 4.4, 1e-9));
      expect(regions[MuscleRegion.core], closeTo(3.3, 1e-9));
      expect(regions[MuscleRegion.legs], closeTo(44.4 + 2.2 + 1.1, 1e-9));

      expect(split.loads[MuscleCompartment.midChest], closeTo(37.3 * 0.5, 1e-9));
      expect(
        split.loads[MuscleCompartment.upperChest],
        closeTo(37.3 * 0.3 + 0.7, 1e-9),
      );
      expect(
        split.loads[MuscleCompartment.triceps],
        closeTo(9.9 * 0.45 + 5.5, 1e-9),
      );
    });

    test('a legacy key is split exactly into its parts', () {
      for (final region in kLegacyRegionSplit.keys) {
        final split = splitLoad({region.name: 123.456});
        expect(split.unmapped, isEmpty);
        expect(split.loads.keys.toSet(), region.compartments.toSet());
        final sum = split.loads.values.fold<double>(0, (a, b) => a + b);
        expect(sum, closeTo(123.456, 1e-12), reason: region.name);
      }
    });

    test('empty input yields empty output', () {
      final split = splitLoad(const {});
      expect(split.loads, isEmpty);
      expect(split.unmappedTotal, 0.0);
    });
  });

  group('expandRecoveryKey', () {
    test("'chest' returns the 3 chest compartments", () {
      expect(expandRecoveryKey('chest').toSet(), {
        MuscleCompartment.upperChest,
        MuscleCompartment.midChest,
        MuscleCompartment.lowerChest,
      });
      expect(expandRecoveryKey('Göğüs'), hasLength(3));
    });

    test('legacy region keys expand to all child compartments', () {
      expect(expandRecoveryKey('legs').toSet(),
          MuscleRegion.legs.compartments.toSet());
      expect(expandRecoveryKey('sirt').toSet(),
          MuscleRegion.back.compartments.toSet());
    });

    test('direct keys return a single compartment', () {
      expect(expandRecoveryKey('biceps'), [MuscleCompartment.biceps]);
      expect(expandRecoveryKey('core'), [MuscleCompartment.core]);
      expect(expandRecoveryKey('lateral_deltoid'),
          [MuscleCompartment.lateralDeltoid]);
    });

    test('unknown keys return an empty list', () {
      expect(expandRecoveryKey('Genel'), isEmpty);
    });

    test('returned list is a copy', () {
      final first = expandRecoveryKey('chest')..clear();
      expect(first, isEmpty);
      expect(expandRecoveryKey('chest'), hasLength(3));
    });
  });

  test('aggregateToRegions sums compartments per region', () {
    final regions = aggregateToRegions({
      MuscleCompartment.upperChest: 1.0,
      MuscleCompartment.lowerChest: 2.0,
      MuscleCompartment.calves: 4.0,
    });
    expect(regions, {MuscleRegion.chest: 3.0, MuscleRegion.legs: 4.0});
  });
}
