// lib/data/repositories/fake_exercise_repository.dart

// BU DOĞRU SATIRLARI EKLEYİN
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart' as mli;
import 'package:calisthenics_app/data/repositories/exercise_repository.dart';
import 'package:calisthenics_app/data/repositories/phase7_exercise_descriptions.dart';
import 'package:calisthenics_app/domain/services/muscle_group_derivation.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';

/// A fake implementation of [ExerciseRepository] for development and testing.
///
/// This class returns a hardcoded list of exercises and simulates an async
/// data fetch using `Future.delayed`. This allows the UI to be developed
/// without needing a real backend.
class FakeExerciseRepository implements ExerciseRepository {
  static final List<Exercise> _fakeExercises = exerciseDatabase.entries
      .map((entry) => _toDomainExercise(entry.key, entry.value))
      .toList();

  /// 80 hareketlik hibrit katalog (40 kalistenik + 40 vücut geliştirme).
  static final List<Exercise> _catalogExercises = exerciseCatalog.entries
      .map((entry) => _toDomainExercise(entry.key, entry.value))
      .toList();

  static const Map<String, List<String>> prerequisiteExerciseIds = {
    'standard_push_up': ['incline_push_up', 'knee_push_up'],
    'wide_push_up': ['standard_push_up'],
    'diamond_push_up': ['knee_push_up', 'standard_push_up'],
    'decline_push_up': ['standard_push_up', 'pike_push_up'],
    'pike_push_up': ['decline_push_up', 'dips_parallel_bar'],
    'dips_parallel_bar': ['standard_push_up', 'diamond_push_up'],
    'pseudo_planche_push_up': ['pike_push_up', 'dips_parallel_bar'],
    'handstand_push_up': ['pike_push_up', 'pseudo_planche_push_up'],
    '90_degree_push_up': ['handstand_push_up', 'pseudo_planche_push_up'],
    'standard_pull_up': ['australian_row', 'chin_up_hold_top'],
    'chin_up': ['australian_row', 'chin_up_hold_top'],
    'wide_grip_pull_up': ['standard_pull_up', 'pull_up_hold_top'],
    'archer_pull_up': ['wide_grip_pull_up', 'chin_up'],
    'muscle_up': ['standard_pull_up', 'dips_parallel_bar', 'archer_pull_up'],
    'front_lever_raise': ['tuck_front_lever', 'pull_up_hold_top'],
    'one_arm_pull_up': ['archer_pull_up', 'front_lever_raise'],
    'standard_squat': ['wall_sit', 'glute_bridge'],
    'lunge': ['standard_squat', 'wall_sit'],
    'bulgarian_split_squat': ['standard_squat', 'lunge'],
    'box_jump': ['standard_squat', 'calf_raise'],
    'nordic_curl': ['glute_bridge', 'lunge'],
    'pistol_squat': ['bulgarian_split_squat', 'box_jump'],
    'shrimp_squat': ['bulgarian_split_squat', 'lunge'],
    'chin_up_hold_top': ['australian_row'],
    'pull_up_hold_top': ['australian_row', 'chin_up_hold_top'],
    'l_sit_hold': ['plank', 'support_hold_parallel_bar'],
    'tuck_front_lever': ['pull_up_hold_top', 'hollow_body_hold'],
    'tuck_planche': ['support_hold_parallel_bar', 'pike_push_up'],
  };

