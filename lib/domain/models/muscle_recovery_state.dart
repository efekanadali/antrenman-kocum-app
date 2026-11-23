// lib/domain/models/muscle_recovery_state.dart
//
// `users/{uid}/muscle_recovery` koleksiyonunun kompartıman (v2) + bölge (v1)
// kayıtlarının okunması / yazılması için saf (Firestore'dan bağımsız) mantık.
//
// Doküman id'leri:
//  * Bölge (v1, eski sürümler okur): chest, back, shoulders, arms, core, legs
//    → alanlar: muscle, lastTrainedAt, recoveryHours, averageRir, load
//  * Kompartıman (v2): 17 `firestoreKey` (upper_chest … calves, core)
//    → alanlar: compartment, region, lastTrainedAt, recoveryHours,
//      averageRir, load, schemaVersion
//  * `core` hem bölge hem kompartıman id'sidir. Karın bölgesi tek
//    kompartımandan oluştuğu için iki kayıt zaman olarak özdeştir; tek doküman
//    hem `muscle: core` hem `compartment: core` alanlarını taşır.

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/muscle_load_snapshot.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';
import 'package:calisthenics_app/domain/services/recovery_calculator.dart';

/// Yeni sürümün yazdığı bölge dokümanlarını işaretleyen alanlar.
const String kDerivedFromCompartmentsField = 'derivedFromCompartments';
const String kDerivedReadyAtField = 'derivedReadyAt';

/// Bölge dokümanı eski bir sürüm tarafından yazıldıysa (veya yeni sürümün
/// yazdığından sonra eski sürüm tarafından güncellendiyse) `true`: yalnızca
/// bu durumda kompartımanlara geri dönüş kaynağı olur. Eski sürüm
/// `merge: true` ile yazarken işaret alanını silmez, fakat zaman alanlarını
/// değiştirir; bu yüzden `derivedReadyAt` ile mevcut hazır olma zamanı
/// karşılaştırılır.
bool isLegacyRegionDoc(Map<String, dynamic> data, MuscleRecoveryRecord record) {
  if (data[kDerivedFromCompartmentsField] != true) return true;
  return data[kDerivedReadyAtField] != record.readyAt.toIso8601String();
}

/// Kompartıman kaydını Firestore dokümanına çevirir.
Map<String, dynamic> compartmentRecoveryToMap(CompartmentRecoveryRecord r) {
  final c = r.compartment;
  return {
    'compartment': c.firestoreKey,
    'region': c.region.name,
    // `core` dokümanı eski sürümler için bölge kaydı olarak da okunur.
    if (c.firestoreKey == c.region.name) 'muscle': c.region.name,
    'lastTrainedAt': r.lastTrainedAt.toIso8601String(),
    'recoveryHours': r.recoveryHours,
    'averageRir': r.averageRir,
    'load': r.load,
    'schemaVersion': kMuscleDataSchemaVersion,
  };
}

/// Dokümanı kompartıman kaydı olarak okur. `compartment` alanı yoksa doküman
/// id'si kullanılır; bu sayede eski `core` bölge dokümanı da `core`
/// kompartımanı olarak okunur. Bölge id'leri (`chest` …) için `null`.
CompartmentRecoveryRecord? compartmentRecoveryFromMap(
  String docId,
  Map<String, dynamic> map,
) {
  final key = (map['compartment'] as String?) ?? docId;
  final compartment = MuscleCompartment.fromFirestoreKey(key);
  final trainedAt = DateTime.tryParse('${map['lastTrainedAt']}');
  if (compartment == null || trainedAt == null) return null;
  return CompartmentRecoveryRecord(
    compartment: compartment,
    lastTrainedAt: trainedAt,
    recoveryHours: (map['recoveryHours'] as num?)?.toDouble() ?? 24.0,
    averageRir: (map['averageRir'] as num?)?.toDouble() ?? kDefaultRir,
    load: (map['load'] as num?)?.toDouble() ?? 0.0,
  );
}

/// Kompartıman + bölge toparlanma durumu (UI için).
class MuscleRecoveryState {
  const MuscleRecoveryState({
    this.compartments = const {},
    this.legacyFallback = const {},
  });

  /// 17 kompartımanın bilinen son toparlanma kayıtları.
  final Map<MuscleCompartment, CompartmentRecoveryRecord> compartments;

  /// Kendi dokümanı olmayıp eski bölge dokümanından kopyalanan
  /// kompartımanlar.
  final Set<MuscleCompartment> legacyFallback;

  bool get isEmpty => compartments.isEmpty;

