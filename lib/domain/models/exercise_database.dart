import 'package:calisthenics_app/domain/models/mli_models.dart';

final Map<String, Exercise> exerciseDatabase = {
  'incline_push_up': const Exercise(
    name: 'Incline Push-up',
    difficulty: 0.6,
    muscles: {'chest': 1.0, 'shoulders': 0.3, 'triceps': 0.4, 'core': 0.1},
  ),
  'knee_push_up': const Exercise(
    name: 'Knee Push-up',
    difficulty: 0.7,
    muscles: {'chest': 1.0, 'shoulders': 0.4, 'triceps': 0.4, 'core': 0.1},
  ),
  'standard_push_up': const Exercise(
    name: 'Standard Push-up',
    difficulty: 1.0,
    muscles: {'chest': 1.0, 'shoulders': 0.4, 'triceps': 0.5, 'core': 0.2},
  ),
  'wide_push_up': const Exercise(
    name: 'Wide Push-up',
    difficulty: 1.1,
    muscles: {'chest': 1.0, 'shoulders': 0.5, 'triceps': 0.3, 'core': 0.2},
  ),
  'diamond_push_up': const Exercise(
    name: 'Diamond Push-up',
    difficulty: 1.2,
    muscles: {'chest': 0.6, 'shoulders': 0.3, 'triceps': 1.0, 'core': 0.2},
  ),
  'decline_push_up': const Exercise(
    name: 'Decline Push-up',
    difficulty: 1.3,
    muscles: {'chest': 1.0, 'shoulders': 0.6, 'triceps': 0.5, 'core': 0.2},
  ),
  'pike_push_up': const Exercise(
    name: 'Pike Push-up',
    difficulty: 1.5,
    muscles: {'chest': 0.2, 'shoulders': 1.0, 'triceps': 0.6, 'core': 0.3},
  ),
  'dips_parallel_bar': const Exercise(
    name: 'Dips (Parallel Bar)',
    difficulty: 1.7,
    muscles: {'chest': 0.8, 'shoulders': 0.4, 'triceps': 1.0, 'core': 0.2},
  ),
  'pseudo_planche_push_up': const Exercise(
    name: 'Pseudo-Planche Push-up',
    difficulty: 2.0,
    muscles: {'chest': 0.7, 'shoulders': 1.0, 'triceps': 0.6, 'core': 0.4},
  ),
  'handstand_push_up': const Exercise(
    name: 'Handstand Push-up',
    difficulty: 3.5,
    muscles: {'chest': 0.1, 'shoulders': 1.0, 'triceps': 0.8, 'core': 0.5},
  ),
  '90_degree_push_up': const Exercise(
    name: '90 Degree Push-up',
    difficulty: 5.0,
    muscles: {'chest': 0.5, 'shoulders': 1.0, 'triceps': 0.9, 'core': 0.7},
  ),
  'australian_row': const Exercise(
    name: 'Australian Row',
    difficulty: 0.8,
    muscles: {'back': 1.0, 'biceps': 0.5, 'rear_shoulders': 0.4, 'core': 0.2},
  ),
  'standard_pull_up': const Exercise(
    name: 'Standard Pull-up',
    difficulty: 1.5,
    muscles: {'back': 1.0, 'biceps': 0.5, 'rear_shoulders': 0.4, 'core': 0.3},
  ),
  'chin_up': const Exercise(
    name: 'Chin-up',
    difficulty: 1.5,
    muscles: {'back': 0.8, 'biceps': 1.0, 'shoulders': 0.3, 'core': 0.3},
  ),
  'wide_grip_pull_up': const Exercise(
    name: 'Wide Grip Pull-up',
    difficulty: 1.7,
    muscles: {'back': 1.0, 'biceps': 0.4, 'rear_shoulders': 0.6, 'core': 0.3},
  ),
  'archer_pull_up': const Exercise(
    name: 'Archer Pull-up',
    difficulty: 2.2,
    muscles: {'back': 1.0, 'biceps': 0.7, 'shoulders': 0.5, 'core': 0.4},
  ),
  'muscle_up': const Exercise(
    name: 'Muscle-up',
    difficulty: 3.5,
    muscles: {'back': 1.0, 'biceps': 0.6, 'shoulders': 0.8, 'core': 0.6},
  ),
  'front_lever_raise': const Exercise(
    name: 'Front Lever Raise',
    difficulty: 4.0,
    muscles: {'back': 1.0, 'biceps': 0.4, 'shoulders': 0.6, 'core': 0.8},
  ),
  'one_arm_pull_up': const Exercise(
    name: 'One Arm Pull-up',
    difficulty: 6.0,
    muscles: {'back': 1.0, 'biceps': 0.9, 'shoulders': 0.6, 'core': 0.7},
  ),
  'standard_squat': const Exercise(
    name: 'Standard Squat',
    difficulty: 1.0,
    muscles: {'quads': 1.0, 'hamstrings': 0.4, 'glutes': 0.7, 'calves': 0.2},
  ),
  'lunge': const Exercise(
    name: 'Lunge',
    difficulty: 1.1,
    muscles: {'quads': 1.0, 'hamstrings': 0.5, 'glutes': 0.8, 'calves': 0.3},
  ),
  'bulgarian_split_squat': const Exercise(
    name: 'Bulgarian Split Squat',
    difficulty: 1.5,
    muscles: {'quads': 1.0, 'hamstrings': 0.5, 'glutes': 0.9, 'calves': 0.3},
  ),
  'glute_bridge': const Exercise(
    name: 'Glute Bridge',
    difficulty: 0.8,
    muscles: {'quads': 0.2, 'hamstrings': 0.6, 'glutes': 1.0, 'calves': 0.1},
  ),
  'nordic_curl': const Exercise(
    name: 'Nordic Curl',
    difficulty: 3.0,
    muscles: {'quads': 0.1, 'hamstrings': 1.0, 'glutes': 0.5, 'calves': 0.2},
  ),
  'pistol_squat': const Exercise(
    name: 'Pistol Squat',
    difficulty: 2.5,
    muscles: {'quads': 1.0, 'hamstrings': 0.6, 'glutes': 1.0, 'calves': 0.4},
  ),
  'shrimp_squat': const Exercise(
    name: 'Shrimp Squat',
    difficulty: 2.5,
    muscles: {'quads': 1.0, 'hamstrings': 0.7, 'glutes': 1.0, 'calves': 0.3},
  ),
  'calf_raise': const Exercise(
    name: 'Calf Raise',
    difficulty: 0.6,
    muscles: {'quads': 0.0, 'hamstrings': 0.0, 'glutes': 0.1, 'calves': 1.0},
  ),
  'box_jump': const Exercise(
    name: 'Box Jump',
    difficulty: 1.4,
    muscles: {'quads': 1.0, 'hamstrings': 0.6, 'glutes': 0.8, 'calves': 0.7},
  ),
  'plank': const Exercise(
    name: 'Plank',
    difficulty: 0.5,
    muscles: {'core': 1.0, 'shoulders': 0.3, 'back': 0.1, 'triceps': 0.1},
  ),
  'hollow_body_hold': const Exercise(
    name: 'Hollow Body Hold',
    difficulty: 0.7,
    muscles: {'core': 1.0, 'shoulders': 0.1, 'back': 0.1, 'triceps': 0.0},
  ),
};
