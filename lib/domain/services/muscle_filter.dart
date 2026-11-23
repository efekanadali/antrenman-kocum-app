// lib/domain/services/muscle_filter.dart
//
// Kütüphane / favori filtreleri için kompartıman ağırlıklarına dayalı eşleme.

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';

/// Bir egzersizin bir bölgeyi / kompartımanı "hedeflediği" kabul edilen en
/// düşük ağırlık (toplam 1.00 içinde). Böylece %5'lik stabilizatör payları
/// (ör. şınavda kalça) filtre sonuçlarını kirletmez.
const double kMuscleFilterMinWeight = 0.10;

/// Bölgenin toplam ağırlığı.
double regionWeight(
  Map<MuscleCompartment, double> weights,
  MuscleRegion region,
) {
  var sum = 0.0;
  weights.forEach((c, w) {
    if (c.region == region) sum += w;
  });
  return sum;
}

bool targetsRegion(Map<MuscleCompartment, double> weights, MuscleRegion r) =>
    regionWeight(weights, r) >= kMuscleFilterMinWeight;

bool targetsCompartment(
  Map<MuscleCompartment, double> weights,
  MuscleCompartment c,
) =>
    (weights[c] ?? 0) >= kMuscleFilterMinWeight;

/// Hedeflenen bölgeler (ağırlığa göre azalan).
List<MuscleRegion> targetRegions(Map<MuscleCompartment, double> weights) {
  final regions = [
    for (final r in MuscleRegion.values)
      if (targetsRegion(weights, r)) r,
  ];
  regions.sort((a, b) {
    final byWeight = regionWeight(weights, b).compareTo(regionWeight(weights, a));
    return byWeight != 0 ? byWeight : a.index.compareTo(b.index);
  });
  return regions;
}

/// Seçili bölge ve kompartımanlara göre eşleme.
///
/// * Seçim yoksa her egzersiz eşleşir.
/// * [matchAll] `true` ise seçilen HER bölge/kompartıman hedeflenmelidir;
///   `false` ise herhangi biri yeterlidir.
bool matchesMuscleFilter(
  Map<MuscleCompartment, double> weights, {
  Set<MuscleRegion> regions = const {},
  Set<MuscleCompartment> compartments = const {},
  bool matchAll = true,
}) {
  if (regions.isEmpty && compartments.isEmpty) return true;
  final checks = [
    for (final r in regions) targetsRegion(weights, r),
    for (final c in compartments) targetsCompartment(weights, c),
  ];
  return matchAll ? checks.every((m) => m) : checks.any((m) => m);
}
