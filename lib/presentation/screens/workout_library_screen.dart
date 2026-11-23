// lib/presentation/screens/workout_library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/services/muscle_filter.dart';
import 'package:calisthenics_app/presentation/providers/exercise_list_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';

class WorkoutLibraryScreen extends ConsumerStatefulWidget {
  const WorkoutLibraryScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  ConsumerState<WorkoutLibraryScreen> createState() =>
      _WorkoutLibraryScreenState();
}

class _WorkoutLibraryScreenState extends ConsumerState<WorkoutLibraryScreen> {
  final Set<MuscleRegion> _selectedRegions = {};
  final Set<MuscleCompartment> _selectedCompartments = {};

  List<String> _exerciseMuscleLabels(Exercise exercise) {
    return targetRegions(
      exercise.compartmentWeights,
    ).map((region) => region.label).toList();
  }

  void _toggleRegion(MuscleRegion region) {
    setState(() {
      if (!_selectedRegions.remove(region)) {
        _selectedRegions.add(region);
      } else {
        // Bölge kapatılınca alt kompartıman seçimleri de kalkar.
        _selectedCompartments.removeWhere((c) => c.region == region);
      }
    });
  }

  void _toggleCompartment(MuscleCompartment compartment) {
    setState(() {
      if (!_selectedCompartments.remove(compartment)) {
        _selectedCompartments.add(compartment);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedRegions.clear();
      _selectedCompartments.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final asyncExercises = ref.watch(exerciseListProvider);
    final canPop = Navigator.of(context).canPop();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: asyncExercises.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.page),
              child: Text('Hata: $error', style: AppText.bodyMuted),
            ),
          ),
          data: (exercises) {
            final filteredWorkouts = exercises
                .where(
                  (exercise) => matchesMuscleFilter(
                    exercise.compartmentWeights,
                    regions: _selectedRegions,
                    compartments: _selectedCompartments,
                  ),
                )
                .toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.page,
                      AppSpace.lg,
                      AppSpace.page,
                      0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (canPop) ...[
                          IconButton(
                            onPressed: () => Navigator.of(context).maybePop(),
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: AppColors.textHigh,
                            tooltip: 'Geri',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                            style: IconButton.styleFrom(
                              alignment: Alignment.centerLeft,
                            ),
                          ),
                          const SizedBox(height: AppSpace.sm),
                        ],
                        const Text(
                          'Hareket Kütüphanesi',
                          style: AppText.pageTitle,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${filteredWorkouts.length} hareket · kalistenik katalog',
                          style: AppText.bodyMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpace.page,
                      AppSpace.section,
                      AppSpace.page,
                      0,
                    ),
                    child: _TargetRegionPicker(
                      selectedRegions: _selectedRegions,
                      selectedCompartments: _selectedCompartments,
                      onToggleRegion: _toggleRegion,
                      onToggleCompartment: _toggleCompartment,
                      onClear: _clearFilters,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpace.page,
                    AppSpace.lg,
                    AppSpace.page,
                    AppSpace.section,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredWorkouts[index];
                      return DecoratedBox(
                        decoration: BoxDecoration(
                          border: index == 0
                              ? null
                              : const Border(
                                  top: BorderSide(
                                    color: AppColors.hairline,
                                    width: AppSpace.hairline,
                                  ),
                                ),
                        ),
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
                    }, childCount: filteredWorkouts.length),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(selectedIndex: 1)
          : null,
    );
  }
}

/// Kütüphane üstündeki etkileşimli anatomik kas filtresi: solda dikey bölge
/// hapları, sağda seçimi vücut üzerinde vurgulayan ön/arka silüet. Hem haplara
/// hem de silüetteki kaslara dokunarak filtrelenir.
class _TargetRegionPicker extends StatelessWidget {
  const _TargetRegionPicker({
    required this.selectedRegions,
    required this.selectedCompartments,
    required this.onToggleRegion,
    required this.onToggleCompartment,
    required this.onClear,
  });

  final Set<MuscleRegion> selectedRegions;
  final Set<MuscleCompartment> selectedCompartments;
  final ValueChanged<MuscleRegion> onToggleRegion;
  final ValueChanged<MuscleCompartment> onToggleCompartment;
  final VoidCallback onClear;

