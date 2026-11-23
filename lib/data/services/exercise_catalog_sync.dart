// lib/data/services/exercise_catalog_sync.dart
//
// `exercises` koleksiyonunun sürümlü tohumlanması ve yerel katalogla
// birleştirilmesi için saf yardımcılar.

import 'package:calisthenics_app/domain/models/exercise.dart' as domain;
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';
import 'package:calisthenics_app/domain/models/muscle_load_snapshot.dart';

/// Yerel egzersiz kataloğunun sürümü. `exerciseDatabase`'de biyomekanik bir
/// değişiklik yapıldığında artırılır; Firestore'daki
/// `meta/exercise_catalog.version` bundan küçükse katalog yeniden yazılır.
///
/// * 1: göç öncesi (yalnızca `muscles`, "koleksiyon boşsa" tohumlama)
/// * 2: 17 kompartıman (`compartments`, `type`, `schemaVersion`)
const int kExerciseCatalogVersion = 2;

const String kCatalogMetaCollection = 'meta';
const String kCatalogMetaDoc = 'exercise_catalog';

/// Uzak sürüm yerelden eskiyse (veya hiç yoksa) `true`.
bool shouldUpsertExerciseCatalog(
  Object? remoteVersion, {
  int localVersion = kExerciseCatalogVersion,
}) {
  final remote = remoteVersion is num ? remoteVersion.toInt() : 0;
  return remote < localVersion;
}

/// Bir kütüphane egzersizinin Firestore dokümanı (merge: true ile yazılır).
/// Eski sürümler için `muscles` (bölge anahtarları) korunur.
Map<String, dynamic> exerciseCatalogDoc(String id, Exercise exercise) {
  final compartments = MuscleLoadSnapshot(compartments: exercise.compartments);
  return {
    'id': id,
    'name': exercise.name,
    'difficulty': exercise.difficulty,
    'leverageFactor': exercise.difficulty,
    'type': exercise.type.name,
    'muscles': exercise.muscles,
    'compartments': compartments.compartmentsByKey,
    'schemaVersion': kMuscleDataSchemaVersion,
    'catalogVersion': kExerciseCatalogVersion,
  };
}

/// Tüm yerel katalog dokümanları (id → veri).
Map<String, Map<String, dynamic>> buildExerciseCatalogDocs() => {
      for (final e in exerciseDatabase.entries)
        e.key: exerciseCatalogDoc(e.key, e.value),
    };

/// Firestore'dan gelen katalogu yerel katalogla birleştirir.
///
/// * Yerelde bilinen id'ler için yerel kayıt (biyomekanik) kazanır.
/// * Yalnızca uzakta olan id'ler sona eklenir.
/// * Sıra: yerel katalog sırası, ardından uzak-özel kayıtlar.
List<domain.Exercise> mergeExerciseCatalog({
  required List<domain.Exercise> local,
  required List<domain.Exercise> remote,
}) {
  final localIds = {for (final e in local) e.id};
  final seenRemote = <String>{};
  return [
    ...local,
    for (final e in remote)
      if (!localIds.contains(e.id) && seenRemote.add(e.id)) e,
  ];
}
