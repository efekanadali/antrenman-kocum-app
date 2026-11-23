// test/domain/mli_golden_test.dart
//
// Göç öncesi modelin dondurulmuş referansına (test/fixtures/mli_golden_v1.json)
// karşı, kompartıman göçünde DEĞİŞMEMESİ gerekenleri doğrular:
//  * egzersiz id'leri, adları ve Lf (difficulty) değerleri,
//  * her vakanın ham set MLI'ı (kas ağırlıklarından bağımsız),
//  * her vakanın birincil bölgesi (eşitlikte eski birincil bölgelerden biri).

import 'dart:convert';
import 'dart:io';

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mli_golden_v2_builder.dart';

const double _tolerance = 1e-9;

void main() {
  final v1 = jsonDecode(File(kMliGoldenV1FixturePath).readAsStringSync())
      as Map<String, dynamic>;
  final cases = (v1['cases'] as List).cast<Map<String, dynamic>>();

  test('v1 fixture is the frozen 48-case reference', () {
    expect(v1['schemaVersion'], 1);
    expect(cases, hasLength(48));
  });

  test('exercise ids are unchanged', () {
    final ids = exerciseDatabase.keys.toList()..sort();
    expect(ids, v1['exerciseIds']);
    expect(exerciseDatabase, hasLength(38));
  });

  group('invariant', () {
    for (final c in cases) {
      final id = '${c['exerciseId']}/${c['variant']}';
      test(id, () {
        final exercise = exerciseDatabase[c['exerciseId']]!;
        expect(exercise.name, c['name']);
        expect(exercise.difficulty, c['difficulty']);

        final set = workoutSetFromJson(c['set'] as Map<String, dynamic>);
        final setMli = calculateSetMli(exercise: exercise, set: set);
        expect(
          (setMli - (c['setMli'] as num)).abs() <= _tolerance,
          isTrue,
          reason: 'raw set MLI changed: ${c['setMli']} → $setMli',
        );

        final oldPrimary =
            primaryRegions((c['regionLoad'] as Map).cast<String, num>());
        final newRegionLoad = {
          for (final e in aggregateToRegions(
            calculateCompartmentLoad(exercise: exercise, set: set),
          ).entries)
            e.key.name: e.value,
        };
        final newPrimary = primaryRegions(newRegionLoad);
        expect(newPrimary, hasLength(1), reason: 'new primary must be unique');
        expect(
          oldPrimary.contains(newPrimary.single),
          isTrue,
          reason: 'primary region changed: $oldPrimary → $newPrimary',
        );
      });
    }
  });

  test('every region name in v1 is a MuscleRegion', () {
    final names = MuscleRegion.values.map((r) => r.name).toSet();
    for (final c in cases) {
      for (final key in (c['regionLoad'] as Map).keys) {
        expect(names, contains(key));
      }
    }
  });
}
