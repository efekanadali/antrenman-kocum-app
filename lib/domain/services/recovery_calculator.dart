// lib/domain/services/recovery_calculator.dart

import 'dart:math' as math;

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';

/// RIR varsayılanı: bilgi yoksa "optimal hipertrofi" kabul edilir.
const double kDefaultRir = 2.0;

/// Bir kompartıman, seanstaki en çok yüklenen kompartımanın yükünün en az bu
/// oranına maruz kalırsa "çalıştırılmış" sayılır (stabilizatörleri gereksiz
/// yere yormamak için). Kompartıman seviyesinde uygulanır.
const double kPrimaryMuscleShare = 0.25;

/// Ardışık seanslarda birleştirilmiş toparlanma süresinin alt/üst sınırı (sa).
const double kMergedRecoveryMinHours = 24.0;
const double kMergedRecoveryMaxHours = 96.0;

/// RIR → toparlanma süresi (saat).
///
/// Doğrusal modelin anahtar noktaları:
///  * RIR 0-1 (tükeniş / aşırı yük): 72 → 60 sa  (48-72 sa bandı)
///  * RIR 2-3 (optimal hipertrofi):  48 → 36 sa  (36-48 sa bandı)
///  * RIR 4+  (hafif / deload):      24 sa
double recoveryHoursForRir(double rir) {
  return (72.0 - 12.0 * rir).clamp(24.0, 72.0).toDouble();
}

/// Kompartımanın toparlanma süresi:
/// `recoveryHoursForRir(rir) × compartment.recoverySizeFactor`.
///
/// Boyut katsayısı (küçük kaslar 0.85, büyük kaslar 1.10) RIR bandının
/// (24–72 sa) sınırlandırılmasından SONRA uygulanır; bu nedenle tek bir seans
/// için kompartıman süresi 20.4–79.2 sa aralığında olabilir. Ardışık seans
/// birleştirmesi ([mergeCompartmentRecovery]) değişmeden 24–96 sa bandını
/// uygular.
double compartmentRecoveryHours(MuscleCompartment compartment, double rir) {
  return recoveryHoursForRir(rir) * compartment.recoverySizeFactor;
}

/// Statik (süreli) setlerde `rir` "tükenişe kalan saniye"dir; dinamik RIR
/// ölçeğine (0-4+) normalize edilir.
double effectiveRir(WorkoutSet set) {
  if (set.durationInSeconds == null) {
    return set.rir.toDouble();
  }
  final secondsInReserve = set.rir;
  if (secondsInReserve <= 0) return 0.0;
  if (secondsInReserve <= 3) return 2.0;
  if (secondsInReserve <= 6) return 3.0;
  return 4.0;
}

/// Kas bazında (eski bölge anahtarlarıyla), yük ağırlıklı ortalama RIR hesaplar.
Map<String, double> calculateWorkoutMuscleRir(
  List<ExerciseWorkoutEntry> entries,
) {
  final weightedRir = <String, double>{};
  final totalLoad = <String, double>{};

  for (final entry in entries) {
    for (final set in entry.sets) {
      final setLoad = calculateMuscleLoad(exercise: entry.exercise, set: set);
      final rir = effectiveRir(set);
      setLoad.forEach((muscle, load) {
        weightedRir[muscle] = (weightedRir[muscle] ?? 0) + load * rir;
        totalLoad[muscle] = (totalLoad[muscle] ?? 0) + load;
      });
    }
  }

  final result = <String, double>{};
  totalLoad.forEach((muscle, load) {
    if (load > 0) {
      result[muscle] = (weightedRir[muscle] ?? 0) / load;
    }
  });
  return result;
}

