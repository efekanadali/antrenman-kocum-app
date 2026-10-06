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

int calculateStreakFromDates(List<DateTime> dates) {
  if (dates.isEmpty) return 0;
  final uniqueDays = dates
      .map((d) => DateTime(d.year, d.month, d.day))
      .toSet()
      .toList()
    ..sort((a, b) => b.compareTo(a));

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  final latest = uniqueDays.first;
  if (latest.isBefore(yesterday)) {
    return 0;
  }

  int streak = 0;
  DateTime expectedDate = latest;

  for (final day in uniqueDays) {
    if (day.isAtSameMomentAs(expectedDate)) {
      streak++;
      expectedDate = expectedDate.subtract(const Duration(days: 1));
    } else if (day.isAfter(expectedDate)) {
      continue;
    } else {
      break;
    }
  }

  return streak;
}

int calculateWorkoutStreak(List<WorkoutSummaryEntry> summaries) {
  return calculateStreakFromDates(summaries.map((s) => s.date).toList());
}
