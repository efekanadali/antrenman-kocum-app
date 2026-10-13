// lib/domain/services/recovery_calculator.dart

import 'package:calisthenics_app/domain/models/mli_models.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';

/// RIR varsayılanı: bilgi yoksa "optimal hipertrofi" kabul edilir.
const double kDefaultRir = 2.0;

/// Bir kas grubunun, toplam yükün en az bu oranına maruz kalması durumunda
/// "çalıştırılmış" sayılır (stabilizatör kasları gereksiz yere yormamak için).
const double kPrimaryMuscleShare = 0.25;

/// RIR → toparlanma süresi (saat).
///
/// Doğrusal modelin anahtar noktaları:
///  * RIR 0-1 (tükeniş / aşırı yük): 72 → 60 sa  (48-72 sa bandı)
///  * RIR 2-3 (optimal hipertrofi):  48 → 36 sa  (36-48 sa bandı)
///  * RIR 4+  (hafif / deload):      24 sa
double recoveryHoursForRir(double rir) {
  return (72.0 - 12.0 * rir).clamp(24.0, 72.0).toDouble();
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

/// Kas bazında, yük ağırlıklı ortalama RIR hesaplar.
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

/// Tamamlanan seanstan, kas grubu bazlı toparlanma kayıtları üretir.
Map<RecoveryMuscle, MuscleRecoveryRecord> buildSessionRecovery({
  required Map<String, double> muscleLoad,
  required Map<String, double> muscleRir,
  required DateTime completedAt,
  double defaultRir = kDefaultRir,
}) {
  final loads = <RecoveryMuscle, double>{};
  final rirWeighted = <RecoveryMuscle, double>{};

  muscleLoad.forEach((key, load) {
    final muscle = recoveryMuscleFromKey(key);
    if (muscle == null || load <= 0) return;
    final rir = muscleRir[key] ?? defaultRir;
    loads[muscle] = (loads[muscle] ?? 0) + load;
    rirWeighted[muscle] = (rirWeighted[muscle] ?? 0) + load * rir;
  });

  if (loads.isEmpty) return const {};

  final maxLoad = loads.values.reduce((a, b) => a > b ? a : b);
  final records = <RecoveryMuscle, MuscleRecoveryRecord>{};

  loads.forEach((muscle, load) {
    if (load < maxLoad * kPrimaryMuscleShare) return;
    final avgRir = rirWeighted[muscle]! / load;
    records[muscle] = MuscleRecoveryRecord(
      muscle: muscle,
      lastTrainedAt: completedAt,
      recoveryHours: recoveryHoursForRir(avgRir),
      averageRir: avgRir,
      load: load,
    );
  });

  return records;
}

/// Kas henüz toparlanmadan tekrar çalıştırıldıysa, daha geç biten toparlanma
/// süresi korunur (kümülatif yorgunluk).
MuscleRecoveryRecord mergeRecovery(
  MuscleRecoveryRecord? existing,
  MuscleRecoveryRecord incoming,
) {
  if (existing == null || !existing.readyAt.isAfter(incoming.readyAt)) {
    return incoming;
  }
  final hours =
      existing.readyAt.difference(incoming.lastTrainedAt).inMinutes / 60.0;
  return MuscleRecoveryRecord(
    muscle: incoming.muscle,
    lastTrainedAt: incoming.lastTrainedAt,
    recoveryHours: hours,
    averageRir: incoming.averageRir,
    load: incoming.load,
  );
}