  /// Bölge görünümü: bölgede kayıtlı herhangi bir kompartıman varsa bölge
  /// görünür; hazır olma zamanı en geç toparlanan kompartımandır.
  Map<MuscleRegion, MuscleRecoveryRecord> get regions =>
      regionRecoveryFromCompartments(compartments);

  List<CompartmentRecoveryRecord> compartmentsOf(MuscleRegion region) => [
        for (final c in region.compartments)
          if (compartments[c] != null) compartments[c]!,
      ];
}

/// Koleksiyondaki dokümanları (id → veri) okur.
///
/// 1. Her kompartıman için önce kendi dokümanı kullanılır.
/// 2. Yoksa bölgesinin ESKİ dokümanı ([isLegacyRegionDoc]) [expandRecoveryKey] ile kompartımanlara
///    açılır: zaman verisi (lastTrainedAt, recoveryHours, averageRir) AYNEN
///    kopyalanır (saatler bölünmez); yük [kLegacyRegionSplit] oranıyla
///    paylaştırılır.
MuscleRecoveryState parseRecoveryDocs(Map<String, Map<String, dynamic>> docs) {
  final compartments = <MuscleCompartment, CompartmentRecoveryRecord>{};
  final regionDocs = <MuscleRegion, MuscleRecoveryRecord>{};

  docs.forEach((id, data) {
    final c = compartmentRecoveryFromMap(id, data);
    if (c != null) compartments[c.compartment] = c;
    if (data['muscle'] != null) {
      final region = MuscleRecoveryRecord.fromMap(data);
      if (region != null && isLegacyRegionDoc(data, region)) {
        regionDocs[region.muscle] = region;
      }
    }
  });

  final fallback = <MuscleCompartment>{};
  regionDocs.forEach((region, record) {
    for (final c in expandRecoveryKey(region.name)) {
      if (compartments.containsKey(c)) continue;
      final share = kLegacyRegionSplit[region]?[c] ?? 1.0;
      compartments[c] = CompartmentRecoveryRecord(
        compartment: c,
        lastTrainedAt: record.lastTrainedAt,
        recoveryHours: record.recoveryHours,
        averageRir: record.averageRir,
        load: record.load * share,
      );
      fallback.add(c);
    }
  });

  return MuscleRecoveryState(
    compartments: compartments,
    legacyFallback: fallback,
  );
}

/// Seans sonrası yazılacak dokümanları (id → veri) hesaplar.
///
/// * Her gelen kompartıman kaydı, mevcut kompartıman dokümanıyla
///   [mergeCompartmentRecovery] ile birleştirilir.
/// * Eski sürümler için 6 bölge dokümanı da yazılır: seansın bölge kaydı
///   (en geç toparlanan kompartıman) mevcut bölge dokümanıyla [mergeRecovery]
///   ile birleştirilir. `core` id'si kompartıman dokümanıyla ortaktır ve
///   yalnızca bir kez (iki alan setiyle) yazılır.
Map<String, Map<String, dynamic>> buildRecoveryWrites({
  required Map<MuscleCompartment, CompartmentRecoveryRecord> incoming,
  required Map<String, Map<String, dynamic>> existingDocs,
}) {
  final writes = <String, Map<String, dynamic>>{};

  incoming.forEach((c, record) {
    final existingData = existingDocs[c.firestoreKey];
    final existing = existingData == null
        ? null
        : compartmentRecoveryFromMap(c.firestoreKey, existingData);
    final merged = mergeCompartmentRecovery(existing, record);
    writes[c.firestoreKey] = compartmentRecoveryToMap(merged);
  });

  regionRecoveryFromCompartments(incoming).forEach((region, record) {
    if (writes.containsKey(region.name)) return; // core: ortak doküman
    final existingData = existingDocs[region.name];
    final existing =
        existingData == null ? null : MuscleRecoveryRecord.fromMap(existingData);
    final merged = mergeRecovery(existing, record);
    writes[region.name] = {
      ...merged.toMap(),
      // Bu bölge dokümanı kompartımanlardan türetildi; okurken geri dönüş
      // kaynağı olarak kullanılmaz (eski bir sürüm üzerine yazmadıkça).
      kDerivedFromCompartmentsField: true,
      kDerivedReadyAtField: merged.readyAt.toIso8601String(),
    };
  });

  return writes;
}

/// Yazım öncesi okunması gereken doküman id'leri.
Set<String> recoveryDocIdsFor(
  Map<MuscleCompartment, CompartmentRecoveryRecord> incoming,
) {
  return {
    for (final c in incoming.keys) ...[c.firestoreKey, c.region.name],
  };
}
