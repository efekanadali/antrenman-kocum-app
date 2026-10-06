// lib/presentation/providers/workout_history_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/data/services/firestore_service.dart';
import 'package:calisthenics_app/domain/models/workout_session_summary.dart';

/// Bu provider, Firestore'daki `users/{uid}/workout_sessions` koleksiyonunu
/// tarihe göre azalan (en yeniden en eskiye) canlı bir Stream olarak dinler.
final workoutHistoryProvider =
    StreamProvider<List<WorkoutSessionSummary>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getWorkoutSessionsStream();
});