/// Kompartıman bazında, yük ağırlıklı ortalama RIR hesaplar.
Map<MuscleCompartment, double> calculateWorkoutCompartmentRir(
  List<ExerciseWorkoutEntry> entries,
) {
  final weightedRir = <MuscleCompartment, double>{};
  final totalLoad = <MuscleCompartment, double>{};

  for (final entry in entries) {
    for (final set in entry.sets) {
      final rir = effectiveRir(set);
      calculateCompartmentLoad(exercise: entry.exercise, set: set)
          .forEach((c, load) {
        weightedRir[c] = (weightedRir[c] ?? 0) + load * rir;
        totalLoad[c] = (totalLoad[c] ?? 0) + load;
      });
    }
  }

  final result = <MuscleCompartment, double>{};
  totalLoad.forEach((c, load) {
    if (load > 0) result[c] = (weightedRir[c] ?? 0) / load;
  });
  return result;
}

/// Bir kas kompartımanının son antrenmanı ve toparlanma durumu.
class CompartmentRecoveryRecord {
  const CompartmentRecoveryRecord({
    required this.compartment,
    required this.lastTrainedAt,
    required this.recoveryHours,
    required this.averageRir,
    required this.load,
  });

  final MuscleCompartment compartment;
  final DateTime lastTrainedAt;
  final double recoveryHours;
  final double averageRir;
  final double load;

  DateTime get readyAt =>
      lastTrainedAt.add(Duration(minutes: (recoveryHours * 60).round()));

  /// 0.0 – 1.0 arası toparlanma oranı.
  double progressAt(DateTime now) {
    final totalMinutes = recoveryHours * 60;
    if (totalMinutes <= 0) return 1.0;
    final elapsed = now.difference(lastTrainedAt).inMinutes;
    return (elapsed / totalMinutes).clamp(0.0, 1.0).toDouble();
  }

  bool isReadyAt(DateTime now) => !now.isBefore(readyAt);

  Duration remainingAt(DateTime now) {
    final remaining = readyAt.difference(now);
    return remaining.isNegative ? Duration.zero : remaining;
  }
}

/// Tamamlanan seanstan kompartıman bazlı toparlanma kayıtları üretir.
///
/// * [kPrimaryMuscleShare] kompartıman seviyesinde uygulanır: en yüklü
///   kompartımanın %25'inin altında kalanlar kayda girmez.
/// * `recoveryHours = recoveryHoursForRir(avgRir) × recoverySizeFactor`.
Map<MuscleCompartment, CompartmentRecoveryRecord> buildCompartmentRecovery({
  required Map<MuscleCompartment, double> compartmentLoad,
  Map<MuscleCompartment, double> compartmentRir = const {},
  required DateTime completedAt,
  double defaultRir = kDefaultRir,
}) {
  final loads = <MuscleCompartment, double>{
    for (final e in compartmentLoad.entries)
      if (e.value > 0) e.key: e.value,
  };
  if (loads.isEmpty) return const {};

  final maxLoad = loads.values.reduce(math.max);
  final records = <MuscleCompartment, CompartmentRecoveryRecord>{};
  loads.forEach((c, load) {
    if (load < maxLoad * kPrimaryMuscleShare) return;
    final rir = compartmentRir[c] ?? defaultRir;
    records[c] = CompartmentRecoveryRecord(
      compartment: c,
      lastTrainedAt: completedAt,
      recoveryHours: compartmentRecoveryHours(c, rir),
      averageRir: rir,
      load: load,
    );
  });
  return records;
}

