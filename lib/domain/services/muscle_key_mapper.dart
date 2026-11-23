// lib/domain/services/muscle_key_mapper.dart
//
// Kas anahtarı eşlemesinin TEK giriş noktası.
//
// Farklı kaynaklardan gelen anahtarlar (eski İngilizce bölge adları, Türkçe
// etiketler — aksanlı/aksansız —, kompartıman `firestoreKey` / camelCase
// adları) burada 6 ana [MuscleRegion]'a veya 17 [MuscleCompartment]'a
// çevrilir. Eski bölge anahtarları (ör. `chest`) için yük, sabit
// [kLegacyRegionSplit] tablosuna göre kompartımanlara bölünür.

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';

/// Anahtarı karşılaştırma için normalize eder: küçük harf, Türkçe aksanlar
/// kaldırılır, boşluk / `_` / `-` / `/` / parantez gibi ayraçlar atılır.
///
/// Örn. `' Üst Sırt / Trapez '` → `ustsirttrapez`, `upper_back_traps` →
/// `upperbacktraps`, `upperBackTraps` → `upperbacktraps`.
String _fold(String raw) {
  final lower = raw.trim().toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    switch (ch) {
      case 'ç':
        buffer.write('c');
      case 'ğ':
        buffer.write('g');
      case 'ı':
        buffer.write('i');
      case 'ö':
        buffer.write('o');
      case 'ş':
        buffer.write('s');
      case 'ü':
        buffer.write('u');
      case 'â':
        buffer.write('a');
      case 'î':
        buffer.write('i');
      case 'û':
        buffer.write('u');
      default:
        final isAsciiLetter = rune >= 0x61 && rune <= 0x7A; // a-z
        final isDigit = rune >= 0x30 && rune <= 0x39; // 0-9
        if (isAsciiLetter || isDigit) buffer.write(ch);
      // Diğer her şey (boşluk, ayraç, U+0307 birleşik nokta vb.) atılır.
    }
  }
  return buffer.toString();
}

/// 1:1 kompartıman eş anlamlıları (kompartımanın kendi `firestoreKey`, `name`
/// ve `label` değerlerine ek olarak).
const Map<String, MuscleCompartment> _compartmentSynonyms = {
  'biseps': MuscleCompartment.biceps,
  'triseps': MuscleCompartment.triceps,
  'quadriceps': MuscleCompartment.quads,
  'kalça': MuscleCompartment.glutes,
  'baldır': MuscleCompartment.calves,
  'abs': MuscleCompartment.core,
  'karın': MuscleCompartment.core,
  'rear_shoulders': MuscleCompartment.posteriorDeltoid,
  'rear_delts': MuscleCompartment.posteriorDeltoid,
  'ön kol': MuscleCompartment.forearms,
  'traps': MuscleCompartment.upperBackTraps,
};

/// Eski (bölge seviyesindeki) anahtarlar. Bunlar tek bir kompartımana değil,
/// bir bölgeye karşılık gelir ve yükleri [kLegacyRegionSplit] ile bölünür.
const Map<String, MuscleRegion> _legacyRegionKeys = {
  'chest': MuscleRegion.chest,
  'göğüs': MuscleRegion.chest,
  'back': MuscleRegion.back,
  'sırt': MuscleRegion.back,
  'shoulders': MuscleRegion.shoulders,
  'shoulder': MuscleRegion.shoulders,
  'omuz': MuscleRegion.shoulders,
  'arms': MuscleRegion.arms,
  'kol': MuscleRegion.arms,
  'legs': MuscleRegion.legs,
  'bacak': MuscleRegion.legs,
};

/// Eski bölge anahtarlarının kompartımanlara bölünme oranları.
/// Her satırın toplamı tam olarak 1.00'dır.
///
/// `core` bölgesi tek kompartımandan oluştuğu için doğrudan eşlenir.
const Map<MuscleRegion, Map<MuscleCompartment, double>> kLegacyRegionSplit = {
  MuscleRegion.chest: {
    MuscleCompartment.midChest: 0.50,
    MuscleCompartment.upperChest: 0.30,
    MuscleCompartment.lowerChest: 0.20,
  },
  MuscleRegion.shoulders: {
    MuscleCompartment.anteriorDeltoid: 0.50,
    MuscleCompartment.lateralDeltoid: 0.30,
    MuscleCompartment.posteriorDeltoid: 0.20,
  },
  MuscleRegion.back: {
    MuscleCompartment.lats: 0.55,
    MuscleCompartment.upperBackTraps: 0.30,
    MuscleCompartment.lowerBack: 0.15,
  },
  MuscleRegion.arms: {
    MuscleCompartment.biceps: 0.45,
    MuscleCompartment.triceps: 0.45,
    MuscleCompartment.forearms: 0.10,
  },
  MuscleRegion.legs: {
    MuscleCompartment.quads: 0.40,
    MuscleCompartment.glutes: 0.25,
    MuscleCompartment.hamstrings: 0.25,
    MuscleCompartment.calves: 0.10,
  },
};

