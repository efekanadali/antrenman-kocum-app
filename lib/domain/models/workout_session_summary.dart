// lib/domain/models/workout_session_summary.dart

import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a completed workout session retrieved from Firestore or local storage.
class WorkoutSessionSummary {
  final String id;
  final DateTime completedAt;
  final int durationSeconds;
  final List<String> exercisesDone;
  final double totalMliWorkload;
  final Map<String, double> muscleWorkloads;

  const WorkoutSessionSummary({
    required this.id,
    required this.completedAt,
    required this.durationSeconds,
    required this.exercisesDone,
    required this.totalMliWorkload,
    this.muscleWorkloads = const {},
  });

  /// Factory constructor to parse Firestore document into [WorkoutSessionSummary].
  factory WorkoutSessionSummary.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    DateTime completedAt = DateTime.now();
    final rawCompletedAt = data['completedAt'];
    if (rawCompletedAt is Timestamp) {
      completedAt = rawCompletedAt.toDate();
    } else if (rawCompletedAt is String) {
      completedAt = DateTime.tryParse(rawCompletedAt) ?? DateTime.now();
    }

    final duration = (data['durationSeconds'] as num?)?.toInt() ??
        (data['totalDurationSeconds'] as num?)?.toInt() ??
        (data['duration'] as num?)?.toInt() ??
        0;

    final workload = (data['totalMliWorkload'] as num?)?.toDouble() ??
        (data['totalLoad'] as num?)?.toDouble() ??
        0.0;

    final exercises = <String>[];
    final rawExercisesDone = data['exercisesDone'];
    if (rawExercisesDone is List) {
      for (final item in rawExercisesDone) {
        if (item is String) {
          exercises.add(item);
        } else if (item is Map && item['name'] != null) {
          exercises.add(item['name'].toString());
        }
      }
    } else if (data['exerciseName'] is String) {
      exercises.add(data['exerciseName'] as String);
    }

    if (exercises.isEmpty && data['exercises'] is List) {
      for (final item in (data['exercises'] as List)) {
        if (item is Map && item['name'] != null) {
          exercises.add(item['name'].toString());
        }
      }
    }

    final rawMuscle = data['muscleWorkloads'] ?? data['muscleLoad'];
    final parsedMuscle = <String, double>{};
    if (rawMuscle is Map) {
      rawMuscle.forEach((k, v) {
        if (v is num) {
          parsedMuscle[k.toString()] = v.toDouble();
        }
      });
    }

    return WorkoutSessionSummary(
      id: id,
      completedAt: completedAt,
      durationSeconds: duration,
      exercisesDone: exercises,
      totalMliWorkload: workload,
      muscleWorkloads: parsedMuscle,
    );
  }

  /// Converts this entity into a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'completedAt': completedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'exercisesDone': exercisesDone,
      'totalMliWorkload': totalMliWorkload,
      'muscleWorkloads': muscleWorkloads,
    };
  }
}
