// lib/presentation/screens/custom_program_day_session_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';

const Color _bgTop = Color(0xFF151028);
const Color _bgBottom = Color(0xFF0E0A1D);
const Color _cardSurface = Color(0xFF201836);
const Color _cardSurfaceSoft = Color(0xFF2A2048);
const Color _accentPurple = Color(0xFF6D5BFF);
const Color _accentBlue = Color(0xFF4FC3F7);
const Color _textHigh = Color(0xFFEDE9FF);
const Color _textMid = Color(0xFFB4A9D8);

class CustomProgramDaySessionArgs {
  const CustomProgramDaySessionArgs({
    required this.programName,
    required this.day,
  });

  final String programName;
  final CustomProgramDay day;
}

class CustomProgramDaySessionScreen extends StatefulWidget {
  const CustomProgramDaySessionScreen({super.key, required this.args});

  final CustomProgramDaySessionArgs args;

  @override
  State<CustomProgramDaySessionScreen> createState() =>
      _CustomProgramDaySessionScreenState();
}

class _CustomProgramDaySessionScreenState
    extends State<CustomProgramDaySessionScreen> {
  late final List<List<int?>> _actualValues;
  int _restDurationSeconds = 60;
  int _restRemainingSeconds = 0;
  Timer? _restTimer;

  @override
  void initState() {
    super.initState();
    _actualValues = widget.args.day.exercises
      .map((exercise) => List<int?>.filled(exercise.sets, null))
      .toList();
  }

  @override
  void dispose() {
    _restTimer?.cancel();
    super.dispose();
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

  void _completeSet(CustomProgramDay day) {
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
    final previousValue = _actualValues[index][setIndex];
    final targetValue = day.exercises[index].value;

    setState(() {
      _actualValues[index][setIndex] = targetValue;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${day.exercises[index].exerciseName} set tamamlandi',
        ),
        action: SnackBarAction(
          label: 'Geri al',
          onPressed: () {
            setState(() {
              _actualValues[index][setIndex] = previousValue;
            });
          },
        ),
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
    required int exerciseIndex,
    required int setIndex,
  }) async {
    final controller = TextEditingController(
      text: (_actualValues[exerciseIndex][setIndex] ?? exercise.value)
          .toString(),
    );

    final result = await showDialog<int?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Set duzenle'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: exercise.isTimed ? 'Saniye' : 'Tekrar',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: const Text('Iptal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, -1),
              child: const Text('Sil'),
            ),
            FilledButton(
              onPressed: () {
                final value = int.tryParse(controller.text.trim());
                if (value == null || value <= 0) {
                  Navigator.pop(context, null);
                  return;
                }
                Navigator.pop(context, value);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (!mounted || result == null) {
      return;
    }

    setState(() {
      if (result == -1) {
        _actualValues[exerciseIndex][setIndex] = null;
      } else {
        _actualValues[exerciseIndex][setIndex] = result;
      }
    });
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dinlenme bitti'),
          ),
        );
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

  String _formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    final minuteLabel = minutes.toString().padLeft(2, '0');
    final secondLabel = seconds.toString().padLeft(2, '0');
    return '$minuteLabel:$secondLabel';
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
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _textMid,
                        ),
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
    final totalSets = _totalSets(day);
    final completedSets = _completedSetCount();
    final progress = totalSets == 0 ? 0.0 : completedSets / totalSets;
    final activeIndex = _currentExerciseIndex(day);
    final activeExercise =
        day.exercises.isEmpty ? null : day.exercises[activeIndex];
    final nextExercise = day.exercises.length > activeIndex + 1
        ? day.exercises[activeIndex + 1]
        : null;

    return Scaffold(
      backgroundColor: _bgBottom,
      appBar: AppBar(
        title: Text(day.name),
        backgroundColor: _bgBottom,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_bgTop, _bgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 140.0),
              children: [
                _ProgressHeader(
                  programName: widget.args.programName,
                  dayIndex: day.dayIndex,
                  completed: completedSets,
                  total: totalSets,
                  progress: progress,
                ),
                const SizedBox(height: 16.0),
                if (activeExercise != null)
                  _ActiveExerciseCard(
                    exercise: activeExercise,
                    completedSets: _completedForExercise(activeIndex),
                  )
                else
                  _EmptyWorkoutCard(),
                if (activeExercise != null) ...[
                  const SizedBox(height: 16.0),
                  _SetPanel(
                    exercise: activeExercise,
                    exerciseIndex: activeIndex,
                    values: _actualValues[activeIndex],
                    onEdit: (setIndex) => _openSetEditor(
                      exercise: activeExercise,
                      exerciseIndex: activeIndex,
                      setIndex: setIndex,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Row(
                    children: [
                      _QuickAdjustButton(
                        label: '+1',
                        onTap: () => _applyQuickAdjust(day, 1),
                      ),
                      const SizedBox(width: 8.0),
                      _QuickAdjustButton(
                        label: '+2',
                        onTap: () => _applyQuickAdjust(day, 2),
                      ),
                      const SizedBox(width: 8.0),
                      _QuickAdjustButton(
                        label: '+5',
                        onTap: () => _applyQuickAdjust(day, 5),
                      ),
                    ],
                  ),
                ],
                if (nextExercise != null) ...[
                  const SizedBox(height: 14.0),
                  _NextUpCard(exercise: nextExercise),
                ],
                const SizedBox(height: 18.0),
                _ExerciseOverviewList(
                  exercises: day.exercises,
                  completedSets: List<int>.generate(
                    day.exercises.length,
                    (index) => _completedForExercise(index),
                  ),
                ),
              ],
            ),
          ),
          if (_restRemainingSeconds > 0)
            Positioned(
              left: 16.0,
              right: 16.0,
              bottom: 120.0,
              child: _RestOverlay(
                remaining: _formatSeconds(_restRemainingSeconds),
                onStop: _stopRestTimer,
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _isWorkoutComplete(day)
                          ? () => Navigator.pop(context)
                          : () => _completeSet(day),
                      icon: Icon(
                        _isWorkoutComplete(day)
                            ? Icons.check_circle_rounded
                            : Icons.check_rounded,
                      ),
                      label: Text(
                        _isWorkoutComplete(day)
                            ? 'Antrenmani Tamamla'
                            : 'Seti Tamamla',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12.0),
                  OutlinedButton(
                    onPressed: _openRestSheet,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textHigh,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: const Icon(Icons.timer_outlined),
                  ),
                  const SizedBox(width: 12.0),
                  OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Varyasyon yakinda eklenecek'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textHigh,
                      side: BorderSide(color: Colors.white.withOpacity(0.2)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 14.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                    ),
                    child: const Icon(Icons.tune_rounded),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _textMid,
                ),
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _textMid,
                ),
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _textMid,
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
          _ExerciseMiniRow(
            exercise: exercises[i],
            completed: completedSets[i],
          ),
      ],
    );
  }
}

class _ExerciseMiniRow extends StatelessWidget {
  const _ExerciseMiniRow({
    required this.exercise,
    required this.completed,
  });

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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: _textMid,
                      ),
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
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: _textMid,
            ),
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
          TextButton(
            onPressed: onStop,
            child: const Text('Bitir'),
          ),
        ],
      ),
    );
  }
}