final Map<String, MuscleCompartment> _compartmentIndex = () {
  final index = <String, MuscleCompartment>{};
  for (final c in MuscleCompartment.values) {
    index[_fold(c.firestoreKey)] = c;
    index[_fold(c.name)] = c;
    index[_fold(c.label)] = c;
  }
  _compartmentSynonyms.forEach((key, c) => index[_fold(key)] = c);
  return index;
}();

final Map<String, MuscleRegion> _legacyRegionIndex = () {
  final index = <String, MuscleRegion>{};
  for (final r in MuscleRegion.values) {
    index[_fold(r.name)] = r;
    index[_fold(r.label)] = r;
  }
  _legacyRegionKeys.forEach((key, r) => index[_fold(key)] = r);
  // `core` / `Karın` doğrudan kompartımandır; bölge bölünmesine girmez.
  index.removeWhere((key, _) => _compartmentIndex.containsKey(key));
  return index;
}();

/// Anahtar tek bir kompartımana birebir karşılık geliyorsa onu döner.
/// Eski bölge anahtarları (`chest`, `Bacak` …) ve bilinmeyenler için `null`.
MuscleCompartment? compartmentFromKey(String rawKey) =>
    _compartmentIndex[_fold(rawKey)];

/// Anahtar eski bölge seviyesinde bir anahtarsa (`chest`, `Sırt`, `kol` …)
/// karşılık gelen bölgeyi döner; aksi halde `null`.
MuscleRegion? legacyRegionFromKey(String rawKey) =>
    _legacyRegionIndex[_fold(rawKey)];

/// Herhangi bir kas anahtarını 6 ana bölgeden birine eşler.
///
/// Eski `recoveryMuscleFromKey`'in üst kümesidir. `Genel` ve bilinmeyen
/// anahtarlar için `null` döner.
MuscleRegion? regionFromKey(String rawKey) {
  final folded = _fold(rawKey);
  return _compartmentIndex[folded]?.region ?? _legacyRegionIndex[folded];
}

/// [splitLoad] sonucu.
class CompartmentSplit {
  const CompartmentSplit({
    required this.loads,
    required this.unmapped,
  });

  /// Kompartıman bazında yük.
  final Map<MuscleCompartment, double> loads;

  /// Hiçbir kompartımana eşlenemeyen anahtarlar (ör. `Genel`) ve yükleri.
  final Map<String, double> unmapped;

  /// Eşlenemeyen toplam yük.
  double get unmappedTotal => unmapped.values.fold(0.0, (a, b) => a + b);

  /// Kompartımanlara dağıtılan toplam yük.
  double get mappedTotal => loads.values.fold(0.0, (a, b) => a + b);

  /// Girdi toplamı ( = [mappedTotal] + [unmappedTotal]).
  double get total => mappedTotal + unmappedTotal;
}

/// Anahtar → yük haritasını kompartımanlara dağıtır.
///
/// * Birebir anahtarlar tek kompartımana gider.
/// * Eski bölge anahtarları [kLegacyRegionSplit] oranlarıyla bölünür; son
///   pay kalan olarak hesaplanır, böylece anahtar başına toplam korunur.
/// * Eşlenemeyenler [CompartmentSplit.unmapped] içinde aynen tutulur.
CompartmentSplit splitLoad(Map<String, double> loadByKey) {
  final loads = <MuscleCompartment, double>{};
  final unmapped = <String, double>{};

  void add(MuscleCompartment c, double value) {
    loads[c] = (loads[c] ?? 0) + value;
  }

  loadByKey.forEach((key, load) {
    final direct = compartmentFromKey(key);
    if (direct != null) {
      add(direct, load);
      return;
    }
    final region = legacyRegionFromKey(key);
    final split = region == null ? null : kLegacyRegionSplit[region];
    if (split == null) {
      unmapped[key] = (unmapped[key] ?? 0) + load;
      return;
    }
    var remaining = load;
    final entries = split.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final isLast = i == entries.length - 1;
      final part = isLast ? remaining : load * entries[i].value;
      remaining -= part;
      add(entries[i].key, part);
    }
  });

  return CompartmentSplit(loads: loads, unmapped: unmapped);
}

/// ZAMAN verisi (toparlanma kaydı) için anahtarı kompartımanlara açar.
///
/// Eski bölge anahtarı o bölgenin tüm kompartımanlarını döner (zaman
/// bölünmez, her birine kopyalanır); birebir anahtar tek eleman döner;
/// bilinmeyen anahtar boş liste döner.
List<MuscleCompartment> expandRecoveryKey(String rawKey) {
  final direct = compartmentFromKey(rawKey);
  if (direct != null) return [direct];
  final region = legacyRegionFromKey(rawKey);
  if (region == null) return const [];
  return List.of(region.compartments);
}

/// Kompartıman yüklerini 6 ana bölgede toplar.
Map<MuscleRegion, double> aggregateToRegions(
  Map<MuscleCompartment, double> loads,
) {
  final result = <MuscleRegion, double>{};
  loads.forEach((c, value) {
    result[c.region] = (result[c.region] ?? 0) + value;
  });
  return result;
}
