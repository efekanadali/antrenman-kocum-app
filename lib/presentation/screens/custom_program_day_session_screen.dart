// lib/presentation/screens/custom_program_day_session_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/domain/models/exercise.dart' as domain;
import 'package:calisthenics_app/domain/models/mli_models.dart' as mli;
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/domain/services/exercise_mli_resolver.dart';
import 'package:calisthenics_app/domain/services/recovery_calculator.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/screens/workout_summary_screen.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

const Color _bgTop = AppColors.surfaceSoft;
const Color _bgBottom = AppColors.background;
const Color _cardSurface = AppColors.surface;
const Color _cardSurfaceSoft = AppColors.surfaceSoft;
const Color _accentVolcanic = AppColors.volcanic;
const Color _accentEmerald = AppColors.emerald;
const Color _accentBlue = AppColors.nordicIce;
const Color _textHigh = AppColors.textHigh;
const Color _textMid = AppColors.textMid;
const Color _sessionPageBg = AppColors.background;
const Color _sessionInk = AppColors.textHigh;
const Color _sessionSoft = AppColors.surfaceSoft;
const Color _sessionMuted = AppColors.textMuted;
const String _sessionHeroImageAsset = 'assets/images/Incline-pushup.png';

class CustomProgramDaySessionArgs {
  const CustomProgramDaySessionArgs({
    required this.programName,
    required this.day,
  });

  final String programName;
  final CustomProgramDay day;
}

class CustomProgramDaySessionScreen extends ConsumerStatefulWidget {
  const CustomProgramDaySessionScreen({super.key, required this.args});

  final CustomProgramDaySessionArgs args;

  @override
  ConsumerState<CustomProgramDaySessionScreen> createState() =>
      _CustomProgramDaySessionScreenState();
}

