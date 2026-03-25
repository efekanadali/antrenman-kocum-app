// lib/presentation/screens/workout_session_screen.dart

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
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
  bool _isPaused = false;
  bool _restRunning = false;
  int _restPresetSeconds = 60;
  late int _totalSets;
  int _completedSets = 0;

  static const Color _pageBackground = Color(0xFFF2F3EE);
  static const Color _heroTop = Color(0xFF1F2435);
  static const Color _heroBottom = Color(0xFF0F121E);
  static const Color _accentLime = Color(0xFFC2F13A);
  static const Color _ink = Color(0xFF1A132E);
  static const Color _softGray = Color(0xFFE4E6E0);
  static const Color _mutedText = Color(0xFF72756D);

  @override
  void initState() {
    super.initState();
    _totalSets = _totalSetsForLevel(widget.exercise.level);
    _startWorkTimer();
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

  int _targetRepsForLevel(ExerciseLevel level) {
    switch (level) {
      case ExerciseLevel.beginner:
        return 10;
      case ExerciseLevel.intermediate:
        return 15;
      case ExerciseLevel.advanced:
        return 8;
    }
  }

  void _startWorkTimer() {
    _workTimer?.cancel();
    _workTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_isPaused || !mounted) {
        return;
      }
      setState(() {
        _workElapsed += const Duration(seconds: 1);
      });
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

    void _stopRest() {
      _restTimer?.cancel();
      setState(() {
        _restRunning = false;
        _restRemaining = Duration.zero;
      });
    }

    void _togglePause() {
      setState(() {
        _isPaused = !_isPaused;
      });
    }

    void _completeSet() {
      if (_completedSets >= _totalSets) {
        _finishWorkout();
        return;
      }

      HapticFeedback.selectionClick();
      setState(() {
        _completedSets += 1;
      });

      if (_completedSets < _totalSets) {
        _startRest();
        return;
      }

      HapticFeedback.mediumImpact();
    }

    void _openRestSettings() {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        builder: (context) {
          final options = <int>[30, 45, 60, 90];
          return Padding(
            padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dinlenme suresi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                ),
                const SizedBox(height: 12.0),
                Wrap(
                  spacing: 10.0,
                  runSpacing: 10.0,
                  children: [
                    for (final seconds in options)
                      _RestPresetChip(
                        seconds: seconds,
                        selected: _restPresetSeconds == seconds,
                        onTap: () {
                          Navigator.pop(context);
                          setState(() {
                            _restPresetSeconds = seconds;
                          });
                        },
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _finishWorkout() {
    _workTimer?.cancel();
    _restTimer?.cancel();

    final durationMinutes = (_workElapsed.inSeconds / 60).clamp(0.0, 1e9);
    final difficultyFactor = switch (widget.exercise.difficulty) {
      DifficultyLevel.easy => 1.0,
      DifficultyLevel.medium => 1.25,
      DifficultyLevel.hard => 1.5,
    };
    final totalLoad = durationMinutes * 100 * difficultyFactor;

    final muscleLoad = <String, double>{};
    final ratings = widget.exercise.muscleRatings;
    final ratingSum = ratings.values.fold<int>(0, (sum, item) => sum + item);

    if (ratingSum > 0) {
      for (final entry in ratings.entries) {
        muscleLoad[entry.key.name] = totalLoad * (entry.value / ratingSum);
      }
    } else if (widget.exercise.targetMuscleGroups.isNotEmpty) {
      final perMuscle = totalLoad / widget.exercise.targetMuscleGroups.length;
      for (final muscle in widget.exercise.targetMuscleGroups) {
        muscleLoad[muscle.name] = perMuscle;
      }
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.workoutSummary,
      (route) => false,
      arguments: WorkoutSummaryArgs(
        exerciseName: widget.exercise.name,
        totalTime: _workElapsed,
        setsCompleted: _completedSets,
        totalSets: _totalSets,
        totalLoad: totalLoad,
        muscleLoad: muscleLoad,
      ),
    );
  }

  void _closeSession() {
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final setIndex = math.min(_completedSets + 1, _totalSets);
    final target = _targetRepsForLevel(widget.exercise.level);
    final isWorkoutDone = _completedSets >= _totalSets;
    final restProgress = _restPresetSeconds == 0
        ? 0.0
        : _restRemaining.inSeconds / _restPresetSeconds;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            children: [
              Row(
                children: [
                  _TopIconButton(
                    icon: Icons.close_rounded,
                    onTap: _closeSession,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999.0),
                      border: Border.all(color: const Color(0xFFE4E7DE)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10.0,
                          height: 10.0,
                          decoration: const BoxDecoration(
                            color: _accentLime,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          _formatDuration(_workElapsed),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: _ink,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _TopIconButton(
                    icon: Icons.settings,
                    onTap: _openRestSettings,
                  ),
                ],
              ),
              const SizedBox(height: 14.0),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const _ExerciseHeroCard(),
                      const SizedBox(height: 24.0),
                      Text(
                        widget.exercise.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: _ink,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TagChip(
                            text: 'Set $setIndex of $_totalSets',
                            textColor: _ink,
                            background: _softGray,
                          ),
                          const SizedBox(width: 8.0),
                          _TagChip(
                            text: 'Target: $target Reps',
                            textColor: _ink,
                            background: _accentLime,
                          ),
                        ],
                      ),
                      const SizedBox(height: 22.0),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _completeSet,
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentLime,
                            foregroundColor: _ink,
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22.0),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(
                            isWorkoutDone ? 'ANTRENMANI BITIR' : 'COMPLETE SET',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18.0),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 14.0,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(color: const Color(0xFFE7E9E1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42.0,
                              height: 42.0,
                              decoration: const BoxDecoration(
                                color: Color(0xFF11151F),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: Colors.white,
                                size: 20.0,
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NEXT UP',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: _mutedText,
                                          letterSpacing: 1.0,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    isWorkoutDone
                                        ? 'Antrenman Tamamlandi'
                                        : _restRunning
                                            ? 'Dinlenme ${_formatDuration(_restRemaining)}'
                                            : 'Sonraki set hazir',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: _ink,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  Text(
                                    _repsForLevel(widget.exercise.level),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: _mutedText),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16.0,
                              color: Color(0xFF8B8E86),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_restRunning) ...[
                const SizedBox(height: 10.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999.0),
                  child: LinearProgressIndicator(
                    value: restProgress.clamp(0.0, 1.0),
                    minHeight: 8.0,
                    backgroundColor: const Color(0xFFD8DBD3),
                    valueColor: const AlwaysStoppedAnimation<Color>(_accentLime),
                  ),
                ),
              ],
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(
                    child: _ActionPillButton(
                      label: _isPaused ? 'RESUME' : 'PAUSE',
                      icon: _isPaused
                          ? Icons.play_circle_fill_rounded
                          : Icons.pause_circle_filled_rounded,
                      backgroundColor: _softGray,
                      foregroundColor: _ink,
                      onPressed: _togglePause,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _ActionPillButton(
                      label: 'STOP',
                      icon: Icons.stop_circle_rounded,
                      backgroundColor: _accentLime,
                      foregroundColor: _ink,
                      onPressed: _finishWorkout,
                    ),
                  ),
                ],
              ),
              if (_restRunning)
                TextButton(
                  onPressed: _stopRest,
                  child: Text(
                    'Dinlenmeyi bitir',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999.0),
      onTap: onTap,
      child: Container(
        width: 38.0,
        height: 38.0,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE4E7DE)),
        ),
        child: Icon(
          icon,
          color: _WorkoutSessionScreenState._ink,
          size: 19.0,
        ),
      ),
    );
  }
}

class _ExerciseHeroCard extends StatelessWidget {
  const _ExerciseHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 290.0,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        gradient: const LinearGradient(
          colors: [
            _WorkoutSessionScreenState._heroTop,
            _WorkoutSessionScreenState._heroBottom,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: const [
          Expanded(child: _HeroFrame()),
          SizedBox(height: 8.0),
          Expanded(child: _HeroFrame()),
        ],
      ),
    );
  }
}

class _HeroFrame extends StatelessWidget {
  const _HeroFrame();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.0),
        gradient: const LinearGradient(
          colors: [Color(0xFF2C3144), Color(0xFF181C2A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.accessibility_new_rounded,
          size: 64.0,
          color: Colors.white.withOpacity(0.92),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.text,
    required this.textColor,
    required this.background,
  });

  final String text;
  final Color textColor;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: selected
              ? _WorkoutSessionScreenState._accentLime
              : const Color(0xFFF3F4EF),
          borderRadius: BorderRadius.circular(999.0),
          border: Border.all(
            color: selected
                ? _WorkoutSessionScreenState._accentLime
                : const Color(0xFFD5D9CF),
          ),
        ),
        child: Text(
          '${seconds}s',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: selected
                    ? _WorkoutSessionScreenState._ink
                    : const Color(0xFF4E5348),
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _ActionPillButton extends StatelessWidget {
  const _ActionPillButton({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999.0)),
      ),
      icon: Icon(icon, size: 18.0),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }
}
