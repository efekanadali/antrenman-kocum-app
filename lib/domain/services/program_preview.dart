// lib/domain/services/program_preview.dart

import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/services/exercise_mli_resolver.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';

/// Bir egzersiz listesinin biyomekanik tahmini.
class ProgramPreview {
  const ProgramPreview({
    required this.totalMli,
    required this.muscleLoad,
    required this.averageLeverage,
  });

  static const ProgramPreview empty = ProgramPreview(
    totalMli: 0,
    muscleLoad: {},
    averageLeverage: 0,
  );

  /// Tahmini toplam MLI iş yükü.
  final double totalMli;

  /// Ana kas grubu bazında dağılım (MLI).
  final Map<RecoveryMuscle, double> muscleLoad;

  /// Set sayısına göre ağırlıklı ortalama kaldıraç (zorluk) katsayısı.
  final double averageLeverage;

  bool get isEmpty => totalMli <= 0;

  double get _muscleSum => muscleLoad.values.fold(0.0, (a, b) => a + b);

  /// En ağır yüklenen kas grubu.
  RecoveryMuscle? get topMuscle {
    if (muscleLoad.isEmpty) return null;
    return muscleLoad.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Hedef kas grubunun toplam içindeki payı (0-1).
  double get topMuscleShare {
    final top = topMuscle;
    if (top == null || _muscleSum <= 0) return 0;
    return muscleLoad[top]! / _muscleSum;
  }
}

/// Planlanan egzersizler için, [assumedRir] varsayımıyla tahmini MLI hesaplar.
///
/// `MLI = hacim x kaldıraç katsayısı x (1 + (10-RIR)/10)`, kas bazlı dağılım
/// `omega` ağırlıklarıyla yapılır.
ProgramPreview estimateProgramPreview(
  Iterable<CustomProgramExercise> exercises,
  ExerciseMliResolver resolver, {
  int assumedRir = 2,
}) {
  var total = 0.0;
  var leverageWeighted = 0.0;
  var totalSets = 0;
  final byMuscle = <RecoveryMuscle, double>{};

  for (final item in exercises) {
    if (item.sets <= 0 || item.value <= 0) continue;
    final exercise = resolver.build(item);
    final set = item.isTimed
        ? WorkoutSet(
            reps: 0,
            rir: assumedRir,
            durationInSeconds: item.value,
          )
        : WorkoutSet(reps: item.value, rir: assumedRir);

    final perSet = calculateMuscleLoad(exercise: exercise, set: set);
    perSet.forEach((key, load) {
      final scaled = load * item.sets;
      final muscle = recoveryMuscleFromKey(key);
      if (muscle != null) {
        byMuscle[muscle] = (byMuscle[muscle] ?? 0) + scaled;
      }
    });

    final setMli = set.durationInSeconds != null
        ? calculateStaticMLI(
            durationInSeconds: item.value,
            difficulty: exercise.difficulty,
            secondsInReserve: assumedRir,
          )
        : calculateMLI(
            volume: set.volume,
            difficulty: exercise.difficulty,
            rir: assumedRir,
          );
    total += setMli * item.sets;
    leverageWeighted += exercise.difficulty * item.sets;
    totalSets += item.sets;
  }

  if (totalSets == 0) return ProgramPreview.empty;

  return ProgramPreview(
    totalMli: total,
    muscleLoad: byMuscle,
    averageLeverage: leverageWeighted / totalSets,
  );
}
