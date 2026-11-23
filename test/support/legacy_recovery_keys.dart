// test/support/legacy_recovery_keys.dart

import 'package:calisthenics_app/domain/models/muscle_recovery.dart';

/// Eski switch'teki her anahtar ve beklenen bölge.
const Map<String, RecoveryMuscle> kLegacyRecoveryKeys = {
  'chest': RecoveryMuscle.chest,
  'göğüs': RecoveryMuscle.chest,
  'gogus': RecoveryMuscle.chest,
  'back': RecoveryMuscle.back,
  'sırt': RecoveryMuscle.back,
  'sirt': RecoveryMuscle.back,
  'shoulders': RecoveryMuscle.shoulders,
  'shoulder': RecoveryMuscle.shoulders,
  'omuz': RecoveryMuscle.shoulders,
  'biceps': RecoveryMuscle.arms,
  'biseps': RecoveryMuscle.arms,
  'triceps': RecoveryMuscle.arms,
  'triseps': RecoveryMuscle.arms,
  'kol': RecoveryMuscle.arms,
  'arms': RecoveryMuscle.arms,
  'core': RecoveryMuscle.core,
  'abs': RecoveryMuscle.core,
  'karın': RecoveryMuscle.core,
  'karin': RecoveryMuscle.core,
  'legs': RecoveryMuscle.legs,
  'bacak': RecoveryMuscle.legs,
  'quads': RecoveryMuscle.legs,
  'quadriceps': RecoveryMuscle.legs,
  'hamstrings': RecoveryMuscle.legs,
  'glutes': RecoveryMuscle.legs,
  'kalça': RecoveryMuscle.legs,
  'kalca': RecoveryMuscle.legs,
  'calves': RecoveryMuscle.legs,
  'baldır': RecoveryMuscle.legs,
  'baldir': RecoveryMuscle.legs,
};
