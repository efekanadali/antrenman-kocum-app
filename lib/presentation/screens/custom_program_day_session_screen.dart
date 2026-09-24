// lib/presentation/screens/custom_program_day_session_screen.dart

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';
import 'package:calisthenics_app/domain/enums/difficulty_level.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/domain/models/exercise.dart' as domain;
import 'package:calisthenics_app/domain/models/exercise_database.dart'
    as library_data;
import 'package:calisthenics_app/domain/models/mli_models.dart' as mli;
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/screens/workout_summary_screen.dart';

const Color _bgTop = Color(0xFF1A1230);
const Color _bgBottom = Color(0xFF120A22);
const Color _cardSurface = Color(0xFF231A3B);
const Color _cardSurfaceSoft = Color(0xFF2A2048);
const Color _accentPurple = Color(0xFFC2F13A);
const Color _accentBlue = Color(0xFF4FC3F7);
const Color _textHigh = Color(0xFFEDE9FF);
const Color _textMid = Color(0xFFC1B8E0);
const Color _sessionPageBg = _bgBottom;
const Color _sessionInk = _textHigh;
const Color _sessionSoft = _cardSurfaceSoft;
const Color _sessionMuted = _textMid;
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
  final Map<String, domain.Exercise> _exerciseById =
      <String, domain.Exercise>{};
  final Map<String, domain.Exercise> _exerciseByName =
      <String, domain.Exercise>{};
  final Map<String, domain.Exercise> _exerciseByNormalizedName =
      <String, domain.Exercise>{};
  final Map<String, mli.Exercise> _libraryExerciseByNormalizedName =
      <String, mli.Exercise>{};
  final Set<String> _loggedFallbackExercises = <String>{};
  bool _exerciseDetailsLoaded = false;
  Map<String, double> _lastSetLoadByMuscle = <String, double>{};
  Map<String, double> _workoutLoadByMuscle = <String, double>{};
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
    for (final entry in library_data.exerciseDatabase.entries) {
      final exercise = entry.value;
      _libraryExerciseByNormalizedName[_normalizeExerciseName(entry.key)] =
          exercise;
      _libraryExerciseByNormalizedName[_normalizeExerciseName(exercise.name)] =
          exercise;
    }
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
      _exerciseById
        ..clear()
        ..addEntries(allExercises.map((item) => MapEntry(item.id, item)));
      _exerciseByName
        ..clear()
        ..addEntries(allExercises.map((item) => MapEntry(item.name, item)));
      _exerciseByNormalizedName
        ..clear()
        ..addEntries(
          allExercises.map(
            (item) => MapEntry(_normalizeExerciseName(item.name), item),
          ),
        );
      _exerciseDetailsLoaded = true;
    });

    _recalculateWorkoutLoad(widget.args.day);
  }

  String _normalizeExerciseName(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  domain.Exercise? _resolveExerciseDetail(CustomProgramExercise exercise) {
    return _exerciseById[exercise.exerciseId] ??
        _exerciseByName[exercise.exerciseName] ??
        _exerciseByNormalizedName[_normalizeExerciseName(
          exercise.exerciseName,
        )];
  }

  mli.Exercise? _resolveLibraryExercise(CustomProgramExercise exercise) {
    return library_data.exerciseDatabase[exercise.exerciseId] ??
        _libraryExerciseByNormalizedName[_normalizeExerciseName(
          exercise.exerciseId,
        )] ??
        _libraryExerciseByNormalizedName[_normalizeExerciseName(
          exercise.exerciseName,
        )];
  }

  void _logFallbackOnce(CustomProgramExercise source, String strategy) {
    if (!kDebugMode) {
      return;
    }

    final key = '${source.exerciseId}|${source.exerciseName}|$strategy';
    if (_loggedFallbackExercises.add(key)) {
      debugPrint(
        '[MLI-Fallback] strategy=$strategy id=${source.exerciseId} name=${source.exerciseName}',
      );
    }
  }

  mli.Exercise _inferExerciseFromName(CustomProgramExercise source) {
    final normalized = _normalizeExerciseName(source.exerciseName);

    if (normalized.contains('push') || normalized.contains('dip')) {
      return mli.Exercise(
        name: source.exerciseName,
        difficulty: 1.0,
        muscles: {
          'chest': 0.45,
          'shoulders': 0.25,
          'triceps': 0.25,
          'core': 0.05,
        },
      );
    }

    if (normalized.contains('pull') ||
        normalized.contains('row') ||
        normalized.contains('chin') ||
        normalized.contains('lever')) {
      return mli.Exercise(
        name: source.exerciseName,
        difficulty: 1.0,
        muscles: {'back': 0.5, 'biceps': 0.25, 'shoulders': 0.15, 'core': 0.1},
      );
    }

    if (normalized.contains('squat') ||
        normalized.contains('lunge') ||
        normalized.contains('pistol') ||
        normalized.contains('shrimp') ||
        normalized.contains('jump') ||
        normalized.contains('calf') ||
        normalized.contains('bridge') ||
        normalized.contains('curl')) {
      return mli.Exercise(
        name: source.exerciseName,
        difficulty: 1.0,
        muscles: {
          'quads': 0.35,
          'hamstrings': 0.2,
          'glutes': 0.3,
          'calves': 0.15,
        },
      );
    }

    return mli.Exercise(
      name: source.exerciseName,
      difficulty: 1.0,
      muscles: {'core': 0.7, 'shoulders': 0.2, 'back': 0.1},
    );
  }

  mli.Exercise _buildMliExercise(
    CustomProgramExercise source,
    domain.Exercise? exerciseDetail,
  ) {
    if (exerciseDetail != null) {
      return _toMliExercise(source, exerciseDetail);
    }

    final libraryExercise = _resolveLibraryExercise(source);
    if (libraryExercise != null) {
      _logFallbackOnce(source, 'library-match');
      return mli.Exercise(
        name: source.exerciseName,
        difficulty: libraryExercise.difficulty,
        muscles: libraryExercise.muscles,
      );
    }

    _logFallbackOnce(source, 'name-inference');
    return _inferExerciseFromName(source);
  }

  double _difficultyCoefficient(domain.Exercise? exerciseDetail) {
    if (exerciseDetail == null) {
      return 1.0;
    }

    switch (exerciseDetail.difficulty) {
      case DifficultyLevel.easy:
        return 1.0;
      case DifficultyLevel.medium:
        return 1.25;
      case DifficultyLevel.hard:
        return 1.5;
    }
  }

  mli.Exercise _toMliExercise(
    CustomProgramExercise source,
    domain.Exercise? exerciseDetail,
  ) {
    final muscles = <String, double>{};

    if (exerciseDetail != null && exerciseDetail.muscleRatings.isNotEmpty) {
      final total = exerciseDetail.muscleRatings.values
          .fold<int>(0, (sum, value) => sum + value)
          .toDouble();

      exerciseDetail.muscleRatings.forEach((group, rating) {
        muscles[group.label] = total == 0 ? 0 : rating / total;
      });
    } else if (exerciseDetail != null &&
        exerciseDetail.targetMuscleGroups.isNotEmpty) {
      final weight = 1 / exerciseDetail.targetMuscleGroups.length;
      for (final group in exerciseDetail.targetMuscleGroups) {
        muscles[group.label] = weight;
      }
    }

    return mli.Exercise(
      name: source.exerciseName,
      difficulty: _difficultyCoefficient(exerciseDetail),
      muscles: muscles,
    );
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
    setState(() {
      _workoutLoadByMuscle = totals;
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

  Future<void> _skipCurrentExercise(CustomProgramDay day) async {
    if (day.exercises.isEmpty || _isWorkoutComplete(day)) {
      return;
    }

    final index = _currentExerciseIndex(day);
    final exercise = day.exercises[index];

    final effort = await _askSetEffort(isTimed: exercise.isTimed);
    if (!mounted || effort == null) {
      return;
    }

    setState(() {
      for (var i = 0; i < _actualValues[index].length; i++) {
        _actualValues[index][i] ??= exercise.value;
        _actualRirs[index][i] ??= effort.rir;
        _actualExtraWeights[index][i] ??= effort.extraWeightKg;
        _actualBodyWeights[index][i] ??= effort.bodyWeightKg;
      }
      _lastBodyWeightKg = effort.bodyWeightKg;
    });

    _recalculateWorkoutLoad(day);
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
      context: context,
      backgroundColor: _cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        var tempRir = _defaultRir;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 20.0),
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
                      return ChoiceChip(
                        label: Text('$rir'),
                        selected: tempRir == rir,
                        onSelected: (_) {
                          setModalState(() {
                            tempRir = rir;
                          });
                        },
                        selectedColor: _accentPurple.withOpacity(0.35),
                        backgroundColor: _cardSurfaceSoft,
                        labelStyle: TextStyle(
                          color: tempRir == rir ? _textHigh : _textMid,
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
                            backgroundColor: _accentPurple,
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
        exerciseName:
            '${widget.args.programName} - ${day.name}',
        totalTime: _workElapsed,
        setsCompleted: completedSetsCount,
        totalSets: totalSetsCount,
        totalLoad: totalLoad,
        muscleLoad: muscleLoad,
      ),
    );
  }

  void _applyQuickAdjust(CustomProgramDay day, int delta) {
    if (day.exercises.isEmpty) {
      return;
    }
    final index = _currentExerciseIndex(day);
    final values = _actualValues[index];
    var targetIndex = values.lastIndexWhere((value) => value != null);
    if (targetIndex == -1) {
      targetIndex = values.indexWhere((value) => value == null);
      if (targetIndex == -1) {
        return;
      }
      values[targetIndex] = day.exercises[index].value;
    }

    setState(() {
      final current = values[targetIndex] ?? day.exercises[index].value;
      values[targetIndex] = (current + delta).clamp(1, 999);
    });
  }

  Future<void> _openSetEditor({
    required CustomProgramExercise exercise,
    required CustomProgramDay day,
    required int exerciseIndex,
    required int setIndex,
  }) async {
    final repsController = TextEditingController(
      text: (_actualValues[exerciseIndex][setIndex] ?? exercise.value)
          .toString(),
    );
    final rirController = TextEditingController(
      text: (_actualRirs[exerciseIndex][setIndex] ?? _defaultRir).toString(),
    );
    final extraWeightController = TextEditingController(
      text: (_actualExtraWeights[exerciseIndex][setIndex] ?? 0.0)
          .toStringAsFixed(1),
    );
    final bodyWeightController = TextEditingController(
      text: (_actualBodyWeights[exerciseIndex][setIndex] ?? _lastBodyWeightKg)
          .toStringAsFixed(1),
    );

    final result = await showDialog<_SetEditorResult?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set duzenle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: exercise.isTimed ? 'Saniye' : 'Tekrar',
                ),
              ),
              const SizedBox(height: 10.0),
              TextField(
                controller: rirController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'RIR'),
              ),
              const SizedBox(height: 10.0),
              TextField(
                controller: extraWeightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Ekstra agirlik (kg)',
                ),
              ),
              const SizedBox(height: 10.0),
              TextField(
                controller: bodyWeightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Vucut agirligi (kg)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Iptal'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, const _SetEditorResult.delete()),
              child: const Text('Sil'),
            ),
            FilledButton(
              onPressed: () {
                final reps = int.tryParse(repsController.text.trim());
                final rir = int.tryParse(rirController.text.trim());
                final extraWeight =
                    double.tryParse(
                      extraWeightController.text.trim().replaceAll(',', '.'),
                    ) ??
                    0.0;
                final bodyWeight = double.tryParse(
                  bodyWeightController.text.trim().replaceAll(',', '.'),
                );

                if (reps == null ||
                    reps <= 0 ||
                    rir == null ||
                    rir < 0 ||
                    extraWeight < 0 ||
                    bodyWeight == null ||
                    bodyWeight <= 0) {
                  Navigator.pop(context, null);
                  return;
                }

                Navigator.pop(
                  context,
                  _SetEditorResult(
                    reps: reps,
                    rir: rir,
                    extraWeightKg: extraWeight,
                    bodyWeightKg: bodyWeight,
                  ),
                );
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    repsController.dispose();
    rirController.dispose();
    extraWeightController.dispose();
    bodyWeightController.dispose();

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      if (result.delete) {
        _actualValues[exerciseIndex][setIndex] = null;
        _actualRirs[exerciseIndex][setIndex] = null;
        _actualExtraWeights[exerciseIndex][setIndex] = null;
        _actualBodyWeights[exerciseIndex][setIndex] = null;
      } else {
        _actualValues[exerciseIndex][setIndex] = result.reps;
        _actualRirs[exerciseIndex][setIndex] = result.rir;
        _actualExtraWeights[exerciseIndex][setIndex] = result.extraWeightKg;
        _actualBodyWeights[exerciseIndex][setIndex] = result.bodyWeightKg;
        _lastBodyWeightKg = result.bodyWeightKg;
      }
    });

    _recalculateWorkoutLoad(day);
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    setState(() {
      _restRemainingSeconds = _restDurationSeconds;
    });

    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_restRemainingSeconds <= 1) {
        timer.cancel();
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

  int _timePart(Duration duration, String unit) {
    switch (unit) {
      case 'hour':
        return duration.inHours;
      case 'minute':
        return duration.inMinutes.remainder(60);
      case 'second':
        return duration.inSeconds.remainder(60);
      default:
        return 0;
    }
  }

  Future<void> _openRestSheet() async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: _cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
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
                        backgroundColor: _accentPurple,
                        foregroundColor: const Color(0xFF1A132E),
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
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10.0,
                          height: 10.0,
                          decoration: const BoxDecoration(
                            color: _accentPurple,
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
                          ),
                          const SizedBox(width: 8.0),
                          _SessionTagChip(
                            text: 'Target: $targetLabel',
                            background: _accentPurple,
                            textColor: _sessionInk,
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
                            backgroundColor: _accentPurple,
                            foregroundColor: _sessionInk,
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
                          border: Border.all(color: Colors.white.withOpacity(0.12)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42.0,
                              height: 42.0,
                              decoration: BoxDecoration(
                                color: _cardSurfaceSoft,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: _accentBlue,
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
                    valueColor: const AlwaysStoppedAnimation<Color>(_accentPurple),
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
                      backgroundColor: _accentPurple,
                      foregroundColor: _sessionInk,
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
                              color: _accentBlue,
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
          border: Border.all(color: Colors.white.withOpacity(0.12)),
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
          colors: [Color(0xFF2C3144), Color(0xFF181C2A)],
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
                color: Colors.white.withOpacity(0.9),
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
  });

  final String text;
  final Color background;
  final Color textColor;

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

class _TimeUnitCard extends StatelessWidget {
  const _TimeUnitCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: _textHigh,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _textMid,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionInfoTile extends StatelessWidget {
  const _SessionInfoTile({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _textMid,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _textHigh,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseInsightCard extends StatelessWidget {
  const _ExerciseInsightCard({
    required this.description,
    required this.muscleLabels,
  });

  final String description;
  final List<String> muscleLabels;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hareket Aciklamasi',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _textMid,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: _textHigh, height: 1.35),
          ),
          const SizedBox(height: 12.0),
          Text(
            'Calistirdigi Bolgeler',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _textMid,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8.0),
          if (muscleLabels.isEmpty)
            Text(
              'Bolge bilgisi bulunamadi.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: _textMid),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                for (final label in muscleLabels)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 6.0,
                    ),
                    decoration: BoxDecoration(
                      color: _cardSurfaceSoft,
                      borderRadius: BorderRadius.circular(999.0),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _accentBlue,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
        ],
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
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                      color: _accentBlue,
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
        border: Border.all(color: Colors.white.withOpacity(0.1)),
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
                      color: _accentBlue,
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

class _SetEditorResult {
  const _SetEditorResult({
    required this.reps,
    required this.rir,
    required this.extraWeightKg,
    required this.bodyWeightKg,
  }) : delete = false;

  const _SetEditorResult.delete()
    : reps = 0,
      rir = 0,
      extraWeightKg = 0,
      bodyWeightKg = 0,
      delete = true;

  final int reps;
  final int rir;
  final double extraWeightKg;
  final double bodyWeightKg;
  final bool delete;
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

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.programName,
    required this.dayIndex,
    required this.completed,
    required this.total,
    required this.progress,
  });

  final String programName;
  final int dayIndex;
  final int completed;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.0),
        color: _cardSurface,
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            programName,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _textMid,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Gun $dayIndex',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _textHigh,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(10.0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8.0,
              backgroundColor: _cardSurfaceSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(_accentBlue),
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            '$completed / $total set tamamlandi',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _textMid),
          ),
        ],
      ),
    );
  }
}

