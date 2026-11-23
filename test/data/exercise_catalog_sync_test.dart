// test/data/exercise_catalog_sync_test.dart

import 'package:calisthenics_app/data/repositories/fake_exercise_repository.dart';
import 'package:calisthenics_app/data/services/exercise_catalog_sync.dart';
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/models/exercise.dart' as domain;
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

domain.Exercise _remote(String id, String name) => domain.Exercise(
      id: id,
      name: name,
      level: ExerciseLevel.beginner,
      difficulty: DifficultyLevel.easy,
      targetMuscleGroups: const [],
      muscleRatings: const {},
      description: 'remote',
    );

void main() {
  test('versioned seed: upsert only when remote version is older', () {
    expect(kExerciseCatalogVersion, 2);
    expect(shouldUpsertExerciseCatalog(null), isTrue);
    expect(shouldUpsertExerciseCatalog(1), isTrue);
    expect(shouldUpsertExerciseCatalog('2'), isTrue); // geçersiz tip → 0
    expect(shouldUpsertExerciseCatalog(2), isFalse);
    expect(shouldUpsertExerciseCatalog(3), isFalse);
  });

  test('catalog doc has compartments, type, schemaVersion and legacy muscles',
      () {
    final doc = exerciseCatalogDoc(
      'standard_push_up',
      exerciseDatabase['standard_push_up']!,
    );
    expect(doc['id'], 'standard_push_up');
    expect(doc['type'], 'calisthenics');
    expect(doc['schemaVersion'], 2);
    expect(doc['difficulty'], 1.0);
    expect(doc['leverageFactor'], 1.0);
    expect((doc['muscles'] as Map).keys.toSet(),
        {'chest', 'arms', 'shoulders', 'core'});
    final compartments = (doc['compartments'] as Map).cast<String, double>();
    expect(compartments['mid_chest'], 0.35);
    final sum = compartments.values.fold<double>(0, (a, b) => a + b);
    expect(sum, closeTo(1.0, 1e-9));

    // Uygulamanın Firestore okuyucusu aynı ağırlıkları geri elde eder.
    final parsed = parseCompartmentWeights(doc['compartments']);
    final expected = exerciseDatabase['standard_push_up']!.compartments;
    expect(parsed.keys.toSet(), expected.keys.toSet());
    expected.forEach((c, w) => expect(parsed[c], closeTo(w, 1e-9)));
  });

  test('all 38 library exercises produce a doc', () {
    expect(buildExerciseCatalogDocs(), hasLength(38));
  });

  test('merge: local biomechanics win, remote-only exercises are added',
      () async {
    final local = await FakeExerciseRepository().getAllExercises();
    final merged = mergeExerciseCatalog(
      local: local,
      remote: [
        _remote('standard_push_up', 'Remote Override'),
        _remote('ring_dip', 'Ring Dip'),
        _remote('ring_dip', 'Ring Dip duplicate'),
      ],
    );
    expect(merged, hasLength(39));
    final pushUp = merged.firstWhere((e) => e.id == 'standard_push_up');
    expect(pushUp.name, 'Standard Push-up');
    expect(pushUp.compartmentWeights, isNotEmpty);
    expect(merged.last.id, 'ring_dip');
    expect(merged.last.name, 'Ring Dip');
  });

  test('merge with empty remote returns the local catalog', () async {
    final local = await FakeExerciseRepository().getAllExercises();
    expect(mergeExerciseCatalog(local: local, remote: const []), local);
  });
}
