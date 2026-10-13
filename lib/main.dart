import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:calisthenics_app/data/services/firestore_service.dart';

import 'package:calisthenics_app/core/local_storage/workout_summary_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Arka plan servisleri: Veritabanı tohumlama ve streak/antrenman senkronizasyonu
  try {
    final firestoreService = FirestoreService(
      firestore: FirebaseFirestore.instance,
      auth: FirebaseAuth.instance,
    );
    unawaited(firestoreService.seedIfNeeded().catchError((_) {}));
    unawaited(_syncStreakAndWorkoutsOnLaunch(firestoreService).catchError((_) {}));
  } catch (_) {}

  runApp(const ProviderScope(child: MyApp()));
}

Future<void> _syncStreakAndWorkoutsOnLaunch(FirestoreService firestoreService) async {
  try {
    final storage = WorkoutSummaryStorage();
    final summaries = await storage.loadSummaries();
    if (summaries.isNotEmpty) {
      final totalWorkouts = summaries.length;
      final streak = calculateWorkoutStreak(summaries);
      final lastDate = summaries.map((s) => s.date).reduce((a, b) => a.isAfter(b) ? a : b);
      await firestoreService.syncUserStreakAndWorkouts(
        localTotalWorkouts: totalWorkouts,
        localStreak: streak,
        localLastWorkoutDate: lastDate,
      );
    } else {
      await firestoreService.syncUserStreakAndWorkouts();
    }
  } catch (_) {}
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calisthenics App',
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
