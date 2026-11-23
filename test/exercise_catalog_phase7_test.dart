// test/exercise_catalog_phase7_test.dart
//
// Faz 7: 80 hareketlik hibrit kütüphanenin bütünlük testleri.

import 'package:flutter_test/flutter_test.dart';

import 'package:calisthenics_app/domain/enums/exercise_type.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';

MuscleCompartment _primaryOf(Exercise e) =>
    e.compartments.entries.reduce((a, b) => b.value > a.value ? b : a).key;

void main() {
  group('Faz 7 hibrit katalog', () {
    test('katalog 40 kalistenik + 40 vücut geliştirme = 80 hareket', () {
      expect(calisthenicsExercises, hasLength(40));
      expect(bodybuildingExercises, hasLength(40));
      expect(exerciseCatalog, hasLength(80));
      expect(
        calisthenicsExercises.values.every(
          (e) => e.type == ExerciseType.calisthenics,
        ),
        isTrue,
      );
      expect(
        bodybuildingExercises.values.every(
          (e) => e.type == ExerciseType.bodybuilding,
        ),
        isTrue,
      );
    });

    test("tüm id'ler benzersizdir ve snake_case'tir", () {
      final ids = [
        ...calisthenicsExercises.keys,
        ...bodybuildingExercises.keys,
      ];
      expect(ids.toSet(), hasLength(ids.length));
      for (final id in ids) {
        expect(
          RegExp(r'^[a-z0-9]+(_[a-z0-9]+)*$').hasMatch(id),
          isTrue,
          reason: id,
        );
      }
      final names = exerciseCatalog.values.map((e) => e.name).toList();
      expect(names.toSet(), hasLength(names.length));
    });

    test('her hareketin kompartıman ağırlık toplamı 1.00 ± 0.001', () {
      for (final entry in exerciseCatalog.entries) {
        final sum = entry.value.compartments.values.fold<double>(
          0,
          (a, b) => a + b,
        );
        expect(sum, closeTo(1.0, 0.001), reason: entry.key);
        expect(
          entry.value.compartments.values.every((w) => w > 0),
          isTrue,
          reason: entry.key,
        );
        expect(entry.value.difficulty, greaterThan(0), reason: entry.key);
      }
    });

    test('17 kompartımanın her biri en az 2 harekette birincil kastır', () {
      final counts = <MuscleCompartment, int>{};
      for (final e in exerciseCatalog.values) {
        final p = _primaryOf(e);
        counts[p] = (counts[p] ?? 0) + 1;
      }
      expect(MuscleCompartment.values, hasLength(17));
      for (final c in MuscleCompartment.values) {
        expect(counts[c] ?? 0, greaterThanOrEqualTo(2), reason: c.name);
      }
    });

    test('dondurulmuş 38 hareketlik çekirdek katalogda aynen yer alır', () {
      expect(exerciseDatabase, hasLength(38));
      for (final entry in exerciseDatabase.entries) {
        expect(identical(exerciseCatalog[entry.key], entry.value), isTrue);
      }
      for (final id in kPhase7CalisthenicsIds) {
        expect(exerciseCatalog.containsKey(id), isTrue);
        expect(exerciseDatabase.containsKey(id), isFalse);
      }
    });
  });
}
