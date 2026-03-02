// lib/core/local_storage/workout_history_storage.dart

import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class WorkoutSessionEntry {
  WorkoutSessionEntry({
    required this.exerciseName,
    required this.totalTimeSeconds,
    required this.setsCompleted,
    required this.totalSets,
    required this.completedAt,
  });

  final String exerciseName;
  final int totalTimeSeconds;
  final int setsCompleted;
  final int totalSets;
  final DateTime completedAt;

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'totalTimeSeconds': totalTimeSeconds,
      'setsCompleted': setsCompleted,
      'totalSets': totalSets,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory WorkoutSessionEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutSessionEntry(
      exerciseName: json['exerciseName'] as String,
      totalTimeSeconds: json['totalTimeSeconds'] as int,
      setsCompleted: json['setsCompleted'] as int,
      totalSets: json['totalSets'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}

class WorkoutHistoryStorage {
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/workout_history.json');
  }

  Future<List<WorkoutSessionEntry>> loadSessions() async {
    final file = await _getFile();
    if (!await file.exists()) {
      return [];
    }

    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(content);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(WorkoutSessionEntry.fromJson)
        .toList();
  }

  Future<void> saveSession(WorkoutSessionEntry entry) async {
    final file = await _getFile();
    final existing = await loadSessions();
    final updated = [...existing, entry];
    final encoded = jsonEncode(updated.map((item) => item.toJson()).toList());
    await file.writeAsString(encoded);
  }
}
