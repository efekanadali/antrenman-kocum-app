// lib/presentation/screens/custom_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/core/utils/exercise_unit.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/providers/custom_program_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/domain/services/exercise_mli_resolver.dart';
import 'package:calisthenics_app/domain/services/program_preview.dart';
import 'package:calisthenics_app/presentation/widgets/program_preview_badge.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

class CustomPlanScreen extends ConsumerStatefulWidget {
  const CustomPlanScreen({super.key});

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
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: AppColors.border, width: 1.0),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Haftada Kaç Gün?',
                      style: TextStyle(
                        color: AppColors.textHigh,
                        fontSize: 17.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Haftalık antrenman sıklığını belirle.',
                      style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: 13.0,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: List.generate(7, (index) {
                        final day = index + 1;
                        final selected = temp == day;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              temp = day;
                            });
                          },
                          borderRadius: BorderRadius.circular(10.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 64.0,
                            padding: const EdgeInsets.symmetric(vertical: 10.0),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.volcanic
                                  : AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(10.0),
                              border: Border.all(
                                color: selected
                                    ? AppColors.volcanic
                                    : AppColors.border,
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$day',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white
                                        : AppColors.textHigh,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'Gün',
                                  style: TextStyle(
                                    color: selected
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : AppColors.textMid,
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMid,
                          ),
                          child: const Text('Vazgeç'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(temp),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.volcanic,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: const Text('Devam Et'),
                        ),
                      ],
                    ),
                  ],
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
    final selected = await showModalBottomSheet<Exercise>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
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
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: const BorderSide(color: AppColors.border, width: 1.0),
          ),
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              int minTarget() => isTimed ? 10 : 3;
              int maxTarget() => isTimed ? 300 : 100;
              if (sets < 1) sets = 1;
              if (sets > 6) sets = 6;
              if (targetValue < minTarget()) targetValue = minTarget();
              if (targetValue > maxTarget()) targetValue = maxTarget();

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hedef Set & Tekrar',
                      style: TextStyle(
                        color: AppColors.textHigh,
                        fontSize: 17.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      isTimed
                          ? 'Set sayısı ve hedef saniyeyi belirle.'
                          : 'Set ve hedef tekrar sayısını belirle.',
                      style: const TextStyle(
                        color: AppColors.textMid,
                        fontSize: 13.0,
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    _StepperField(
                      label: 'Set Sayısı',
                      value: sets,
                      minValue: 1,
                      maxValue: 6,
                      onChanged: (val) {
                        setDialogState(() {
                          sets = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12.0),
                    _StepperField(
                      label: isTimed ? 'Süre (saniye)' : 'Tekrar Sayısı',
                      value: targetValue,
                      minValue: minTarget(),
                      maxValue: maxTarget(),
                      onChanged: (val) {
                        setDialogState(() {
                          targetValue = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textMid,
                          ),
                          child: const Text('Vazgeç'),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(
                            _SetRepConfig(sets, targetValue, isTimed),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.volcanic,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                          child: const Text('Kaydet'),
                        ),
                      ],
                    ),
                  ],
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

  ProgramPreview _buildPreview(List<Exercise> catalog) {
    final resolver = ExerciseMliResolver(catalog: catalog);
    final items = _days.expand(
      (day) => day.exercises.map(
        (e) => CustomProgramExercise(
          exerciseId: e.exerciseId,
          exerciseName: e.exerciseName,
          sets: e.sets,
          value: e.value,
          isTimed: e.isTimed,
        ),
      ),
    );
    return estimateProgramPreview(items, resolver);
  }

  Future<void> _saveProgram() async {
    if (_daysCount == null || _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce gün sayısını seç.')),
      );
      return;
    }

    final hasExercises =
        _days.any((day) => day.exercises.isNotEmpty);
    if (!hasExercises) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce en az bir egzersiz ekle.')),
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

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Program başarıyla kaydedildi.')),
    );

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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Üst Başlık & Geri Butonu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 12.0),
                child: Row(
                  children: [
                    _BackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Senin Planın',
                            style: TextStyle(
                              color: AppColors.textHigh,
                              fontSize: 22.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 3.0),
                          Text(
                            'Özel kalistenik antrenman mimarı',
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Program Adı Kartı
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.border, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Program Adı',
                        style: TextStyle(
                          color: AppColors.textHigh,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: AppColors.textHigh,
                          fontSize: 14.5,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Örn: Tüm Vücut 3 Günlük Rutin',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13.5,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceSoft,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 12.0,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: const BorderSide(
                              color: AppColors.volcanic,
                              width: 1.0,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceSoft,
                              borderRadius: BorderRadius.circular(6.0),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              _daysCount == null
                                  ? 'Henüz gün seçilmedi'
                                  : '$_daysCount Günlük Plan',
                              style: const TextStyle(
                                color: AppColors.textMid,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 14.0),
            ),

            // Eğer gün sayısı henüz seçilmemişse Başlangıç Rehberi göster
            if (_daysCount == null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nasıl Çalışır?',
                          style: TextStyle(
                            color: AppColors.textHigh,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        const _StepItem(
                          index: '01',
                          title: 'Gün Sayısını Seç',
                          subtitle: 'Haftalık 1 ile 7 gün arasında plan kur.',
                        ),
                        const SizedBox(height: 12.0),
                        const _StepItem(
                          index: '02',
                          title: 'Egzersizleri Ekle',
                          subtitle: 'Her gün için kataloğumuzdan hareket seç.',
                        ),
                        const SizedBox(height: 12.0),
                        const _StepItem(
                          index: '03',
                          title: 'Set ve Tekrarları Ayarla',
                          subtitle: 'Biyomekanik iş yükünü canlı önizle ve kaydet.',
                        ),
                        const SizedBox(height: 18.0),
                        SizedBox(
                          width: double.infinity,
                          height: 44.0,
                          child: FilledButton.icon(
                            onPressed: _startProgramFlow,
                            icon: const Icon(Icons.edit_calendar_rounded, size: 18.0),
                            label: const Text('Yeni Program Başlat'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.volcanic,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),
                      ],
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
                              child: CircularProgressIndicator(
                                color: AppColors.volcanic,
                              ),
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
                              const SizedBox(height: 12.0),
                              ProgramPreviewBadge(
                                title: 'Canlı Biyomekanik Önizleme',
                                preview: _buildPreview(exercises),
                                footnote:
                                    'Haftalık toplam, RIR 2 varsayımıyla; kaldıraç katsayısı ve kas ağırlıklarına göre hesaplanır.',
                              ),
                              const SizedBox(height: 16.0),
                              SizedBox(
                                width: double.infinity,
                                height: 46.0,
                                child: FilledButton.icon(
                                  onPressed: _saveProgram,
                                  icon: const Icon(Icons.check_circle_rounded, size: 18.0),
                                  label: const Text(
                                    'Programı Kaydet ve Başla',
                                    style: TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.volcanic,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 36.0),
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
          width: 32.0,
          height: 32.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.volcanic.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: AppColors.volcanic.withValues(alpha: 0.35),
              width: 1.0,
            ),
          ),
          child: Text(
            index,
            style: const TextStyle(
              color: AppColors.volcanic,
              fontSize: 12.0,
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
                style: const TextStyle(
                  color: AppColors.textHigh,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2.0),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textMid,
                  fontSize: 12.0,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSoft,
                    borderRadius: BorderRadius.circular(10.0),
                    border: Border.all(
                      color: AppColors.border,
                      width: 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: day.nameController,
                    style: const TextStyle(
                      color: AppColors.textHigh,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Gün ${day.dayIndex}',
                      hintStyle: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13.0,
                      ),
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10.0),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 16.0),
                label: const Text('Egzersiz Ekle'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.volcanic,
                  side: BorderSide(
                    color: AppColors.volcanic.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 8.0,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          if (day.exercises.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: const Text(
                'Bu güne henüz egzersiz eklenmedi.',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12.5,
                ),
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
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: AppColors.border,
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32.0,
            height: 32.0,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppColors.textMid,
              size: 16.0,
            ),
          ),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  style: const TextStyle(
                    color: AppColors.textHigh,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  exercise.isTimed
                      ? '${exercise.sets} set × ${exercise.value} sn'
                      : '${exercise.sets} set × ${exercise.value} tekrar',
                  style: const TextStyle(
                    color: AppColors.textMid,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
            iconSize: 18.0,
            padding: const EdgeInsets.all(4.0),
            constraints: const BoxConstraints(),
            tooltip: 'Egzersizi kaldır',
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
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 8.0, 20.0, 12.0),
              child: TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(color: AppColors.textHigh, fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'Egzersiz ara...',
                  hintStyle: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13.5,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20.0,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceSoft,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 10.0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: 1.0,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: AppColors.border,
                      width: 1.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: const BorderSide(
                      color: AppColors.volcanic,
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 20.0),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1.0,
                  color: AppColors.border,
                ),
                itemBuilder: (context, index) {
                  final exercise = filtered[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    leading: Container(
                      width: 36.0,
                      height: 36.0,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: AppColors.textHigh,
                        size: 18.0,
                      ),
                    ),
                    title: Text(
                      exercise.name,
                      style: const TextStyle(
                        color: AppColors.textHigh,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      exercise.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMid,
                        fontSize: 12.0,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.add_rounded,
                      color: AppColors.volcanic,
                      size: 20.0,
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
    if (parsed == null) return;
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
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.textMid,
              fontSize: 12.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6.0),
          Row(
            children: [
              _StepButton(
                icon: Icons.remove_rounded,
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
                  style: const TextStyle(
                    color: AppColors.textHigh,
                    fontSize: 16.0,
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
                icon: Icons.add_rounded,
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          width: 32.0,
          height: 32.0,
          decoration: BoxDecoration(
            color: enabled
                ? AppColors.volcanic.withValues(alpha: 0.15)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: enabled
                  ? AppColors.volcanic.withValues(alpha: 0.35)
                  : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Icon(
            icon,
            size: 18.0,
            color: enabled ? AppColors.volcanic : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textHigh,
            size: 20.0,
          ),
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
