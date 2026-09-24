import 'package:calisthenics_app/domain/models/mli_models.dart';

final Map<String, Exercise> exerciseDatabase = {
  // ==================== İTİŞ (PUSH) ====================
  'incline_push_up': const Exercise(
    name: 'Incline Push-up',
    difficulty: 0.65, // GRF %41-45 vücut ağırlığı
    muscles: {
      'chest': 1.0,
      'triceps': 0.5,
      'shoulders': 0.5,
      'core': 0.2,
    },
  ),
  'knee_push_up': const Exercise(
    name: 'Knee Push-up',
    difficulty: 0.75, // GRF %53 vücut ağırlığı
    muscles: {
      'chest': 1.0,
      'triceps': 0.5,
      'shoulders': 0.5,
      'core': 0.2,
    },
  ),
  'standard_push_up': const Exercise(
    name: 'Standard Push-up',
    difficulty: 1.00, // Taban referans (GRF %64)
    muscles: {
      'chest': 1.0,
      'triceps': 0.5,
      'shoulders': 0.5,
      'core': 0.2,
    },
  ),
  'wide_push_up': const Exercise(
    name: 'Wide Push-up',
    difficulty: 1.10,
    muscles: {
      'chest': 1.0,
      'shoulders': 0.5,
      'triceps': 0.3,
      'core': 0.2,
    },
  ),
  'diamond_push_up': const Exercise(
    name: 'Diamond Push-up',
    difficulty: 1.25,
    muscles: {
      'triceps': 1.0,
      'chest': 0.7,
      'shoulders': 0.5,
      'core': 0.2,
    },
  ),
  'decline_push_up': const Exercise(
    name: 'Decline Push-up',
    difficulty: 1.20, // GRF %74 vücut ağırlığı
    muscles: {
      'shoulders': 1.0,
      'chest': 0.8,
      'triceps': 0.5,
      'core': 0.2,
    },
  ),
  'pike_push_up': const Exercise(
    name: 'Pike Push-up',
    difficulty: 1.55,
    muscles: {
      'shoulders': 1.0,
      'triceps': 0.8,
      'chest': 0.2,
      'core': 0.5,
    },
  ),
  'dips_parallel_bar': const Exercise(
    name: 'Parallel Bar Dips',
    difficulty: 1.55, // %100 vücut ağırlığı serbest asılı
    muscles: {
      'chest': 1.0,
      'triceps': 1.0,
      'shoulders': 0.5,
      'core': 0.2,
    },
  ),
  'pseudo_planche_push_up': const Exercise(
    name: 'Pseudo Planche Push-up',
    difficulty: 2.10,
    muscles: {
      'shoulders': 1.0,
      'chest': 0.5,
      'triceps': 0.5,
      'core': 0.8,
    },
  ),
  'handstand_push_up': const Exercise(
    name: 'Handstand Push-up',
    difficulty: 2.70,
    muscles: {
      'shoulders': 1.0,
      'triceps': 0.8,
      'core': 0.5,
      'back': 0.2,
    },
  ),
  '90_degree_push_up': const Exercise(
    name: '90 Degree Push-up',
    difficulty: 3.40,
    muscles: {
      'shoulders': 1.0,
      'triceps': 1.0,
      'core': 0.8,
      'back': 0.5,
    },
  ),

  // ==================== ÇEKİŞ (PULL) ====================
  'australian_row': const Exercise(
    name: 'Australian Row (Horizontal Pull)',
    difficulty: 0.85,
    muscles: {
      'back': 1.0,
      'biceps': 0.5,
      'shoulders': 0.5,
      'core': 0.2,
    },
  ),
  'chin_up_hold_top': const Exercise(
    name: 'Chin-up Hold Top',
    difficulty: 1.15,
    muscles: {
      'biceps': 1.0,
      'back': 0.8,
      'core': 0.2,
    },
  ),
  'pull_up_hold_top': const Exercise(
    name: 'Pull-up Hold Top',
    difficulty: 1.20,
    muscles: {
      'back': 1.0,
      'biceps': 0.5,
      'shoulders': 0.5,
      'core': 0.2,
    },
  ),
  'standard_pull_up': const Exercise(
    name: 'Standard Pull-up',
    difficulty: 1.55, // %100 vücut ağırlığı
    muscles: {
      'back': 1.0,
      'biceps': 0.5,
      'shoulders': 0.5,
      'core': 0.2,
    },
  ),
  'chin_up': const Exercise(
    name: 'Chin-up',
    difficulty: 1.45,
    muscles: {
      'biceps': 1.0,
      'back': 1.0,
      'core': 0.2,
    },
  ),
  'wide_grip_pull_up': const Exercise(
    name: 'Wide Grip Pull-up',
    difficulty: 1.70,
    muscles: {
      'back': 1.0,
      'shoulders': 0.5,
      'biceps': 0.3,
      'core': 0.2,
    },
  ),
  'archer_pull_up': const Exercise(
    name: 'Archer Pull-up',
    difficulty: 2.20,
    muscles: {
      'back': 1.0,
      'biceps': 0.8,
      'core': 0.5,
      'shoulders': 0.5,
    },
  ),
  'tuck_front_lever': const Exercise(
    name: 'Tuck Front Lever',
    difficulty: 2.10,
    muscles: {
      'back': 1.0,
      'core': 0.8,
      'shoulders': 0.5,
      'biceps': 0.3,
    },
  ),
  'front_lever_raise': const Exercise(
    name: 'Front Lever Raise',
    difficulty: 2.70,
    muscles: {
      'back': 1.0,
      'core': 1.0,
      'shoulders': 0.5,
      'triceps': 0.2,
    },
  ),
  'muscle_up': const Exercise(
    name: 'Muscle-up',
    difficulty: 2.90,
    muscles: {
      'back': 1.0,
      'triceps': 0.8,
      'chest': 0.8,
      'biceps': 0.5,
      'core': 0.5,
    },
  ),
  'one_arm_pull_up': const Exercise(
    name: 'One Arm Pull-up',
    difficulty: 4.20,
    muscles: {
      'back': 1.0,
      'biceps': 1.0,
      'core': 0.8,
      'shoulders': 0.5,
    },
  ),

  // ==================== BACAK (LEGS) ====================
  'wall_sit': const Exercise(
    name: 'Wall Sit',
    difficulty: 0.70,
    muscles: {
      'quads': 1.0,
      'glutes': 0.5,
      'calves': 0.2,
    },
  ),
  'glute_bridge': const Exercise(
    name: 'Glute Bridge',
    difficulty: 0.75,
    muscles: {
      'glutes': 1.0,
      'hamstrings': 0.5,
      'core': 0.2,
    },
  ),
  'calf_raise': const Exercise(
    name: 'Calf Raise',
    difficulty: 0.65,
    muscles: {
      'calves': 1.0,
    },
  ),
  'standard_squat': const Exercise(
    name: 'Standard Squat',
    difficulty: 0.90,
    muscles: {
      'quads': 1.0,
      'glutes': 0.5,
      'hamstrings': 0.2,
      'calves': 0.2,
    },
  ),
  'lunge': const Exercise(
    name: 'Lunge',
    difficulty: 1.15,
    muscles: {
      'quads': 1.0,
      'glutes': 0.8,
      'hamstrings': 0.5,
      'calves': 0.2,
    },
  ),
  'bulgarian_split_squat': const Exercise(
    name: 'Bulgarian Split Squat',
    difficulty: 1.45,
    muscles: {
      'quads': 1.0,
      'glutes': 0.8,
      'hamstrings': 0.5,
      'core': 0.2,
    },
  ),
  'box_jump': const Exercise(
    name: 'Box Jump',
    difficulty: 1.50,
    muscles: {
      'quads': 1.0,
      'glutes': 0.8,
      'calves': 0.8,
      'hamstrings': 0.5,
    },
  ),
  'nordic_curl': const Exercise(
    name: 'Nordic Hamstring Curl',
    difficulty: 2.40,
    muscles: {
      'hamstrings': 1.0,
      'glutes': 0.5,
      'calves': 0.5,
      'core': 0.2,
    },
  ),
  'shrimp_squat': const Exercise(
    name: 'Shrimp Squat',
    difficulty: 2.20,
    muscles: {
      'quads': 1.0,
      'glutes': 0.8,
      'core': 0.5,
      'calves': 0.2,
    },
  ),
  'pistol_squat': const Exercise(
    name: 'Pistol Squat',
    difficulty: 2.30,
    muscles: {
      'quads': 1.0,
      'glutes': 0.8,
      'core': 0.5,
      'calves': 0.5,
    },
  ),

  // ==================== STATİK & CORE ====================
  'plank': const Exercise(
    name: 'Plank',
    difficulty: 0.70,
    muscles: {
      'core': 1.0,
      'shoulders': 0.2,
      'glutes': 0.2,
    },
  ),
  'side_plank': const Exercise(
    name: 'Side Plank',
    difficulty: 0.80,
    muscles: {
      'core': 1.0,
      'shoulders': 0.2,
      'glutes': 0.2,
    },
  ),
  'hollow_body_hold': const Exercise(
    name: 'Hollow Body Hold',
    difficulty: 1.10,
    muscles: {
      'core': 1.0,
    },
  ),
  'support_hold_parallel_bar': const Exercise(
    name: 'Support Hold',
    difficulty: 0.95,
    muscles: {
      'shoulders': 0.8,
      'triceps': 0.5,
      'core': 0.5,
    },
  ),
  'l_sit_hold': const Exercise(
    name: 'L-Sit Hold',
    difficulty: 1.80,
    muscles: {
      'core': 1.0,
      'triceps': 0.5,
      'shoulders': 0.5,
    },
  ),
  'tuck_planche': const Exercise(
    name: 'Tuck Planche',
    difficulty: 2.80,
    muscles: {
      'shoulders': 1.0,
      'triceps': 0.5,
      'core': 0.8,
      'back': 0.5,
    },
  ),
};