/// Kompartıman kayıtlarından 6 ana bölge için kayıt türetir.
///
/// * Bölgenin hazır olma zamanı = en geç toparlanan kompartımanın zamanı
///   (`lastTrainedAt` ve `recoveryHours` o kompartımandan alınır).
/// * `averageRir` kayıttaki kompartımanların yük ağırlıklı ortalamasıdır.
/// * `load` kayıttaki kompartıman yüklerinin toplamıdır.
Map<RecoveryMuscle, MuscleRecoveryRecord> regionRecoveryFromCompartments(
  Map<MuscleCompartment, CompartmentRecoveryRecord> compartments,
) {
  final latest = <MuscleRegion, CompartmentRecoveryRecord>{};
  final loads = <MuscleRegion, double>{};
  final rirWeighted = <MuscleRegion, double>{};

  for (final record in compartments.values) {
    final region = record.compartment.region;
    final current = latest[region];
    if (current == null || record.readyAt.isAfter(current.readyAt)) {
      latest[region] = record;
    }
    loads[region] = (loads[region] ?? 0) + record.load;
    rirWeighted[region] =
        (rirWeighted[region] ?? 0) + record.load * record.averageRir;
  }

  final result = <RecoveryMuscle, MuscleRecoveryRecord>{};
  for (final region in MuscleRegion.values) {
    final record = latest[region];
    if (record == null) continue;
    final load = loads[region]!;
    result[region] = MuscleRecoveryRecord(
      muscle: region,
      lastTrainedAt: record.lastTrainedAt,
      recoveryHours: record.recoveryHours,
      averageRir: load > 0 ? rirWeighted[region]! / load : record.averageRir,
      load: load,
    );
  }
  return result;
}

/// Tamamlanan seanstan, ana bölge (6 grup) bazlı toparlanma kayıtları üretir.
/// Firestore `muscle_recovery/{bölge}` yazımı bu çıktıyı kullanır.
///
/// Hesap kompartıman seviyesinde yapılır ([buildCompartmentRecovery]) ve
/// bölgeye [regionRecoveryFromCompartments] ile indirgenir.
///
/// * [compartmentLoad]/[compartmentRir] verilirse doğrudan kullanılır
///   (en doğru sonuç).
/// * Verilmezse [muscleLoad] anahtarları [splitLoad] ile kompartımanlara
///   açılır; eski bölge anahtarları (`chest`, `legs` …) sabit
///   [kLegacyRegionSplit] oranlarıyla bölünür. Her kompartımanın RIR'ı, onu
///   besleyen anahtarların yük ağırlıklı RIR ortalamasıdır.
Map<RecoveryMuscle, MuscleRecoveryRecord> buildSessionRecovery({
  required Map<String, double> muscleLoad,
  required Map<String, double> muscleRir,
  required DateTime completedAt,
  double defaultRir = kDefaultRir,
  Map<MuscleCompartment, double>? compartmentLoad,
  Map<MuscleCompartment, double>? compartmentRir,
}) {
  Map<MuscleCompartment, double> loads;
  Map<MuscleCompartment, double> rirs;

  if (compartmentLoad != null) {
    loads = compartmentLoad;
    rirs = compartmentRir ?? const {};
  } else {
    loads = <MuscleCompartment, double>{};
    final rirWeighted = <MuscleCompartment, double>{};
    muscleLoad.forEach((key, load) {
      if (load <= 0) return;
      final rir = muscleRir[key] ?? defaultRir;
      splitLoad({key: load}).loads.forEach((c, part) {
        loads[c] = (loads[c] ?? 0) + part;
        rirWeighted[c] = (rirWeighted[c] ?? 0) + part * rir;
      });
    });
    rirs = {
      for (final e in loads.entries)
        if (e.value > 0) e.key: rirWeighted[e.key]! / e.value,
    };
  }

  final compartmentRecords = buildCompartmentRecovery(
    compartmentLoad: loads,
    compartmentRir: rirs,
    completedAt: completedAt,
    defaultRir: defaultRir,
  );
  return regionRecoveryFromCompartments(compartmentRecords);
}

