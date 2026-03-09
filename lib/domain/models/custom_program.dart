// lib/domain/models/custom_program.dart

class CustomProgramExercise {
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int value;
  final bool isTimed;

  const CustomProgramExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.value,
    required this.isTimed,
  });

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'exerciseName': exerciseName,
        'sets': sets,
      'value': value,
      'isTimed': isTimed,
      };

  factory CustomProgramExercise.fromJson(Map<String, dynamic> json) {
    return CustomProgramExercise(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      sets: json['sets'] as int,
      value: (json['value'] ?? json['reps']) as int,
      isTimed: (json['isTimed'] ?? false) as bool,
    );
  }
}

class CustomProgramDay {
  final int dayIndex;
  final List<CustomProgramExercise> exercises;

  const CustomProgramDay({
    required this.dayIndex,
    required this.exercises,
  });

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'exercises': exercises.map((item) => item.toJson()).toList(),
      };

  factory CustomProgramDay.fromJson(Map<String, dynamic> json) {
    return CustomProgramDay(
      dayIndex: json['dayIndex'] as int,
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
