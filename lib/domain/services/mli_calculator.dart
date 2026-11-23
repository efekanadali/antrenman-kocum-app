import 'package:calisthenics_app/domain/enums/exercise_type.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';

double _dynamicRirFactor(int rir) {
  return 1 + (10 - rir) / 10;
}

double _staticMsirFactor(int secondsInReserve) {
  if (secondsInReserve <= 0) {
    return 1.05;
  }
  if (secondsInReserve <= 3) {
    return 1.0;
  }
  if (secondsInReserve <= 6) {
    return 0.8;
  }
  return 0.6;
}

/// MLI = reps x C x (1 + (10 - RIR) / 10)
///
/// Backward compatibility icin reps parametresi de desteklenir.
double calculateMLI({
  double? volume,
  int? reps,
  required double difficulty,
  required int rir,
  double weightMultiplier = 1.0,
}) {
  final resolvedVolume = volume ?? reps?.toDouble();
  if (resolvedVolume == null) {
    throw ArgumentError('Either volume or reps must be provided.');
  }

  return resolvedVolume *
      difficulty *
      _dynamicRirFactor(rir) *
      weightMultiplier;
}

/// Statik model: (sure * 0.5) x C x M_SIR
double calculateStaticMLI({
  required int durationInSeconds,
  required double difficulty,
  required int secondsInReserve,
  double weightMultiplier = 1.0,
}) {
  final volume = durationInSeconds * 0.5;
  return volume *
      difficulty *
      _staticMsirFactor(secondsInReserve) *
      weightMultiplier;
}

/// Vücut geliştirme formülünde vücut ağırlığı bilinmiyorsa kullanılan
/// referans vücut ağırlığı (kg).
const double kDefaultBodyWeightKg = 75.0;

/// Vücut geliştirme seti için göreli yük oranı `loadKg / bodyWeightKg`.
///
/// * `loadKg` null veya ≤ 0 ise oran 0 kabul edilir → set MLI'ı 0 olur
///   (kaldırılan ağırlık bilinmeden mekanik yük tahmin edilmez).
/// * `bodyWeightKg` null veya ≤ 0 ise [kDefaultBodyWeightKg] kullanılır.
double bodybuildingLoadRatio(WorkoutSet set) {
  final load = set.loadKg;
  if (load == null || load <= 0) return 0.0;
  final bw = set.bodyWeightKg;
  final bodyWeight = (bw == null || bw <= 0) ? kDefaultBodyWeightKg : bw;
  return load / bodyWeight;
}

/// Tek bir setin ham MLI skorunu (kas ağırlıklarıyla çarpılmadan önce) hesaplar.
///
/// * Kalistenik (varsayılan) – göç öncesi formülle BİREBİR aynıdır:
///   dinamik `Hacim × Lf × RIR_faktörü × W_m`, statik
///   `(sn × 0.5) × Lf × M_SIR × W_m`.
/// * Vücut geliştirme – `Hacim × (loadKg / bodyWeightKg) × Lf_bb × RIR_faktörü`;
///   statikte hacim yine `sn × 0.5` ve RIR faktörü yerine M_SIR kullanılır.
///   Ek ağırlık çarpanı (W_m) uygulanmaz: dış yük zaten `loadKg`'dir.
double calculateSetMli({
  required Exercise exercise,
  required WorkoutSet set,
}) {
  final weightMultiplier = exercise.type == ExerciseType.bodybuilding
      ? bodybuildingLoadRatio(set)
      : set.weightMultiplier;
  return set.durationInSeconds != null
      ? calculateStaticMLI(
          durationInSeconds: set.durationInSeconds!,
          difficulty: exercise.difficulty,
          secondsInReserve: set.rir,
          weightMultiplier: weightMultiplier,
        )
      : calculateMLI(
          volume: set.volume,
          difficulty: exercise.difficulty,
          rir: set.rir,
          weightMultiplier: weightMultiplier,
        );
}

/// Tek bir setin kompartıman bazlı yükü: `setMli × kompartıman_ağırlığı`.
Map<MuscleCompartment, double> calculateCompartmentLoad({
  required Exercise exercise,
  required WorkoutSet set,
}) {
  final mli = calculateSetMli(exercise: exercise, set: set);
  return {
    for (final entry in exercise.compartments.entries)
      entry.key: mli * entry.value,
  };
}

