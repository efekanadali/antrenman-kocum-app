// test/domain/threshold_calibration_test.dart
//
// 80/220 MLI eşiklerinin 17 kompartımanlı (ağırlık toplamı 1.00) modele
// kalibrasyonunu belgeler ve doğrular.
//
// Yöntem:
//  1. test/fixtures/mli_golden_v1.json'daki her vaka için birincil bölge
//     belirlenir (eski bölge yüklerinde en büyük; eşitlikte yeni modelin
//     birincil bölgesi seçilir).
//  2. Bu bölgede `oran = yeni_bölge_yükü / eski_bölge_yükü` hesaplanır. Ham set
//     MLI değişmediği için oran = yeni bölge ağırlığı / eski ağırlık toplamı.
//  3. Ölçek = oranların medyanı (aykırı değerlere dayanıklı).
//  4. Yeni eşikler = 80 × ölçek, 220 × ölçek.

import 'dart:convert';
import 'dart:io';

import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/mli_golden_v2_builder.dart';

class _CaseCalibration {
  _CaseCalibration({
    required this.id,
    required this.region,
    required this.oldLoad,
    required this.newLoad,
  });

  final String id;
  final String region;
  final double oldLoad;
  final double newLoad;

  double get ratio => newLoad / oldLoad;
}

MliStimulusLevel _legacyLevel(double score) {
  if (score < kLegacyUnderstimulatedThreshold) {
    return MliStimulusLevel.understimulated;
  }
  if (score <= kLegacyOverloadThreshold) return MliStimulusLevel.optimal;
  return MliStimulusLevel.overload;
}

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final n = sorted.length;
  return n.isOdd
      ? sorted[n ~/ 2]
      : (sorted[n ~/ 2 - 1] + sorted[n ~/ 2]) / 2;
}

void main() {
  final v1 = jsonDecode(File(kMliGoldenV1FixturePath).readAsStringSync())
      as Map<String, dynamic>;

  final calibrations = <_CaseCalibration>[];
  for (final c in (v1['cases'] as List).cast<Map<String, dynamic>>()) {
    final oldRegionLoad = (c['regionLoad'] as Map).cast<String, num>();
    final exercise = exerciseDatabase[c['exerciseId']]!;
    final set = workoutSetFromJson(c['set'] as Map<String, dynamic>);
    final newRegionLoad = {
      for (final e in aggregateToRegions(
        calculateCompartmentLoad(exercise: exercise, set: set),
      ).entries)
        e.key.name: e.value,
    };
    final oldPrimary = primaryRegions(oldRegionLoad);
    final newPrimary = primaryRegions(newRegionLoad).single;
    final region =
        oldPrimary.contains(newPrimary) ? newPrimary : (oldPrimary.toList()..sort()).first;
    calibrations.add(_CaseCalibration(
      id: '${c['exerciseId']}/${c['variant']}',
      region: region,
      oldLoad: oldRegionLoad[region]!.toDouble(),
      newLoad: newRegionLoad[region] ?? 0,
    ));
  }

  final medianRatio = _median(calibrations.map((c) => c.ratio).toList());

  test('calibration uses all 48 golden v1 cases', () {
    expect(calibrations, hasLength(48));
  });

  test('scale constant is the median primary-region ratio', () {
    expect(medianRatio, closeTo(0.47, 1e-9));
    expect(kMliCalibrationScale, closeTo(medianRatio, 1e-9));
  });

  test('thresholds are the legacy thresholds × scale', () {
    expect(
      kMliUnderstimulatedThreshold,
      closeTo(kLegacyUnderstimulatedThreshold * kMliCalibrationScale, 1e-9),
    );
    expect(
      kMliOverloadThreshold,
      closeTo(kLegacyOverloadThreshold * kMliCalibrationScale, 1e-9),
    );
    expect(kMliUnderstimulatedThreshold, 37.6);
    expect(kMliOverloadThreshold, 103.4);
  });

  test('evaluateMuscleLoad uses the calibrated boundaries', () {
    expect(evaluateMuscleLoad(37.59).level, MliStimulusLevel.understimulated);
    expect(evaluateMuscleLoad(37.6).level, MliStimulusLevel.optimal);
    expect(evaluateMuscleLoad(103.4).level, MliStimulusLevel.optimal);
    expect(evaluateMuscleLoad(103.41).level, MliStimulusLevel.overload);
  });

  test('primary-region classification before vs after is pinned', () {
    final changed = <String>[];
    for (final c in calibrations) {
      final before = _legacyLevel(c.oldLoad);
      final after = evaluateMuscleLoad(c.newLoad).level;
      if (before != after) {
        changed.add('${c.id} (${c.region}): ${before.name} → ${after.name}');
      }
    }
    // Tek set (10 tekrar / 30 sn) vakalarında 48 vakanın 46'sı aynı kalır.
    expect(changed, [
      'box_jump/reps10_rir2 (legs): optimal → understimulated',
      'pistol_squat/reps10_rir2 (legs): optimal → understimulated',
    ]);
  });
}
