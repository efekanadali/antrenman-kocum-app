// lib/presentation/screens/custom_plan_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/core/utils/exercise_unit.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/providers/custom_program_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';

class CustomPlanScreen extends ConsumerStatefulWidget {
  const CustomPlanScreen({super.key});

  static const Color _bgTop = Color(0xFF151028);
  static const Color _bgBottom = Color(0xFF0E0A1D);
  static const Color _cardSurface = Color(0xFF201836);
  static const Color _accentPurple = Color(0xFF6D5BFF);
  static const Color _accentBlue = Color(0xFF4FC3F7);
  static const Color _textHigh = Color(0xFFEDE9FF);
  static const Color _textMid = Color(0xFFB4A9D8);

  @override
  ConsumerState<CustomPlanScreen> createState() => _CustomPlanScreenState();
}

class _CustomPlanScreenState extends ConsumerState<CustomPlanScreen> {
  int? _daysCount;
  final List<_DraftDay> _days = [];
  final TextEditingController _nameController =
      TextEditingController(text: 'Senin Programın');

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _startProgramFlow() async {
    final selected = await showDialog<int>(
      context: context,
      builder: (context) {
        int temp = _daysCount ?? 3;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return _GlassCard(
                borderRadius: 24.0,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kaç gün antrenman yapacaksın?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: CustomPlanScreen._textHigh,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        'Haftalık planını belirle.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: CustomPlanScreen._textMid,
                            ),
                      ),
                      const SizedBox(height: 14.0),
                      Wrap(
                        spacing: 10.0,
                        runSpacing: 10.0,
                        children: List.generate(7, (index) {
                          final day = index + 1;
                          final selected = temp == day;
                          return InkWell(
                            onTap: () {
                              setDialogState(() {
                                temp = day;
                              });
                            },
                            borderRadius: BorderRadius.circular(14.0),
                            child: Container(
                              width: 72.0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              decoration: BoxDecoration(
                                color: selected
                                    ? CustomPlanScreen._accentPurple
                                        .withOpacity(0.3)
                                    : CustomPlanScreen._cardSurface
                                        .withOpacity(0.6),
                                borderRadius: BorderRadius.circular(14.0),
                                border: Border.all(
                                  color: selected
                                      ? CustomPlanScreen._accentPurple
                                      : Colors.white.withOpacity(0.1),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '$day',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: CustomPlanScreen._textHigh,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    'Gün',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: CustomPlanScreen._textMid,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Vazgeç'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(temp),
                            style: FilledButton.styleFrom(
                              backgroundColor: CustomPlanScreen._accentPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Devam et'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _daysCount = selected;
      _days
        ..clear()
        ..addAll(
          List.generate(selected, (index) => _DraftDay(dayIndex: index + 1)),
        );
    });
  }

  Future<void> _addExercise(int dayIndex, List<Exercise> exercises) async {
    if (exercises.isEmpty) {
      return;
    }
    Exercise? selected;
    selected = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return _ExercisePickerSheet(exercises: exercises);
      },
    );

    if (selected == null) {
      return;
    }

    final chosen = selected;

    if (!mounted) {
      return;
    }

    await Future<void>.delayed(const Duration(milliseconds: 150));

    final isTimed = isTimedExercise(
      exerciseId: chosen.id,
      exerciseName: chosen.name,
    );

    final config = await _promptSetRep(isTimed: isTimed);
    if (config == null) {
      return;
    }

    setState(() {
      final day = _days.firstWhere((item) => item.dayIndex == dayIndex);
      day.exercises.add(
        _DraftExercise(
          exerciseId: chosen.id,
          exerciseName: chosen.name,
          sets: config.sets,
          value: config.value,
          isTimed: config.isTimed,
        ),
      );
    });
  }

  Future<_SetRepConfig?> _promptSetRep({required bool isTimed}) async {
    final result = await showDialog<_SetRepConfig>(
      context: context,
      builder: (context) {
        int sets = 3;
        int targetValue = isTimed ? 30 : 10;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              int minTarget() => isTimed ? 10 : 3;
              int maxTarget() => isTimed ? 300 : 100;
              if (sets < 1) {
                sets = 1;
              }
              if (sets > 6) {
                sets = 6;
              }
              if (targetValue < minTarget()) {
                targetValue = minTarget();
              }
              if (targetValue > maxTarget()) {
                targetValue = maxTarget();
              }
              return _GlassCard(
                borderRadius: 24.0,
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Set ve hedef',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: CustomPlanScreen._textHigh,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        isTimed
                            ? 'Bu hareket sure bazli. Hedef saniyeyi belirle.'
                            : 'Bu hareket tekrar bazli. Hedef tekrari belirle.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: CustomPlanScreen._textMid,
                            ),
                      ),
                      const SizedBox(height: 12.0),
                      Row(
                        children: [
                          Expanded(
                            child: _StepperField(
                              label: 'Set',
                              value: sets,
                              minValue: 1,
                              maxValue: 6,
                              onChanged: (value) {
                                setDialogState(() {
                                  sets = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Expanded(
                            child: _StepperField(
                              label: isTimed ? 'Saniye' : 'Tekrar',
                              value: targetValue,
                              minValue: minTarget(),
                              maxValue: maxTarget(),
                              onChanged: (next) {
                                setDialogState(() {
                                  targetValue = next;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Vazgeç'),
                          ),
                          const Spacer(),
                          FilledButton(
                            onPressed: () {
                              if (sets < 1 || targetValue < minTarget()) {
                                return;
                              }
                              Navigator.of(context)
                                  .pop(_SetRepConfig(sets, targetValue, isTimed));
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: CustomPlanScreen._accentPurple,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Ekle'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
    return result;
  }

  void _removeExercise(int dayIndex, int exerciseIndex) {
    setState(() {
      final day = _days.firstWhere((item) => item.dayIndex == dayIndex);
      day.exercises.removeAt(exerciseIndex);
    });
  }

  Future<void> _saveProgram() async {
    if (_daysCount == null) {
      return;
    }

    final totalExercises = _days.fold<int>(
      0,
      (sum, day) => sum + day.exercises.length,
    );

    if (totalExercises == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce egzersiz ekle.')),
      );
      return;
    }

    final program = CustomProgram(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim().isEmpty
          ? 'Senin Programın'
          : _nameController.text.trim(),
      daysCount: _daysCount!,
      days: _days
          .map(
            (day) => CustomProgramDay(
              dayIndex: day.dayIndex,
              name: day.nameController.text.trim().isEmpty
                  ? 'Gün ${day.dayIndex}'
                  : day.nameController.text.trim(),
              exercises: day.exercises
                  .map(
                    (exercise) => CustomProgramExercise(
                      exerciseId: exercise.exerciseId,
                      exerciseName: exercise.exerciseName,
                      sets: exercise.sets,
                      value: exercise.value,
                      isTimed: exercise.isTimed,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
      createdAt: DateTime.now(),
    );

    await ref.read(customProgramProvider.notifier).addProgram(program);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Program kaydedildi.')),
    );

    if (!mounted) {
      return;
    }

    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.stats,
      (route) => false,
    );

    setState(() {
      _daysCount = null;
      for (final day in _days) {
        day.dispose();
      }
      _days.clear();
      _nameController.text = 'Senin Programın';
    });
  }

  @override
  Widget build(BuildContext context) {
    final exerciseRepository = ref.watch(exerciseRepositoryProvider);

    return Scaffold(
      backgroundColor: CustomPlanScreen._bgBottom,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CustomPlanScreen._bgTop,
                  CustomPlanScreen._bgBottom,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -110.0,
            right: -60.0,
            child: Container(
              width: 220.0,
              height: 220.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CustomPlanScreen._accentPurple.withOpacity(0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -110.0,
            left: -60.0,
            child: Container(
              width: 220.0,
              height: 220.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CustomPlanScreen._accentBlue.withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                              color: CustomPlanScreen._textHigh,
                            ),
                            const SizedBox(width: 6.0),
                            Text(
                              'Senin Planın',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: CustomPlanScreen._textHigh,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Programını oluştur, egzersiz ekle ve kaydet.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: CustomPlanScreen._textMid,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: _GlassCard(
                      borderRadius: 22.0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Program adı',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color: CustomPlanScreen._textHigh,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            const SizedBox(height: 8.0),
                            TextField(
                              controller: _nameController,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Örn: Tüm Vücut 3 Gün',
                                hintStyle: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: CustomPlanScreen._textMid,
                                    ),
                                filled: true,
                                fillColor:
                                    CustomPlanScreen._cardSurface.withOpacity(0.6),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.08),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12.0),
                            Text(
                              _daysCount == null
                                  ? 'Henüz gün seçilmedi'
                                  : '$_daysCount günlük plan',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: CustomPlanScreen._textMid),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16.0),
                ),
                if (_daysCount == null)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverToBoxAdapter(
                      child: _GlassCard(
                        borderRadius: 22.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Başlangıç rehberi',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: CustomPlanScreen._textHigh,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 10.0),
                              const _StepItem(
                                index: '01',
                                title: 'Gün sayısını seç',
                                subtitle: 'Haftalık 1-7 gün arası plan kur.',
                              ),
                              const SizedBox(height: 10.0),
                              const _StepItem(
                                index: '02',
                                title: 'Egzersizleri ekle',
                                subtitle:
                                    'Her gün için antrenmanını oluştur.',
                              ),
                              const SizedBox(height: 10.0),
                              const _StepItem(
                                index: '03',
                                title: 'Set/tekrar ayarla',
                                subtitle: 'Zorluk seviyene göre optimize et.',
                              ),
                              const SizedBox(height: 14.0),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _startProgramFlow,
                                  icon:
                                      const Icon(Icons.edit_calendar_outlined),
                                  label: const Text('Yeni program başlat'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor:
                                        CustomPlanScreen._accentPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: FutureBuilder<List<Exercise>>(
                            future: exerciseRepository.getAllExercises(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final exercises = snapshot.data ?? <Exercise>[];

                              return Column(
                                children: [
                                  for (final day in _days)
                                    _DayEditorCard(
                                      day: day,
                                      onAdd: () =>
                                          _addExercise(day.dayIndex, exercises),
                                      onRemove: (index) =>
                                          _removeExercise(day.dayIndex, index),
                                    ),
                                  const SizedBox(height: 16.0),
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                      onPressed: _saveProgram,
                                      icon: const Icon(Icons.save_outlined),
                                      label: const Text('Programı kaydet'),
                                      style: FilledButton.styleFrom(
                                        backgroundColor:
                                            CustomPlanScreen._accentPurple,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14.0,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16.0),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32.0),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
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

class _StepItem extends StatelessWidget {
  const _StepItem({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final String index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36.0,
          height: 36.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: CustomPlanScreen._accentPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            index,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: CustomPlanScreen._textHigh,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: CustomPlanScreen._textHigh,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CustomPlanScreen._textMid,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DayEditorCard extends StatelessWidget {
  const _DayEditorCard({
    required this.day,
    required this.onAdd,
    required this.onRemove,
  });

  final _DraftDay day;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _GlassCard(
        borderRadius: 22.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: CustomPlanScreen._cardSurface.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: TextField(
                        controller: day.nameController,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: CustomPlanScreen._textHigh,
                              fontWeight: FontWeight.w700,
                            ),
                        decoration: InputDecoration(
                          hintText: 'Gün ${day.dayIndex}',
                          hintStyle: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: CustomPlanScreen._textMid),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add),
                    label: const Text('Egzersiz ekle'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: CustomPlanScreen._textHigh,
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.18),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12.0),
              if (day.exercises.isEmpty)
                Text(
                  'Henüz egzersiz eklenmedi.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: CustomPlanScreen._textMid,
                      ),
                )
              else
                Column(
                  children: [
                    for (int i = 0; i < day.exercises.length; i++)
                      _ExerciseRow(
                        exercise: day.exercises[i],
                        onRemove: () => onRemove(i),
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

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.exercise,
    required this.onRemove,
  });

  final _DraftExercise exercise;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: CustomPlanScreen._cardSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: CustomPlanScreen._textHigh,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  exercise.isTimed
                      ? '${exercise.sets} set x ${exercise.value} sn'
                      : '${exercise.sets} set x ${exercise.value} tekrar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: CustomPlanScreen._textMid,
                      ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            color: CustomPlanScreen._textMid,
          ),
        ],
      ),
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  const _ExercisePickerSheet({required this.exercises});

  final List<Exercise> exercises;

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var filtered = widget.exercises;
    final query = _controller.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      filtered = widget.exercises
          .where(
            (exercise) =>
                exercise.name.toLowerCase().contains(query) ||
                exercise.description.toLowerCase().contains(query),
          )
          .toList();
    }

    return SafeArea(
      child: _GlassCard(
        borderRadius: 24.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
              child: TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Egzersiz ara',
                  hintStyle: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: CustomPlanScreen._textMid),
                  prefixIcon: const Icon(Icons.search),
                  prefixIconColor: CustomPlanScreen._textMid,
                  filled: true,
                  fillColor: CustomPlanScreen._cardSurface.withOpacity(0.6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16.0),
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4.0),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  height: 16.0,
                  color: Colors.white.withOpacity(0.08),
                ),
                itemBuilder: (context, index) {
                  final exercise = filtered[index];
                  return ListTile(
                    title: Text(
                      exercise.name,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: CustomPlanScreen._textHigh,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: Text(
                      exercise.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: CustomPlanScreen._textMid,
                          ),
                    ),
                    onTap: () => Navigator.of(context).pop(exercise),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepperField extends StatefulWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;

  @override
  State<_StepperField> createState() => _StepperFieldState();
}

class _StepperFieldState extends State<_StepperField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _StepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != widget.value.toString()) {
      _controller.text = widget.value.toString();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _applyTypedValue(String text) {
    final parsed = int.tryParse(text);
    if (parsed == null) {
      return;
    }
    final clamped = parsed < widget.minValue
        ? widget.minValue
        : (parsed > widget.maxValue ? widget.maxValue : parsed);
    if (clamped != parsed) {
      _controller.text = clamped.toString();
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
    }
    widget.onChanged(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: CustomPlanScreen._cardSurface.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: CustomPlanScreen._textMid,
                ),
          ),
          const SizedBox(height: 6.0),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove,
                onTap: value > widget.minValue
                    ? () => widget.onChanged(value - 1)
                    : null,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: TextField(
                  controller: _controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CustomPlanScreen._textHigh,
                        fontWeight: FontWeight.w700,
                      ),
                  decoration: const InputDecoration(
                    isCollapsed: true,
                    border: InputBorder.none,
                  ),
                  onSubmitted: _applyTypedValue,
                  onChanged: _applyTypedValue,
                ),
              ),
              const SizedBox(width: 10.0),
              _StepButton(
                icon: Icons.add,
                onTap: value < widget.maxValue
                    ? () => widget.onChanged(value + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: Ink(
        width: 32.0,
        height: 32.0,
        decoration: BoxDecoration(
          color: enabled
              ? CustomPlanScreen._accentPurple.withOpacity(0.25)
              : CustomPlanScreen._cardSurface.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
          ),
        ),
        child: Icon(
          icon,
          size: 18.0,
          color: enabled
              ? CustomPlanScreen._textHigh
              : CustomPlanScreen._textMid,
        ),
      ),
    );
  }
}

class _DraftDay {
  _DraftDay({required this.dayIndex})
      : nameController = TextEditingController(text: 'Gün $dayIndex');

  final int dayIndex;
  final List<_DraftExercise> exercises = [];
  final TextEditingController nameController;

  void dispose() {
    nameController.dispose();
  }
}

class _DraftExercise {
  _DraftExercise({
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.value,
    required this.isTimed,
  });

  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int value;
  final bool isTimed;
}

class _SetRepConfig {
  const _SetRepConfig(this.sets, this.value, this.isTimed);

  final int sets;
  final int value;
  final bool isTimed;
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.borderRadius = 20.0});

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: CustomPlanScreen._cardSurface.withOpacity(0.78),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
