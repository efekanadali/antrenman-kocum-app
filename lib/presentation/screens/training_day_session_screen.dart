// lib/presentation/screens/training_day_session_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/core/utils/exercise_unit.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart' as mli;
import 'package:calisthenics_app/domain/services/exercise_mli_resolver.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/domain/services/recovery_calculator.dart';
import 'package:calisthenics_app/presentation/providers/exercise_list_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/screens/workout_summary_screen.dart';

class TrainingDaySessionArgs {
  const TrainingDaySessionArgs({
    required this.level,
    required this.week,
    required this.day,
  });

  final String level;
  final int week;
  final Map<String, dynamic> day;
}

class TrainingDaySessionScreen extends ConsumerStatefulWidget {
  const TrainingDaySessionScreen({super.key, required this.args});

  final TrainingDaySessionArgs args;

  @override
  ConsumerState<TrainingDaySessionScreen> createState() =>
      _TrainingDaySessionScreenState();
}

class _TrainingDaySessionScreenState
    extends ConsumerState<TrainingDaySessionScreen> {
  static const int _defaultRir = 2;

  late final List<_SessionStep> _steps;
  late final List<bool> _completed;
  late final DateTime _startedAt;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    _steps = _buildSteps(widget.args.day);
    _completed = List<bool>.filled(_steps.length, false);
  }

  List<_SessionStep> _buildSteps(Map<String, dynamic> day) {
    final warmup = (day["warmup"] as List<dynamic>).cast<String>();
    final workout = (day["workout"] as List<dynamic>)
        .map((item) => item as Map<String, dynamic>)
        .toList();
    final cooldown = (day["cooldown"] as List<dynamic>).cast<String>();

    final steps = <_SessionStep>[];
    for (final item in warmup) {
      steps.add(
        _SessionStep(
          title: item,
          badge: 'Isinma',
        ),
      );
    }
    for (final item in workout) {
      final detail =
          '${item["sets"]} set • ${item["reps_or_time"]} • Dinlenme ${item["rest"]}';
      final progression = 'Ilerleme: ${item["progression"]}';
      final regression = 'Kolaylastirma: ${item["regression"]}';
      steps.add(
        _SessionStep(
          title: item["exercise"] as String,
          badge: 'Ana Antrenman',
          detail: '$detail\n$progression\n$regression',
          workoutItem: item,
        ),
      );
    }
    for (final item in cooldown) {
      steps.add(
        _SessionStep(
          title: item,
          badge: 'Esneme',
        ),
      );
    }
    return steps;
  }

  void _toggleStep(int index) {
    setState(() {
      _completed[index] = !_completed[index];
    });
  }

  String _resolvePresetExerciseId(String rawName) {
    final normalized = rawName.trim().toLowerCase();
    const mapping = <String, String>{
      'diz ustu sinav': 'knee_push_up',
      'sandalyeye triceps dip': 'dips_parallel_bar',
      'plank': 'plank',
      'vucut agirligi squat': 'standard_squat',
      'geri lunge': 'lunge',
      'dead bug': 'hollow_body_hold',
      'ters sinav (row)': 'australian_row',
      'superman': 'glute_bridge',
      'yan plank': 'side_plank',
      'bench press': 'standard_push_up',
      'incline dumbbell press': 'decline_push_up',
      'cable triceps pushdown': 'diamond_push_up',
      'leg press': 'standard_squat',
      'romanian deadlift': 'nordic_curl',
      'hanging knee raise': 'hollow_body_hold',
      'lat pulldown': 'standard_pull_up',
      'seated cable row': 'australian_row',
      'face pull': 'australian_row',
    };
    return mapping[normalized] ?? normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }

  int _parseTargetValue(String rawRepsOrTime, {required bool isTimed}) {
    final matches = RegExp(r'\d+').allMatches(rawRepsOrTime).toList();
    if (matches.isEmpty) {
      return isTimed ? 30 : 10;
    }
    final parsed = int.tryParse(matches.last.group(0) ?? '');
    if (parsed == null || parsed <= 0) {
      return isTimed ? 30 : 10;
    }
    return parsed;
  }

  void _completeDaySession() {
    final day = widget.args.day;
    final catalog =
        ref.read(exerciseListProvider).valueOrNull ?? const <Exercise>[];
    final resolver = ExerciseMliResolver(catalog: catalog);

    final entries = <mli.ExerciseWorkoutEntry>[];
    var totalSets = 0;
    var setsCompleted = 0;

    for (var i = 0; i < _steps.length; i++) {
      final workoutItem = _steps[i].workoutItem;
      if (workoutItem == null) {
        continue;
      }

      final exerciseName = (workoutItem['exercise'] as String?) ?? _steps[i].title;
      final setsCount = int.tryParse(workoutItem['sets']?.toString() ?? '') ?? 3;
      final rawRepsOrTime = workoutItem['reps_or_time']?.toString() ?? '';
      final exerciseId = _resolvePresetExerciseId(exerciseName);
      final isTimed =
          rawRepsOrTime.toLowerCase().contains('sn') ||
          isTimedExercise(exerciseName: exerciseName, exerciseId: exerciseId);
      final targetValue = _parseTargetValue(rawRepsOrTime, isTimed: isTimed);

      totalSets += setsCount;
      if (!_completed[i]) {
        continue;
      }
      setsCompleted += setsCount;

      final customExercise = CustomProgramExercise(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        sets: setsCount,
        value: targetValue,
        isTimed: isTimed,
      );
      final mliExercise = resolver.build(customExercise);

      final workoutSets = List<mli.WorkoutSet>.generate(
        setsCount,
        (_) => isTimed
            ? mli.WorkoutSet(
                reps: 0,
                rir: _defaultRir,
                durationInSeconds: targetValue,
              )
            : mli.WorkoutSet(
                reps: targetValue,
                rir: _defaultRir,
              ),
      );

      entries.add(
        mli.ExerciseWorkoutEntry(
          exercise: mliExercise,
          sets: workoutSets,
        ),
      );
    }

    final muscleLoad = calculateWorkoutLoad(entries);
    final muscleRir = calculateWorkoutMuscleRir(entries);
    final totalLoad = muscleLoad.values.fold<double>(
      0.0,
      (sum, val) => sum + val,
    );
    final elapsed = DateTime.now().difference(_startedAt);

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.workoutSummary,
      (route) => false,
      arguments: WorkoutSummaryArgs(
        exerciseName: '${day["name"]} - ${day["focus"]}',
        totalTime: elapsed,
        setsCompleted: setsCompleted,
        totalSets: totalSets,
        totalLoad: totalLoad,
        muscleLoad: muscleLoad,
        muscleRir: muscleRir,
        averageRir: kDefaultRir,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Egzersiz kataloğunu seans boyunca önbellekte hazır tut
    ref.watch(exerciseListProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final day = widget.args.day;
    final completedCount = _completed.where((value) => value).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('${day["name"]} - ${day["focus"]}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        children: [
          _HeaderCard(
            level: widget.args.level,
            week: widget.args.week,
            focus: day["focus"] as String,
            totalSteps: _steps.length,
            completedSteps: completedCount,
          ),
          const SizedBox(height: 16.0),
          for (var i = 0; i < _steps.length; i++)
            _StepCard(
              step: _steps[i],
              index: i + 1,
              completed: _completed[i],
              onTap: () => _toggleStep(i),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: FilledButton.icon(
            onPressed: completedCount == _steps.length
                ? _completeDaySession
                : null,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Günü Tamamla'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.level,
    required this.week,
    required this.focus,
    required this.totalSteps,
    required this.completedSteps,
  });

  final String level;
  final int week;
  final String focus;
  final int totalSteps;
  final int completedSteps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = totalSteps == 0 ? 0.0 : completedSteps / totalSteps;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.18),
            colorScheme.secondary.withValues(alpha: 0.16),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'Hafta $week',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(width: 10.0),
              Text(
                level.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          Text(
            focus,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.0,
              backgroundColor: colorScheme.surface.withValues(alpha: 0.6),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            '$completedSteps / $totalSteps adim tamamlandi',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.step,
    required this.index,
    required this.completed,
    required this.onTap,
  });

  final _SessionStep step;
  final int index;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.0),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: completed
                  ? colorScheme.primary.withValues(alpha: 0.5)
                  : colorScheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30.0,
                height: 30.0,
                decoration: BoxDecoration(
                  color: completed
                      ? colorScheme.primary
                      : colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: completed
                              ? colorScheme.onPrimary
                              : colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 4.0,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            step.badge,
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: Text(
                            step.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (step.detail != null) ...[
                      const SizedBox(height: 6.0),
                      Text(
                        step.detail!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: completed
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionStep {
  const _SessionStep({
    required this.title,
    required this.badge,
    this.detail,
    this.workoutItem,
  });

  final String title;
  final String badge;
  final String? detail;
  final Map<String, dynamic>? workoutItem;
}
