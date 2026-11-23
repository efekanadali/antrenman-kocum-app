// lib/domain/enums/muscle_compartment.dart

/// Toparlanma ve analizde kullanılan 6 ana kas bölgesi.
///
/// Sıra, eski `RecoveryMuscle` ile birebir aynıdır (UI `values` üzerinde
/// iterasyon yapar, Firestore doküman id'leri `name` alanını kullanır).
enum MuscleRegion {
  chest('Göğüs'),
  back('Sırt'),
  shoulders('Omuz'),
  arms('Kol'),
  core('Karın'),
  legs('Bacak');

  const MuscleRegion(this.label);

  /// Türkçe görünen ad.
  final String label;
}

/// 17 kas kompartımanı (biyomekanik alt bölge).
enum MuscleCompartment {
  upperChest(
    region: MuscleRegion.chest,
    firestoreKey: 'upper_chest',
    label: 'Üst Göğüs',
  ),
  midChest(
    region: MuscleRegion.chest,
    firestoreKey: 'mid_chest',
    label: 'Orta Göğüs',
  ),
  lowerChest(
    region: MuscleRegion.chest,
    firestoreKey: 'lower_chest',
    label: 'Alt Göğüs',
  ),
  anteriorDeltoid(
    region: MuscleRegion.shoulders,
    firestoreKey: 'anterior_deltoid',
    label: 'Ön Omuz',
  ),
  lateralDeltoid(
    region: MuscleRegion.shoulders,
    firestoreKey: 'lateral_deltoid',
    label: 'Yan Omuz',
    recoverySizeFactor: 0.85,
  ),
  posteriorDeltoid(
    region: MuscleRegion.shoulders,
    firestoreKey: 'posterior_deltoid',
    label: 'Arka Omuz',
  ),
  lats(
    region: MuscleRegion.back,
    firestoreKey: 'lats',
    label: 'Kanat (Lats)',
  ),
  upperBackTraps(
    region: MuscleRegion.back,
    firestoreKey: 'upper_back_traps',
    label: 'Üst Sırt / Trapez',
  ),
  lowerBack(
    region: MuscleRegion.back,
    firestoreKey: 'lower_back',
    label: 'Bel',
    recoverySizeFactor: 1.10,
  ),
  biceps(
    region: MuscleRegion.arms,
    firestoreKey: 'biceps',
    label: 'Biseps',
    recoverySizeFactor: 0.85,
  ),
  triceps(
    region: MuscleRegion.arms,
    firestoreKey: 'triceps',
    label: 'Triseps',
  ),
  forearms(
    region: MuscleRegion.arms,
    firestoreKey: 'forearms',
    label: 'Ön Kol',
    recoverySizeFactor: 0.85,
  ),
  quads(
    region: MuscleRegion.legs,
    firestoreKey: 'quads',
    label: 'Quadriceps',
    recoverySizeFactor: 1.10,
  ),
  hamstrings(
    region: MuscleRegion.legs,
    firestoreKey: 'hamstrings',
    label: 'Hamstrings',
    recoverySizeFactor: 1.10,
  ),
  glutes(
    region: MuscleRegion.legs,
    firestoreKey: 'glutes',
    label: 'Kalça',
  ),
  calves(
    region: MuscleRegion.legs,
    firestoreKey: 'calves',
    label: 'Baldır',
    recoverySizeFactor: 0.85,
  ),
  core(
    region: MuscleRegion.core,
    firestoreKey: 'core',
    label: 'Karın',
  );

  const MuscleCompartment({
    required this.region,
    required this.firestoreKey,
    required this.label,
    this.recoverySizeFactor = 1.0,
  });

  /// Bağlı olduğu ana bölge.
  final MuscleRegion region;

  /// Firestore / kalıcı veri anahtarı (snake_case). Değiştirilmemelidir.
  final String firestoreKey;

  /// Türkçe görünen ad.
  final String label;

  /// Kas boyutuna göre toparlanma süresi çarpanı.
  ///
  /// NOT: Henüz toparlanma hesaplayıcısı tarafından kullanılmıyor (faz 4).
  final double recoverySizeFactor;

  static final Map<String, MuscleCompartment> _byFirestoreKey = {
    for (final c in MuscleCompartment.values) c.firestoreKey: c,
  };

  /// `firestoreKey`'den kompartımana çevirir; bilinmeyen anahtar için `null`.
  static MuscleCompartment? fromFirestoreKey(String key) =>
      _byFirestoreKey[key];
}

extension MuscleRegionCompartments on MuscleRegion {
  /// Bu bölgeye ait kompartımanlar (`MuscleCompartment.values` sırasıyla).
  List<MuscleCompartment> get compartments => [
        for (final c in MuscleCompartment.values)
          if (c.region == this) c,
      ];
}
