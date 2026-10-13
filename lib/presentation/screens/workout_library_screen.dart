// lib/presentation/screens/workout_library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

class WorkoutLibraryScreen extends ConsumerStatefulWidget {
  const WorkoutLibraryScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  ConsumerState<WorkoutLibraryScreen> createState() =>
      _WorkoutLibraryScreenState();
}

class _WorkoutLibraryScreenState extends ConsumerState<WorkoutLibraryScreen> {
  final Set<MuscleGroup> _selectedMuscleGroups = {};
  late final Future<List<Exercise>> _exerciseFuture;

  static const List<MuscleGroup> _libraryGroups = [
    MuscleGroup.chest,
    MuscleGroup.back,
    MuscleGroup.shoulders,
    MuscleGroup.biceps,
    MuscleGroup.triceps,
    MuscleGroup.core,
    MuscleGroup.quads,
    MuscleGroup.hamstrings,
    MuscleGroup.glutes,
    MuscleGroup.calves,
  ];

  @override
  void initState() {
    super.initState();
    _exerciseFuture =
        ref.read(exerciseRepositoryProvider).getAllExercises();
  }

  List<MuscleGroup> _allMuscleGroups() {
    return _libraryGroups;
  }

  List<String> _exerciseMuscleLabels(Exercise exercise) {
    return exercise.targetMuscleGroups.map(_muscleLabel).toList();
  }

  String _muscleLabel(MuscleGroup group) {
    switch (group) {
      case MuscleGroup.chest:
        return 'Göğüs';
      case MuscleGroup.back:
        return 'Sırt';
      case MuscleGroup.shoulders:
        return 'Omuz';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.core:
        return 'Karın / Core';
      case MuscleGroup.quads:
        return 'Ön Bacak';
      case MuscleGroup.hamstrings:
        return 'Arka Bacak';
      case MuscleGroup.glutes:
        return 'Kalça';
      case MuscleGroup.calves:
        return 'Kalf';
      case MuscleGroup.legs:
        return 'Bacak';
    }
  }

  void _toggleMuscleGroup(MuscleGroup group) {
    setState(() {
      if (_selectedMuscleGroups.contains(group)) {
        _selectedMuscleGroups.remove(group);
      } else {
        _selectedMuscleGroups.add(group);
      }
    });
  }

  void _clearMuscleGroups() {
    setState(() {
      _selectedMuscleGroups.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<Exercise>>(
          future: _exerciseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppColors.volcanic,
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Hata: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.textMid),
                ),
              );
            }

            final exercises = snapshot.data ?? <Exercise>[];
            final availableGroups = _allMuscleGroups();
            final filteredWorkouts = _selectedMuscleGroups.isEmpty
                ? exercises
                : exercises
                    .where(
                      (exercise) => _selectedMuscleGroups.every(
                        (group) =>
                            exercise.targetMuscleGroups.contains(group),
                      ),
                    )
                    .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
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
                                'Hareket Kütüphanesi',
                                style: TextStyle(
                                  color: AppColors.textHigh,
                                  fontSize: 22.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 3.0),
                              Text(
                                'Kalisthenik Egzersiz Kataloğu',
                                style: TextStyle(
                                  color: AppColors.textMid,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10.0,
                            vertical: 5.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Text(
                            '${filteredWorkouts.length} Hareket',
                            style: const TextStyle(
                              color: AppColors.textMid,
                              fontSize: 12.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 8.0),
                    child: _TargetRegionPicker(
                      availableGroups: availableGroups,
                      selectedGroups: _selectedMuscleGroups,
                      onToggleGroup: _toggleMuscleGroup,
                      labelBuilder: _muscleLabel,
                      onClear: _clearMuscleGroups,
                    ),
                  ),
                ),
                SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filteredWorkouts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _WorkoutCard(
                            exercise: item,
                            muscleLabels: _exerciseMuscleLabels(item),
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRoutes.detail,
                                arguments: item,
                              );
                            },
                          ),
                        );
                      },
                      childCount: filteredWorkouts.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32.0),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar:
          widget.showBottomNav ? const AppBottomNav(selectedIndex: 1) : null,
    );
  }
}

class _TargetRegionPicker extends StatelessWidget {
  const _TargetRegionPicker({
    required this.availableGroups,
    required this.selectedGroups,
    required this.onToggleGroup,
    required this.labelBuilder,
    required this.onClear,
  });

  final List<MuscleGroup> availableGroups;
  final Set<MuscleGroup> selectedGroups;
  final ValueChanged<MuscleGroup> onToggleGroup;
  final String Function(MuscleGroup) labelBuilder;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const Text(
                'Hedef Bölge Filtresi',
                style: TextStyle(
                  color: AppColors.textHigh,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              if (selectedGroups.isNotEmpty)
                GestureDetector(
                  onTap: onClear,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceSoft,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.close_rounded,
                          size: 13.0,
                          color: AppColors.volcanic,
                        ),
                        SizedBox(width: 4.0),
                        Text(
                          'Temizle',
                          style: TextStyle(
                            color: AppColors.volcanic,
                            fontSize: 11.0,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6.0),
          const Text(
            'İlgili kas grubuna dokunarak egzersizleri daralt.',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.0,
            ),
          ),
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: availableGroups
                .map(
                  (group) => _RegionCard(
                    label: labelBuilder(group),
                    isSelected: selectedGroups.contains(group),
                    onTap: () => onToggleGroup(group),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _RegionCard extends StatelessWidget {
  const _RegionCard({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.volcanic : AppColors.surfaceSoft,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: isSelected ? AppColors.volcanic : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.textMid,
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.exercise,
    required this.muscleLabels,
    required this.onTap,
  });

  final Exercise exercise;
  final List<String> muscleLabels;
  final VoidCallback onTap;

  Color _levelColor(ExerciseLevel level) {
    switch (level) {
      case ExerciseLevel.beginner:
        return AppColors.emerald;
      case ExerciseLevel.intermediate:
        return AppColors.amber;
      case ExerciseLevel.advanced:
        return AppColors.volcanic;
    }
  }

  String _levelName(ExerciseLevel level) {
    switch (level) {
      case ExerciseLevel.beginner:
        return 'Başlangıç';
      case ExerciseLevel.intermediate:
        return 'Orta';
      case ExerciseLevel.advanced:
        return 'İleri';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stripeColor = _levelColor(exercise.level);
    final levelName = _levelName(exercise.level);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3px Zarif Dikey Seviye Şeridi
                Container(
                  width: 3.5,
                  color: stripeColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Koyu Mat Grafit İkon Kutusu
                            Container(
                              width: 42.0,
                              height: 42.0,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceSoft,
                                borderRadius: BorderRadius.circular(10.0),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.0,
                                ),
                              ),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: AppColors.textHigh,
                                size: 20.0,
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.name,
                                    style: const TextStyle(
                                      color: AppColors.textHigh,
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 3.0),
                                  Text(
                                    '${exercise.name} hareketi için biyomekanik aktivasyon profili.',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            // Seviye Kapsülü
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9.0,
                                vertical: 4.0,
                              ),
                              decoration: BoxDecoration(
                                color: stripeColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: stripeColor.withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                levelName,
                                style: TextStyle(
                                  color: stripeColor,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        Wrap(
                          spacing: 6.0,
                          runSpacing: 6.0,
                          children: muscleLabels
                              .map(
                                (label) => Container(
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
                                    label,
                                    style: const TextStyle(
                                      color: AppColors.textMid,
                                      fontSize: 11.0,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
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
