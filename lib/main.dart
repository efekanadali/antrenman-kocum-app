import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/providers/theme_mode_provider.dart';

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

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  static AppPalette _paletteFor(ThemeMode mode) =>
      mode == ThemeMode.dark ? AppPalette.dark : AppPalette.light;

  /// Tema değiştiğinde (const olanlar dahil) tüm elementleri yeniden kurar;
  /// renkler [AppColors]'tan build sırasında okunduğu için durum (gezinme
  /// yığını, kaydırma, form) kaybolmadan yeni palet uygulanır.
  void _rebuildAll() {
    void visit(Element element) {
      element.markNeedsBuild();
      element.visitChildren(visit);
    }

    (context as Element).visitChildren(visit);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ThemeMode>(themeModeProvider, (previous, next) {
      AppColors.apply(_paletteFor(next));
      _rebuildAll();
    });
    final palette = _paletteFor(ref.watch(themeModeProvider));
    AppColors.apply(palette);
    final theme = AppTheme.themeFor(palette);

    return MaterialApp(
      title: 'Calisthenics App',
      theme: theme,
      darkTheme: theme,
      themeMode: palette.isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRoutes.generateRoute,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: palette.isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
