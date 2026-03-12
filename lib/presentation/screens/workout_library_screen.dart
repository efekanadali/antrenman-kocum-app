// lib/presentation/screens/workout_library_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';

class WorkoutLibraryScreen extends ConsumerStatefulWidget {
  const WorkoutLibraryScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  static const Color _bgTop = Color(0xFF151028);
  static const Color _bgBottom = Color(0xFF0E0A1D);
  static const Color _cardSurface = Color(0xFF201836);
  static const Color _cardSurfaceSoft = Color(0xFF2A2048);
  static const Color _accentPurple = Color(0xFF6D5BFF);
  static const Color _accentBlue = Color(0xFF4FC3F7);
  static const Color _textHigh = Color(0xFFEDE9FF);
  static const Color _textMid = Color(0xFFB4A9D8);

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
        return 'Chest';
      case MuscleGroup.back:
        return 'Back';
      case MuscleGroup.shoulders:
        return 'Shoulders';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.core:
        return 'Core';
      case MuscleGroup.quads:
        return 'Quads';
      case MuscleGroup.hamstrings:
        return 'Hamstrings';
      case MuscleGroup.glutes:
        return 'Glutes';
      case MuscleGroup.calves:
        return 'Calves';
      case MuscleGroup.legs:
        return 'Legs';
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
      backgroundColor: WorkoutLibraryScreen._bgBottom,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  WorkoutLibraryScreen._bgTop,
                  WorkoutLibraryScreen._bgBottom,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -120.0,
            left: -60.0,
            child: Container(
              width: 240.0,
              height: 240.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WorkoutLibraryScreen._accentPurple.withOpacity(0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -100.0,
            right: -40.0,
            child: Container(
              width: 220.0,
              height: 220.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: WorkoutLibraryScreen._accentBlue.withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            child: FutureBuilder<List<Exercise>>(
              future: _exerciseFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Hata: ${snapshot.error}'));
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
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0),
                    child: Row(
                      children: [
                        _BackButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        const SizedBox(width: 12.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hareket Kütüphanesi',
                              style:
                                  Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: WorkoutLibraryScreen._textHigh,
                                        fontWeight: FontWeight.w800,
                                      ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Kalisthenik hareketler',
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: WorkoutLibraryScreen._textMid,
                                        fontWeight: FontWeight.w500,
                                      ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Text(
                      'Hareket kartlarına dokunup detaylı bilgi alabilirsin.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: WorkoutLibraryScreen._textMid,
                          ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
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
                      const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = filteredWorkouts[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14.0),
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
        ],
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
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Hedeflediğin bölge',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: WorkoutLibraryScreen._textHigh,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                if (selectedGroups.isNotEmpty)
                  TextButton(
                    onPressed: onClear,
                    child: Text(
                      'Temizle',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: WorkoutLibraryScreen._accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6.0),
            Text(
              'Kartlara dokunarak hedef bölgeyi seç.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WorkoutLibraryScreen._textMid,
                  ),
            ),
            const SizedBox(height: 14.0),
            if (availableGroups.isEmpty)
              Text(
                'Şu an listelenecek bölge yok.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: WorkoutLibraryScreen._textMid,
                    ),
              )
            else
              Wrap(
                spacing: 10.0,
                runSpacing: 10.0,
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
    final bgColor = isSelected
        ? WorkoutLibraryScreen._accentPurple.withOpacity(0.28)
        : WorkoutLibraryScreen._cardSurface;
    final borderColor = isSelected
        ? WorkoutLibraryScreen._accentPurple
        : Colors.white.withOpacity(0.18);
    final textColor = isSelected
        ? WorkoutLibraryScreen._accentPurple
        : WorkoutLibraryScreen._textHigh;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        splashColor: WorkoutLibraryScreen._accentBlue.withOpacity(0.2),
        highlightColor: WorkoutLibraryScreen._accentBlue.withOpacity(0.08),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.18),
                blurRadius: 10.0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
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

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 20.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: WorkoutLibraryScreen._cardSurfaceSoft,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: WorkoutLibraryScreen._textHigh,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: WorkoutLibraryScreen._textHigh,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            exercise.description,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: WorkoutLibraryScreen._textMid,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    _LevelPill(level: exercise.level.label),
                  ],
                ),
                const SizedBox(height: 12.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: muscleLabels
                      .map(
                        (group) => _MuscleChip(label: group),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.level});

  final String level;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: WorkoutLibraryScreen._accentPurple.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        level,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: WorkoutLibraryScreen._accentPurple,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  const _MuscleChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: WorkoutLibraryScreen._cardSurfaceSoft,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: WorkoutLibraryScreen._textHigh,
              fontWeight: FontWeight.w600,
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
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14.0),
      child: Ink(
        decoration: BoxDecoration(
          color: WorkoutLibraryScreen._cardSurface,
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: const SizedBox(
          width: 44.0,
          height: 44.0,
          child: Icon(
            Icons.arrow_back_rounded,
            color: WorkoutLibraryScreen._textHigh,
          ),
        ),
      ),
    );
  }
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
            color: WorkoutLibraryScreen._cardSurface.withOpacity(0.78),
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
