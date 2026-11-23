// lib/presentation/utils/core_zone_filter.dart
//
// Hareket kütüphanesindeki "Karın" filtresinin Karın / Oblik alt ayrımı.
//
// Biyomekanik modelde karın tek kompartımandır (`MuscleCompartment.core`) ve
// MLI ağırlıkları bu ayrımdan ETKİLENMEZ. Alt bölge yalnızca harita ve
// filtre içindir: oblik (yan karın / anti-rotasyon / yana bükülme) ağırlıklı
// hareketler aşağıdaki listede tutulur.

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/services/muscle_filter.dart';
import 'package:calisthenics_app/presentation/widgets/ui/anatomical_muscle_map.dart';

/// Obliği belirgin çalıştıran hareketler (anti-rotasyon, yan plank, rotasyonel
/// stabilizasyon, bacak kaldırma varyasyonları).
const Set<String> kObliqueExerciseIds = {
  'side_plank',
  'pallof_press',
  'single_arm_dumbbell_row',
  'one_arm_pull_up',
  'hanging_leg_raise',
  'ab_wheel_rollout',
};

/// Karın orta hattını (rectus abdominis) değil, yalnızca obliği öne çıkaran
/// hareketler; "Karın" alt filtresinde listelenmez.
const Set<String> kObliqueOnlyExerciseIds = {
  'side_plank',
  'pallof_press',
  'single_arm_dumbbell_row',
  'one_arm_pull_up',
};

/// Hareket bu karın alt bölgesini hedefliyor mu?
bool targetsCoreZone(
  String exerciseId,
  Map<MuscleCompartment, double> weights,
  CoreZone zone,
) {
  switch (zone) {
    case CoreZone.obliques:
      return kObliqueExerciseIds.contains(exerciseId);
    case CoreZone.abs:
      return targetsCompartment(weights, MuscleCompartment.core) &&
          !kObliqueOnlyExerciseIds.contains(exerciseId);
  }
}

/// Seçili alt bölgelerden herhangi biri hedefleniyorsa `true` (seçim yoksa
/// her hareket eşleşir).
bool matchesCoreZones(
  String exerciseId,
  Map<MuscleCompartment, double> weights,
  Set<CoreZone> zones,
) {
  if (zones.isEmpty) return true;
  return zones.any((z) => targetsCoreZone(exerciseId, weights, z));
}
