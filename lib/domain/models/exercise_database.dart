// lib/domain/models/exercise_database.dart

import 'package:calisthenics_app/domain/data/exercises/bodybuilding_exercises.dart';
import 'package:calisthenics_app/domain/data/exercises/calisthenics_exercises.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';

export 'package:calisthenics_app/domain/data/exercises/bodybuilding_exercises.dart';
export 'package:calisthenics_app/domain/data/exercises/calisthenics_exercises.dart';

/// Faz 7'de eklenen ve MLI golden fixture'larında yer almayan kalistenik id'ler.
const Set<String> kPhase7CalisthenicsIds = {
  'towel_dead_hang',
  'arch_body_hold',
};

/// Hibrit egzersiz kataloğu: 40 kalistenik + 40 vücut geliştirme = 80 hareket.
///
/// Uygulama genelinde (kütüphane, MLI çözümleyici, program oluşturucu)
/// kullanılan tek kaynaktır. Her egzersizin kompartıman ağırlıkları toplamı
/// tam olarak 1.00'dır.
final Map<String, Exercise> exerciseCatalog = {
  ...calisthenicsExercises,
  ...bodybuildingExercises,
};

/// Dondurulmuş 38 hareketlik kalistenik çekirdek.
///
/// MLI golden fixture'ları ve Firestore katalog senkronizasyonu (sürüm 2) bu
/// kümeye bağlıdır; bu yüzden içeriği DEĞİŞTİRİLMEZ. Yeni hareketler
/// [exerciseCatalog] üzerinden erişilir.
final Map<String, Exercise> exerciseDatabase = {
  for (final entry in calisthenicsExercises.entries)
    if (!kPhase7CalisthenicsIds.contains(entry.key)) entry.key: entry.value,
};
