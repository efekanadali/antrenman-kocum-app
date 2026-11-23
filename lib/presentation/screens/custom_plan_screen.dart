// lib/presentation/screens/custom_plan_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/core/utils/exercise_unit.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/enums/exercise_type.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/presentation/providers/exercise_list_provider.dart';
import 'package:calisthenics_app/presentation/providers/custom_program_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/domain/services/exercise_mli_resolver.dart';
import 'package:calisthenics_app/domain/services/program_preview.dart';
import 'package:calisthenics_app/presentation/widgets/program_preview_badge.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';

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
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Haftada kaç gün?', style: AppText.cardTitle),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Haftalık antrenman sıklığını belirle.',
                      style: AppText.bodyMuted,
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
                                  : AppColors.surfaceRaised,
                              borderRadius: BorderRadius.circular(
                                AppRadius.control,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$day',
                                  style: AppText.metricM.copyWith(
                                    fontSize: 17,
                                    color: selected
                                        ? AppColors.onAccent
                                        : AppColors.textHigh,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'Gün',
                                  style: TextStyle(
                                    color: selected
                                        ? AppColors.onAccent.withValues(alpha: 0.7)
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
                            foregroundColor: AppColors.onAccent,
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

    // Vücut geliştirme hareketlerinde hedef yük (kg) da sorulur.
    final isBodybuilding = ExerciseMliResolver(catalog: exercises)
            .build(
              CustomProgramExercise(
                exerciseId: chosen.id,
                exerciseName: chosen.name,
                sets: 1,
                value: 1,
                isTimed: isTimed,
              ),
              detail: chosen,
            )
            .type ==
        ExerciseType.bodybuilding;

    final config = await _promptSetRep(
      isTimed: isTimed,
      askLoad: isBodybuilding,
    );
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
          loadKg: config.loadKg,
        ),
      );
    });
  }

  Future<_SetRepConfig?> _promptSetRep({
    required bool isTimed,
    bool askLoad = false,
  }) async {
    final loadController = TextEditingController();
    final result = await showDialog<_SetRepConfig>(
      context: context,
      builder: (context) {
        int sets = 3;
        int targetValue = isTimed ? 30 : 10;
        return Dialog(
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
                    const Text('Hedef set & tekrar', style: AppText.cardTitle),
                    const SizedBox(height: 4.0),
                    Text(
                      isTimed
                          ? 'Set sayısı ve hedef saniyeyi belirle.'
                          : 'Set ve hedef tekrar sayısını belirle.',
                      style: AppText.bodyMuted,
                    ),
                    const SizedBox(height: 12.0),
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
                    if (askLoad) ...[
                      const SizedBox(height: 12.0),
                      TextField(
                        key: const ValueKey('load-kg-field'),
                        controller: loadController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: AppText.metricS,
                        decoration: const InputDecoration(
                          labelText: 'Hedef yük',
                          suffixText: 'kg',
                          suffixStyle: AppText.unit,
                        ),
                      ),
                    ],
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
                            _SetRepConfig(
                              sets,
                              targetValue,
                              isTimed,
                              loadKg: askLoad
                                  ? parseLoadKgInput(loadController.text)
                                  : null,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.volcanic,
                            foregroundColor: AppColors.onAccent,
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

    loadController.dispose();
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
          loadKg: e.loadKg,
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
                      loadKg: exercise.loadKg,
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
    final exercisesAsync = ref.watch(exerciseListProvider);
    final building = _daysCount != null;
    final catalog = exercisesAsync.valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: building && catalog != null
          ? _LiveMliDock(
              preview: _buildPreview(catalog),
              onSave: _saveProgram,
            )
          : null,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Üst Başlık & Geri Butonu
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.sm,
                  AppSpace.sm,
                  AppSpace.page,
                  0,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _BackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.xs,
                AppSpace.page,
                AppSpace.section,
              ),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Senin Planın', style: AppText.pageTitle),
                    SizedBox(height: 6),
                    Text(
                      'Özel kalistenik antrenman mimarı',
                      style: AppText.bodyMuted,
                    ),
                  ],
                ),
              ),
            ),

            // Program Adı
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.page),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      'Program adı',
                      trailing: Text(
                        _daysCount == null
                            ? 'Gün seçilmedi'
                            : '$_daysCount günlük plan',
                        style: AppText.caption,
                      ),
                      padding: const EdgeInsets.only(bottom: AppSpace.sm),
                    ),
                    TextField(
                      controller: _nameController,
                      style: AppText.body.copyWith(fontSize: 15),
                      decoration: const InputDecoration(
                        hintText: 'Örn: Tüm Vücut 3 Günlük Rutin',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: AppSpace.section),
            ),

            // Eğer gün sayısı henüz seçilmemişse Başlangıç Rehberi göster
            if (!building)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.page,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        'Nasıl çalışır',
                        padding: EdgeInsets.only(bottom: AppSpace.sm),
                      ),
                      const AppSurface(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _StepItem(
                              index: '01',
                              title: 'Gün sayısını seç',
                              subtitle:
                                  'Haftalık 1 ile 7 gün arasında plan kur.',
                            ),
                            Hairline(indent: 56),
                            _StepItem(
                              index: '02',
                              title: 'Egzersizleri ekle',
                              subtitle:
                                  'Her gün için kataloğumuzdan hareket seç.',
                            ),
                            Hairline(indent: 56),
                            _StepItem(
                              index: '03',
                              title: 'Set ve tekrarları ayarla',
                              subtitle:
                                  'Biyomekanik iş yükünü canlı önizle ve kaydet.',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      PrimaryButton(
                        label: 'Yeni Program Başlat',
                        onPressed: _startProgramFlow,
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.page,
                      ),
                      child: exercisesAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(AppSpace.section),
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                        error: (_, _) => const Center(
                          child: Text(
                            'Egzersiz kataloğu yüklenemedi.',
                            style: AppText.bodyMuted,
                          ),
                        ),
                        data: (exercises) {
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
                              const SizedBox(height: AppSpace.lg),
                              const Text(
                                'Haftalık toplam, RIR 2 varsayımıyla; kaldıraç '
                                'katsayısı ve kas ağırlıklarına göre hesaplanır.',
                                style: AppText.caption,
                              ),
                              const SizedBox(height: AppSpace.section),
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

/// Oluşturucunun altına sabitlenen canlı MLI şeridi + kaydet butonu.
class _LiveMliDock extends StatelessWidget {
  const _LiveMliDock({required this.preview, required this.onSave});

  final ProgramPreview preview;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.hairline,
            width: AppSpace.hairline,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.lg,
            AppSpace.page,
            AppSpace.md,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgramPreviewBadge(
                title: 'Tahmini haftalık MLI',
                preview: preview,
                docked: true,
              ),
              const SizedBox(height: AppSpace.lg),
              PrimaryButton(
                label: 'Programı Kaydet ve Başla',
                onPressed: onSave,
              ),
            ],
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.lg,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            child: Text(
              index,
              style: AppText.metricS.copyWith(color: AppColors.textMuted),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.caption),
              ],
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.only(bottom: AppSpace.lg),
      child: AppSurface(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.card,
                AppSpace.lg,
                AppSpace.card,
                AppSpace.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(trUpper('Gün ${day.dayIndex}'),
                      style: AppText.sectionLabel),
                  const SizedBox(height: 2),
                  TextField(
                    controller: day.nameController,
                    style: AppText.cardTitle,
                    decoration: InputDecoration(
                      hintText: 'Gün ${day.dayIndex}',
                      hintStyle: AppText.cardTitle.copyWith(
                        color: AppColors.textMuted,
                      ),
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isCollapsed: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ],
              ),
            ),
            if (day.exercises.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpace.card,
                  AppSpace.xs,
                  AppSpace.card,
                  AppSpace.md,
                ),
                child: Text(
                  'Bu güne henüz egzersiz eklenmedi.',
                  style: AppText.caption,
                ),
              )
            else
              for (int i = 0; i < day.exercises.length; i++) ...[
                const Hairline(indent: AppSpace.card),
                _ExerciseRow(
                  index: i + 1,
                  exercise: day.exercises[i],
                  onRemove: () => onRemove(i),
                ),
              ],
            const Hairline(),
            InkWell(
              onTap: onAdd,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: AppColors.textMid),
                    SizedBox(width: 6),
                    Text(
                      'Egzersiz Ekle',
                      style: TextStyle(
                        color: AppColors.textMid,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({
    required this.index,
    required this.exercise,
    required this.onRemove,
  });

  final int index;
  final _DraftExercise exercise;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.card, 12, 8, 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$index',
              style: AppText.metricS.copyWith(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.exerciseName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  exercise.isTimed
                      ? '${exercise.sets} × ${exercise.value} sn'
                      : '${exercise.sets} × ${exercise.value} tekrar'
                          '${formatLoadKgSuffix(exercise.loadKg)}',
                  style: AppText.caption.copyWith(
                    fontSize: 13,
                    color: AppColors.textMid,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            color: AppColors.textMuted,
            iconSize: 16,
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
              padding: const EdgeInsets.fromLTRB(
                AppSpace.page,
                AppSpace.xs,
                AppSpace.page,
                AppSpace.md,
              ),
              child: TextField(
                controller: _controller,
                onChanged: (_) => setState(() {}),
                style: AppText.body.copyWith(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Egzersiz ara',
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                padding: const EdgeInsets.only(bottom: AppSpace.xl),
                itemCount: filtered.length,
                separatorBuilder: (context, index) =>
                    const Hairline(indent: AppSpace.page),
                itemBuilder: (context, index) {
                  final exercise = filtered[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(exercise),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.page,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  exercise.name,
                                  style: AppText.body.copyWith(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  exercise.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.caption,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          const Icon(
                            Icons.add_rounded,
                            color: AppColors.textMid,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(widget.label, style: AppText.bodyMuted),
          ),
          _StepButton(
            icon: Icons.remove_rounded,
            onTap: value > widget.minValue
                ? () => widget.onChanged(value - 1)
                : null,
          ),
          SizedBox(
            width: 64,
            child: TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: AppText.metricM,
              decoration: const InputDecoration(
                isCollapsed: true,
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
              onSubmitted: _applyTypedValue,
              onChanged: _applyTypedValue,
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            onTap: value < widget.maxValue
                ? () => widget.onChanged(value + 1)
                : null,
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
      color: AppColors.surfaceRaised,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: enabled ? AppColors.textHigh : AppColors.textMuted,
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
    return IconButton(
      onPressed: onPressed,
      tooltip: 'Geri',
      icon: const Icon(
        Icons.arrow_back_rounded,
        color: AppColors.textHigh,
        size: 22,
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
    this.loadKg,
  });

  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int value;
  final bool isTimed;
  final double? loadKg;
}

class _SetRepConfig {
  const _SetRepConfig(this.sets, this.value, this.isTimed, {this.loadKg});

  final int sets;
  final int value;
  final bool isTimed;
  final double? loadKg;
}
