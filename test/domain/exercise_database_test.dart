// test/domain/exercise_database_test.dart

import 'package:calisthenics_app/domain/enums/exercise_type.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('database has 38 calisthenics exercises', () {
    expect(exerciseDatabase, hasLength(38));
    for (final e in exerciseDatabase.values) {
      expect(e.type, ExerciseType.calisthenics, reason: e.name);
    }
  });

  test('every exercise compartment weights sum to exactly 1.00', () {
    exerciseDatabase.forEach((id, e) {
      final sum = e.compartments.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-9), reason: id);
      for (final w in e.compartments.values) {
        expect(w, greaterThan(0), reason: id);
      }
    });
  });

  test('derived legacy muscles aggregate compartments to region keys', () {
    final pushUp = exerciseDatabase['standard_push_up']!;
    expect(pushUp.muscles.keys.toSet(), {'chest', 'arms', 'shoulders', 'core'});
    expect(pushUp.muscles['chest'], closeTo(0.55, 1e-9));
    for (final e in exerciseDatabase.values) {
      final sum = e.muscles.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(1.0, 1e-9), reason: e.name);
      final regionNames = MuscleRegion.values.map((r) => r.name).toSet();
      expect(regionNames.containsAll(e.muscles.keys), isTrue, reason: e.name);
    }
  });

  test('every compartment is used by at least one exercise', () {
    final coverage = <MuscleCompartment, int>{
      for (final c in MuscleCompartment.values) c: 0,
    };
    for (final e in exerciseDatabase.values) {
      for (final c in e.compartments.keys) {
        coverage[c] = coverage[c]! + 1;
      }
    }
    for (final c in MuscleCompartment.values) {
      expect(coverage[c], greaterThan(0), reason: c.name);
    }
  });

  test('constructor asserts that weights sum to 1.00', () {
    expect(
      () => Exercise(
        name: 'bad',
        difficulty: 1,
        compartments: const {MuscleCompartment.core: 0.5},
      ),
      throwsA(isA<AssertionError>()),
    );
    expect(
      compartmentWeightsSumToOne(const {
        MuscleCompartment.core: 0.5,
        MuscleCompartment.lats: 0.5005,
      }),
      isTrue,
    );
  });
}