  static const Map<String, String> exerciseDescriptions = {
    'incline_push_up':
        'Kurulum: Eller yükselti üzerinde omuz genişliğinde, gövde düz çizgi.\n'
        'Uygulama: Dirsekleri 30-45 derece geriye kırıp göğsü yükseltiye yaklaştır, iterek başa dön.\n'
        'İpucu: Kalçayı düşürme, boynu nötr tut.\n'
        'Sık hata: Dirsekleri yana açmak, beli çökertmek.',
    'knee_push_up':
        'Kurulum: Dizler yerde, eller omuz altında, diz-omuz hattı düz.\n'
        'Uygulama: Kontrollü in, kolları açarak yukarı it.\n'
        'İpucu: Gövde tek parça hareket etsin.\n'
        'Sık hata: Kalçayı fazla kaldırıp hareketi kısaltmak.',
    'standard_push_up':
        'Kurulum: Eller omuz altında/az geniş, ayaklar geride, plank duruşu.\n'
        'Uygulama: Göğsü kontrollü yaklaştır, zemini iterek yukarı çık.\n'
        'İpucu: Karın ve kalçayı sık.\n'
        'Sık hata: Belin sarkması, yarım tekrar.',
    'wide_push_up':
        'Kurulum: Eller omuzdan geniş, gövde düz çizgi.\n'
        'Uygulama: Kontrollü aşağı in, güçlü şekilde yukarı it.\n'
        'İpucu: Dirsekleri hafif geriye yönlendir.\n'
        'Sık hata: Omuzları öne düşürmek, kontrolsüz iniş.',
    'diamond_push_up':
        'Kurulum: Eller göğüs altında elmas/üçgen şekli, gövde düz.\n'
        'Uygulama: Dirsekleri gövdeye yakın tutup in, triceps ile iterek çık.\n'
        'İpucu: Omuzları öne yığma.\n'
        'Sık hata: Dirsekleri yana açmak, bileği zorlamak.',
    'decline_push_up':
      'Kurulum: Ayaklar yüksekte, eller yerde omuz genişliğinde.\n'
        'Uygulama: Göğsü eller arasına indir, zemini iterek yukarı çık.\n'
        'İpucu: Beli sarkıtma, kalçayı kırma.\n'
        'Sık hata: Boynu germek, beli çökertmek.',
    'pike_push_up':
        'Kurulum: Kalça yukarıda ters V, eller omuz genişliğinde.\n'
        'Uygulama: Başı kontrollü yaklaştır, omuzlarla iterek yukarı çık.\n'
        'İpucu: Ağırlığı ellere taşı.\n'
        'Sık hata: Hareketi normal şınava çevirmek.',
    'dips_parallel_bar':
        'Kurulum: Paralelde support pozisyonu, omuzlar aşağıda.\n'
        'Uygulama: Dirsekleri kırıp kontrollü in, barları iterek kilitle.\n'
        'İpucu: Omuzları öne düşürme.\n'
        'Sık hata: Çok derine inmek, omuz silkerek çıkmak.',
    'pseudo_planche_push_up':
        'Kurulum: Eller biraz geride, omuzlar öne lean pozisyonunda.\n'
        'Uygulama: Lean koruyarak şınav gibi kontrollü in-çık.\n'
        'İpucu: Bilekleri iyi ısıt.\n'
        'Sık hata: Lean kaybedip normal şınava dönmek.',
    'handstand_push_up':
        'Kurulum: Duvar destekli el duruşu, karın sıkı, bel düz.\n'
        'Uygulama: Başı kontrollü indir, omuzlarla iterek yukarı kalk.\n'
        'İpucu: Banana pozisyonundan kaçın in.\n'
        'Sık hata: Bel aşırı kavisi, kolların öne kaçması.',
    '90_degree_push_up':
        'Kurulum: Omuzları öne al, ağırlığı ellere taşı, gövde sıkı.\n'
        'Uygulama: Kontrollü in, 90 derece civarında dengeyi koruyup presle.\n'
        'İpucu: Düşük tekrar, temiz form.\n'
        'Sık hata: Kontrolsüz düşmek, omuzu çökertmek.',
    'australian_row':
        'Kurulum: Bar altında gövde plank, topuklar yerde.\n'
        'Uygulama: Göğsü bara çek, kürekleri geriye-aşağı topla, kontrollü in.\n'
        'İpucu: Kalçayı düşürme.\n'
        'Sık hata: Sadece kolla çekmek, beli sarkıtmak.',
    'chin_up_hold_top':
        'Kurulum: Supine tutuş, çene bar üstünde tepe pozisyon.\n'
        'Uygulama: Omuzları aşağıda tutup süreyi koru.\n'
        'İpucu: Kısa ve kontrollü nefes al.\n'
        'Sık hata: Omuzları kulağa çekmek.',
    'pull_up_hold_top':
        'Kurulum: Pronated tutuş, çene bar üstünde tepe pozisyon.\n'
        'Uygulama: Kürekleri aşağı/geri sabitleyip bekle.\n'
        'İpucu: Boynu nötr tut, göğsü yukarıda kal.\n'
        'Sık hata: Omuzların yükselmesi, gövdenin dönmesi.',
    'standard_pull_up':
        'Kurulum: Omuz genişliği tutuş, aktif asılış ile başla.\n'
        'Uygulama: Dirsekleri aşağı/geri sürerek yukarı çek, kontrollü tam in.\n'
        'İpucu: Sallanma yapma.\n'
        'Sık hata: Yarım tekrar, boynu öne uzatmak.',
    'chin_up':
        'Kurulum: Avuç içleri sana bakar, gövde sıkı.\n'
        'Uygulama: Dirsekleri aşağı çekip çeneyi bara getir, kontrollü in.\n'
        'İpucu: İnişi yavaş yap.\n'
        'Sık hata: Belden sallanmak, omuzları yukarı çekmek.',
    'wide_grip_pull_up':
        'Kurulum: Omuzdan geniş tutuş, omuzlar kulaktan uzak.\n'
        'Uygulama: Kürekleri aşağı çekip yukarı çık, kontrollü in.\n'
        'İpucu: Ağrısız aralıkta çalış.\n'
        'Sık hata: Omuzu sıkıştırmak, kontrolsüz iniş.',
    'archer_pull_up':
        'Kurulum: Geniş tutuş, gövde sıkı.\n'
        'Uygulama: Bir tarafa kayarak bir kolu daha çok bük, diğer tarafa tekrarla.\n'
        'İpucu: Hareketi savurmadan yap.\n'
        'Sık hata: Momentumla yana fırlamak.',
    'muscle_up':
        'Kurulum: Patlayıcı çekiş + dip gücü, gövde sıkı.\n'
        'Uygulama: Yüksek çekiş, geçiş, dip ile üstte kilitle.\n'
        'İpucu: Geçişte acele etme.\n'
        'Sık hata: Sadece sallanmayla geçmeye çalışmak.',
    'tuck_front_lever':
        'Kurulum: Asılışta dizleri göğse çek, hollow pozisyon.\n'
        'Uygulama: Kürekleri aşağı/geri sabitleyip paralel hattı koru.\n'
        'İpucu: Kalçayı düşürme.\n'
        'Sık hata: Swing ile tutmak, beli boşlamak.',
    'front_lever_raise':
        'Kurulum: Asılış ve kürek kontrolü hazır olsun.\n'
        'Uygulama: Tuck front lever\'a kontrollü yüksel, kontrollü geri in.\n'
        'İpucu: Hız değil çizgi kontrolü.\n'
        'Sık hata: Momentumla yükselmek.',
    'one_arm_pull_up':
        'Kurulum: Çok ileri seviye, genelde yardımlı çalışılır.\n'
        'Uygulama: Küreği aşağı bastır, dirseği çekip gövdeyi bara yaklaştır.\n'
        'İpucu: Az tekrar, uzun dinlenme.\n'
        'Sık hata: Omuzun yukarı kaçması, dirseği zorlamak.',
    'standard_squat':
        'Kurulum: Ayaklar omuz genişliği, parmaklar hafif dışarı.\n'
        'Uygulama: Kalçayı geriye-aşağı indir, topuktan iterek kalk.\n'
        'İpucu: Ayak tabanını yere kilitle.\n'
        'Sık hata: Dizlerin içe çökmesi.',
    'lunge':
        'Kurulum: Dik duruş, orta adım mesafesi.\n'
        'Uygulama: Arka dizi yere yaklaştır, ön topuktan iterek dön.\n'
        'İpucu: Gövde dik, diz çizgisi sabit.\n'
        'Sık hata: Ön dizin içe kaçması.',
    'bulgarian_split_squat':
      'Kurulum: Arka ayak yüksekte, ön ayak sabit.\n'
        'Uygulama: Düz aşağı in, ön bacakla yukarı kalk.\n'
        'İpucu: Hareketi öne değil aşağı yap.\n'
        'Sık hata: Öne aşırı yığılmak, topuğu kaldırmak.',
    'box_jump':
        'Kurulum: Ayaklar omuz genişliği, hafif çömelme ile hazırlan.\n'
        'Uygulama: Patlayıcı zıpla, yumuşak in, kontrollü iniş yap.\n'
        'İpucu: Sessiz iniş hedefle.\n'
        'Sık hata: Sert iniş, dizlerin içe çökmesi.',
    'nordic_curl':
        'Kurulum: Dizler yerde, ayaklar sabit, gövde düz çizgi.\n'
        'Uygulama: Yavaş öne in, hamstring ile frenle, destekle geri dön.\n'
        'İpucu: Yavaş iniş en kritik kısımdır.\n'
        'Sık hata: Kalçadan kırılmak, kontrolsüz düşmek.',
    'pistol_squat':
        'Kurulum: Tek ayak denge, diğer bacak öne uzatılı.\n'
        'Uygulama: Kontrollü çömel, tek bacakla itip kalk.\n'
        'İpucu: Denge için kolları öne uzat.\n'
        'Sık hata: Topuğun kalkması, dizin içe kaçması.',
    'shrimp_squat':
        'Kurulum: Tek ayak denge, diğer bacak arkada bükülü.\n'
        'Uygulama: Kontrollü in, dizi yaklaştır, aynı çizgide kalk.\n'
        'İpucu: İnişi yavaşlat.\n'
        'Sık hata: Hızlı sert iniş, diz çizgisini bozmak.',
    'wall_sit':
        'Kurulum: Sırt duvarda, dizler yaklaşık 90 derece.\n'
        'Uygulama: Pozisyonu bozmadan süre tut.\n'
        'İpucu: Nefesi düzenli tut.\n'
        'Sık hata: Dizlerin içe çökmesi.',
    'glute_bridge':
        'Kurulum: Sırt yerde, dizler bükülü, topuklar kalçaya yakın.\n'
        'Uygulama: Kalçayı yukarı kaldır, üstte sık, kontrollü indir.\n'
        'İpucu: Yükü topukta tut.\n'
        'Sık hata: Belden itmek, hızlı düşmek.',
    'calf_raise':
        'Kurulum: Dik duruş, ayaklar paralel.\n'
        'Uygulama: Parmak ucuna yüksel, üstte kısa bekle, yavaş in.\n'
        'İpucu: Tam aralık ve kontrol uygula.\n'
        'Sık hata: Zıplayarak yapmak, yarım tekrar.',
    'plank':
        'Kurulum: Dirsekler omuz altında, gövde düz çizgi.\n'
        'Uygulama: Karın ve kalçayı sıkıp pozisyonu süreyle koru.\n'
        'İpucu: Boynu nötr tut, kaburgayı aşağıda tut.\n'
        'Sık hata: Belin sarkması, kalçayı fazla kaldırmak.',
    'side_plank':
        'Kurulum: Dirsek omuz altında, yan hizada denge kur.\n'
        'Uygulama: Kalçayı kaldırıp düz yanal çizgiyi süreyle koru.\n'
        'İpucu: Omzu kulaktan uzak, boynu nötr tut.\n'
        'Sık hata: Kalçayı düşürmek, gövdeyi öne döndürmek.',
    'support_hold_parallel_bar':
        'Kurulum: Paralelde kolları kilitle, omuzları aşağı bastır.\n'
        'Uygulama: Sallanmadan üst pozisyonu koru.\n'
        'İpucu: Gövdeyi ve kalçayı sık.\n'
        'Sık hata: Dirseği kırma, omuz silkme.',
    'l_sit_hold':
        'Kurulum: Kolları kilitle, omuzları aşağı it.\n'
        'Uygulama: Bacakları öne kaldırıp L pozisyonunu süreyle koru.\n'
        'İpucu: Zorsa diz bükülü versiyonla başla.\n'
        'Sık hata: Omuzların çökmesi, bacakları düşürmek.',
    'hollow_body_hold':
        'Kurulum: Sırt üstü, bel yere yapışık.\n'
        'Uygulama: Omuz ve bacakları kaldırıp hollow pozisyonunu koru.\n'
        'İpucu: Bel kalkarsa bacakları biraz yukarı al.\n'
        'Sık hata: Belin yerden ayrılması.',
    'tuck_planche':
        'Kurulum: Eller yerde/paralette, kollar kilitli, omuzlar öne lean.\n'
        'Uygulama: Dizleri göğse çekip ayakları yerden keserek dengeyi koru.\n'
        'İpucu: Omuzlar ellerin önünde kalsın.\n'
        'Sık hata: Dirsek bükmek, omuzları geride bırakmak.',
  };

