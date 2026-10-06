import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/core/local_storage/workout_summary_storage.dart';

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService(
    firestore: FirebaseFirestore.instance,
    auth: FirebaseAuth.instance,
  );
});

class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({
    required FirebaseFirestore firestore,
    required FirebaseAuth auth,
  }) : _firestore = firestore,
       _auth = auth;

  // Anonim veya mevcut kullanıcı kimliğini al/oluştur
  Future<String> getOrCreateUserId() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      final userCredential = await _auth.signInAnonymously();
      currentUser = userCredential.user;
    }
    return currentUser!.uid;
  }

  // 1. Antrenman Oturumu Kaydetme (Workout Session & MLI Verisi)
  Future<void> saveWorkoutSession(Map<String, dynamic> sessionData) async {
    try {
      final uid = await getOrCreateUserId();
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workout_sessions')
          .add({...sessionData, 'syncedAt': FieldValue.serverTimestamp()});

      // Oturum sonrasında kullanıcının streak ve toplam antrenman sayısını güncelle
      await _updateStatsOnSessionSaved(uid, sessionData);
    } catch (_) {
      // Ağ veya Firestore hatalarında UI akışını engellemez
    }
  }

  Future<void> _updateStatsOnSessionSaved(
    String uid,
    Map<String, dynamic> sessionData,
  ) async {
    try {
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get();
      final userData = userDoc.data() ?? {};

      final currentTotal = (userData['totalWorkouts'] as num?)?.toInt() ?? 0;
      final newTotal = currentTotal + 1;

      // Tamamlanma tarihini al
      final completedAtRaw = sessionData['completedAt'];
      DateTime sessionDate = DateTime.now();
      if (completedAtRaw is String) {
        sessionDate = DateTime.tryParse(completedAtRaw) ?? DateTime.now();
      }

      // Son oturumlardan streak hesapla
      final recentSessions = await userDocRef
          .collection('workout_sessions')
          .orderBy('completedAt', descending: true)
          .limit(30)
          .get();

      final dates = <DateTime>[sessionDate];
      for (final doc in recentSessions.docs) {
        final dStr = doc.data()['completedAt'];
        if (dStr is String) {
          final parsed = DateTime.tryParse(dStr);
          if (parsed != null) dates.add(parsed);
        }
      }

      final newStreak = calculateStreakFromDates(dates);

      await userDocRef.set({
        'totalWorkouts': newTotal,
        'streak': newStreak,
        'lastWorkoutAt': sessionDate.toIso8601String(),
        'lastActiveAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Sessiz hata yönetimi
    }
  }

  /// Uygulama açılışında veya profil sayfasında streak ve toplam antrenman sayısını senkronize eder
  Future<Map<String, int>> syncUserStreakAndWorkouts({
    int? localTotalWorkouts,
    int? localStreak,
    DateTime? localLastWorkoutDate,
  }) async {
    try {
      final uid = await getOrCreateUserId();
      final userDocRef = _firestore.collection('users').doc(uid);
      final userDoc = await userDocRef.get();
      final userData = userDoc.data() ?? {};

      final cloudTotal = (userData['totalWorkouts'] as num?)?.toInt() ?? 0;
      final cloudStreak = (userData['streak'] as num?)?.toInt() ?? 0;

      // Yerel veya bulut arasındaki en güncel/büyük değerleri koru
      final effectiveTotal = (localTotalWorkouts != null && localTotalWorkouts > cloudTotal)
          ? localTotalWorkouts
          : (cloudTotal > 0 ? cloudTotal : (localTotalWorkouts ?? 0));

      final effectiveStreak = (localStreak != null && localStreak > cloudStreak)
          ? localStreak
          : (cloudStreak > 0 ? cloudStreak : (localStreak ?? 0));

      await userDocRef.set({
        'totalWorkouts': effectiveTotal,
        'streak': effectiveStreak,
        'lastActiveAt': FieldValue.serverTimestamp(),
        if (localLastWorkoutDate != null)
          'lastWorkoutAt': localLastWorkoutDate.toIso8601String(),
      }, SetOptions(merge: true));

      return {
        'totalWorkouts': effectiveTotal,
        'streak': effectiveStreak,
      };
    } catch (_) {
      return {
        'totalWorkouts': localTotalWorkouts ?? 0,
        'streak': localStreak ?? 0,
      };
    }
  }

  /// Kullanıcının mevcut istatistiklerini getir
  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final uid = await getOrCreateUserId();
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  /// workout_sessions koleksiyonundaki oturumları listele
  Future<List<Map<String, dynamic>>> getWorkoutSessions() async {
    try {
      final uid = await getOrCreateUserId();
      final snapshot = await _firestore
          .collection('users')
          .doc(uid)
          .collection('workout_sessions')
          .orderBy('completedAt', descending: true)
          .get();
      return snapshot.docs.map((d) => d.data()).toList();
    } catch (_) {
      return [];
    }
  }

  // 2. Kullanıcı Profil ve Biyometrik Verilerini Güncelleme
  Future<void> syncUserProfile(Map<String, dynamic> profileData) async {
    final uid = await getOrCreateUserId();
    await _firestore.collection('users').doc(uid).set({
      ...profileData,
      'lastActiveAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // 3. Egzersiz Kütüphanesini Buluta Tohumlama (Seed Database)
  Future<void> seedExerciseLibrary(List<Map<String, dynamic>> exercises) async {
    final batch = _firestore.batch();
    final collection = _firestore.collection('exercises');

    for (final exercise in exercises) {
      final docRef = collection.doc(exercise['id'] as String);
      batch.set(docRef, exercise, SetOptions(merge: true));
    }

    await batch.commit();
  }

  // 4. Buluttan Egzersizleri Canlı Dinleme (Stream)
  Stream<List<Map<String, dynamic>>> streamExercises() {
    return _firestore.collection('exercises').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // 5. Veritabanı Boşsa Egzersiz Kütüphanesini Otomatik Tohumlama
  Future<void> seedIfNeeded() async {
    try {
      final snapshot = await _firestore.collection('exercises').limit(1).get();
      if (snapshot.docs.isNotEmpty) {
        return;
      }

      final batch = _firestore.batch();
      final collection = _firestore.collection('exercises');

      exerciseDatabase.forEach((id, exercise) {
        final docRef = collection.doc(id);
        batch.set(docRef, {
          'id': id,
          'name': exercise.name,
          'difficulty': exercise.difficulty,
          'leverageFactor': exercise.difficulty,
          'type': 'calisthenics',
          'muscles': exercise.muscles,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });

      await batch.commit();
    } catch (_) {
      // Sessiz hata yönetimi
    }
  }
}