class _ActiveExerciseCard extends StatelessWidget {
  const _ActiveExerciseCard({
    required this.exercise,
    required this.completedSets,
  });

  final CustomProgramExercise exercise;
  final int completedSets;

  @override
  Widget build(BuildContext context) {
    final detail = exercise.isTimed
        ? '${exercise.sets} set x ${exercise.value} sn'
        : '${exercise.sets} set x ${exercise.value} tekrar';

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 16.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aktif Egzersiz',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: _textMid,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            exercise.exerciseName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: _textHigh,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'Hedef: $detail',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: _textMid),
          ),
          const SizedBox(height: 12.0),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tamamlanan set: $completedSets / ${exercise.sets}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: _accentPurple.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  exercise.isTimed ? 'Sure' : 'Set-rep',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _accentPurple,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NextUpCard extends StatelessWidget {
  const _NextUpCard({required this.exercise});

  final CustomProgramExercise exercise;

  @override
  Widget build(BuildContext context) {
    final detail = exercise.isTimed
        ? '${exercise.sets} set x ${exercise.value} sn'
        : '${exercise.sets} set x ${exercise.value} tekrar';

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: _cardSurfaceSoft,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          const Icon(Icons.arrow_forward_rounded, color: _accentBlue),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sonraki',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _textMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  exercise.exerciseName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: _textHigh,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  detail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _textMid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseOverviewList extends StatelessWidget {
  const _ExerciseOverviewList({
    required this.exercises,
    required this.completedSets,
  });

  final List<CustomProgramExercise> exercises;
  final List<int> completedSets;

  @override
  Widget build(BuildContext context) {
    if (exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Egzersiz Listesi',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: _textHigh,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10.0),
        for (var i = 0; i < exercises.length; i++)
          _ExerciseMiniRow(exercise: exercises[i], completed: completedSets[i]),
      ],
    );
  }
}

class _ExerciseMiniRow extends StatelessWidget {
  const _ExerciseMiniRow({required this.exercise, required this.completed});

