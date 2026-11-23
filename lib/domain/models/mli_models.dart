import 'package:calisthenics_app/domain/enums/exercise_type.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';

/// Kompartıman ağırlıkları toplamı için izin verilen sapma.
const double kCompartmentWeightSumTolerance = 0.001;

/// Kompartıman ağırlıklarının toplamı 1.00 ± [kCompartmentWeightSumTolerance]
/// aralığında mı?
bool compartmentWeightsSumToOne(Map<MuscleCompartment, double> weights) {
  final sum = weights.values.fold<double>(0, (a, b) => a + b);
  return (sum - 1.0).abs() <= kCompartmentWeightSumTolerance;
}

/// MLI hesaplamasında kullanılan biyomekanik egzersiz modeli.
class Exercise {
  Exercise({
    required this.name,
    required this.difficulty,
    required this.compartments,
    this.type = ExerciseType.calisthenics,
  }) : assert(
          compartmentWeightsSumToOne(compartments),
          'Compartment weights of "$name" must sum to 1.00',
        );

  final String name;

  /// Kaldıraç / zorluk katsayısı (Lf). Vücut geliştirmede `Lf_bb`.
  final double difficulty;

  /// 17 kas kompartımanı üzerindeki ağırlık dağılımı (toplam = 1.00).
  final Map<MuscleCompartment, double> compartments;

  /// Hangi MLI formülünün kullanılacağı.
  final ExerciseType type;

  /// Eski (bölge seviyesindeki) kas ağırlıkları: [compartments] 6 ana bölgeye
  /// toplanır ve eski İngilizce anahtarlarla (`chest`, `back`, `shoulders`,
  /// `arms`, `core`, `legs`) döner. Henüz kompartımana geçmemiş çağıranlar
  /// için türetilmiş, salt-okunur görünümdür.
  late final Map<String, double> muscles = () {
    final result = <String, double>{};
    for (final region in MuscleRegion.values) {
      var sum = 0.0;
      var present = false;
      compartments.forEach((c, w) {
        if (c.region == region) {
          sum += w;
          present = true;
        }
      });
      if (present) result[region.name] = sum;
    }
    return Map<String, double>.unmodifiable(result);
  }();
}

class WorkoutSet {
  const WorkoutSet({
    required this.reps,
    required this.rir,
    this.durationInSeconds,
    this.extraWeightKg = 0,
    this.bodyWeightKg,
    this.loadKg,
  });

  final int reps;
  final int rir;
  final int? durationInSeconds;

  /// Kalistenik: vücut ağırlığına eklenen yük (yelek, kemer).
  final double extraWeightKg;
  final double? bodyWeightKg;

  /// Vücut geliştirme: kaldırılan toplam dış yük (kg). Kalistenikte kullanılmaz.
  final double? loadKg;

  // Dynamic hareketlerde reps, statik hareketlerde saniye * 0.5 kullanilir.
  double get volume {
    if (durationInSeconds != null) {
      return durationInSeconds! * 0.5;
    }
    return reps.toDouble();
  }

  /// W_m = 1 + (ekstra agirlik / vucut agirligi)
  double get weightMultiplier {
    if (extraWeightKg <= 0) {
      return 1.0;
    }
    final bw = bodyWeightKg;
    if (bw == null || bw <= 0) {
      return 1.0;
    }
    return 1.0 + (extraWeightKg / bw);
  }
}

class ExerciseWorkoutEntry {
  const ExerciseWorkoutEntry({required this.exercise, required this.sets});

  final Exercise exercise;
  final List<WorkoutSet> sets;
}
