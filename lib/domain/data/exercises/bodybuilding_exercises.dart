// lib/domain/data/exercises/bodybuilding_exercises.dart

import 'package:calisthenics_app/domain/enums/exercise_type.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';

/// Vücut geliştirme (serbest ağırlık / kablo / makine) hareketleri: 40 hareket.
///
/// * `type: ExerciseType.bodybuilding` olduğundan MLI
///   `Set × Tekrar × (Ağırlık / Vücut_Ağırlığı) × Lf_bb × RIR` formülüyle hesaplanır.
/// * `difficulty` burada `Lf_bb` katsayısıdır (bileşik hareketler > izolasyon).
/// * Her egzersizin kompartıman ağırlıkları toplamı tam olarak 1.00'dır.
final Map<String, Exercise> bodybuildingExercises = {
  // ==================== GÖĞÜS ====================
  'barbell_bench_press': Exercise(
    name: 'Barbell Bench Press',
    difficulty: 1.00,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.midChest: 0.40,
      MuscleCompartment.upperChest: 0.08,
      MuscleCompartment.lowerChest: 0.10,
      MuscleCompartment.triceps: 0.20,
      MuscleCompartment.anteriorDeltoid: 0.17,
      MuscleCompartment.core: 0.05,
    },
  ),
  'incline_dumbbell_press': Exercise(
    name: 'Incline Dumbbell Press',
    difficulty: 0.95,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.upperChest: 0.40,
      MuscleCompartment.midChest: 0.15,
      MuscleCompartment.anteriorDeltoid: 0.22,
      MuscleCompartment.triceps: 0.18,
      MuscleCompartment.core: 0.05,
    },
  ),
  'decline_bench_press': Exercise(
    name: 'Decline Bench Press',
    difficulty: 0.95,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.lowerChest: 0.40,
      MuscleCompartment.midChest: 0.20,
      MuscleCompartment.triceps: 0.25,
      MuscleCompartment.anteriorDeltoid: 0.10,
      MuscleCompartment.core: 0.05,
    },
  ),
  'high_to_low_cable_fly': Exercise(
    name: 'High-to-Low Cable Fly',
    difficulty: 0.70,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.lowerChest: 0.55,
      MuscleCompartment.midChest: 0.20,
      MuscleCompartment.anteriorDeltoid: 0.10,
      MuscleCompartment.triceps: 0.10,
      MuscleCompartment.core: 0.05,
    },
  ),
  'low_to_high_cable_fly': Exercise(
    name: 'Low-to-High Cable Fly',
    difficulty: 0.70,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.upperChest: 0.55,
      MuscleCompartment.midChest: 0.15,
      MuscleCompartment.anteriorDeltoid: 0.25,
      MuscleCompartment.core: 0.05,
    },
  ),
  'machine_chest_press': Exercise(
    name: 'Machine Chest Press',
    difficulty: 0.80,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.midChest: 0.45,
      MuscleCompartment.upperChest: 0.10,
      MuscleCompartment.lowerChest: 0.10,
      MuscleCompartment.triceps: 0.20,
      MuscleCompartment.anteriorDeltoid: 0.15,
    },
  ),
  // ==================== OMUZ ====================
  'overhead_press': Exercise(
    name: 'Overhead Press',
    difficulty: 1.10,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.anteriorDeltoid: 0.40,
      MuscleCompartment.lateralDeltoid: 0.15,
      MuscleCompartment.triceps: 0.20,
      MuscleCompartment.upperChest: 0.05,
      MuscleCompartment.upperBackTraps: 0.10,
      MuscleCompartment.core: 0.10,
    },
  ),
  'seated_dumbbell_shoulder_press': Exercise(
    name: 'Seated Dumbbell Shoulder Press',
    difficulty: 1.00,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.anteriorDeltoid: 0.42,
      MuscleCompartment.lateralDeltoid: 0.18,
      MuscleCompartment.triceps: 0.22,
      MuscleCompartment.upperBackTraps: 0.10,
      MuscleCompartment.upperChest: 0.08,
    },
  ),
  'lateral_raise': Exercise(
    name: 'Lateral Raise',
    difficulty: 0.65,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.lateralDeltoid: 0.70,
      MuscleCompartment.anteriorDeltoid: 0.10,
      MuscleCompartment.upperBackTraps: 0.15,
      MuscleCompartment.forearms: 0.05,
    },
  ),
  'rear_delt_fly': Exercise(
    name: 'Rear Delt Fly',
    difficulty: 0.65,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.posteriorDeltoid: 0.60,
      MuscleCompartment.upperBackTraps: 0.25,
      MuscleCompartment.lateralDeltoid: 0.10,
      MuscleCompartment.forearms: 0.05,
    },
  ),
  'face_pull': Exercise(
    name: 'Face Pull',
    difficulty: 0.70,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.posteriorDeltoid: 0.45,
      MuscleCompartment.upperBackTraps: 0.30,
      MuscleCompartment.lateralDeltoid: 0.10,
      MuscleCompartment.biceps: 0.05,
      MuscleCompartment.forearms: 0.05,
      MuscleCompartment.lats: 0.05,
    },
  ),
  'upright_row': Exercise(
    name: 'Upright Row',
    difficulty: 0.85,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.lateralDeltoid: 0.45,
      MuscleCompartment.upperBackTraps: 0.30,
      MuscleCompartment.anteriorDeltoid: 0.10,
      MuscleCompartment.biceps: 0.10,
      MuscleCompartment.forearms: 0.05,
    },
  ),
  // ==================== SIRT ====================
  'deadlift': Exercise(
    name: 'Deadlift',
    difficulty: 1.30,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.lowerBack: 0.25,
      MuscleCompartment.glutes: 0.20,
      MuscleCompartment.hamstrings: 0.20,
      MuscleCompartment.upperBackTraps: 0.10,
      MuscleCompartment.quads: 0.10,
      MuscleCompartment.forearms: 0.10,
      MuscleCompartment.lats: 0.05,
    },
  ),
  'barbell_row': Exercise(
    name: 'Barbell Row',
    difficulty: 1.05,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.lats: 0.35,
      MuscleCompartment.upperBackTraps: 0.25,
      MuscleCompartment.posteriorDeltoid: 0.12,
      MuscleCompartment.biceps: 0.13,
      MuscleCompartment.lowerBack: 0.10,
      MuscleCompartment.forearms: 0.05,
    },
  ),
  'lat_pulldown': Exercise(
    name: 'Lat Pulldown',
    difficulty: 0.85,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.lats: 0.50,
      MuscleCompartment.upperBackTraps: 0.10,
      MuscleCompartment.biceps: 0.20,
      MuscleCompartment.posteriorDeltoid: 0.08,
      MuscleCompartment.forearms: 0.07,
      MuscleCompartment.core: 0.05,
    },
  ),
  'seated_cable_row': Exercise(
    name: 'Seated Cable Row',
    difficulty: 0.85,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.upperBackTraps: 0.35,
      MuscleCompartment.lats: 0.30,
      MuscleCompartment.posteriorDeltoid: 0.12,
      MuscleCompartment.biceps: 0.15,
      MuscleCompartment.forearms: 0.08,
    },
  ),
  'single_arm_dumbbell_row': Exercise(
    name: 'Single-Arm Dumbbell Row',
    difficulty: 0.90,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.lats: 0.45,
      MuscleCompartment.upperBackTraps: 0.15,
      MuscleCompartment.posteriorDeltoid: 0.10,
      MuscleCompartment.biceps: 0.15,
      MuscleCompartment.forearms: 0.05,
      MuscleCompartment.core: 0.10,
    },
  ),
  'barbell_shrug': Exercise(
    name: 'Barbell Shrug',
    difficulty: 0.80,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.upperBackTraps: 0.75,
      MuscleCompartment.forearms: 0.20,
      MuscleCompartment.lowerBack: 0.05,
    },
  ),
  'back_extension': Exercise(
    name: 'Back Extension',
    difficulty: 0.75,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.lowerBack: 0.55,
      MuscleCompartment.glutes: 0.25,
      MuscleCompartment.hamstrings: 0.20,
    },
  ),
  // ==================== KOL ====================
  'barbell_curl': Exercise(
    name: 'Barbell Curl',
    difficulty: 0.75,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.biceps: 0.70,
      MuscleCompartment.forearms: 0.20,
      MuscleCompartment.anteriorDeltoid: 0.05,
      MuscleCompartment.core: 0.05,
    },
  ),
  'hammer_curl': Exercise(
    name: 'Hammer Curl',
    difficulty: 0.70,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.biceps: 0.50,
      MuscleCompartment.forearms: 0.45,
      MuscleCompartment.anteriorDeltoid: 0.05,
    },
  ),
  'incline_dumbbell_curl': Exercise(
    name: 'Incline Dumbbell Curl',
    difficulty: 0.70,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.biceps: 0.80,
      MuscleCompartment.forearms: 0.15,
      MuscleCompartment.anteriorDeltoid: 0.05,
    },
  ),
  'triceps_pushdown': Exercise(
    name: 'Triceps Pushdown',
    difficulty: 0.65,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.triceps: 0.85,
      MuscleCompartment.forearms: 0.05,
      MuscleCompartment.core: 0.10,
    },
  ),
  'skull_crusher': Exercise(
    name: 'Skull Crusher',
    difficulty: 0.75,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.triceps: 0.85,
      MuscleCompartment.forearms: 0.05,
      MuscleCompartment.lowerChest: 0.05,
      MuscleCompartment.anteriorDeltoid: 0.05,
    },
  ),
  'overhead_triceps_extension': Exercise(
    name: 'Overhead Triceps Extension',
    difficulty: 0.70,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.triceps: 0.85,
      MuscleCompartment.anteriorDeltoid: 0.05,
      MuscleCompartment.core: 0.10,
    },
  ),
  'wrist_curl': Exercise(
    name: 'Wrist Curl',
    difficulty: 0.60,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.forearms: 0.90,
      MuscleCompartment.biceps: 0.10,
    },
  ),
  // ==================== BACAK / KALÇA ====================
  'back_squat': Exercise(
    name: 'Back Squat',
    difficulty: 1.25,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.quads: 0.40,
      MuscleCompartment.glutes: 0.25,
      MuscleCompartment.hamstrings: 0.08,
      MuscleCompartment.lowerBack: 0.10,
      MuscleCompartment.core: 0.10,
      MuscleCompartment.calves: 0.02,
      MuscleCompartment.upperBackTraps: 0.05,
    },
  ),
  'front_squat': Exercise(
    name: 'Front Squat',
    difficulty: 1.20,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.quads: 0.50,
      MuscleCompartment.glutes: 0.18,
      MuscleCompartment.core: 0.14,
      MuscleCompartment.upperBackTraps: 0.08,
      MuscleCompartment.lowerBack: 0.10,
    },
  ),
  'leg_press': Exercise(
    name: 'Leg Press',
    difficulty: 1.00,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.quads: 0.55,
      MuscleCompartment.glutes: 0.25,
      MuscleCompartment.hamstrings: 0.10,
      MuscleCompartment.calves: 0.10,
    },
  ),
  'romanian_deadlift': Exercise(
    name: 'Romanian Deadlift',
    difficulty: 1.15,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.hamstrings: 0.45,
      MuscleCompartment.glutes: 0.25,
      MuscleCompartment.lowerBack: 0.15,
      MuscleCompartment.forearms: 0.08,
      MuscleCompartment.upperBackTraps: 0.07,
    },
  ),
  'hip_thrust': Exercise(
    name: 'Hip Thrust',
    difficulty: 1.00,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.glutes: 0.65,
      MuscleCompartment.hamstrings: 0.15,
      MuscleCompartment.quads: 0.10,
      MuscleCompartment.core: 0.10,
    },
  ),
  'lying_leg_curl': Exercise(
    name: 'Lying Leg Curl',
    difficulty: 0.65,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.hamstrings: 0.85,
      MuscleCompartment.calves: 0.15,
    },
  ),
  'leg_extension': Exercise(
    name: 'Leg Extension',
    difficulty: 0.65,
    type: ExerciseType.bodybuilding,
    compartments: {MuscleCompartment.quads: 0.95, MuscleCompartment.core: 0.05},
  ),
  'standing_calf_raise': Exercise(
    name: 'Standing Calf Raise',
    difficulty: 0.70,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.calves: 0.90,
      MuscleCompartment.core: 0.05,
      MuscleCompartment.quads: 0.05,
    },
  ),
  'seated_calf_raise': Exercise(
    name: 'Seated Calf Raise',
    difficulty: 0.60,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.calves: 0.95,
      MuscleCompartment.quads: 0.05,
    },
  ),
  'walking_lunge': Exercise(
    name: 'Walking Lunge',
    difficulty: 0.95,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.quads: 0.40,
      MuscleCompartment.glutes: 0.30,
      MuscleCompartment.hamstrings: 0.10,
      MuscleCompartment.calves: 0.05,
      MuscleCompartment.core: 0.10,
      MuscleCompartment.forearms: 0.05,
    },
  ),
  // ==================== KARIN ====================
  'cable_crunch': Exercise(
    name: 'Cable Crunch',
    difficulty: 0.70,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.core: 0.90,
      MuscleCompartment.lats: 0.05,
      MuscleCompartment.upperBackTraps: 0.05,
    },
  ),
  'hanging_leg_raise': Exercise(
    name: 'Hanging Leg Raise',
    difficulty: 0.95,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.core: 0.70,
      MuscleCompartment.forearms: 0.10,
      MuscleCompartment.lats: 0.10,
      MuscleCompartment.quads: 0.10,
    },
  ),
  'ab_wheel_rollout': Exercise(
    name: 'Ab Wheel Rollout',
    difficulty: 0.95,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.core: 0.70,
      MuscleCompartment.lats: 0.10,
      MuscleCompartment.anteriorDeltoid: 0.10,
      MuscleCompartment.triceps: 0.05,
      MuscleCompartment.lowerBack: 0.05,
    },
  ),
  'pallof_press': Exercise(
    name: 'Pallof Press',
    difficulty: 0.60,
    type: ExerciseType.bodybuilding,
    compartments: {
      MuscleCompartment.core: 0.80,
      MuscleCompartment.anteriorDeltoid: 0.05,
      MuscleCompartment.glutes: 0.10,
      MuscleCompartment.triceps: 0.05,
    },
  ),
};
