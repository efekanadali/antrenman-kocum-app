// lib/data/repositories/fake_exercise_repository.dart

// BU DOĞRU SATIRLARI EKLEYİN
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart' as mli;
import 'package:calisthenics_app/data/repositories/exercise_repository.dart';

/// A fake implementation of [ExerciseRepository] for development and testing.
///
/// This class returns a hardcoded list of exercises and simulates an async
/// data fetch using `Future.delayed`. This allows the UI to be developed
/// without needing a real backend.
class FakeExerciseRepository implements ExerciseRepository {
  static final List<Exercise> _fakeExercises = exerciseDatabase.entries
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
        'Kurulum: Eller yukselti uzerinde omuz genisliginde, govde duz cizgi.\n'
        'Uygulama: Dirsekleri 30-45 derece geriye kirip gogsu yukseltiye yaklastir, iterek basa don.\n'
        'Ipucu: Kalcayi dusurme, boynu notr tut.\n'
        'Sik hata: Dirsekleri yana acmak, beli cokertmek.',
    'knee_push_up':
        'Kurulum: Dizler yerde, eller omuz altinda, diz-omuz hatti duz.\n'
        'Uygulama: Kontrollu in, kollari acarak yukari it.\n'
        'Ipucu: Govde tek parca hareket etsin.\n'
        'Sik hata: Kalcayi fazla kaldirip hareketi kisaltmak.',
    'standard_push_up':
        'Kurulum: Eller omuz altinda/az genis, ayaklar geride, plank durusu.\n'
        'Uygulama: Gogsu kontrollu yaklastir, zemini iterek yukari cik.\n'
        'Ipucu: Karin ve kalcayi sik.\n'
        'Sik hata: Belin sarkmasi, yarim tekrar.',
    'wide_push_up':
        'Kurulum: Eller omuzdan genis, govde duz cizgi.\n'
        'Uygulama: Kontrollu asagi in, guclu sekilde yukari it.\n'
        'Ipucu: Dirsekleri hafif geriye yonlendir.\n'
        'Sik hata: Omuzlari one dusurmek, kontrolsuz inis.',
    'diamond_push_up':
        'Kurulum: Eller gogus altinda elmas/ucgen sekli, govde duz.\n'
        'Uygulama: Dirsekleri govdeye yakin tutup in, triceps ile iterek cik.\n'
        'Ipucu: Omuzlari one yigma.\n'
        'Sik hata: Dirsekleri yana acmak, bilegi zorlamak.',
    'decline_push_up':
      'Kurulum: Ayaklar yuksekte, eller yerde omuz genisliginde.\n'
        'Uygulama: Gogsu eller arasina indir, zemini iterek yukari cik.\n'
        'Ipucu: Beli sarkitma, kalcayi kirma.\n'
        'Sik hata: Boynu germek, beli cokertmek.',
    'pike_push_up':
        'Kurulum: Kalca yukarida ters V, eller omuz genisliginde.\n'
        'Uygulama: Basi kontrollu yaklastir, omuzlarla iterek yukari cik.\n'
        'Ipucu: Agirligi ellere tasi.\n'
        'Sik hata: Hareketi normal sinava cevirmek.',
    'dips_parallel_bar':
        'Kurulum: Paralelde support pozisyonu, omuzlar asagida.\n'
        'Uygulama: Dirsekleri kirip kontrollu in, barlari iterek kilitle.\n'
        'Ipucu: Omuzlari one dusurme.\n'
        'Sik hata: Cok derine inmek, omuz silkerek cikmak.',
    'pseudo_planche_push_up':
        'Kurulum: Eller biraz geride, omuzlar one lean pozisyonunda.\n'
        'Uygulama: Lean koruyarak sinav gibi kontrollu in-cik.\n'
        'Ipucu: Bilekleri iyi isit.\n'
        'Sik hata: Lean kaybedip normal sinava donmek.',
    'handstand_push_up':
        'Kurulum: Duvar destekli el durusu, karin siki, bel duz.\n'
        'Uygulama: Basi kontrollu indir, omuzlarla iterek yukari kalk.\n'
        'Ipucu: Banana pozisyonundan kac in.\n'
        'Sik hata: Bel asiri kavisi, kollarin one kacmasi.',
    '90_degree_push_up':
        'Kurulum: Omuzlari one al, agirligi ellere tasi, govde siki.\n'
        'Uygulama: Kontrollu in, 90 derece civarinda dengeyi koruyup presle.\n'
        'Ipucu: Dusuk tekrar, temiz form.\n'
        'Sik hata: Kontrolsuz dusmek, omuzu cokertmek.',
    'australian_row':
        'Kurulum: Bar altinda govde plank, topuklar yerde.\n'
        'Uygulama: Gogsu bara cek, kurekleri geriye-asagi topla, kontrollu in.\n'
        'Ipucu: Kalcayi dusurme.\n'
        'Sik hata: Sadece kolla cekmek, beli sarkitmak.',
    'chin_up_hold_top':
        'Kurulum: Supine tutus, cene bar ustunde tepe pozisyon.\n'
        'Uygulama: Omuzlari asagida tutup sureyi koru.\n'
        'Ipucu: Kisa ve kontrollu nefes al.\n'
        'Sik hata: Omuzlari kulaga cekmek.',
    'pull_up_hold_top':
        'Kurulum: Pronated tutus, cene bar ustunde tepe pozisyon.\n'
        'Uygulama: Kurekleri asagi/geri sabitleyip bekle.\n'
        'Ipucu: Boynu notr tut, gogsu yukarida kal.\n'
        'Sik hata: Omuzlarin yukselmesi, govdenin donmesi.',
    'standard_pull_up':
        'Kurulum: Omuz genisligi tutus, aktif asilis ile basla.\n'
        'Uygulama: Dirsekleri asagi/geri surerek yukari cek, kontrollu tam in.\n'
        'Ipucu: Sallanma yapma.\n'
        'Sik hata: Yarim tekrar, boynu one uzatmak.',
    'chin_up':
        'Kurulum: Avuc icleri sana bakar, govde siki.\n'
        'Uygulama: Dirsekleri asagi cekip ceneyi bara getir, kontrollu in.\n'
        'Ipucu: Inisi yavas yap.\n'
        'Sik hata: Belden sallanmak, omuzlari yukari cekmek.',
    'wide_grip_pull_up':
        'Kurulum: Omuzdan genis tutus, omuzlar kulaktan uzak.\n'
        'Uygulama: Kurekleri asagi cekip yukari cik, kontrollu in.\n'
        'Ipucu: Agrisiz aralikta calis.\n'
        'Sik hata: Omuzu sikistirmak, kontrolsuz inis.',
    'archer_pull_up':
        'Kurulum: Genis tutus, govde siki.\n'
        'Uygulama: Bir tarafa kayarak bir kolu daha cok buk, diger tarafa tekrarla.\n'
        'Ipucu: Hareketi savurmadan yap.\n'
        'Sik hata: Momentumla yana firlamak.',
    'muscle_up':
        'Kurulum: Patlayici cekis + dip gucu, govde siki.\n'
        'Uygulama: Yuksek cekis, gecis, dip ile ustte kilitle.\n'
        'Ipucu: Geciste acele etme.\n'
        'Sik hata: Sadece sallanmayla gecmeye calismak.',
    'tuck_front_lever':
        'Kurulum: Asilista dizleri gogse cek, hollow pozisyon.\n'
        'Uygulama: Kurekleri asagi/geri sabitleyip paralel hatti koru.\n'
        'Ipucu: Kalcayi dusurme.\n'
        'Sik hata: Swing ile tutmak, beli boslamak.',
    'front_lever_raise':
        'Kurulum: Asilis ve kurek kontrolu hazir olsun.\n'
        'Uygulama: Tuck front levera kontrollu yuksel, kontrollu geri in.\n'
        'Ipucu: Hiz degil cizgi kontrolu.\n'
        'Sik hata: Momentumla yukselmek.',
    'one_arm_pull_up':
        'Kurulum: Cok ileri seviye, genelde yardimli calisilir.\n'
        'Uygulama: Kuregi asagi bastir, dirsegi cekip govdeyi bara yaklastir.\n'
        'Ipucu: Az tekrar, uzun dinlenme.\n'
        'Sik hata: Omuzun yukari kacmasi, dirsegi zorlamak.',
    'standard_squat':
        'Kurulum: Ayaklar omuz genisligi, parmaklar hafif disari.\n'
        'Uygulama: Kalcayi geriye-asagi indir, topuktan iterek kalk.\n'
        'Ipucu: Ayak tabanini yere kilitle.\n'
        'Sik hata: Dizlerin ice cokmesi.',
    'lunge':
        'Kurulum: Dik durus, orta adim mesafesi.\n'
        'Uygulama: Arka dizi yere yaklastir, on topuktan iterek don.\n'
        'Ipucu: Govde dik, diz cizgisi sabit.\n'
        'Sik hata: On dizin ice kacmasi.',
    'bulgarian_split_squat':
      'Kurulum: Arka ayak yuksekte, on ayak sabit.\n'
        'Uygulama: Duz asagi in, on bacakla yukari kalk.\n'
        'Ipucu: Hareketi one degil asagi yap.\n'
        'Sik hata: One asiri yigilmak, topugu kaldirmak.',
    'box_jump':
        'Kurulum: Ayaklar omuz genisligi, hafif comelme ile hazirlan.\n'
        'Uygulama: Patlayici zipla, yumusak in, kontrollu inis yap.\n'
        'Ipucu: Sessiz inis hedefle.\n'
        'Sik hata: Sert inis, dizlerin ice cokmesi.',
    'nordic_curl':
        'Kurulum: Dizler yerde, ayaklar sabit, govde duz cizgi.\n'
        'Uygulama: Yavas one in, hamstring ile frenle, destekle geri don.\n'
        'Ipucu: Yavas inis en kritik kisimdir.\n'
        'Sik hata: Kalcadan kirilmak, kontrolsuz dusmek.',
    'pistol_squat':
        'Kurulum: Tek ayak denge, diger bacak one uzatili.\n'
        'Uygulama: Kontrollu comel, tek bacakla itip kalk.\n'
        'Ipucu: Denge icin kollari one uzat.\n'
        'Sik hata: Topugun kalkmasi, dizin ice kacmasi.',
    'shrimp_squat':
        'Kurulum: Tek ayak denge, diger bacak arkada bukulu.\n'
        'Uygulama: Kontrollu in, dizi yaklastir, ayni cizgide kalk.\n'
        'Ipucu: Inisi yavaslat.\n'
        'Sik hata: Hizli sert inis, diz cizgisini bozmak.',
    'wall_sit':
        'Kurulum: Sirt duvarda, dizler yaklasik 90 derece.\n'
        'Uygulama: Pozisyonu bozmadan sure tut.\n'
        'Ipucu: Nefesi duzenli tut.\n'
        'Sik hata: Dizlerin ice cokmesi.',
    'glute_bridge':
        'Kurulum: Sirt yerde, dizler bukulu, topuklar kalcaya yakin.\n'
        'Uygulama: Kalcayi yukari kaldir, ustte sik, kontrollu indir.\n'
        'Ipucu: Yuku topukta tut.\n'
        'Sik hata: Belden itmek, hizli dusmek.',
    'calf_raise':
        'Kurulum: Dik durus, ayaklar paralel.\n'
        'Uygulama: Parmak ucuna yuksel, ustte kisa bekle, yavas in.\n'
        'Ipucu: Tam aralik ve kontrol uygula.\n'
        'Sik hata: Ziplayarak yapmak, yarim tekrar.',
    'plank':
        'Kurulum: Dirsekler omuz altinda, govde duz cizgi.\n'
        'Uygulama: Karin ve kalcayi sikip pozisyonu sureyle koru.\n'
        'Ipucu: Boynu notr tut, kaburgayi asagida tut.\n'
        'Sik hata: Belin sarkmasi, kalcayi fazla kaldirmak.',
    'side_plank':
        'Kurulum: Dirsek omuz altinda, yan hizada denge kur.\n'
        'Uygulama: Kalcayi kaldirip duz yanal cizgiyi sureyle koru.\n'
        'Ipucu: Omzu kulaktan uzak, boynu notr tut.\n'
        'Sik hata: Kalcayi dusurmek, govdeyi one dondurmek.',
    'support_hold_parallel_bar':
        'Kurulum: Paralelde kollari kilitle, omuzlari asagi bastir.\n'
        'Uygulama: Sallanmadan ust pozisyonu koru.\n'
        'Ipucu: Govdeyi ve kalcayi sik.\n'
        'Sik hata: Dirsegi kirma, omuz silkme.',
    'l_sit_hold':
        'Kurulum: Kollari kilitle, omuzlari asagi it.\n'
        'Uygulama: Bacaklari one kaldirip L pozisyonunu sureyle koru.\n'
        'Ipucu: Zorsa diz bukulu versiyonla basla.\n'
        'Sik hata: Omuzlarin cokmesi, bacaklari dusurmek.',
    'hollow_body_hold':
        'Kurulum: Sirt ustu, bel yere yapisik.\n'
        'Uygulama: Omuz ve bacaklari kaldirip hollow pozisyonunu koru.\n'
        'Ipucu: Bel kalkarsa bacaklari biraz yukari al.\n'
        'Sik hata: Belin yerden ayrilmasi.',
    'tuck_planche':
        'Kurulum: Eller yerde/paralette, kollar kilitli, omuzlar one lean.\n'
        'Uygulama: Dizleri gogse cekip ayaklari yerden keserek dengeyi koru.\n'
        'Ipucu: Omuzlar ellerin onunde kalsin.\n'
        'Sik hata: Dirsek bukmek, omuzlari geride birakmak.',
  };

  static Exercise _toDomainExercise(String id, mli.Exercise source) {
    final ratings = <MuscleGroup, int>{};
    final targetMuscles = <MuscleGroup>[];
    final level = levelFromCoefficient(source.difficulty);

    source.muscles.forEach((key, value) {
      final group = muscleFromKey(key);
      if (group == null) {
        return;
      }

      final rating = (value * 5).round().clamp(0, 5);
      ratings[group] = rating;
      if (!targetMuscles.contains(group)) {
        targetMuscles.add(group);
      }
    });

    return Exercise(
      id: id,
      name: source.name,
      level: level,
      difficulty: difficultyFromCoefficient(source.difficulty),
      targetMuscleGroups: targetMuscles,
      muscleRatings: ratings,
      description:
          exerciseDescriptions[id] ??
          '${source.name} hareketi icin kas aktivasyon dagilimi.',
      prerequisiteExercises: buildPrerequisites(id: id, level: level),
    );
  }

  static List<String> buildPrerequisites({
    required String id,
    required ExerciseLevel level,
  }) {
    if (level == ExerciseLevel.beginner) {
      return const <String>[];
    }

    final prerequisiteNames = (prerequisiteExerciseIds[id] ?? const <String>[])
        .map((exerciseId) => exerciseDatabase[exerciseId]?.name)
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

  @override
  Future<List<Exercise>> getAllExercises() async {
    await _simulateNetworkDelay();
    return _fakeExercises;
  }

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
