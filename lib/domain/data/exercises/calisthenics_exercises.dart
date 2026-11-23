// lib/domain/data/exercises/calisthenics_exercises.dart

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';

/// Kalistenik (vücut ağırlığı) hareketleri: 40 hareket.
///
/// * Her egzersizin kompartıman ağırlıkları toplamı tam olarak 1.00'dır.
/// * `difficulty` (Lf) değerleri kompartıman göçünden önceki değerlerle aynıdır.
/// * Anahtarlar (egzersiz id'leri) kalıcı veride kullanıldığı için DEĞİŞTİRİLMEZ.
/// * İlk 38 hareket MLI golden fixture'larıyla dondurulmuştur
///   (bkz. `exerciseDatabase`); Faz 7 ekleri listenin sonundadır.
final Map<String, Exercise> calisthenicsExercises = {
  // ==================== İTİŞ (PUSH) ====================
  // Eller yüksekte: itiş açısı aşağı yönlü → alt/orta göğüs baskın.
  'incline_push_up': Exercise(
    name: 'Incline Push-up',
    difficulty: 0.65, // GRF %41-45 vücut ağırlığı
    compartments: {
      MuscleCompartment.midChest: 0.30,
      MuscleCompartment.lowerChest: 0.20,
      MuscleCompartment.upperChest: 0.05,
      MuscleCompartment.triceps: 0.20,
      MuscleCompartment.anteriorDeltoid: 0.15,
      MuscleCompartment.core: 0.10,
    },
  ),
  // Kısaltılmış kaldıraç; standart şınavla aynı kas dağılımı.
  'knee_push_up': Exercise(
    name: 'Knee Push-up',
    difficulty: 0.75, // GRF %53 vücut ağırlığı
    compartments: {
      MuscleCompartment.midChest: 0.35,
      MuscleCompartment.upperChest: 0.10,
      MuscleCompartment.lowerChest: 0.10,
      MuscleCompartment.triceps: 0.20,
      MuscleCompartment.anteriorDeltoid: 0.15,
      MuscleCompartment.core: 0.10,
    },
  ),
  // Yatay itiş: orta göğüs ana kas, triseps + ön omuz yardımcı, karın anti-ekstansiyon.
  'standard_push_up': Exercise(
    name: 'Standard Push-up',
    difficulty: 1.00, // Taban referans (GRF %64)
    compartments: {
      MuscleCompartment.midChest: 0.35,
      MuscleCompartment.upperChest: 0.10,
      MuscleCompartment.lowerChest: 0.10,
      MuscleCompartment.triceps: 0.20,
      MuscleCompartment.anteriorDeltoid: 0.15,
      MuscleCompartment.core: 0.10,
    },
  ),
  // Geniş tutuş: horizontal addüksiyon artar → göğüs payı yükselir, triseps azalır.
  'wide_push_up': Exercise(
    name: 'Wide Push-up',
    difficulty: 1.10,
    compartments: {
      MuscleCompartment.midChest: 0.40,
      MuscleCompartment.upperChest: 0.10,
      MuscleCompartment.lowerChest: 0.10,
      MuscleCompartment.anteriorDeltoid: 0.18,
      MuscleCompartment.triceps: 0.12,
      MuscleCompartment.core: 0.10,
    },
  ),
  // Dar tutuş: dirsek ekstansiyonu baskın → triseps ana kas.
  'diamond_push_up': Exercise(
    name: 'Diamond Push-up',
    difficulty: 1.25,
    compartments: {
      MuscleCompartment.triceps: 0.40,
      MuscleCompartment.midChest: 0.20,
      MuscleCompartment.upperChest: 0.05,
      MuscleCompartment.lowerChest: 0.05,
      MuscleCompartment.anteriorDeltoid: 0.20,
      MuscleCompartment.core: 0.10,
    },
  ),
  // Ayaklar yüksekte: itiş açısı yukarı → en baskın kompartıman üst göğüs; bölge olarak omuz önde.
  'decline_push_up': Exercise(
    name: 'Decline Push-up',
    difficulty: 1.20, // GRF %74 vücut ağırlığı
    compartments: {
      MuscleCompartment.upperChest: 0.30,
      MuscleCompartment.midChest: 0.05,
      MuscleCompartment.anteriorDeltoid: 0.28,
      MuscleCompartment.lateralDeltoid: 0.08,
      MuscleCompartment.triceps: 0.19,
      MuscleCompartment.core: 0.10,
    },
  ),
  // Dikey itiş: ön omuz + triseps, trapez skapula yukarı rotasyonu.
  'pike_push_up': Exercise(
    name: 'Pike Push-up',
    difficulty: 1.55,
    compartments: {
      MuscleCompartment.anteriorDeltoid: 0.35,
      MuscleCompartment.lateralDeltoid: 0.10,
      MuscleCompartment.triceps: 0.25,
      MuscleCompartment.upperBackTraps: 0.10,
      MuscleCompartment.upperChest: 0.05,
      MuscleCompartment.core: 0.15,
    },
  ),
  // Öne eğik dikey itiş: alt göğüs + triseps; bar kavrama ön kol.
  'dips_parallel_bar': Exercise(
    name: 'Parallel Bar Dips',
    difficulty: 1.55, // %100 vücut ağırlığı serbest asılı
    compartments: {
      MuscleCompartment.lowerChest: 0.30,
      MuscleCompartment.midChest: 0.10,
      MuscleCompartment.triceps: 0.33,
      MuscleCompartment.forearms: 0.05,
      MuscleCompartment.anteriorDeltoid: 0.17,
      MuscleCompartment.core: 0.05,
    },
  ),
  // Omuzlar ellerin önünde: ön omuz çok baskın; düz kol yükü biseps/ön kol, karın güçlü stabilizasyon.
  'pseudo_planche_push_up': Exercise(
    name: 'Pseudo Planche Push-up',
    difficulty: 2.10,
    compartments: {
      MuscleCompartment.anteriorDeltoid: 0.35,
      MuscleCompartment.lateralDeltoid: 0.05,
      MuscleCompartment.midChest: 0.10,
      MuscleCompartment.upperChest: 0.05,
      MuscleCompartment.triceps: 0.15,
      MuscleCompartment.biceps: 0.05,
      MuscleCompartment.forearms: 0.05,
      MuscleCompartment.upperBackTraps: 0.05,
      MuscleCompartment.core: 0.15,
    },
  ),
  // Tam dikey itiş: ön/yan omuz + triseps, trapez yukarı rotasyon.
  'handstand_push_up': Exercise(
    name: 'Handstand Push-up',
    difficulty: 2.70,
    compartments: {
      MuscleCompartment.anteriorDeltoid: 0.35,
      MuscleCompartment.lateralDeltoid: 0.12,
      MuscleCompartment.triceps: 0.25,
      MuscleCompartment.upperBackTraps: 0.13,
      MuscleCompartment.upperChest: 0.05,
      MuscleCompartment.core: 0.10,
    },
  ),
  // Yatay vücutta dikey itiş: ön omuz + triseps, bilek yükü ön kol, gövde kilidi karın/bel.
  '90_degree_push_up': Exercise(
    name: '90 Degree Push-up',
    difficulty: 3.40,
    compartments: {
      MuscleCompartment.anteriorDeltoid: 0.30,
      MuscleCompartment.lateralDeltoid: 0.05,
      MuscleCompartment.triceps: 0.22,
      MuscleCompartment.forearms: 0.08,
      MuscleCompartment.core: 0.20,
      MuscleCompartment.upperBackTraps: 0.05,
      MuscleCompartment.lowerBack: 0.05,
      MuscleCompartment.upperChest: 0.05,
    },
  ),

  // ==================== ÇEKİŞ (PULL) ====================
  // Yatay çekiş: lats + üst sırt eşit, arka omuz ve biseps yardımcı.
  'australian_row': Exercise(
    name: 'Australian Row (Horizontal Pull)',
    difficulty: 0.85,
    compartments: {
      MuscleCompartment.lats: 0.25,
      MuscleCompartment.upperBackTraps: 0.25,
      MuscleCompartment.lowerBack: 0.05,
      MuscleCompartment.posteriorDeltoid: 0.15,
      MuscleCompartment.biceps: 0.15,
      MuscleCompartment.forearms: 0.05,
      MuscleCompartment.core: 0.10,
    },
  ),
  // Supine tutuşla tepede izometrik: biseps ana kas, lats yardımcı, bar tutuşu ön kol.
  'chin_up_hold_top': Exercise(
    name: 'Chin-up Hold Top',
    difficulty: 1.15,
    compartments: {
      MuscleCompartment.biceps: 0.35,
      MuscleCompartment.forearms: 0.12,
      MuscleCompartment.lats: 0.25,
      MuscleCompartment.upperBackTraps: 0.08,
      MuscleCompartment.posteriorDeltoid: 0.05,
      MuscleCompartment.core: 0.15,
    },
  ),
  // Pronasyon tutuşla tepede izometrik: lats ana kas, bar tutuşu ön kol.
  'pull_up_hold_top': Exercise(
    name: 'Pull-up Hold Top',
    difficulty: 1.20,
    compartments: {
      MuscleCompartment.lats: 0.35,
      MuscleCompartment.upperBackTraps: 0.12,
      MuscleCompartment.biceps: 0.18,
      MuscleCompartment.forearms: 0.12,
      MuscleCompartment.posteriorDeltoid: 0.08,
      MuscleCompartment.core: 0.15,
    },
  ),
  // Dikey çekiş: lats ana kas, biseps + arka omuz yardımcı.
  'standard_pull_up': Exercise(
    name: 'Standard Pull-up',
    difficulty: 1.55, // %100 vücut ağırlığı
    compartments: {
      MuscleCompartment.lats: 0.40,
      MuscleCompartment.upperBackTraps: 0.10,
      MuscleCompartment.biceps: 0.20,
      MuscleCompartment.forearms: 0.08,
      MuscleCompartment.posteriorDeltoid: 0.10,
      MuscleCompartment.core: 0.12,
    },
  ),
  // Supine dikey çekiş: lats ≈ biseps; alt göğüs (sternal) omuz ekstansiyonuna katkı.
  'chin_up': Exercise(
    name: 'Chin-up',
    difficulty: 1.45,
    compartments: {
      MuscleCompartment.lats: 0.35,
      MuscleCompartment.upperBackTraps: 0.05,
      MuscleCompartment.biceps: 0.30,
      MuscleCompartment.forearms: 0.07,
      MuscleCompartment.posteriorDeltoid: 0.05,
      MuscleCompartment.lowerChest: 0.05,
      MuscleCompartment.core: 0.13,
    },
  ),
  // Geniş tutuş: lats + arka omuz baskın, biseps payı düşer.
  'wide_grip_pull_up': Exercise(
    name: 'Wide Grip Pull-up',
    difficulty: 1.70,
    compartments: {
      MuscleCompartment.lats: 0.45,
      MuscleCompartment.upperBackTraps: 0.12,
      MuscleCompartment.posteriorDeltoid: 0.13,
      MuscleCompartment.biceps: 0.12,
      MuscleCompartment.forearms: 0.06,
      MuscleCompartment.core: 0.12,
    },
  ),
  // Tek tarafa ağırlıklı dikey çekiş: lats + biseps, anti-rotasyon karın.
  'archer_pull_up': Exercise(
    name: 'Archer Pull-up',
    difficulty: 2.20,
    compartments: {
      MuscleCompartment.lats: 0.40,
      MuscleCompartment.upperBackTraps: 0.08,
      MuscleCompartment.biceps: 0.20,
      MuscleCompartment.forearms: 0.08,
      MuscleCompartment.posteriorDeltoid: 0.08,
      MuscleCompartment.core: 0.16,
    },
  ),
  // Düz kol omuz ekstansiyonu: lats + triseps uzun başı; karın ve bel gövde kilidi.
  'tuck_front_lever': Exercise(
    name: 'Tuck Front Lever',
    difficulty: 2.10,
    compartments: {
      MuscleCompartment.lats: 0.35,
      MuscleCompartment.upperBackTraps: 0.05,
      MuscleCompartment.lowerBack: 0.05,
      MuscleCompartment.core: 0.25,
      MuscleCompartment.posteriorDeltoid: 0.08,
      MuscleCompartment.biceps: 0.08,
      MuscleCompartment.forearms: 0.07,
      MuscleCompartment.triceps: 0.07,
    },
  ),
  // Dinamik front lever: lats ana kas, karın yüksek yük, bel ekstansiyonu.
  'front_lever_raise': Exercise(
    name: 'Front Lever Raise',
    difficulty: 2.70,
    compartments: {
      MuscleCompartment.lats: 0.38,
      MuscleCompartment.upperBackTraps: 0.05,
      MuscleCompartment.lowerBack: 0.07,
      MuscleCompartment.core: 0.25,
      MuscleCompartment.posteriorDeltoid: 0.08,
      MuscleCompartment.triceps: 0.07,
      MuscleCompartment.biceps: 0.05,
      MuscleCompartment.forearms: 0.05,
    },
  ),
  // Çekiş + geçiş + dip: kol bölgesi (biseps çekiş, triseps itiş) baskın; lats, alt göğüs.
  'muscle_up': Exercise(
    name: 'Muscle-up',
    difficulty: 2.90,
    compartments: {
      MuscleCompartment.lats: 0.28,
      MuscleCompartment.upperBackTraps: 0.07,
      MuscleCompartment.triceps: 0.18,
      MuscleCompartment.biceps: 0.12,
      MuscleCompartment.forearms: 0.08,
      MuscleCompartment.lowerChest: 0.12,
      MuscleCompartment.anteriorDeltoid: 0.05,
      MuscleCompartment.core: 0.10,
    },
  ),
  // Tek kol dikey çekiş: lats + biseps, yüksek kavrama yükü, anti-rotasyon karın.
  'one_arm_pull_up': Exercise(
    name: 'One Arm Pull-up',
    difficulty: 4.20,
    compartments: {
      MuscleCompartment.lats: 0.38,
      MuscleCompartment.upperBackTraps: 0.07,
      MuscleCompartment.biceps: 0.20,
      MuscleCompartment.forearms: 0.10,
      MuscleCompartment.posteriorDeltoid: 0.07,
      MuscleCompartment.core: 0.18,
    },
  ),

  // ==================== BACAK (LEGS) ====================
  // Diz 90° izometrik: quadriceps baskın.
  'wall_sit': Exercise(
    name: 'Wall Sit',
    difficulty: 0.70,
    compartments: {
      MuscleCompartment.quads: 0.70,
      MuscleCompartment.glutes: 0.17,
      MuscleCompartment.hamstrings: 0.05,
      MuscleCompartment.calves: 0.08,
    },
  ),
  // Kalça ekstansiyonu: kalça ana kas, hamstring yardımcı, bel/karın stabilizasyon.
  'glute_bridge': Exercise(
    name: 'Glute Bridge',
    difficulty: 0.75,
    compartments: {
      MuscleCompartment.glutes: 0.55,
      MuscleCompartment.hamstrings: 0.25,
      MuscleCompartment.quads: 0.05,
      MuscleCompartment.lowerBack: 0.08,
      MuscleCompartment.core: 0.07,
    },
  ),
  // Plantar fleksiyon: izole baldır.
  'calf_raise': Exercise(
    name: 'Calf Raise',
    difficulty: 0.65,
    compartments: {MuscleCompartment.calves: 1.00},
  ),
  // Diz + kalça ekstansiyonu: quadriceps ana kas, kalça yardımcı.
  'standard_squat': Exercise(
    name: 'Standard Squat',
    difficulty: 0.90,
    compartments: {
      MuscleCompartment.quads: 0.50,
      MuscleCompartment.glutes: 0.25,
      MuscleCompartment.hamstrings: 0.08,
      MuscleCompartment.calves: 0.05,
      MuscleCompartment.lowerBack: 0.05,
      MuscleCompartment.core: 0.07,
    },
  ),
  // Tek bacak ağırlıklı: quadriceps + kalça, denge için karın.
  'lunge': Exercise(
    name: 'Lunge',
    difficulty: 1.15,
    compartments: {
      MuscleCompartment.quads: 0.42,
      MuscleCompartment.glutes: 0.30,
      MuscleCompartment.hamstrings: 0.12,
      MuscleCompartment.calves: 0.06,
      MuscleCompartment.core: 0.10,
    },
  ),
  // Arka ayak yüksekte: ön bacak quadriceps + kalça, denge karın.
  'bulgarian_split_squat': Exercise(
    name: 'Bulgarian Split Squat',
    difficulty: 1.45,
    compartments: {
      MuscleCompartment.quads: 0.42,
      MuscleCompartment.glutes: 0.32,
      MuscleCompartment.hamstrings: 0.10,
      MuscleCompartment.calves: 0.04,
      MuscleCompartment.core: 0.12,
    },
  ),
  // Patlayıcı üçlü ekstansiyon: quadriceps, kalça ve baldır.
  'box_jump': Exercise(
    name: 'Box Jump',
    difficulty: 1.50,
    compartments: {
      MuscleCompartment.quads: 0.38,
      MuscleCompartment.glutes: 0.25,
      MuscleCompartment.calves: 0.22,
      MuscleCompartment.hamstrings: 0.10,
      MuscleCompartment.core: 0.05,
    },
  ),
  // Eksantrik diz fleksiyonu: hamstring baskın, gastroknemius yardımcı.
  'nordic_curl': Exercise(
    name: 'Nordic Hamstring Curl',
    difficulty: 2.40,
    compartments: {
      MuscleCompartment.hamstrings: 0.70,
      MuscleCompartment.glutes: 0.12,
      MuscleCompartment.calves: 0.08,
      MuscleCompartment.lowerBack: 0.05,
      MuscleCompartment.core: 0.05,
    },
  ),
  // Tek bacak derin squat: quadriceps baskın, kalça, denge karın.
  'shrimp_squat': Exercise(
    name: 'Shrimp Squat',
    difficulty: 2.20,
    compartments: {
      MuscleCompartment.quads: 0.52,
      MuscleCompartment.glutes: 0.28,
      MuscleCompartment.hamstrings: 0.05,
      MuscleCompartment.calves: 0.03,
      MuscleCompartment.core: 0.12,
    },
  ),
  // Tek bacak squat: quadriceps + kalça; serbest bacak için kalça fleksörü/karın.
  'pistol_squat': Exercise(
    name: 'Pistol Squat',
    difficulty: 2.30,
    compartments: {
      MuscleCompartment.quads: 0.48,
      MuscleCompartment.glutes: 0.25,
      MuscleCompartment.hamstrings: 0.04,
      MuscleCompartment.calves: 0.08,
      MuscleCompartment.core: 0.15,
    },
  ),

  // ==================== STATİK & CORE ====================
  // Anti-ekstansiyon: karın baskın, ön omuz ve kalça stabilizasyon.
  'plank': Exercise(
    name: 'Plank',
    difficulty: 0.70,
    compartments: {
      MuscleCompartment.core: 0.72,
      MuscleCompartment.anteriorDeltoid: 0.12,
      MuscleCompartment.glutes: 0.08,
      MuscleCompartment.quads: 0.08,
    },
  ),
  // Anti-lateral fleksiyon: oblikler + quadratus lumborum (bel), glute medius.
  'side_plank': Exercise(
    name: 'Side Plank',
    difficulty: 0.80,
    compartments: {
      MuscleCompartment.core: 0.68,
      MuscleCompartment.lowerBack: 0.10,
      MuscleCompartment.lateralDeltoid: 0.10,
      MuscleCompartment.glutes: 0.12,
    },
  ),
  // Anti-ekstansiyon: karın neredeyse izole; kalça fleksörü (rectus femoris).
  'hollow_body_hold': Exercise(
    name: 'Hollow Body Hold',
    difficulty: 1.10,
    compartments: {
      MuscleCompartment.core: 0.90,
      MuscleCompartment.quads: 0.05,
      MuscleCompartment.anteriorDeltoid: 0.05,
    },
  ),
  // Barda kilitli destek: omuz stabilizasyonu, triseps kilidi, kavrama ön kol, skapula depresyonu.
  'support_hold_parallel_bar': Exercise(
    name: 'Support Hold',
    difficulty: 0.95,
    compartments: {
      MuscleCompartment.anteriorDeltoid: 0.22,
      MuscleCompartment.lateralDeltoid: 0.08,
      MuscleCompartment.posteriorDeltoid: 0.05,
      MuscleCompartment.triceps: 0.20,
      MuscleCompartment.forearms: 0.10,
      MuscleCompartment.upperBackTraps: 0.10,
      MuscleCompartment.lowerChest: 0.10,
      MuscleCompartment.core: 0.15,
    },
  ),
  // Kalça fleksiyonu + omuz depresyonu: karın baskın, triseps kilidi, trapez/alt göğüs depresyon.
  'l_sit_hold': Exercise(
    name: 'L-Sit Hold',
    difficulty: 1.80,
    compartments: {
      MuscleCompartment.core: 0.50,
      MuscleCompartment.quads: 0.10,
      MuscleCompartment.triceps: 0.15,
      MuscleCompartment.forearms: 0.05,
      MuscleCompartment.anteriorDeltoid: 0.05,
      MuscleCompartment.lowerChest: 0.05,
      MuscleCompartment.upperBackTraps: 0.10,
    },
  ),
  // Düz kol öne eğilme: ön omuz çok baskın; karın, bel ve skapula protraksiyonu.
  'tuck_planche': Exercise(
    name: 'Tuck Planche',
    difficulty: 2.80,
    compartments: {
      MuscleCompartment.anteriorDeltoid: 0.35,
      MuscleCompartment.lateralDeltoid: 0.03,
      MuscleCompartment.core: 0.18,
      MuscleCompartment.lowerBack: 0.07,
      MuscleCompartment.upperBackTraps: 0.10,
      MuscleCompartment.triceps: 0.10,
      MuscleCompartment.biceps: 0.05,
      MuscleCompartment.forearms: 0.07,
      MuscleCompartment.upperChest: 0.05,
    },
  ),

  // ==================== FAZ 7 EKLERİ ====================
  // Havluyla asılı kalma: kavrama (ön kol) baskın; lats ve skapula aktif.
  'towel_dead_hang': Exercise(
    name: 'Towel Dead Hang',
    difficulty: 0.90,
    compartments: {
      MuscleCompartment.forearms: 0.55,
      MuscleCompartment.lats: 0.20,
      MuscleCompartment.upperBackTraps: 0.10,
      MuscleCompartment.biceps: 0.10,
      MuscleCompartment.core: 0.05,
    },
  ),
  // Yüzüstü kemer tutuşu / reverse hyperextension: erector spinae baskın,
  // kalça ve hamstring kalça ekstansiyonuna katılır.
  'arch_body_hold': Exercise(
    name: 'Arch Body Hold',
    difficulty: 0.75,
    compartments: {
      MuscleCompartment.lowerBack: 0.55,
      MuscleCompartment.glutes: 0.25,
      MuscleCompartment.hamstrings: 0.10,
      MuscleCompartment.upperBackTraps: 0.10,
    },
  ),
};