class _CustomProgramDaySessionScreenState
    extends ConsumerState<CustomProgramDaySessionScreen> {
  late final List<List<int?>> _actualValues;
  late final List<List<int?>> _actualRirs;
  late final List<List<double?>> _actualExtraWeights;
  late final List<List<double?>> _actualBodyWeights;
  ExerciseMliResolver _resolver = ExerciseMliResolver();
  Map<String, double> _lastSetLoadByMuscle = <String, double>{};
  Map<String, double> _workoutLoadByMuscle = <String, double>{};
  Map<String, double> _workoutRirByMuscle = <String, double>{};
  static const int _defaultRir = 2;
  static const double _defaultBodyWeightKg = 70.0;
  double _lastBodyWeightKg = _defaultBodyWeightKg;
  Timer? _workTimer;
  Duration _workElapsed = Duration.zero;
  bool _workPaused = false;
  int _restDurationSeconds = 60;
  int _restRemainingSeconds = 0;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _actualValues = widget.args.day.exercises
        .map((exercise) => List<int?>.filled(exercise.sets, null))
        .toList();
    _actualRirs = widget.args.day.exercises
        .map((exercise) => List<int?>.filled(exercise.sets, null))
        .toList();
    _actualExtraWeights = widget.args.day.exercises
        .map((exercise) => List<double?>.filled(exercise.sets, null))
        .toList();
    _actualBodyWeights = widget.args.day.exercises
        .map((exercise) => List<double?>.filled(exercise.sets, null))
        .toList();
    _loadExerciseDetails();
    _startWorkTimer();
  }

  Future<void> _loadExerciseDetails() async {
    final exerciseRepository = ref.read(exerciseRepositoryProvider);
    final allExercises = await exerciseRepository.getAllExercises();
    if (!mounted) {
      return;
    }

    setState(() {
      _resolver = ExerciseMliResolver(catalog: allExercises);
    });

    _recalculateWorkoutLoad(widget.args.day);
  }

  domain.Exercise? _resolveExerciseDetail(CustomProgramExercise exercise) {
    return _resolver.resolveDetail(exercise);
  }

  mli.Exercise _buildMliExercise(
    CustomProgramExercise source,
    domain.Exercise? exerciseDetail,
  ) {
    return _resolver.build(source, detail: exerciseDetail);
  }

  void _recalculateWorkoutLoad(CustomProgramDay day) {
    final entries = <mli.ExerciseWorkoutEntry>[];

    for (
      var exerciseIndex = 0;
      exerciseIndex < day.exercises.length;
      exerciseIndex++
    ) {
      final customExercise = day.exercises[exerciseIndex];
      final sets = <mli.WorkoutSet>[];

      for (var setIndex = 0; setIndex < customExercise.sets; setIndex++) {
        final actualValue = _actualValues[exerciseIndex][setIndex];
        if (actualValue == null) {
          continue;
        }

        final rir = _actualRirs[exerciseIndex][setIndex];
        if (rir == null) {
          continue;
        }
        final extraWeightKg =
            _actualExtraWeights[exerciseIndex][setIndex] ?? 0.0;
        final bodyWeightKg = _actualBodyWeights[exerciseIndex][setIndex];
        sets.add(
          customExercise.isTimed
              ? mli.WorkoutSet(
                  reps: 0,
                  rir: rir,
                  durationInSeconds: actualValue,
                  extraWeightKg: extraWeightKg,
                  bodyWeightKg: bodyWeightKg,
                )
              : mli.WorkoutSet(
                  reps: actualValue,
                  rir: rir,
                  extraWeightKg: extraWeightKg,
                  bodyWeightKg: bodyWeightKg,
                ),
        );
      }

      if (sets.isEmpty) {
        continue;
      }

      final exerciseDetail = _resolveExerciseDetail(customExercise);
      final mliExercise = _buildMliExercise(customExercise, exerciseDetail);
      entries.add(mli.ExerciseWorkoutEntry(exercise: mliExercise, sets: sets));
    }

    final totals = calculateWorkoutLoad(entries);
    final rirs = calculateWorkoutMuscleRir(entries);
    setState(() {
      _workoutLoadByMuscle = totals;
      _workoutRirByMuscle = rirs;
    });
  }

  String _feedbackForLoad(double score) {
    if (score < 200) {
      return 'Low';
    }
    if (score <= 600) {
      return 'Good';
    }
    return 'High';
  }

  String _lastSetIndicator(double score) {
    if (score < 80) {
      return 'Low';
    }
    if (score <= 180) {
      return 'Good';
    }
    return 'High';
  }

  @override
  void dispose() {
    _workTimer?.cancel();
    _restTimer?.cancel();
    super.dispose();
  }

  void _startWorkTimer() {
    _workTimer?.cancel();
    _workTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_workPaused) {
        setState(() {
          _workElapsed += const Duration(seconds: 1);
        });
      }
    });
  }

  void _togglePause() {
    setState(() {
      _workPaused = !_workPaused;
    });
  }

  int _currentExerciseIndex(CustomProgramDay day) {
    for (var i = 0; i < day.exercises.length; i++) {
      if (_completedForExercise(i) < day.exercises[i].sets) {
        return i;
      }
    }
    return day.exercises.isEmpty ? 0 : day.exercises.length - 1;
  }

  bool _isWorkoutComplete(CustomProgramDay day) {
    for (var i = 0; i < day.exercises.length; i++) {
      if (_completedForExercise(i) < day.exercises[i].sets) {
        return false;
      }
    }
    return true;
  }

  int _totalSets(CustomProgramDay day) {
    return day.exercises.fold(0, (sum, item) => sum + item.sets);
  }

  int _completedSetCount() {
    var total = 0;
    for (final values in _actualValues) {
      total += values.where((value) => value != null).length;
    }
    return total;
  }

  int _completedForExercise(int index) {
    return _actualValues[index].where((value) => value != null).length;
  }

  Future<_SetEffortResult?> _askSetEffort({required bool isTimed}) async {
    var extraWeightText = '0';
    var bodyWeightText = _lastBodyWeightKg.toStringAsFixed(1);

    final selected = await showModalBottomSheet<_SetEffortResult>(
      isScrollControlled: true,
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        side: BorderSide(color: AppColors.borderSubtle, width: 1.0),
      ),
      builder: (context) {
        var tempRir = _defaultRir;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0) +
                  EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTimed
                        ? 'Kac saniye daha durabilirdin?'
                        : 'Kac tekrar daha cikarabilirdin?',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _textHigh,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Wrap(
                    spacing: 8.0,
                    children: List.generate(isTimed ? 11 : 5, (rir) {
                      final isSelected = tempRir == rir;
                      return ChoiceChip(
                        label: Text('$rir'),
                        selected: isSelected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            tempRir = rir;
                          });
                        },
                        selectedColor: _accentVolcanic.withValues(alpha: 0.22),
                        backgroundColor: _cardSurfaceSoft,
                        checkmarkColor: _accentVolcanic,
                        side: BorderSide(
                          color: isSelected
                              ? _accentVolcanic
                              : AppColors.borderSubtle,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : _textMid,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12.0),
                  TextFormField(
                    initialValue: extraWeightText,
                    onChanged: (value) {
                      extraWeightText = value;
                    },
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Ekstra agirlik (kg)',
                      hintText: '0',
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  TextFormField(
                    initialValue: bodyWeightText,
                    onChanged: (value) {
                      bodyWeightText = value;
                    },
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Vucut agirligi (kg)',
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: _textMid,
                          ),
                          child: const Text('Vazgec'),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            final extraWeight =
                                double.tryParse(
                                  extraWeightText.trim().replaceAll(',', '.'),
                                ) ??
                                0.0;
                            final bodyWeight = double.tryParse(
                              bodyWeightText.trim().replaceAll(',', '.'),
                            );

                            if (extraWeight < 0 ||
                                bodyWeight == null ||
                                bodyWeight <= 0) {
                              return;
                            }

                            Navigator.pop(
                              context,
                              _SetEffortResult(
                                rir: tempRir,
                                extraWeightKg: extraWeight,
                                bodyWeightKg: bodyWeight,
                              ),
                            );
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentVolcanic,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    return selected;
  }

  Future<void> _completeSet(CustomProgramDay day) async {
    if (day.exercises.isEmpty) {
      return;
    }

    if (_isWorkoutComplete(day)) {
      return;
    }

    final index = _currentExerciseIndex(day);
    final setIndex = _actualValues[index].indexWhere((value) => value == null);
    if (setIndex == -1) {
      return;
    }
    final activeExercise = day.exercises[index];
    final targetValue = activeExercise.value;
    final effort = await _askSetEffort(isTimed: activeExercise.isTimed);
    if (!mounted || effort == null) {
      return;
    }

    HapticFeedback.selectionClick();

    final exerciseDetail = _resolveExerciseDetail(activeExercise);
    final mliExercise = _buildMliExercise(activeExercise, exerciseDetail);
    final setLoad = calculateMuscleLoad(
      exercise: mliExercise,
      set: activeExercise.isTimed
          ? mli.WorkoutSet(
              reps: 0,
              rir: effort.rir,
              durationInSeconds: targetValue,
              extraWeightKg: effort.extraWeightKg,
              bodyWeightKg: effort.bodyWeightKg,
            )
          : mli.WorkoutSet(
              reps: targetValue,
              rir: effort.rir,
              extraWeightKg: effort.extraWeightKg,
              bodyWeightKg: effort.bodyWeightKg,
            ),
    );

    setState(() {
      _actualValues[index][setIndex] = targetValue;
      _actualRirs[index][setIndex] = effort.rir;
      _actualExtraWeights[index][setIndex] = effort.extraWeightKg;
      _actualBodyWeights[index][setIndex] = effort.bodyWeightKg;
      _lastBodyWeightKg = effort.bodyWeightKg;
      _lastSetLoadByMuscle = setLoad;
    });

    _recalculateWorkoutLoad(day);

    if (_isWorkoutComplete(day)) {
      _finishSession(day);
    } else {
      _startRestTimer();
    }
  }

  void _finishSession(CustomProgramDay day) {
    _workTimer?.cancel();
    _restTimer?.cancel();

    final totalSetsCount = _totalSets(day);
    final completedSetsCount = _completedSetCount();

    double totalLoad = _workoutLoadByMuscle.values.fold(
      0.0,
      (sum, val) => sum + val,
    );
    if (totalLoad <= 0) {
      final durationMinutes =
          _workElapsed.inSeconds > 0 ? _workElapsed.inSeconds / 60.0 : 1.0;
      totalLoad = durationMinutes * 100 * 1.25;
    }

    final Map<String, double> muscleLoad = Map<String, double>.from(
      _workoutLoadByMuscle,
    );
    if (muscleLoad.isEmpty) {
      muscleLoad['Genel'] = totalLoad;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.workoutSummary,
      (route) => false,
      arguments: WorkoutSummaryArgs(
        exerciseName: '${widget.args.programName} - ${day.name}',
        totalTime: _workElapsed,
        setsCompleted: completedSetsCount,
        totalSets: totalSetsCount,
        totalLoad: totalLoad,
        muscleLoad: muscleLoad,
        muscleRir: _workoutRirByMuscle,
      ),
    );
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restRemainingSeconds = _restDurationSeconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemainingSeconds <= 1) {
        timer.cancel();
        HapticFeedback.heavyImpact();
        setState(() {
          _restRemainingSeconds = 0;
        });
        return;
      }

      setState(() {
        _restRemainingSeconds -= 1;
      });
    });
  }

  void _stopRestTimer() {
    _restTimer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _restRemainingSeconds = 0;
    });
  }

  void _addRestSeconds(int seconds) {
    if (_restRemainingSeconds <= 0) {
      return;
    }
    setState(() {
      _restRemainingSeconds += seconds;
    });
  }

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minuteLabel = minutes.toString().padLeft(2, '0');
    final secondLabel = seconds.toString().padLeft(2, '0');
    return '$minuteLabel:$secondLabel';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _openRestSheet() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        side: BorderSide(color: AppColors.borderSubtle, width: 1.0),
      ),
      builder: (context) {
        var tempValue = _restDurationSeconds.toDouble();
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 28.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dinlenme suresi',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _textHigh,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    '${tempValue.toInt()} sn',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: _textMid),
                  ),
                  Slider(
                    value: tempValue,
                    min: 30.0,
                    max: 180.0,
                    divisions: 15,
                    activeColor: _accentVolcanic,
                    inactiveColor: AppColors.borderSubtle,
                    label: '${tempValue.toInt()} sn',
                    onChanged: (value) {
                      setModalState(() {
                        tempValue = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8.0),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(context, tempValue.toInt());
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentVolcanic,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                      ),
                      child: const Text('Dinlenmeyi baslat'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _restDurationSeconds = selected;
    });
    _startRestTimer();
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.args.day;
    final activeIndex = _currentExerciseIndex(day);
    final activeExercise = day.exercises.isEmpty
        ? null
        : day.exercises[activeIndex];
    final activeSet = activeExercise == null
        ? 0
        : (_completedForExercise(activeIndex) + 1).clamp(
            1,
            activeExercise.sets,
          );
    final isWorkoutDone = _isWorkoutComplete(day);
    final actionLabel = isWorkoutDone ? 'ANTRENMANI TAMAMLA' : 'COMPLETE SET';
    final targetLabel = activeExercise == null
        ? '-'
        : '${activeExercise.value} ${activeExercise.isTimed ? 'sn' : 'Reps'}';
    final nextLabel = activeExercise == null
        ? 'Egzersiz bulunamadi'
        : isWorkoutDone
            ? 'Antrenman Tamamlandi'
            : _restRemainingSeconds > 0
                ? 'Dinlenme ${_formatSeconds(_restRemainingSeconds)}'
                : activeExercise.exerciseName;
    final nextDetail = activeExercise == null
        ? ''
        : '${activeExercise.sets} set • ${activeExercise.isTimed ? '${activeExercise.value} sn' : '${activeExercise.value} tekrar'}';
    final restProgress = _restDurationSeconds == 0
        ? 0.0
        : (_restRemainingSeconds / _restDurationSeconds).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: _sessionPageBg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            children: [
              Row(
                children: [
                  _SessionTopIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: _cardSurface,
                      borderRadius: BorderRadius.circular(999.0),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10.0,
                          height: 10.0,
                          decoration: const BoxDecoration(
                            color: _accentVolcanic,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6.0),
                        Text(
                          _formatDuration(_workElapsed),
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                color: _sessionInk,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _SessionTopIconButton(
                    icon: Icons.settings,
                    onTap: _openRestSheet,
                  ),
                ],
              ),
              const SizedBox(height: 14.0),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const _SessionHeroCard(),
                      const SizedBox(height: 24.0),
                      Text(
                        activeExercise?.exerciseName ?? 'Workout',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: _sessionInk,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _SessionTagChip(
                            text: activeExercise == null
                                ? 'Set -'
                                : 'Set $activeSet of ${activeExercise.sets}',
                            background: _sessionSoft,
                            textColor: _sessionInk,
                            borderColor: AppColors.borderSubtle,
                          ),
                          const SizedBox(width: 8.0),
                          _SessionTagChip(
                            text: 'Target: $targetLabel',
                            background: _accentEmerald.withValues(alpha: 0.16),
                            textColor: AppColors.emeraldSoft,
                            borderColor: _accentEmerald.withValues(alpha: 0.45),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22.0),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: activeExercise == null
                              ? null
                              : isWorkoutDone
                                  ? () => _finishSession(day)
                                  : () => _completeSet(day),
                          icon: const Icon(Icons.check_circle_rounded),
                          label: Text(
                            actionLabel,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: _accentVolcanic,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22.0),
                            ),
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
                          color: _cardSurface,
                          borderRadius: BorderRadius.circular(20.0),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42.0,
                              height: 42.0,
                              decoration: const BoxDecoration(
                                color: _cardSurfaceSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: _accentVolcanic,
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
                                          color: _sessionMuted,
                                          letterSpacing: 1.0,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    nextLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: _sessionInk,
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  if (nextDetail.isNotEmpty)
                                    Text(
                                      nextDetail,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: _sessionMuted),
                                    ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16.0,
                              color: _textMid,
                            ),
                          ],
                        ),
                      ),
                      if (_lastSetLoadByMuscle.isNotEmpty) ...[
                        const SizedBox(height: 14.0),
                        _LastSetLoadCard(
                          loads: _lastSetLoadByMuscle,
                          indicatorForLoad: _lastSetIndicator,
                        ),
                      ],
                      if (_workoutLoadByMuscle.isNotEmpty) ...[
                        const SizedBox(height: 14.0),
                        _WorkoutLoadCard(
                          loads: _workoutLoadByMuscle,
                          feedbackForLoad: _feedbackForLoad,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_restRemainingSeconds > 0) ...[
                const SizedBox(height: 10.0),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999.0),
                  child: LinearProgressIndicator(
                    value: restProgress,
                    minHeight: 8.0,
                    backgroundColor: _cardSurfaceSoft,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      _accentVolcanic,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12.0),
              Row(
                children: [
                  Expanded(
                    child: _SessionActionPill(
                      label: _workPaused ? 'RESUME' : 'PAUSE',
                      icon: _workPaused
                          ? Icons.play_circle_fill_rounded
                          : Icons.pause_circle_filled_rounded,
                      backgroundColor: _sessionSoft,
                      foregroundColor: _sessionInk,
                      onPressed: _togglePause,
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  Expanded(
                    child: _SessionActionPill(
                      label: 'STOP',
                      icon: Icons.stop_circle_rounded,
                      backgroundColor: _accentVolcanic,
                      foregroundColor: Colors.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ],
              ),
              if (_restRemainingSeconds > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton(
                      onPressed: _stopRestTimer,
                      child: Text(
                        'Dinlenmeyi bitir',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: _accentVolcanic,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    TextButton(
                      onPressed: () => _addRestSeconds(30),
                      child: Text(
                        '+30 saniye',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: _accentBlue,
                              fontWeight: FontWeight.w700,
                            ),
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

class _SessionTopIconButton extends StatelessWidget {
  const _SessionTopIconButton({required this.icon, required this.onTap});

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
          color: _cardSurface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Icon(icon, color: _sessionInk, size: 19.0),
      ),
    );
  }
}

class _SessionHeroCard extends StatelessWidget {
  const _SessionHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 290.0,
      padding: const EdgeInsets.all(10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.0),
        border: Border.all(color: AppColors.border),
        gradient: const LinearGradient(
          colors: [_bgTop, _bgBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: const _SessionHeroFrame(
        imageFit: BoxFit.contain,
        imageAlignment: Alignment.center,
      ),
    );
  }
}

class _SessionHeroFrame extends StatelessWidget {
  const _SessionHeroFrame({
    required this.imageFit,
    required this.imageAlignment,
  });

  final BoxFit imageFit;
  final Alignment imageAlignment;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18.0),
        gradient: const LinearGradient(
          colors: [AppColors.surfaceSubtle, AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18.0),
        child: Image.asset(
          _sessionHeroImageAsset,
          fit: imageFit,
          alignment: imageAlignment,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.accessibility_new_rounded,
                size: 64.0,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SessionTagChip extends StatelessWidget {
  const _SessionTagChip({
    required this.text,
    required this.background,
    required this.textColor,
    this.borderColor,
  });

  final String text;
  final Color background;
  final Color textColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.0),
        border: borderColor != null ? Border.all(color: borderColor!) : null,
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

class _SessionActionPill extends StatelessWidget {
  const _SessionActionPill({
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999.0),
        ),
      ),
      icon: Icon(icon, size: 18.0),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
      ),
    );
  }
}

class _WorkoutLoadCard extends StatelessWidget {
  const _WorkoutLoadCard({required this.loads, required this.feedbackForLoad});

  final Map<String, double> loads;
  final String Function(double) feedbackForLoad;

  @override
  Widget build(BuildContext context) {
    final sorted = loads.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kas Yuk Sonucu',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _textHigh,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10.0),
          for (final entry in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _textHigh,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '${entry.value.round()} • ${feedbackForLoad(entry.value)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _accentVolcanic,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LastSetLoadCard extends StatelessWidget {
  const _LastSetLoadCard({required this.loads, required this.indicatorForLoad});

  final Map<String, double> loads;
  final String Function(double) indicatorForLoad;

  @override
  Widget build(BuildContext context) {
    final sorted = loads.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Set Impact',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: _textHigh,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10.0),
          for (final entry in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _textHigh,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    '+${entry.value.round()} (${indicatorForLoad(entry.value)})',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _accentEmerald,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _SetEffortResult {
  const _SetEffortResult({
    required this.rir,
    required this.extraWeightKg,
    required this.bodyWeightKg,
  });

  final int rir;
  final double extraWeightKg;
  final double bodyWeightKg;
}
