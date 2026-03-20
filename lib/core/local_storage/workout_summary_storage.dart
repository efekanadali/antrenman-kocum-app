import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class WorkoutSummaryEntry {
  WorkoutSummaryEntry({
    required this.date,
    required this.totalLoad,
    required this.muscleLoad,
    required this.duration,
  });

  final DateTime date;
  final double totalLoad;
  final Map<String, double> muscleLoad;
  final int duration;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'totalLoad': totalLoad,
      'muscleLoad': muscleLoad,
      'duration': duration,
    };
  }

  factory WorkoutSummaryEntry.fromJson(Map<String, dynamic> json) {
    final rawMuscleLoad = json['muscleLoad'];
    final parsedMuscleLoad = <String, double>{};

    if (rawMuscleLoad is Map) {
      for (final entry in rawMuscleLoad.entries) {
        final key = entry.key.toString();
        final value = (entry.value as num?)?.toDouble() ?? 0.0;
        parsedMuscleLoad[key] = value;
      }
    }

    return WorkoutSummaryEntry(
      date: DateTime.parse(json['date'] as String),
      totalLoad: (json['totalLoad'] as num?)?.toDouble() ?? 0.0,
      muscleLoad: parsedMuscleLoad,
      duration: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }
}

class WorkoutSummaryStorage {
  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/workout_summaries.json');
  }

  Future<List<WorkoutSummaryEntry>> loadSummaries() async {
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
        .map(WorkoutSummaryEntry.fromJson)
        .toList();
  }

  Future<void> saveSummary(WorkoutSummaryEntry entry) async {
    final file = await _getFile();
    final existing = await loadSummaries();
    final updated = [...existing, entry];
    final encoded = jsonEncode(updated.map((item) => item.toJson()).toList());
    await file.writeAsString(encoded);
  }
}
