// lib/domain/models/workout_session_summary.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/muscle_load_snapshot.dart';

/// Represents a completed workout session retrieved from Firestore or local storage.
class WorkoutSessionSummary {
  final String id;
  final DateTime completedAt;
  final int durationSeconds;
  final List<String> exercisesDone;
  final double totalMliWorkload;

  /// Kayıttaki eski (v1) kas anahtarları aynen (`muscleWorkloads` /
  /// `muscleLoad`).
  final Map<String, double> muscleWorkloads;

  /// Kompartıman + bölge görünümü. v2 kayıtlarda `compartmentWorkloads`'tan,
  /// eski kayıtlarda [muscleWorkloads] bölünerek elde edilir.
  final MuscleLoadSnapshot load;

  /// Kaydın şema sürümü (alan yoksa 1).
  final int schemaVersion;

  const WorkoutSessionSummary({
    required this.id,
    required this.completedAt,
    required this.durationSeconds,
    required this.exercisesDone,
    required this.totalMliWorkload,
    this.muscleWorkloads = const {},
    this.load = const MuscleLoadSnapshot(),
    this.schemaVersion = 1,
  });

  Map<MuscleCompartment, double> get compartmentWorkloads => load.compartments;

  Map<MuscleRegion, double> get regionWorkloads => load.regions;

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
      load: MuscleLoadSnapshot.parse(
        compartmentRaw: data['compartmentWorkloads'],
        legacyRaw: parsedMuscle,
      ),
      schemaVersion: (data['schemaVersion'] as num?)?.toInt() ?? 1,
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
      'compartmentWorkloads': load.compartmentsByKey,
      'schemaVersion': schemaVersion,
    };
  }
}