/// Tüm antrenmandaki setleri kompartıman bazında toplar.
Map<MuscleCompartment, double> calculateWorkoutCompartmentLoad(
  List<ExerciseWorkoutEntry> entries,
) {
  final totals = <MuscleCompartment, double>{};
  for (final entry in entries) {
    for (final set in entry.sets) {
      calculateCompartmentLoad(exercise: entry.exercise, set: set)
          .forEach((c, value) {
        totals[c] = (totals[c] ?? 0) + value;
      });
    }
  }
  return totals;
}

/// Tek bir setin kas bazli dagilimini hesaplar.
///
/// Geriye dönük uyumlu görünüm: kompartıman yükleri 6 ana bölgeye toplanır ve
/// eski İngilizce bölge anahtarlarıyla (`chest`, `back`, `shoulders`, `arms`,
/// `core`, `legs`) döner. Mevcut ekranlar ve Firestore yazımları bu biçimi
/// kullanır.
Map<String, double> calculateMuscleLoad({
  required Exercise exercise,
  required WorkoutSet set,
}) {
  final mli = calculateSetMli(exercise: exercise, set: set);

  final result = <String, double>{};
  exercise.muscles.forEach((muscleName, weight) {
    result[muscleName] = mli * weight;
  });
  return result;
}

/// Tum antrenmandaki setleri kas bazinda (eski bölge anahtarlarıyla) toplar.
Map<String, double> calculateWorkoutLoad(List<ExerciseWorkoutEntry> entries) {
  final totals = <String, double>{};

  for (final entry in entries) {
    for (final set in entry.sets) {
      final setLoad = calculateMuscleLoad(exercise: entry.exercise, set: set);
      setLoad.forEach((muscleName, value) {
        totals[muscleName] = (totals[muscleName] ?? 0) + value;
      });
    }
  }

  return totals;
}

// ─── Yük Eşik Değerlendirmesi ─────────────────────────────────────────────────

enum MliStimulusLevel {
  understimulated,
  optimal,
  overload,
}

class MliEvaluation {
  const MliEvaluation({
    required this.level,
    required this.label,
    required this.description,
  });

  final MliStimulusLevel level;
  final String label;
  final String description;
}

/// Göç öncesi (ağırlık toplamı ≈ 2.2) eşikler – yalnızca kalibrasyon referansı.
const double kLegacyUnderstimulatedThreshold = 80.0;
const double kLegacyOverloadThreshold = 220.0;

/// Kompartıman ağırlıklarının 1.00'a normalize edilmesiyle bölge yükleri
/// küçüldüğü için eşikler aynı oranda ölçeklenmiştir.
///
/// Türetme (bkz. test/domain/threshold_calibration_test.dart):
/// `test/fixtures/mli_golden_v1.json`'daki 48 vakanın her biri için birincil
/// bölgede `yeni_yük / eski_yük` oranı alınır (ham set MLI aynı olduğundan
/// oran = yeni bölge ağırlığı / eski bölge ağırlık toplamı). Bu oranların
/// medyanı **0.47**'dir:
///  * 80  × 0.47 = 37.6
///  * 220 × 0.47 = 103.4
const double kMliCalibrationScale = 0.47;

/// Bölge yükü bu değerin altında → Yetersiz.
const double kMliUnderstimulatedThreshold = 37.6;

/// Bölge yükü bu değerin üstünde → Aşırı Yük.
const double kMliOverloadThreshold = 103.4;

/// Tek bir ana bölgenin (kompartımanlar toplamı) seans MLI skorunu
/// değerlendirir.
/// < 37.6        → Yetersiz (hipertrofi eşiği altı)
/// 37.6 – 103.4  → Optimal
/// > 103.4       → Aşırı Yük
MliEvaluation evaluateMuscleLoad(double score) {
  if (score < kMliUnderstimulatedThreshold) {
    return const MliEvaluation(
      level: MliStimulusLevel.understimulated,
      label: 'Yetersiz',
      description: 'Hipertrofi eşiğinin altında kalan uyarı.',
    );
  } else if (score <= kMliOverloadThreshold) {
    return const MliEvaluation(
      level: MliStimulusLevel.optimal,
      label: 'Optimal',
      description: 'Gelişim için ideal mekanik gerilim aralığı.',
    );
  } else {
    return const MliEvaluation(
      level: MliStimulusLevel.overload,
      label: 'Aşırı Yük',
      description: 'Toparlanmayı zorlaştırabilecek yüksek hacim / aşırı yük.',
    );
  }
}
