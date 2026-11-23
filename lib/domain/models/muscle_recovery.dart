// lib/domain/models/muscle_recovery.dart

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';

/// Toparlanma takibinde kullanılan 6 ana kas grubu.
///
/// Geriye dönük uyumluluk için [MuscleRegion]'ın takma adıdır; `name`
/// değerleri (Firestore doküman id'leri) ve `label` etiketleri aynıdır.
typedef RecoveryMuscle = MuscleRegion;

/// Farklı kaynaklardan gelen kas anahtarlarını (enum adı, Türkçe etiket)
/// ana gruplardan birine eşler. Eşleşmeyen anahtarlar (ör. "Genel") için
/// `null` döner. [regionFromKey]'e yönlendirir.
RecoveryMuscle? recoveryMuscleFromKey(String rawKey) => regionFromKey(rawKey);

/// Bir kas grubunun son antrenmanı ve toparlanma durumu.
class MuscleRecoveryRecord {
  const MuscleRecoveryRecord({
    required this.muscle,
    required this.lastTrainedAt,
    required this.recoveryHours,
    required this.averageRir,
    required this.load,
  });

  final RecoveryMuscle muscle;
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

  Map<String, dynamic> toMap() => {
        'muscle': muscle.name,
        'lastTrainedAt': lastTrainedAt.toIso8601String(),
        'recoveryHours': recoveryHours,
        'averageRir': averageRir,
        'load': load,
      };

  static MuscleRecoveryRecord? fromMap(Map<String, dynamic> map) {
    final muscleName = map['muscle'] as String?;
    final muscle = RecoveryMuscle.values
        .where((m) => m.name == muscleName)
        .firstOrNull;
    final trainedAt = DateTime.tryParse('${map['lastTrainedAt']}');
    if (muscle == null || trainedAt == null) return null;
    return MuscleRecoveryRecord(
      muscle: muscle,
      lastTrainedAt: trainedAt,
      recoveryHours: (map['recoveryHours'] as num?)?.toDouble() ?? 24.0,
      averageRir: (map['averageRir'] as num?)?.toDouble() ?? 2.0,
      load: (map['load'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