  final CustomProgramExercise exercise;
  final int completed;

  @override
  Widget build(BuildContext context) {
    final detail = exercise.isTimed
        ? '${exercise.sets} set x ${exercise.value} sn'
        : '${exercise.sets} set x ${exercise.value} tekrar';
    final isDone = completed >= exercise.sets;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: isDone ? _accentBlue : _textMid,
            size: 18.0,
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  detail,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: _textMid),
                ),
              ],
            ),
          ),
          Text(
            '$completed/${exercise.sets}',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: _textMid,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyWorkoutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Text(
        'Bu gun icin egzersiz yok.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: _textMid),
      ),
    );
  }
}

class _SetPanel extends StatelessWidget {
  const _SetPanel({
    required this.exercise,
    required this.exerciseIndex,
    required this.values,
    required this.onEdit,
  });

  final CustomProgramExercise exercise;
  final int exerciseIndex;
  final List<int?> values;
  final ValueChanged<int> onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: _cardSurfaceSoft,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set Paneli',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: _textHigh,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: List.generate(exercise.sets, (index) {
              final value = values[index];
              final label = value == null
                  ? 'Set ${index + 1}'
                  : '${value}${exercise.isTimed ? ' sn' : ''}';
              return InkWell(
                onTap: () => onEdit(index),
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: value == null
                        ? _cardSurface
                        : _accentBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: value == null
                          ? Colors.white.withOpacity(0.08)
                          : _accentBlue.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: value == null ? _textMid : _accentBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _QuickAdjustButton extends StatelessWidget {
  const _QuickAdjustButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: _textHigh,
          side: BorderSide(color: Colors.white.withOpacity(0.2)),
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _RestOverlay extends StatelessWidget {
  const _RestOverlay({required this.remaining, required this.onStop});

  final String remaining;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: _cardSurface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16.0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.timer_rounded, color: _accentBlue),
          const SizedBox(width: 10.0),
          Expanded(
            child: Text(
              'Dinlenme: $remaining',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _textHigh,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(onPressed: onStop, child: const Text('Bitir')),
        ],
      ),
    );
  }
}