  static Exercise _toDomainExercise(String id, mli.Exercise source) {
    final level = levelFromCoefficient(source.difficulty);
    // Kütüphane kaydı kompartımanlarla tanımlıdır; boşsa eski bölge
    // ağırlıkları (`muscles`) kompartımanlara bölünür.
    final compartments = source.compartments.isNotEmpty
        ? source.compartments
        : compartmentWeightsFromLegacy(source.muscles);
    final derived = deriveMuscleGroups(compartments);
    final ratings = derived.ratings;
    final targetMuscles = derived.targets;

    return Exercise(
      id: id,
      name: source.name,
      level: level,
      difficulty: difficultyFromCoefficient(source.difficulty),
      targetMuscleGroups: targetMuscles,
      muscleRatings: ratings,
      compartmentWeights: compartments,
      type: source.type,
      description:
          exerciseDescriptions[id] ??
          phase7ExerciseDescriptions[id] ??
          '${source.name} hareketi için kas aktivasyon dağılımı.',
      prerequisiteExercises: buildPrerequisites(id: id, level: level),
    );
  }

  static List<String> buildPrerequisites({
    required String id,
    required ExerciseLevel level,
  }) {
    if (level == ExerciseLevel.beginner ||
        bodybuildingExercises.containsKey(id)) {
      return const <String>[];
    }

    final prerequisiteNames = (prerequisiteExerciseIds[id] ?? const <String>[])
        .map((exerciseId) => exerciseCatalog[exerciseId]?.name)
        .whereType<String>()
        .toList();

    if (prerequisiteNames.isEmpty) {
      return const <String>[
        'Standard Push-up',
        'Standard Pull-up',
        'Standard Squat',
      ];
    }

    return prerequisiteNames;
  }

