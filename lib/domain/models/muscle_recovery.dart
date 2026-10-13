// lib/domain/models/muscle_recovery.dart

/// Toparlanma takibinde kullanılan 6 ana kas grubu.
enum RecoveryMuscle { chest, back, shoulders, arms, core, legs }

extension RecoveryMuscleLabel on RecoveryMuscle {
  String get label {
    switch (this) {
      case RecoveryMuscle.chest:
        return 'Göğüs';
      case RecoveryMuscle.back:
        return 'Sırt';
      case RecoveryMuscle.shoulders:
        return 'Omuz';
      case RecoveryMuscle.arms:
        return 'Kol';
      case RecoveryMuscle.core:
        return 'Karın';
      case RecoveryMuscle.legs:
        return 'Bacak';
    }
  }
}

/// Farklı kaynaklardan gelen kas anahtarlarını (enum adı, Türkçe etiket)
/// ana gruplardan birine eşler. Eşleşmeyen anahtarlar (ör. "Genel") için
/// `null` döner.
RecoveryMuscle? recoveryMuscleFromKey(String rawKey) {
  switch (rawKey.toLowerCase().trim()) {
    case 'chest':
    case 'göğüs':
    case 'gogus':
      return RecoveryMuscle.chest;
    case 'back':
    case 'sırt':
    case 'sirt':
      return RecoveryMuscle.back;
    case 'shoulders':
    case 'shoulder':
    case 'omuz':
      return RecoveryMuscle.shoulders;
    case 'biceps':
    case 'biseps':
    case 'triceps':
    case 'triseps':
    case 'kol':
    case 'arms':
      return RecoveryMuscle.arms;
    case 'core':
    case 'abs':
    case 'karın':
    case 'karin':
      return RecoveryMuscle.core;
    case 'legs':
    case 'bacak':
    case 'quads':
    case 'quadriceps':
    case 'hamstrings':
    case 'glutes':
    case 'kalça':
    case 'kalca':
    case 'calves':
    case 'baldır':
    case 'baldir':
      return RecoveryMuscle.legs;
  }
  return null;
}

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
