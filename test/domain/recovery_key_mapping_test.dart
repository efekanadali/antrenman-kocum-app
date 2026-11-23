// test/domain/recovery_key_mapping_test.dart
//
// `recoveryMuscleFromKey` davranışını göç öncesi switch tablosuna kilitler.

import 'package:calisthenics_app/core/utils/enum_label.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/legacy_recovery_keys.dart';

/// EnumLabel'ın MuscleGroup için ürettiği Türkçe etiketlerin beklenen bölgesi.
const Map<MuscleGroup, RecoveryMuscle> kMuscleGroupRegion = {
  MuscleGroup.chest: RecoveryMuscle.chest,
  MuscleGroup.back: RecoveryMuscle.back,
  MuscleGroup.shoulders: RecoveryMuscle.shoulders,
  MuscleGroup.biceps: RecoveryMuscle.arms,
  MuscleGroup.triceps: RecoveryMuscle.arms,
  MuscleGroup.legs: RecoveryMuscle.legs,
  MuscleGroup.core: RecoveryMuscle.core,
  MuscleGroup.quads: RecoveryMuscle.legs,
  MuscleGroup.hamstrings: RecoveryMuscle.legs,
  MuscleGroup.glutes: RecoveryMuscle.legs,
  MuscleGroup.calves: RecoveryMuscle.legs,
};

void main() {
  test('every legacy switch key maps to its region', () {
    kLegacyRecoveryKeys.forEach((key, region) {
      expect(recoveryMuscleFromKey(key), region, reason: key);
    });
  });

  test('every MuscleGroup enum name maps to its region', () {
    for (final group in MuscleGroup.values) {
      expect(
        recoveryMuscleFromKey(group.name),
        kMuscleGroupRegion[group],
        reason: group.name,
      );
    }
  });

  test('EnumLabel Turkish labels of MuscleGroup map to their region', () {
    const expectedLabels = [
      'Göğüs',
      'Sırt',
      'Omuz',
      'Biseps',
      'Triseps',
      'Bacak',
      'Karın',
      'Quadriceps',
      'Hamstrings',
      'Kalça',
      'Baldır',
    ];
    expect(
      MuscleGroup.values.map((g) => g.label).toSet(),
      expectedLabels.toSet(),
    );
    for (final group in MuscleGroup.values) {
      expect(
        recoveryMuscleFromKey(group.label),
        kMuscleGroupRegion[group],
        reason: group.label,
      );
    }
  });

  test('case and whitespace variants are normalised', () {
    expect(recoveryMuscleFromKey('  CHEST '), RecoveryMuscle.chest);
    expect(recoveryMuscleFromKey('Back'), RecoveryMuscle.back);
    expect(recoveryMuscleFromKey('\tShoulders\n'), RecoveryMuscle.shoulders);
    expect(recoveryMuscleFromKey(' Biceps'), RecoveryMuscle.arms);
    expect(recoveryMuscleFromKey('TRISEPS '), RecoveryMuscle.arms);
    expect(recoveryMuscleFromKey(' Karın '), RecoveryMuscle.core);
    expect(recoveryMuscleFromKey('KARIN'), RecoveryMuscle.core);
    expect(recoveryMuscleFromKey('GLUTES'), RecoveryMuscle.legs);
    expect(recoveryMuscleFromKey(' Kalca '), RecoveryMuscle.legs);
    expect(recoveryMuscleFromKey('Baldir'), RecoveryMuscle.legs);
  });

  test('unknown keys return null', () {
    expect(recoveryMuscleFromKey('Genel'), isNull);
    expect(recoveryMuscleFromKey('genel'), isNull);
    expect(recoveryMuscleFromKey(''), isNull);
    expect(recoveryMuscleFromKey('   '), isNull);
    expect(recoveryMuscleFromKey('neck'), isNull);
  });
}
