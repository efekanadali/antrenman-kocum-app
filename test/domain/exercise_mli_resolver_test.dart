// test/domain/exercise_mli_resolver_test.dart

import 'package:calisthenics_app/data/repositories/fake_exercise_repository.dart';
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/domain/models/exercise.dart' as domain;
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart' as mli;
import 'package:calisthenics_app/domain/services/exercise_mli_resolver.dart';
import 'package:calisthenics_app/domain/services/muscle_group_derivation.dart';
import 'package:flutter_test/flutter_test.dart';

CustomProgramExercise _item(String id, String name) => CustomProgramExercise(
      exerciseId: id,
      exerciseName: name,
      sets: 3,
      value: 10,
      isTimed: false,
    );

void _expectValid(mli.Exercise e) {
  final sum = e.compartments.values.fold<double>(0, (a, b) => a + b);
  expect(sum, closeTo(1.0, 1e-9), reason: e.name);
}

void main() {
  test('library exercise resolves to its compartments', () {
    final resolver = ExerciseMliResolver();
    final e = resolver.build(_item('standard_pull_up', 'Standard Pull-up'));
    expect(e.compartments, exerciseDatabase['standard_pull_up']!.compartments);
    expect(e.difficulty, 1.55);
  });

  test('catalog detail with compartmentWeights is used as-is', () async {
    final catalog = await FakeExerciseRepository().getAllExercises();
    final resolver = ExerciseMliResolver(catalog: catalog);
    final e = resolver.build(_item('dips_parallel_bar', 'Parallel Bar Dips'));
    expect(e.compartments, exerciseDatabase['dips_parallel_bar']!.compartments);
    _expectValid(e);
  });

  test('detail ratings are converted to normalized compartments', () {
    const detail = domain.Exercise(
      id: 'custom_curl',
      name: 'Custom Curl',
      level: ExerciseLevel.beginner,
      difficulty: DifficultyLevel.easy,
      targetMuscleGroups: [MuscleGroup.biceps, MuscleGroup.core],
      muscleRatings: {MuscleGroup.biceps: 5, MuscleGroup.core: 1},
      description: '',
    );
    final resolver = ExerciseMliResolver(catalog: const [detail]);
    final e = resolver.build(_item('custom_curl', 'Custom Curl'));
    _expectValid(e);
    // omega: biceps 1.0, core 0.2 → 1/1.2 ve 0.2/1.2
    expect(e.compartments[MuscleCompartment.biceps], closeTo(1 / 1.2, 1e-9));
    expect(e.compartments[MuscleCompartment.core], closeTo(0.2 / 1.2, 1e-9));
    // Türkçe etiket anahtarları artık üretilmez.
    expect(e.muscles.keys.toSet(), {'arms', 'core'});
    expect(e.difficulty, 1.0);
  });

  test('detail target groups only → normalized compartments', () {
    const detail = domain.Exercise(
      id: 'custom_press',
      name: 'Custom Press',
      level: ExerciseLevel.beginner,
      difficulty: DifficultyLevel.medium,
      targetMuscleGroups: [MuscleGroup.chest, MuscleGroup.triceps],
      muscleRatings: {},
      description: '',
    );
    final resolver = ExerciseMliResolver(catalog: const [detail]);
    final e = resolver.build(_item('custom_press', 'Custom Press'));
    _expectValid(e);
    expect(e.muscles['chest'], closeTo(1 / 1.5, 1e-9));
    expect(e.difficulty, 1.25);
  });

  test('name inference templates sum to 1.00', () {
    final resolver = ExerciseMliResolver();
    for (final name in [
      'Ring Push Variation',
      'Weighted Row Thing',
      'Jump Squat Mix',
      'Mystery Move',
    ]) {
      final e = resolver.build(_item('unknown_$name', name));
      _expectValid(e);
    }
    expect(
      resolver.build(_item('x', 'Ring Push Variation')).muscles.keys,
      contains('chest'),
    );
  });

  test('fake repository derives ratings and targets from compartments',
      () async {
    final catalog = await FakeExerciseRepository().getAllExercises();
    expect(catalog, hasLength(38));
    final pushUp = catalog.firstWhere((e) => e.id == 'standard_push_up');
    expect(pushUp.compartmentWeights, isNotEmpty);
    expect(pushUp.targetMuscleGroups.first, MuscleGroup.chest);
    expect(pushUp.muscleRatings[MuscleGroup.chest], 5);
    final calf = catalog.firstWhere((e) => e.id == 'calf_raise');
    expect(calf.targetMuscleGroups, [MuscleGroup.calves]);

    final byBack = await FakeExerciseRepository()
        .getExercisesByMuscleGroup(MuscleGroup.back);
    expect(byBack.map((e) => e.id), contains('standard_pull_up'));
  });

  test('deriveMuscleGroups ignores forearms and ranks by weight', () {
    final derived = deriveMuscleGroups(const {
      MuscleCompartment.lats: 0.4,
      MuscleCompartment.upperBackTraps: 0.1,
      MuscleCompartment.biceps: 0.25,
      MuscleCompartment.forearms: 0.25,
    });
    expect(derived.targets, [MuscleGroup.back, MuscleGroup.biceps]);
    expect(derived.ratings, {MuscleGroup.back: 5, MuscleGroup.biceps: 3});
  });
}
