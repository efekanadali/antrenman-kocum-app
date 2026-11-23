// test/domain/mli_golden_v2_test.dart
//
// 17 kompartımanlı modelin çıktısını test/fixtures/mli_golden_v2.json ile
// karşılaştırır (üretici: tool/generate_mli_golden.dart).

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../support/mli_golden_v2_builder.dart';

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
  final fixture = jsonDecode(File(kMliGoldenV2FixturePath).readAsStringSync())
      as Map<String, dynamic>;
  final actual =
      jsonDecode(jsonEncode(buildMliGoldenV2())) as Map<String, dynamic>;

  test('header matches', () {
    final header = Map<String, dynamic>.of(actual)..remove('cases');
    final expected = Map<String, dynamic>.of(fixture)..remove('cases');
    _expectDeepClose(header, expected, 'header');
  });

  final actualCases = {
    for (final c in (actual['cases'] as List).cast<Map<String, dynamic>>())
      '${c['exerciseId']}/${c['variant']}': c,
  };

  group('golden v2 case', () {
    for (final expected
        in (fixture['cases'] as List).cast<Map<String, dynamic>>()) {
      final id = '${expected['exerciseId']}/${expected['variant']}';
      test(id, () {
        expect(actualCases[id], isNotNull, reason: 'case $id missing');
        _expectDeepClose(actualCases[id], expected, id);
      });
    }
  });

  test('no extra cases', () {
    expect(actualCases.length, (fixture['cases'] as List).length);
  });
}
