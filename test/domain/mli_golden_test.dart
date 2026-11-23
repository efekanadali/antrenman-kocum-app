// test/domain/mli_golden_test.dart
//
// Kas kompartımanı göçü süresince MLI / Recovery sonuçlarının değişmediğini
// doğrular. Fixture: test/fixtures/mli_golden_v1.json
// (üretici: tool/generate_mli_golden.dart).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/mli_golden_builder.dart';

const double _tolerance = 1e-9;

void _expectDeepClose(Object? actual, Object? expected, String path) {
  if (expected is num && actual is num) {
    expect(
      (actual - expected).abs() <= _tolerance,
      isTrue,
      reason: '$path: expected $expected, got $actual',
    );
    return;
  }
  if (expected is Map) {
    expect(actual, isA<Map>(), reason: '$path should be a map');
    final actualMap = actual! as Map;
    expect(
      actualMap.keys.toSet(),
      expected.keys.toSet(),
      reason: '$path: key set differs',
    );
    for (final key in expected.keys) {
      _expectDeepClose(actualMap[key], expected[key], '$path.$key');
    }
    return;
  }
  if (expected is List) {
    expect(actual, isA<List>(), reason: '$path should be a list');
    final actualList = actual! as List;
    expect(actualList.length, expected.length, reason: '$path: length differs');
    for (var i = 0; i < expected.length; i++) {
      _expectDeepClose(actualList[i], expected[i], '$path[$i]');
    }
    return;
  }
  expect(actual, expected, reason: path);
}

void main() {
  final fixture = jsonDecode(File(kMliGoldenFixturePath).readAsStringSync())
      as Map<String, dynamic>;
  // JSON round-trip, üretici ile aynı sayı temsiline normalize eder.
  final actual =
      jsonDecode(jsonEncode(buildMliGolden())) as Map<String, dynamic>;

  test('fixture header matches current exercise database', () {
    expect(actual['schemaVersion'], fixture['schemaVersion']);
    expect(actual['completedAt'], fixture['completedAt']);
    expect(actual['exerciseCount'], fixture['exerciseCount']);
    expect(actual['exerciseIds'], fixture['exerciseIds']);
    expect(
      (actual['cases'] as List).length,
      (fixture['cases'] as List).length,
    );
  });

  final expectedCases = (fixture['cases'] as List).cast<Map<String, dynamic>>();
  final actualCases = {
    for (final c in (actual['cases'] as List).cast<Map<String, dynamic>>())
      '${c['exerciseId']}/${c['variant']}': c,
  };

  group('golden case', () {
    for (final expected in expectedCases) {
      final id = '${expected['exerciseId']}/${expected['variant']}';
      test(id, () {
        final current = actualCases[id];
        expect(current, isNotNull, reason: 'case $id missing');
        _expectDeepClose(current, expected, id);
      });
    }
  });
}
