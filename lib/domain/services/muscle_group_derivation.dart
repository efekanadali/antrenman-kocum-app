// lib/domain/services/muscle_group_derivation.dart
//
// Kompartıman ağırlıklarından kütüphane filtrelerinin kullandığı
// `MuscleGroup` puanlarını ve hedef kas listesini türetir.

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';

/// Kompartımanın kütüphane filtresindeki karşılığı. Ön kolun ayrı bir
/// `MuscleGroup` karşılığı yoktur (`null`).
MuscleGroup? muscleGroupForCompartment(MuscleCompartment compartment) {
  switch (compartment) {
    case MuscleCompartment.upperChest:
    case MuscleCompartment.midChest:
    case MuscleCompartment.lowerChest:
      return MuscleGroup.chest;
    case MuscleCompartment.anteriorDeltoid:
    case MuscleCompartment.lateralDeltoid:
    case MuscleCompartment.posteriorDeltoid:
      return MuscleGroup.shoulders;
    case MuscleCompartment.lats:
    case MuscleCompartment.upperBackTraps:
    case MuscleCompartment.lowerBack:
      return MuscleGroup.back;
    case MuscleCompartment.biceps:
      return MuscleGroup.biceps;
    case MuscleCompartment.triceps:
      return MuscleGroup.triceps;
    case MuscleCompartment.forearms:
      return null;
    case MuscleCompartment.quads:
      return MuscleGroup.quads;
    case MuscleCompartment.hamstrings:
      return MuscleGroup.hamstrings;
    case MuscleCompartment.glutes:
      return MuscleGroup.glutes;
    case MuscleCompartment.calves:
      return MuscleGroup.calves;
    case MuscleCompartment.core:
      return MuscleGroup.core;
  }
}

/// Kompartıman ağırlıklarından türetilen kas grubu puanları (1–5) ve hedef
/// kas listesi (ağırlığa göre azalan sırada).
///
/// Puan, grubun en baskın gruba göre oranıdır:
/// `round(ağırlık / en_büyük_ağırlık × 5)`, pozitif ağırlıklar için en az 1.
({Map<MuscleGroup, int> ratings, List<MuscleGroup> targets})
    deriveMuscleGroups(Map<MuscleCompartment, double> compartments) {
  final weights = <MuscleGroup, double>{};
  compartments.forEach((c, w) {
    final group = muscleGroupForCompartment(c);
    if (group == null || w <= 0) return;
    weights[group] = (weights[group] ?? 0) + w;
  });
  if (weights.isEmpty) {
    return (ratings: <MuscleGroup, int>{}, targets: <MuscleGroup>[]);
  }

  final maxWeight = weights.values.reduce((a, b) => a > b ? a : b);
  final targets = weights.keys.toList()
    ..sort((a, b) {
      final byWeight = weights[b]!.compareTo(weights[a]!);
      return byWeight != 0 ? byWeight : a.index.compareTo(b.index);
    });
  final ratings = <MuscleGroup, int>{
    for (final g in targets)
      g: (weights[g]! / maxWeight * 5).round().clamp(1, 5).toInt(),
  };
  return (ratings: ratings, targets: targets);
}