  static MuscleGroup? muscleFromKey(String key) {
    switch (key) {
      case 'chest':
        return MuscleGroup.chest;
      case 'back':
        return MuscleGroup.back;
      case 'shoulders':
      case 'rear_shoulders':
        return MuscleGroup.shoulders;
      case 'biceps':
        return MuscleGroup.biceps;
      case 'triceps':
        return MuscleGroup.triceps;
      case 'legs':
        return MuscleGroup.legs;
      case 'core':
        return MuscleGroup.core;
      case 'quads':
        return MuscleGroup.quads;
      case 'hamstrings':
        return MuscleGroup.hamstrings;
      case 'glutes':
        return MuscleGroup.glutes;
      case 'calves':
        return MuscleGroup.calves;
      default:
        return null;
    }
  }

  static DifficultyLevel difficultyFromCoefficient(double coefficient) {
    if (coefficient < 1.0) {
      return DifficultyLevel.easy;
    }
    if (coefficient < 2.0) {
      return DifficultyLevel.medium;
    }
    return DifficultyLevel.hard;
  }

  static ExerciseLevel levelFromCoefficient(double coefficient) {
    if (coefficient < 1.0) {
      return ExerciseLevel.beginner;
    }
    if (coefficient < 2.5) {
      return ExerciseLevel.intermediate;
    }
    return ExerciseLevel.advanced;
  }