/// İki ardışık toparlanma kaydının zamanlamasını birleştirir.
///
/// Kas henüz toparlanmadan tekrar çalıştırıldıysa, kalan sürenin %30'u
/// kümülatif yorgunluk cezası olarak eklenir ve geçmiş toparlanma ilerlemesi
/// korunarak toplam süre 24–96 saat bandında sınırlandırılır. Kas zaten
/// toparlandıysa `null` döner (yeni kayıt aynen kullanılır).
({DateTime lastTrainedAt, double recoveryHours})? _mergeTiming({
  required DateTime existingLastTrainedAt,
  required DateTime existingReadyAt,
  required DateTime incomingLastTrainedAt,
  required double incomingRecoveryHours,
}) {
  final now = incomingLastTrainedAt;
  final remainingMinutes = existingReadyAt.difference(now).inMinutes;
  if (remainingMinutes <= 0) {
    return null;
  }

  final remainingHours = remainingMinutes / 60.0;
  final elapsedMinutes = math.max(
    0,
    now.difference(existingLastTrainedAt).inMinutes,
  );
  final elapsedHours = elapsedMinutes / 60.0;

  // Kalan sürenin %30'u kümülatif yorgunluk cezası olarak eklenir (24–96 sa bandı)
  const cumulativePenaltyFactor = 0.30;
  final newRemainingHours =
      (math.max(remainingHours, incomingRecoveryHours) +
              (remainingHours * cumulativePenaltyFactor))
          .clamp(kMergedRecoveryMinHours, kMergedRecoveryMaxHours)
          .toDouble();

  final targetReadyAt = now.add(
    Duration(minutes: (newRemainingHours * 60).round()),
  );
  final totalRecoveryHours = (elapsedHours + newRemainingHours)
      .clamp(kMergedRecoveryMinHours, kMergedRecoveryMaxHours)
      .toDouble();
  final preservedLastTrainedAt = targetReadyAt.subtract(
    Duration(minutes: (totalRecoveryHours * 60).round()),
  );
  return (
    lastTrainedAt: preservedLastTrainedAt,
    recoveryHours: totalRecoveryHours,
  );
}

/// Bölge kaydı birleştirme (bkz. [_mergeTiming]).
MuscleRecoveryRecord mergeRecovery(
  MuscleRecoveryRecord? existing,
  MuscleRecoveryRecord incoming,
) {
  if (existing == null) {
    return incoming;
  }
  final timing = _mergeTiming(
    existingLastTrainedAt: existing.lastTrainedAt,
    existingReadyAt: existing.readyAt,
    incomingLastTrainedAt: incoming.lastTrainedAt,
    incomingRecoveryHours: incoming.recoveryHours,
  );
  if (timing == null) {
    return incoming;
  }

  return MuscleRecoveryRecord(
    muscle: incoming.muscle,
    lastTrainedAt: timing.lastTrainedAt,
    recoveryHours: timing.recoveryHours,
    averageRir: math.min(existing.averageRir, incoming.averageRir),
    load: existing.load + incoming.load,
  );
}

/// Kompartıman kaydı birleştirme: [mergeRecovery] ile aynı mantık.
///
/// Gelen kaydın `recoveryHours` değeri boyut katsayısını zaten içerir; bu
/// yüzden katsayı birleştirmede yeniden uygulanmaz. Birleşik süre yine
/// 24–96 sa bandına sınırlanır.
CompartmentRecoveryRecord mergeCompartmentRecovery(
  CompartmentRecoveryRecord? existing,
  CompartmentRecoveryRecord incoming,
) {
  if (existing == null) {
    return incoming;
  }
  final timing = _mergeTiming(
    existingLastTrainedAt: existing.lastTrainedAt,
    existingReadyAt: existing.readyAt,
    incomingLastTrainedAt: incoming.lastTrainedAt,
    incomingRecoveryHours: incoming.recoveryHours,
  );
  if (timing == null) {
    return incoming;
  }

  return CompartmentRecoveryRecord(
    compartment: incoming.compartment,
    lastTrainedAt: timing.lastTrainedAt,
    recoveryHours: timing.recoveryHours,
    averageRir: math.min(existing.averageRir, incoming.averageRir),
    load: existing.load + incoming.load,
  );
}