  static const List<MuscleRegion> _order = [
    MuscleRegion.chest,
    MuscleRegion.back,
    MuscleRegion.shoulders,
    MuscleRegion.arms,
    MuscleRegion.legs,
    MuscleRegion.core,
  ];

  static const double _pillColumnWidth = 92;

  /// Seçili bölgelerin kompartımanları tam, alt bölge seçiliyse seçilmeyen
  /// kardeşleri soluk tonla vurgulanır.
  Map<MuscleCompartment, double> _highlight() {
    final out = <MuscleCompartment, double>{};
    for (final region in selectedRegions) {
      final picked = region.compartments.where(selectedCompartments.contains);
      for (final c in region.compartments) {
        out[c] = picked.isEmpty || picked.contains(c) ? 1.0 : 0.3;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter =
        selectedRegions.isNotEmpty || selectedCompartments.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Anatomik kas filtresi',
          padding: const EdgeInsets.only(bottom: AppSpace.md),
          trailing: hasFilter
              ? GestureDetector(
                  onTap: onClear,
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    'Temizle',
                    style: AppText.caption.copyWith(
                      color: AppColors.textMid,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : null,
        ),
        AppSurface(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const gap = AppSpace.md;
              const figureSpacing = AppSpace.sm;
              final mapWidth = constraints.maxWidth - _pillColumnWidth - gap;
              // İki silüet + boşluk genişliğe sığacak yükseklik (+ başlık).
              final mapHeight =
                  (((mapWidth - figureSpacing) / 2) * 370 / 200 + 18)
                      .clamp(160.0, 300.0)
                      .toDouble();
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: _pillColumnWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RegionPill(
                          label: 'Tümü',
                          isSelected: !hasFilter,
                          onTap: onClear,
                        ),
                        for (final region in _order) ...[
                          const SizedBox(height: 6),
                          _RegionPill(
                            label: region.label,
                            isSelected: selectedRegions.contains(region),
                            onTap: () => onToggleRegion(region),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: gap),
                  Expanded(
                    child: Center(
                      child: Semantics(
                        label: 'Kas haritası: filtrelemek için bir kasa dokun',
                        child: AnatomicalMuscleMap(
                          intensities: _highlight(),
                          normalize: false,
                          height: mapHeight,
                          spacing: figureSpacing,
                          onCompartmentTap: (c) => onToggleRegion(c.region),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        for (final region in _order)
          if (selectedRegions.contains(region) &&
              region.compartments.length > 1) ...[
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    region.label,
                    style: AppText.caption.copyWith(color: AppColors.textMid),
                  ),
                ),
                for (final compartment in region.compartments)
                  _RegionPill(
                    label: compartment.label,
                    compact: true,
                    isSelected: selectedCompartments.contains(compartment),
                    onTap: () => onToggleCompartment(compartment),
                  ),
              ],
            ),
          ],
      ],
    );
  }
}

class _RegionPill extends StatelessWidget {
  const _RegionPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(999);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: radius,
            border: isSelected
                ? null
                : Border.all(color: AppColors.hairlineStrong, width: 1),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.caption.copyWith(
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColors.onAccent : AppColors.textMid,
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

  int _levelStep(ExerciseLevel level) {
    switch (level) {
      case ExerciseLevel.beginner:
        return 1;
      case ExerciseLevel.intermediate:
        return 2;
      case ExerciseLevel.advanced:
        return 3;
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
    final step = _levelStep(exercise.level);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    muscleLabels.isEmpty ? '—' : muscleLabels.join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.lg),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 1; i <= 3; i++)
                      Container(
                        width: 10,
                        height: 3,
                        margin: EdgeInsets.only(left: i == 1 ? 0 : 2),
                        decoration: BoxDecoration(
                          color: i <= step
                              ? AppColors.textHigh
                              : AppColors.hairlineStrong,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _levelName(exercise.level),
                  style: AppText.caption.copyWith(fontSize: 11),
                ),
              ],
            ),
            const SizedBox(width: AppSpace.sm),
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
