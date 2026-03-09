// lib/presentation/screens/workout_session_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/screens/workout_summary_screen.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({
    super.key,
    required this.exercise,
  });

  final Exercise exercise;

  @override
  State<WorkoutSessionScreen> createState() => _WorkoutSessionScreenState();
}

class _WorkoutSessionScreenState extends State<WorkoutSessionScreen> {
  Timer? _workTimer;
  Timer? _restTimer;
  Duration _workElapsed = Duration.zero;
  Duration _restRemaining = Duration.zero;
  bool _workRunning = false;
  bool _restRunning = false;
  int _restPresetSeconds = 60;
  late int _totalSets;
  int _currentSet = 1;

  @override
  void initState() {
    super.initState();
    _totalSets = _totalSetsForLevel(widget.exercise.level);
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  int _totalSetsForLevel(ExerciseLevel level) {
    switch (level) {
      case ExerciseLevel.beginner:
        return 3;
      case ExerciseLevel.intermediate:
        return 4;
      case ExerciseLevel.advanced:
        return 5;
    }
  }

  String _repsForLevel(ExerciseLevel level) {
    switch (level) {
      case ExerciseLevel.beginner:
        return '8-10 tekrar';
      case ExerciseLevel.intermediate:
        return '10-12 tekrar';
      case ExerciseLevel.advanced:
        return '6-8 tekrar';
    }
  }

  void _toggleWorkTimer() {
    if (_workRunning) {
      _workTimer?.cancel();
      setState(() {
        _workRunning = false;
      });
      return;
    }

    _workTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _workElapsed += const Duration(seconds: 1);
      });
    });

    setState(() {
      _workRunning = true;
    });
  }

  void _resetWorkTimer() {
    _workTimer?.cancel();
    setState(() {
      _workRunning = false;
      _workElapsed = Duration.zero;
    });
  }

  void _startRest() {
    if (_restRunning) {
      return;
    }

    setState(() {
      _restRemaining = Duration(seconds: _restPresetSeconds);
      _restRunning = true;
    });

    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemaining.inSeconds <= 1) {
        timer.cancel();
        setState(() {
          _restRemaining = Duration.zero;
          _restRunning = false;
        });
        HapticFeedback.mediumImpact();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dinlenme bitti!')),
          );
        }
        return;
      }

      setState(() {
        _restRemaining -= const Duration(seconds: 1);
      });
    });
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _finishWorkout() {
    _workTimer?.cancel();
    _restTimer?.cancel();

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.workoutSummary,
      (route) => false,
      arguments: WorkoutSummaryArgs(
        exerciseName: widget.exercise.name,
        totalTime: _workElapsed,
        setsCompleted: _currentSet,
        totalSets: _totalSets,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final restProgress = _restRemaining.inSeconds / _restPresetSeconds;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenman Modu'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        children: [
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exercise.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  'Seviye: ${widget.exercise.level.label.toUpperCase()} · ${_repsForLevel(widget.exercise.level)}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.16),
                  colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Column(
              children: [
                Text(
                  'SÜRE',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  _formatDuration(_workElapsed),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12.0),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _toggleWorkTimer,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                        child: Text(_workRunning ? 'Duraklat' : 'Başlat'),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _resetWorkTimer,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                        ),
                        child: const Text('Sıfırla'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '$_currentSet / $_totalSets',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _currentSet > 1
                      ? () => setState(() => _currentSet--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  onPressed: _currentSet < _totalSets
                      ? () => setState(() => _currentSet++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20.0),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Dinlenme',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      _formatDuration(_restRemaining),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                Wrap(
                  spacing: 8.0,
                  children: [
                    _RestPresetChip(
                      seconds: 30,
                      selected: _restPresetSeconds == 30,
                      onTap: _restRunning
                          ? null
                          : () => setState(() => _restPresetSeconds = 30),
                    ),
                    _RestPresetChip(
                      seconds: 60,
                      selected: _restPresetSeconds == 60,
                      onTap: _restRunning
                          ? null
                          : () => setState(() => _restPresetSeconds = 60),
                    ),
                    _RestPresetChip(
                      seconds: 90,
                      selected: _restPresetSeconds == 90,
                      onTap: _restRunning
                          ? null
                          : () => setState(() => _restPresetSeconds = 90),
                    ),
                  ],
                ),
                const SizedBox(height: 12.0),
                LinearProgressIndicator(
                  value: _restRunning ? restProgress.clamp(0.0, 1.0) : 0.0,
                  minHeight: 8.0,
                  backgroundColor: colorScheme.surfaceContainerHigh,
                  valueColor: AlwaysStoppedAnimation(colorScheme.primary),
                ),
                const SizedBox(height: 12.0),
                OutlinedButton.icon(
                  onPressed: _startRest,
                  icon: const Icon(Icons.bedtime),
                  label: const Text('Dinlenme Baslat'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          ElevatedButton.icon(
            onPressed: _finishWorkout,
            icon: const Icon(Icons.flag),
            label: const Text('Antrenmani Bitir'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestPresetChip extends StatelessWidget {
  const _RestPresetChip({
    required this.seconds,
    required this.selected,
    required this.onTap,
  });

  final int seconds;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary : colorScheme.surface,
          borderRadius: BorderRadius.circular(999.0),
          border: Border.all(
            color: selected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
        child: Text(
          '${seconds}s',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}
