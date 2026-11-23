// test/domain/mli_calculator_test.dart

import 'package:calisthenics_app/domain/enums/exercise_type.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _bench({double lf = 1.2}) => Exercise(
      name: 'Bench Press',
      difficulty: lf,
      type: ExerciseType.bodybuilding,
      compartments: const {
        MuscleCompartment.midChest: 0.5,
        MuscleCompartment.triceps: 0.3,
        MuscleCompartment.anteriorDeltoid: 0.2,
      },
    );

void main() {
  group('calisthenics set MLI (unchanged formula)', () {
    final pushUp = exerciseDatabase['standard_push_up']!;

    test('dynamic: reps × Lf × (1 + (10 - RIR)/10)', () {
      final mli = calculateSetMli(
        exercise: pushUp,
        set: const WorkoutSet(reps: 10, rir: 2),
      );
      expect(mli, closeTo(10 * 1.0 * 1.8, 1e-9));
    });

    test('dynamic with extra weight multiplier', () {
      final mli = calculateSetMli(
        exercise: pushUp,
        set: const WorkoutSet(
          reps: 10,
          rir: 2,
          extraWeightKg: 20,
          bodyWeightKg: 80,
        ),
      );
      expect(mli, closeTo(10 * 1.8 * 1.25, 1e-9));
    });

    test('loadKg is ignored for calisthenics', () {
      final a = calculateSetMli(
        exercise: pushUp,
        set: const WorkoutSet(reps: 10, rir: 2),
      );
      final b = calculateSetMli(
        exercise: pushUp,
        set: const WorkoutSet(reps: 10, rir: 2, loadKg: 100),
      );
      expect(a, b);
    });

    test('static: (seconds × 0.5) × Lf × M_SIR', () {
      final plank = exerciseDatabase['plank']!;
      final mli = calculateSetMli(
        exercise: plank,
        set: const WorkoutSet(reps: 0, rir: 3, durationInSeconds: 30),
      );
      expect(mli, closeTo(15 * 0.70 * 1.0, 1e-9));
    });
  });

  group('bodybuilding set MLI', () {
    test('reps × (loadKg / bodyWeightKg) × Lf_bb × RIR factor', () {
      final mli = calculateSetMli(
        exercise: _bench(),
        set: const WorkoutSet(reps: 8, rir: 2, loadKg: 60, bodyWeightKg: 80),
      );
      expect(mli, closeTo(8 * (60 / 80) * 1.2 * 1.8, 1e-9));
    });

    test('extra weight multiplier is not applied', () {
      final mli = calculateSetMli(
        exercise: _bench(),
        set: const WorkoutSet(
          reps: 8,
          rir: 2,
          loadKg: 60,
          bodyWeightKg: 80,
          extraWeightKg: 20,
        ),
      );
      expect(mli, closeTo(8 * 0.75 * 1.2 * 1.8, 1e-9));
    });

    test('null / non-positive body weight falls back to 75 kg', () {
      expect(kDefaultBodyWeightKg, 75.0);
      for (final bw in <double?>[null, 0, -5]) {
        final mli = calculateSetMli(
          exercise: _bench(lf: 1.0),
          set: WorkoutSet(reps: 10, rir: 0, loadKg: 75, bodyWeightKg: bw),
        );
        expect(mli, closeTo(10 * 1.0 * 1.0 * 2.0, 1e-9), reason: '$bw');
      }
    });

    test('null / non-positive loadKg gives MLI 0', () {
      for (final load in <double?>[null, 0, -10]) {
        final mli = calculateSetMli(
          exercise: _bench(),
          set: WorkoutSet(reps: 10, rir: 2, loadKg: load, bodyWeightKg: 80),
        );
        expect(mli, 0.0, reason: '$load');
      }
    });

    test('static bodybuilding hold uses seconds × 0.5 and M_SIR', () {
      final mli = calculateSetMli(
        exercise: _bench(lf: 1.0),
        set: const WorkoutSet(
          reps: 0,
          rir: 0,
          durationInSeconds: 20,
          loadKg: 40,
          bodyWeightKg: 80,
        ),
      );
      expect(mli, closeTo(10 * 0.5 * 1.0 * 1.05, 1e-9));
    });
  });

  group('per-muscle loads', () {
    final pushUp = exerciseDatabase['standard_push_up']!;
    const set = WorkoutSet(reps: 10, rir: 2);

    test('compartment load = setMli × weight and sums to setMli', () {
      final setMli = calculateSetMli(exercise: pushUp, set: set);
      final load = calculateCompartmentLoad(exercise: pushUp, set: set);
      expect(load[MuscleCompartment.midChest], closeTo(setMli * 0.35, 1e-9));
      final sum = load.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(setMli, 1e-9));
    });

    test('legacy wrapper returns region keys with the same total', () {
      final setMli = calculateSetMli(exercise: pushUp, set: set);
      final legacy = calculateMuscleLoad(exercise: pushUp, set: set);
      expect(legacy.keys.toSet(), {'chest', 'arms', 'shoulders', 'core'});
      expect(legacy['chest'], closeTo(setMli * 0.55, 1e-9));
      final sum = legacy.values.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(setMli, 1e-9));
    });

    test('workout totals agree between compartment and legacy views', () {
      final entries = [
        ExerciseWorkoutEntry(exercise: pushUp, sets: const [set, set]),
        ExerciseWorkoutEntry(
          exercise: exerciseDatabase['standard_pull_up']!,
          sets: const [WorkoutSet(reps: 6, rir: 1)],
        ),
      ];
      final compartments = calculateWorkoutCompartmentLoad(entries);
      final legacy = calculateWorkoutLoad(entries);
      final a = compartments.values.fold<double>(0, (x, y) => x + y);
      final b = legacy.values.fold<double>(0, (x, y) => x + y);
      expect(a, closeTo(b, 1e-9));
    });
  });
}
