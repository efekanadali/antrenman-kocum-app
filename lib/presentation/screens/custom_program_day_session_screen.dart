// lib/presentation/screens/custom_program_day_session_screen.dart

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
  late final List<bool> _completed;

  @override
  void initState() {
    super.initState();
    _completed = List<bool>.filled(widget.args.day.exercises.length, false);
  }

  void _toggleExercise(int index) {
    setState(() {
      _completed[index] = !_completed[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.args.day;
    final total = day.exercises.length;
    final done = _completed.where((value) => value).length;
    final progress = total == 0 ? 0.0 : done / total;

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
              padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 120.0),
              children: [
                _ProgressHeader(
                  programName: widget.args.programName,
                  dayIndex: day.dayIndex,
                  completed: done,
                  total: total,
                  progress: progress,
                ),
                const SizedBox(height: 16.0),
                for (var i = 0; i < day.exercises.length; i++)
                  _ExerciseStepCard(
                    exercise: day.exercises[i],
                    index: i + 1,
                    completed: _completed[i],
                    onTap: () => _toggleExercise(i),
                  ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
          child: FilledButton.icon(
            onPressed: total > 0 && done == total
                ? () => Navigator.pop(context)
                : null,
            icon: const Icon(Icons.check_circle_rounded),
            label: const Text('Antrenmani Tamamla'),
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
            '$completed / $total hareket tamamlandi',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _textMid,
                ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseStepCard extends StatelessWidget {
  const _ExerciseStepCard({
    required this.exercise,
    required this.index,
    required this.completed,
    required this.onTap,
  });

  final CustomProgramExercise exercise;
  final int index;
  final bool completed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final detail = exercise.isTimed
        ? '${exercise.sets} set x ${exercise.value} sn'
        : '${exercise.sets} set x ${exercise.value} tekrar';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(18.0),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: _cardSurfaceSoft,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: completed
                  ? _accentBlue.withOpacity(0.6)
                  : Colors.white.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30.0,
                height: 30.0,
                decoration: BoxDecoration(
                  color: completed ? _accentBlue : _accentPurple,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$index',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white,
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
                    Text(
                      exercise.exerciseName,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: _textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      detail,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _textMid,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              Icon(
                completed
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: completed ? _accentBlue : _textMid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