  /// Simulates a network delay.
  Future<void> _simulateNetworkDelay() {
    return Future.delayed(const Duration(milliseconds: 500));
  }

  /// Dondurulmuş 38 hareketlik kalistenik çekirdek (golden ve senkronizasyon
  /// testlerinin sözleşmesi). Uygulama genelinde [getCatalogExercises]
  /// kullanılır.
  @override
  Future<List<Exercise>> getAllExercises() async {
    await _simulateNetworkDelay();
    return _fakeExercises;
  }

  /// 80 hareketlik hibrit katalog (kalistenik + vücut geliştirme).
  Future<List<Exercise>> getCatalogExercises() async {
    await _simulateNetworkDelay();
    return _catalogExercises;
  }

  /// Ağ gecikmesi olmadan hibrit katalog (ör. çevrimdışı geri dönüş).
  static List<Exercise> get catalogExercises => _catalogExercises;

  @override
  Future<List<Exercise>> getExercisesByLevel(ExerciseLevel level) async {
    await _simulateNetworkDelay();
    return _fakeExercises.where((ex) => ex.level == level).toList();
  }

  @override
  Future<List<Exercise>> getExercisesByMuscleGroup(
    MuscleGroup muscleGroup,
  ) async {
    await _simulateNetworkDelay();
    return _fakeExercises
        .where((ex) => ex.targetMuscleGroups.contains(muscleGroup))
        .toList();
  }

  @override
  Future<List<Exercise>> getFilteredExercises({
    ExerciseLevel? level,
    MuscleGroup? muscleGroup,
  }) async {
    await _simulateNetworkDelay();
    var exercises = _fakeExercises;

    if (level != null) {
      exercises = exercises.where((ex) => ex.level == level).toList();
    }

    if (muscleGroup != null) {
      exercises = exercises
          .where((ex) => ex.targetMuscleGroups.contains(muscleGroup))
          .toList();
    }

    return exercises;
  }
}
