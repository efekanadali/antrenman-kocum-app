// lib/domain/models/muscle_load_snapshot.dart

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';

/// Kalıcı veri şema sürümü (Firestore + yerel depolama).
///
/// * 1 (veya alan yok): yalnızca eski anahtarlar (`muscleWorkloads`,
///   `muscleLoad`, `muscles`) – İngilizce kas adları / Türkçe etiketler.
/// * 2: 17 kompartıman (`compartmentWorkloads`, `compartmentLoad`,
///   `compartments`) + geriye dönük eski bölge anahtarları.
const int kMuscleDataSchemaVersion = 2;

/// Bir seansın (veya özetin) kas yükü: kompartıman görünümü + bölge görünümü.
class MuscleLoadSnapshot {
  const MuscleLoadSnapshot({
    this.compartments = const {},
    this.unmapped = const {},
  });

  /// Kompartıman bazında MLI yükü.
  final Map<MuscleCompartment, double> compartments;

  /// Hiçbir kompartımana eşlenemeyen eski anahtarlar (ör. `Genel`).
  final Map<String, double> unmapped;

  bool get isEmpty => compartments.isEmpty && unmapped.isEmpty;

  /// 6 ana bölge görünümü.
  Map<MuscleRegion, double> get regions => aggregateToRegions(compartments);

  /// Eski uygulama sürümlerinin okuduğu biçim: İngilizce bölge anahtarları
  /// (`chest`, `back`, `shoulders`, `arms`, `core`, `legs`) +
  /// eşlenemeyen anahtarlar aynen.
  Map<String, double> get legacyRegionLoad {
    final byRegion = regions;
    return {
      for (final r in MuscleRegion.values)
        if (byRegion[r] != null) r.name: byRegion[r]!,
      ...unmapped,
    };
  }

  /// Firestore / JSON için `firestoreKey → yük`.
  Map<String, double> get compartmentsByKey => {
        for (final c in MuscleCompartment.values)
          if (compartments[c] != null) c.firestoreKey: compartments[c]!,
      };

  double get mappedTotal => compartments.values.fold(0.0, (a, b) => a + b);

  /// Kayıttan kas yükünü okur.
  ///
  /// 1. [compartmentRaw] (`firestoreKey → sayı`) varsa doğrudan kullanılır.
  /// 2. Yoksa [legacyRaw] (eski İngilizce anahtarlar, Türkçe etiketler,
  ///    `Genel`…) [splitLoad] ile kompartımanlara bölünür; eşlenemeyenler
  ///    [unmapped]'a gider.
  factory MuscleLoadSnapshot.parse({Object? compartmentRaw, Object? legacyRaw}) {
    final direct = _numMap(compartmentRaw);
    if (direct.isNotEmpty) {
      final compartments = <MuscleCompartment, double>{};
      final unmapped = <String, double>{};
      direct.forEach((key, value) {
        final c = MuscleCompartment.fromFirestoreKey(key) ??
            compartmentFromKey(key);
        if (c == null) {
          unmapped[key] = (unmapped[key] ?? 0) + value;
        } else {
          compartments[c] = (compartments[c] ?? 0) + value;
        }
      });
      return MuscleLoadSnapshot(compartments: compartments, unmapped: unmapped);
    }
    final split = splitLoad(_numMap(legacyRaw));
    return MuscleLoadSnapshot(
      compartments: split.loads,
      unmapped: split.unmapped,
    );
  }

  static Map<String, double> _numMap(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, double>{};
    raw.forEach((key, value) {
      if (value is num) result[key.toString()] = value.toDouble();
    });
    return result;
  }
}
