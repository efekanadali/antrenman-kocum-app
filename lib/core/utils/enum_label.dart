// lib/core/utils/enum_label.dart

import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';

extension EnumLabel on Enum {
  String get label {
    if (this is ExerciseLevel) {
      switch (this as ExerciseLevel) {
        case ExerciseLevel.beginner:
          return 'Başlangıç';
        case ExerciseLevel.intermediate:
          return 'Orta';
        case ExerciseLevel.advanced:
          return 'İleri';
      }
    }

    if (this is DifficultyLevel) {
      switch (this as DifficultyLevel) {
        case DifficultyLevel.easy:
          return 'Kolay';
        case DifficultyLevel.medium:
          return 'Orta';
        case DifficultyLevel.hard:
          return 'Zor';
      }
    }

    if (this is MuscleGroup) {
      switch (this as MuscleGroup) {
        case MuscleGroup.chest:
          return 'Göğüs';
        case MuscleGroup.back:
          return 'Sırt';
        case MuscleGroup.shoulders:
          return 'Omuz';
        case MuscleGroup.biceps:
          return 'Biseps';
        case MuscleGroup.triceps:
          return 'Triseps';
        case MuscleGroup.legs:
          return 'Bacak';
        case MuscleGroup.core:
          return 'Karın';
        case MuscleGroup.quads:
          return 'Quadriceps';
        case MuscleGroup.hamstrings:
          return 'Hamstrings';
        case MuscleGroup.glutes:
          return 'Kalça';
        case MuscleGroup.calves:
          return 'Baldır';
      }
    }

    final raw = toString();
    final dotIndex = raw.indexOf('.');
    return dotIndex == -1 ? raw : raw.substring(dotIndex + 1);
  }
}
