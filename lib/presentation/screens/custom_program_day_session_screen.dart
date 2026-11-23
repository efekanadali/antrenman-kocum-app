// lib/presentation/screens/custom_program_day_session_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/domain/models/exercise.dart' as domain;
import 'package:calisthenics_app/domain/models/mli_models.dart' as mli;
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/domain/services/exercise_mli_resolver.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';
import 'package:calisthenics_app/domain/services/recovery_calculator.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/screens/workout_summary_screen.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';

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
  Map<MuscleCompartment, double> _workoutCompartmentLoad =
      <MuscleCompartment, double>{};
  Map<MuscleCompartment, double> _workoutCompartmentRir =
      <MuscleCompartment, double>{};
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
                  loadKg: customExercise.loadKg,
                )
              : mli.WorkoutSet(
                  reps: actualValue,
                  rir: rir,
                  extraWeightKg: extraWeightKg,
                  bodyWeightKg: bodyWeightKg,
                  loadKg: customExercise.loadKg,
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
    final compartmentTotals = calculateWorkoutCompartmentLoad(entries);
    final compartmentRirs = calculateWorkoutCompartmentRir(entries);
    setState(() {
      _workoutLoadByMuscle = totals;
      _workoutRirByMuscle = rirs;
      _workoutCompartmentLoad = compartmentTotals;
      _workoutCompartmentRir = compartmentRirs;
    });
  }

  /// Seans boyunca bir bölgenin biriken yükü (bölge bazlı) – kalibre edilmiş
  /// tek eşik kaynağı: [evaluateMuscleLoad] (37.6 / 103.4).
  String _feedbackForLoad(double score) => evaluateMuscleLoad(score).label;

  /// Son setin bir bölgeye etkisi – aynı kalibre eşikler.
  String _lastSetIndicator(double score) => evaluateMuscleLoad(score).label;

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
      builder: (context) {
        var tempRir = _defaultRir;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding:
                  const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0) +
                  EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom,
                  ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTimed
                        ? 'Kaç saniye daha durabilirdin?'
                        : 'Kaç tekrar daha çıkarabilirdin?',
                    style: AppText.cardTitle,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    'Yedekte kalan tekrar (RIR)',
                    style: AppText.caption,
                  ),
                  const SizedBox(height: AppSpace.lg),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.sm,
                    children: List.generate(isTimed ? 11 : 5, (rir) {
                      final isSelected = tempRir == rir;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setModalState(() {
                            tempRir = rir;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.surfaceRaised,
                          ),
                          child: Text(
                            '$rir',
                            style: AppText.metricS.copyWith(
                              fontSize: 15,
                              color: isSelected
                                  ? AppColors.onAccent
                                  : AppColors.textMid,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpace.xl),
                  TextFormField(
                    initialValue: extraWeightText,
                    onChanged: (value) {
                      extraWeightText = value;
                    },
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Ekstra ağırlık (kg)',
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
                      labelText: 'Vücut ağırlığı (kg)',
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMid,
                          ),
                          child: const Text('Vazgeç'),
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
              loadKg: activeExercise.loadKg,
            )
          : mli.WorkoutSet(
              reps: targetValue,
              rir: effort.rir,
              extraWeightKg: effort.extraWeightKg,
              bodyWeightKg: effort.bodyWeightKg,
              loadKg: activeExercise.loadKg,
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
      final durationMinutes = _workElapsed.inSeconds > 0
          ? _workElapsed.inSeconds / 60.0
          : 1.0;
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
        compartmentLoad: _workoutCompartmentLoad,
        compartmentRir: _workoutCompartmentRir,
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
                  Text('Dinlenme süresi', style: AppText.cardTitle),
                  const SizedBox(height: AppSpace.sm),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${tempValue.toInt()}',
                          style: AppText.metricL,
                        ),
                        TextSpan(text: ' sn', style: AppText.unit),
                      ],
                    ),
                  ),
                  Slider(
                    value: tempValue,
                    min: 30.0,
                    max: 180.0,
                    divisions: 15,
                    activeColor: AppColors.textHigh,
                    inactiveColor: AppColors.hairlineStrong,
                    label: '${tempValue.toInt()} sn',
                    onChanged: (value) {
                      setModalState(() {
                        tempValue = value;
                      });
                    },
                  ),
                  const SizedBox(height: 8.0),
                  PrimaryButton(
                    label: 'Dinlenmeyi Başlat',
                    onPressed: () {
                      Navigator.pop(context, tempValue.toInt());
                    },
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

  static String _formatKg(double kg) =>
      kg == kg.roundToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);

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
    final actionLabel = isWorkoutDone ? 'Antrenmanı Tamamla' : 'Seti Tamamla';
    final targetLabel = activeExercise == null
        ? '—'
        : '${activeExercise.value} ${activeExercise.isTimed ? 'sn' : 'tekrar'}'
              '${activeExercise.loadKg != null ? ' · ${_formatKg(activeExercise.loadKg!)} kg' : ''}';
    final nextLabel = activeExercise == null
        ? 'Egzersiz bulunamadı'
        : isWorkoutDone
        ? 'Antrenman tamamlandı'
        : _restRemainingSeconds > 0
        ? 'Dinlenme ${_formatSeconds(_restRemainingSeconds)}'
        : activeExercise.exerciseName;
    final nextDetail = activeExercise == null
        ? ''
        : '${activeExercise.sets} set · ${activeExercise.isTimed ? '${activeExercise.value} sn' : '${activeExercise.value} tekrar'}';
    final restProgress = _restDurationSeconds == 0
        ? 0.0
        : (_restRemainingSeconds / _restDurationSeconds).clamp(0.0, 1.0);
    final activeWeights = activeExercise == null
        ? const <MuscleCompartment, double>{}
        : (_resolveExerciseDetail(activeExercise)?.compartmentWeights ??
              const <MuscleCompartment, double>{});

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.sm,
            AppSpace.page,
            AppSpace.lg,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  _SessionTopIconButton(
                    icon: Icons.close_rounded,
                    tooltip: 'Kapat',
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  StatusDot(
                    color: _workPaused ? AppColors.amber : AppColors.emerald,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    _formatDuration(_workElapsed),
                    style: AppText.metricS.copyWith(fontSize: 17),
                  ),
                  const Spacer(),
                  _SessionTopIconButton(
                    icon: Icons.timer_outlined,
                    tooltip: 'Dinlenme süresi',
                    onTap: _openRestSheet,
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SessionHeroCard(weights: activeWeights),
                      const SizedBox(height: AppSpace.xxl),
                      Text(
                        trUpper(
                          activeExercise == null
                              ? 'Set —'
                              : 'Set $activeSet / ${activeExercise.sets}',
                        ),
                        style: AppText.sectionLabel,
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(
                        activeExercise?.exerciseName ?? 'Antrenman',
                        style: AppText.pageTitle,
                      ),
                      const SizedBox(height: AppSpace.lg),
                      SegmentedBar(
                        value: activeExercise == null
                            ? 0
                            : _completedForExercise(activeIndex) /
                                  activeExercise.sets,
                        segments: activeExercise?.sets.clamp(1, 12) ?? 1,
                        height: 4,
                        gap: 4,
                        color: AppColors.textHigh,
                      ),
                      const SizedBox(height: AppSpace.xl),
                      IntrinsicHeight(
                        child: Row(
                          children: [
                            Expanded(
                              child: MetricValue(
                                value: targetLabel,
                                label: 'Hedef',
                                style: AppText.metricS.copyWith(fontSize: 17),
                              ),
                            ),
                            const Hairline.vertical(),
                            const SizedBox(width: AppSpace.lg),
                            Expanded(
                              child: MetricValue(
                                value: '${_completedSetCount()}',
                                unit: '/${_totalSets(day)}',
                                label: 'Toplam set',
                                style: AppText.metricS.copyWith(fontSize: 17),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      AppSurface(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpace.lg,
                          vertical: AppSpace.md + 2,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    trUpper('Sıradaki'),
                                    style: AppText.sectionLabel,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    nextLabel,
                                    style: AppText.body.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (nextDetail.isNotEmpty)
                                    Text(nextDetail, style: AppText.caption),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              size: 20,
                              color: AppColors.textMuted,
                            ),
                          ],
                        ),
                      ),
                      if (_lastSetLoadByMuscle.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.section),
                        _LastSetLoadCard(
                          loads: _lastSetLoadByMuscle,
                          indicatorForLoad: _lastSetIndicator,
                        ),
                      ],
                      if (_workoutLoadByMuscle.isNotEmpty) ...[
                        const SizedBox(height: AppSpace.section),
                        _WorkoutLoadCard(
                          loads: _workoutLoadByMuscle,
                          feedbackForLoad: _feedbackForLoad,
                        ),
                      ],
                      const SizedBox(height: AppSpace.lg),
                    ],
                  ),
                ),
              ),
              if (_restRemainingSeconds > 0) ...[
                const SizedBox(height: AppSpace.md),
                Row(
                  children: [
                    Text(
                      'Dinlenme',
                      style: AppText.caption.copyWith(color: AppColors.textMid),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Text(
                      _formatSeconds(_restRemainingSeconds),
                      style: AppText.metricS.copyWith(fontSize: 15),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => _addRestSeconds(30),
                      child: Text(
                        '+30 sn',
                        style: AppText.caption.copyWith(
                          color: AppColors.textHigh,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpace.lg),
                    GestureDetector(
                      onTap: _stopRestTimer,
                      child: Text(
                        'Bitir',
                        style: AppText.caption.copyWith(
                          color: AppColors.textHigh,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.sm),
                SegmentedBar(
                  value: restProgress.toDouble(),
                  segments: 30,
                  height: 4,
                  gap: 2,
                  color: AppColors.amber,
                ),
              ],
              const SizedBox(height: AppSpace.md),
              PrimaryButton(
                label: actionLabel,
                icon: Icons.check_rounded,
                onPressed: activeExercise == null
                    ? null
                    : isWorkoutDone
                    ? () => _finishSession(day)
                    : () => _completeSet(day),
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: _workPaused ? 'Devam Et' : 'Duraklat',
                      icon: _workPaused
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      expand: true,
                      onPressed: _togglePause,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: GhostButton(
                      label: 'Bitir',
                      icon: Icons.stop_rounded,
                      expand: true,
                      foregroundColor: AppColors.textMid,
                      onPressed: () => Navigator.pop(context),
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
  const _SessionTopIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      icon: Icon(icon, size: 20),
      color: AppColors.textHigh,
      style: IconButton.styleFrom(
        backgroundColor: AppColors.surface,
        fixedSize: const Size(40, 40),
        side: BorderSide(
          color: AppColors.hairlineStrong,
          width: AppSpace.hairline,
        ),
      ),
    );
  }
}

/// Aktif egzersizin çalıştırdığı kasların ön/arka haritası.
class _SessionHeroCard extends StatelessWidget {
  const _SessionHeroCard({required this.weights});

  final Map<MuscleCompartment, double> weights;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
      child: Center(
        child: weights.isEmpty
            ? SizedBox(
                height: 200,
                child: Icon(
                  Icons.accessibility_new_outlined,
                  size: 56,
                  color: AppColors.textMuted,
                ),
              )
            : AnatomicalMuscleMap(
                intensities: weights,
                height: 220,
                spacing: AppSpace.xxl,
              ),
      ),
    );
  }
}

/// Bölge anahtarlı yükleri ince barlarla listeler.
class _LoadList extends StatelessWidget {
  const _LoadList({
    required this.title,
    required this.loads,
    required this.valueLabel,
  });

  final String title;
  final Map<String, double> loads;
  final String Function(MapEntry<String, double>) valueLabel;

  @override
  Widget build(BuildContext context) {
    final sorted = loads.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final max = sorted.isEmpty ? 1.0 : sorted.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title,
          padding: const EdgeInsets.only(bottom: AppSpace.md),
        ),
        for (final (i, entry) in sorted.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.md),
          Row(
            children: [
              SizedBox(
                width: 72,
                child: Text(
                  regionFromKey(entry.key)?.label ?? entry.key,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: SegmentedBar(
                  value: max <= 0 ? 0 : entry.value / max,
                  segments: 16,
                  height: 3,
                  color: AppColors.textHigh,
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Text(
                valueLabel(entry),
                style: AppText.caption.copyWith(color: AppColors.textMid),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _WorkoutLoadCard extends StatelessWidget {
  const _WorkoutLoadCard({required this.loads, required this.feedbackForLoad});

  final Map<String, double> loads;
  final String Function(double) feedbackForLoad;

  @override
  Widget build(BuildContext context) {
    return _LoadList(
      title: 'Kas yük sonucu',
      loads: loads,
      valueLabel: (e) => '${e.value.round()} · ${feedbackForLoad(e.value)}',
    );
  }
}

class _LastSetLoadCard extends StatelessWidget {
  const _LastSetLoadCard({required this.loads, required this.indicatorForLoad});

  final Map<String, double> loads;
  final String Function(double) indicatorForLoad;

  @override
  Widget build(BuildContext context) {
    return _LoadList(
      title: 'Son set etkisi',
      loads: loads,
      valueLabel: (e) => '+${e.value.round()} · ${indicatorForLoad(e.value)}',
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
