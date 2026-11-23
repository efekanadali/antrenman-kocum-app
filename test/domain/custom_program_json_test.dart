// test/domain/custom_program_json_test.dart

import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('old-format program JSON (no loadKg) still parses', () {
    final json = <String, dynamic>{
      'id': 'p1',
      'name': 'Eski Program',
      'daysCount': 1,
      'createdAt': '2025-06-01T10:00:00.000',
      'days': [
        {
          'dayIndex': 1,
          'name': 'Gün 1',
          'exercises': [
            {
              'exerciseId': 'standard_push_up',
              'exerciseName': 'Standard Push-up',
              'sets': 3,
              'value': 12,
              'isTimed': false,
            },
            // Daha eski biçim: `value` yerine `reps`, `isTimed` yok.
            {
              'exerciseId': 'plank',
              'exerciseName': 'Plank',
              'sets': 2,
              'reps': 30,
            },
          ],
        },
      ],
    };
    final program = CustomProgram.fromJson(json);
    final exercises = program.days.single.exercises;
    expect(exercises, hasLength(2));
    expect(exercises[0].value, 12);
    expect(exercises[0].loadKg, isNull);
    expect(exercises[1].value, 30);
    expect(exercises[1].isTimed, isFalse);
    expect(exercises[1].loadKg, isNull);
  });

  test('loadKg accepts int, double and numeric strings', () {
    Map<String, dynamic> base(Object? load) => {
          'exerciseId': 'x',
          'exerciseName': 'X',
          'sets': 1,
          'value': 8,
          'isTimed': false,
          'loadKg': load,
        };
    expect(CustomProgramExercise.fromJson(base(60)).loadKg, 60.0);
    expect(CustomProgramExercise.fromJson(base(62.5)).loadKg, 62.5);
    expect(CustomProgramExercise.fromJson(base('40')).loadKg, 40.0);
    expect(CustomProgramExercise.fromJson(base(null)).loadKg, isNull);
    expect(CustomProgramExercise.fromJson(base('abc')).loadKg, isNull);
  });

  test('toJson writes loadKg only when non-null and round-trips', () {
    const calisthenics = CustomProgramExercise(
      exerciseId: 'standard_push_up',
      exerciseName: 'Standard Push-up',
      sets: 3,
      value: 12,
      isTimed: false,
    );
    expect(calisthenics.toJson().containsKey('loadKg'), isFalse);
    expect(calisthenics.toJson(), {
      'exerciseId': 'standard_push_up',
      'exerciseName': 'Standard Push-up',
      'sets': 3,
      'value': 12,
      'isTimed': false,
    });

    const weighted = CustomProgramExercise(
      exerciseId: 'bench',
      exerciseName: 'Bench Press',
      sets: 4,
      value: 8,
      isTimed: false,
      loadKg: 70,
    );
    expect(weighted.toJson()['loadKg'], 70.0);
    expect(CustomProgramExercise.fromJson(weighted.toJson()).loadKg, 70.0);
  });
}
