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
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';

class WorkoutSessionScreen extends StatefulWidget {
  const WorkoutSessionScreen({super.key, required this.exercise});

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
        HapticFeedback.heavyImpact();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Dinlenme bitti!')));
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
    HapticFeedback.heavyImpact();
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
    _finishWorkout();
  }

  void _openRestSettings() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        side: BorderSide(color: AppColors.border, width: 1.0),
      ),
      builder: (context) {
        final options = <int>[30, 45, 60, 90];
        return Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 28.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dinlenme Süresi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHigh,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textMid,
                      size: 20.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14.0),
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

    final targetMuscles = widget.exercise.targetMuscleGroups.isNotEmpty
        ? widget.exercise.targetMuscleGroups
              .map((m) => m.label.toUpperCase())
              .join(' · ')
        : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            children: [
              // 1. ÜST BAR (Minimal & Modern)
              Row(
                children: [
                  _TopIconButton(
                    icon: Icons.close_rounded,
                    onTap: _closeSession,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14.0,
                      vertical: 7.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(999.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.0,
                          height: 8.0,
                          decoration: const BoxDecoration(
                            color: AppColors.iceBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Text(
                          _formatDuration(_workElapsed),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: AppColors.textHigh,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _TopIconButton(
                    icon: Icons.tune_rounded,
                    onTap: _openRestSettings,
                  ),
                ],
              ),
              const SizedBox(height: 14.0),

              // ORTA KAYDIRILABİLİR ALAN
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 2. HAREKET HERO / DİNLENME ALANI
                      _ExerciseHeroCard(
                        exercise: widget.exercise,
                        isRestRunning: _restRunning,
                        restRemainingText: _formatDuration(_restRemaining),
                        restProgress: restProgress,
                        nextSetText:
                            'Sıradaki: Set $setIndex / $_totalSets · $target Tekrar',
                        onStopRest: _stopRest,
                      ),
                      const SizedBox(height: 18.0),

                      // 4. İLERLEME (Segmentli Set Göstergesi)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Row(
                          children: List.generate(_totalSets, (index) {
                            final isCompleted = index < _completedSets;
                            final isCurrent =
                                index == _completedSets && !isWorkoutDone;
                            return Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3.0,
                                ),
                                height: 4.5,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? AppColors.emerald
                                      : isCurrent
                                      ? AppColors.iceBlue
                                      : AppColors.surfaceSoft,
                                  borderRadius: BorderRadius.circular(999.0),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 18.0),

                      // 3. HAREKET BİLGİLERİ (Güçlü Tipografi & Kas Grupları)
                      Text(
                        widget.exercise.name.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              color: AppColors.textHigh,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                      ),
                      if (targetMuscles.isNotEmpty) ...[
                        const SizedBox(height: 6.0),
                        Text(
                          targetMuscles,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppColors.textMid,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                        ),
                      ],
                      const SizedBox(height: 14.0),

                      // Set ve Tekrar Çipleri
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _TagChip(
                            text: 'SET $setIndex / $_totalSets',
                            textColor: AppColors.textHigh,
                            background: AppColors.surface,
                            borderColor: AppColors.border,
                          ),
                          const SizedBox(width: 10.0),
                          _TagChip(
                            text: 'HEDEF: $target TEKRAR',
                            textColor: AppColors.iceBlue,
                            background: AppColors.iceBlue.withValues(
                              alpha: 0.16,
                            ),
                            borderColor: AppColors.iceBlue.withValues(
                              alpha: 0.45,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),

                      // 5. ANA AKSİYON BUTONU (Seti Tamamla)
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _completeSet,
                          style: FilledButton.styleFrom(
                            backgroundColor: isWorkoutDone
                                ? AppColors.emerald
                                : AppColors.volcanic,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.0),
                            ),
                            elevation: 0,
                          ),
                          icon: Icon(
                            isWorkoutDone
                                ? Icons.flag_rounded
                                : Icons.check_rounded,
                            size: 22.0,
                          ),
                          label: Text(
                            isWorkoutDone ? 'ANTRENMANI BİTİR' : 'SETİ TAMAMLA',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 16.0,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16.0),

                      // 6. SIRADAKİ (Next Up) KARTI
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 14.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40.0,
                              height: 40.0,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSoft,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: AppColors.iceBlue,
                                size: 19.0,
                              ),
                            ),
                            const SizedBox(width: 14.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SIRADAKİ',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.textMuted,
                                          letterSpacing: 1.2,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    isWorkoutDone
                                        ? 'Antrenman Tamamlandı'
                                        : _restRunning
                                        ? 'Set $setIndex / $_totalSets'
                                        : 'Sonraki set hazır',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: AppColors.textHigh,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  Text(
                                    _repsForLevel(widget.exercise.level),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: AppColors.textMid),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14.0,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12.0),

              // 8. ALT AKSİYONLAR (DURAKLAT & BİTİR)
              Row(
                children: [
                  Expanded(
                    child: _ActionPillButton(
                      label: _isPaused ? 'DEVAM ET' : 'DURAKLAT',
                      icon: _isPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.textHigh,
                      borderColor: AppColors.border,
                      onPressed: _togglePause,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _ActionPillButton(
                      label: 'BİTİR',
                      icon: Icons.stop_rounded,
                      backgroundColor: AppColors.volcanic,
                      foregroundColor: Colors.white,
                      borderColor: AppColors.volcanic,
                      onPressed: _finishWorkout,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// YARDIMCI WIDGET'LAR
// ---------------------------------------------------------------------------

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
          color: AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(icon, color: AppColors.textHigh, size: 19.0),
      ),
    );
  }
}

class _ExerciseHeroCard extends StatelessWidget {
  const _ExerciseHeroCard({
    required this.exercise,
    required this.isRestRunning,
    required this.restRemainingText,
    required this.restProgress,
    required this.nextSetText,
    required this.onStopRest,
  });

  final Exercise exercise;
  final bool isRestRunning;
  final String restRemainingText;
  final double restProgress;
  final String nextSetText;
  final VoidCallback onStopRest;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280.0,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isRestRunning
              ? AppColors.iceBlue.withValues(alpha: 0.45)
              : AppColors.border,
        ),
      ),
      child: isRestRunning
          // 7. DİNLENME MODU (Büyük Countdown & Progress)
          ? Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 5.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.iceBlue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999.0),
                      border: Border.all(
                        color: AppColors.iceBlue.withValues(alpha: 0.4),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 14.0,
                          color: AppColors.iceBlue,
                        ),
                        SizedBox(width: 6.0),
                        Text(
                          'DİNLENME',
                          style: TextStyle(
                            color: AppColors.iceBlue,
                            fontWeight: FontWeight.w800,
                            fontSize: 12.0,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  Text(
                    restRemainingText,
                    style: const TextStyle(
                      color: AppColors.textHigh,
                      fontSize: 54.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999.0),
                    child: LinearProgressIndicator(
                      value: restProgress.clamp(0.0, 1.0),
                      minHeight: 6.0,
                      backgroundColor: AppColors.surfaceSoft,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.iceBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14.0),
                  Text(
                    nextSetText,
                    style: const TextStyle(
                      color: AppColors.textMid,
                      fontSize: 13.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  TextButton.icon(
                    onPressed: onStopRest,
                    icon: const Icon(
                      Icons.skip_next_rounded,
                      size: 18.0,
                      color: AppColors.volcanic,
                    ),
                    label: const Text(
                      'DİNLENMEYİ BİTİR',
                      style: TextStyle(
                        color: AppColors.volcanic,
                        fontWeight: FontWeight.w800,
                        fontSize: 13.0,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            )
          // HAREKET GÖRSELİ MODU
          : ClipRRect(
              borderRadius: BorderRadius.circular(14.0),
              child: Stack(
                children: [
                  Positioned.fill(child: _HeroVisual(exercise: exercise)),
                  // Seviye Rozeti
                  Positioned(
                    top: 14.0,
                    right: 14.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 5.0,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(999.0),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        exercise.level.label.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textMid,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _HeroVisual extends StatelessWidget {
  const _HeroVisual({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final isMatchingAsset = exercise.name.toLowerCase().contains('incline');
    final assetPath = isMatchingAsset
        ? 'assets/images/Incline-pushup.png'
        : 'assets/images/${exercise.id}.png';

    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const _HeroFallbackIcon();
      },
    );
  }
}

class _HeroFallbackIcon extends StatelessWidget {
  const _HeroFallbackIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 110.0,
        height: 110.0,
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(
          Icons.accessibility_new_rounded,
          size: 58.0,
          color: AppColors.textHigh,
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
    this.borderColor,
  });

  final String text;
  final Color textColor;
  final Color background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 7.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.0),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
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
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 9.0),
        decoration: BoxDecoration(
          color: selected ? AppColors.iceBlue : AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(999.0),
          border: Border.all(
            color: selected ? AppColors.iceBlue : AppColors.border,
          ),
        ),
        child: Text(
          '${seconds}s',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? AppColors.background : AppColors.textHigh,
            fontWeight: FontWeight.w800,
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
    required this.borderColor,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color borderColor;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18.0, color: foregroundColor),
            const SizedBox(width: 8.0),
            Text(
              label,
              style: TextStyle(
                color: foregroundColor,
                fontWeight: FontWeight.w800,
                fontSize: 13.0,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
