// lib/domain/models/custom_program.dart

/// Kullanıcının yazdığı yük değerini (`62,5`, `60`, ` 40 kg`) okur; boş,
/// sayısal olmayan veya ≤ 0 değerler için `null`.
double? parseLoadKgInput(String raw) {
  final cleaned = raw.toLowerCase().replaceAll('kg', '').replaceAll(',', '.').trim();
  final value = double.tryParse(cleaned);
  if (value == null || value <= 0) return null;
  return value;
}

/// Listelerde gösterilen yük eki (` • 62.5 kg`); yük yoksa boş.
String formatLoadKgSuffix(double? loadKg) {
  if (loadKg == null) return '';
  final text = loadKg == loadKg.roundToDouble()
      ? loadKg.toStringAsFixed(0)
      : loadKg.toStringAsFixed(1);
  return ' • $text kg';
}

class CustomProgramExercise {
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int value;
  final bool isTimed;

  /// Vücut geliştirme hareketlerinde hedef dış yük (kg). Kalistenikte `null`.
  final double? loadKg;

  const CustomProgramExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.value,
    required this.isTimed,
    this.loadKg,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets,
        'value': value,
        'isTimed': isTimed,
        if (loadKg != null) 'loadKg': loadKg,
      };

  factory CustomProgramExercise.fromJson(Map<String, dynamic> json) {
    return CustomProgramExercise(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: json['sets'] as int,
      value: (json['value'] ?? json['reps']) as int,
      isTimed: (json['isTimed'] ?? false) as bool,
      loadKg: _parseLoadKg(json['loadKg']),
    );
  }

  /// Eksik / int / double / sayısal metin değerlerini tolere eder.
  static double? _parseLoadKg(Object? raw) {
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }
}

class CustomProgramDay {
  final int dayIndex;
  final String name;
  final List<CustomProgramExercise> exercises;

  const CustomProgramDay({
    required this.dayIndex,
    required this.name,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'name': name,
        'exercises': exercises.map((item) => item.toJson()).toList(),
      };

  factory CustomProgramDay.fromJson(Map<String, dynamic> json) {
    final index = json['dayIndex'] as int;
    return CustomProgramDay(
      dayIndex: index,
      name: (json['name'] as String?) ?? 'Gün $index',
      exercises: (json['exercises'] as List<dynamic>)
          .map((item) =>
              CustomProgramExercise.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CustomProgram {
  final String id;
  final String name;
  final int daysCount;
  final List<CustomProgramDay> days;
  final DateTime createdAt;

  const CustomProgram({
    required this.id,
    required this.name,
    required this.daysCount,
    required this.days,
    required this.createdAt,
  });

  int get totalExercises =>
      days.fold(0, (sum, day) => sum + day.exercises.length);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'daysCount': daysCount,
        'days': days.map((item) => item.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory CustomProgram.fromJson(Map<String, dynamic> json) {
    return CustomProgram(
      id: json['id'] as String,
      name: json['name'] as String,
      daysCount: json['daysCount'] as int,
      days: (json['days'] as List<dynamic>)
          .map((item) => CustomProgramDay.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
