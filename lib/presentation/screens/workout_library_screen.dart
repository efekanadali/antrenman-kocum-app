// lib/presentation/screens/workout_library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/exercise_type.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/services/muscle_filter.dart';
import 'package:calisthenics_app/presentation/providers/exercise_list_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/utils/core_zone_filter.dart';
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

  /// Karın bölgesi seçiliyken Karın / Oblik alt seçimi (yalnızca harita ve
  /// filtre; biyomekanik modelde tek `core` kompartımanı).
  final Set<CoreZone> _selectedZones = {};

  /// Üst şeritteki tür filtresi; `null` = Tümü.
  ExerciseType? _type;

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
        if (region == MuscleRegion.core) _selectedZones.clear();
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

  void _toggleZone(CoreZone zone) {
    setState(() {
      _selectedRegions.add(MuscleRegion.core);
      if (!_selectedZones.remove(zone)) _selectedZones.add(zone);
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedRegions.clear();
      _selectedCompartments.clear();
      _selectedZones.clear();
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
            final byType = _type == null
                ? exercises
                : exercises.where((e) => e.type == _type).toList();
            final calisthenicsCount = exercises
                .where((e) => e.type == ExerciseType.calisthenics)
                .length;
            final filteredWorkouts = byType
                .where(
                  (exercise) =>
                      matchesMuscleFilter(
                        exercise.compartmentWeights,
                        regions: _selectedRegions,
                        compartments: _selectedCompartments,
                      ) &&
                      matchesCoreZones(
                        exercise.id,
                        exercise.compartmentWeights,
                        _selectedZones,
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
                        Text('Hareketler', style: AppText.pageTitle),
                        const SizedBox(height: AppSpace.xl),
                        _TypeStrip(
                          selected: _type,
                          total: exercises.length,
                          calisthenics: calisthenicsCount,
                          bodybuilding: exercises.length - calisthenicsCount,
                          onChanged: (type) => setState(() => _type = type),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Text(
                          '${filteredWorkouts.length} hareket · ${_catalogLabel(_type)}',
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
                      selectedZones: _selectedZones,
                      onToggleRegion: _toggleRegion,
                      onToggleCompartment: _toggleCompartment,
                      onToggleZone: _toggleZone,
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
                      return Padding(
                        padding: EdgeInsets.only(
                          top: index == 0 ? 0 : AppSpace.md,
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

String _catalogLabel(ExerciseType? type) {
  switch (type) {
    case null:
      return 'hibrit katalog';
    case ExerciseType.calisthenics:
      return 'kalistenik katalog';
    case ExerciseType.bodybuilding:
      return 'vücut geliştirme katalog';
  }
}

/// Tümü / Kalistenik / Vücut Geliştirme tür şeridi (sayılarla). Etiketler
/// kesilmez: dar ekranda yazı orantılı küçülür.
class _TypeStrip extends StatelessWidget {
  const _TypeStrip({
    required this.selected,
    required this.total,
    required this.calisthenics,
    required this.bodybuilding,
    required this.onChanged,
  });

  final ExerciseType? selected;
  final int total;
  final int calisthenics;
  final int bodybuilding;
  final ValueChanged<ExerciseType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = <(ExerciseType?, String, int)>[
      (null, 'Tümü ($total)', 8),
      (ExerciseType.calisthenics, 'Kalistenik ($calisthenics)', 10),
      (ExerciseType.bodybuilding, 'Vücut Geliştirme ($bodybuilding)', 14),
    ];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.isDark ? AppColors.surface : AppColors.hairline,
        borderRadius: BorderRadius.circular(14),
        border: AppColors.isDark
            ? Border.all(color: AppColors.hairline, width: AppSpace.hairline)
            : null,
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              flex: item.$3,
              child: GestureDetector(
                key: ValueKey('library-type-${item.$1?.name ?? 'all'}'),
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(item.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected == item.$1
                        ? (AppColors.isDark
                              ? AppColors.accent
                              : AppColors.surface)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      item.$2,
                      maxLines: 1,
                      style: AppText.caption.copyWith(
                        fontSize: 13,
                        fontWeight: selected == item.$1
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: selected == item.$1
                            ? (AppColors.isDark
                                  ? AppColors.onAccent
                                  : AppColors.textHigh)
                            : AppColors.textMid,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
    required this.selectedZones,
    required this.onToggleRegion,
    required this.onToggleCompartment,
    required this.onToggleZone,
    required this.onClear,
  });

  final Set<MuscleRegion> selectedRegions;
  final Set<MuscleCompartment> selectedCompartments;
  final Set<CoreZone> selectedZones;
  final ValueChanged<MuscleRegion> onToggleRegion;
  final ValueChanged<MuscleCompartment> onToggleCompartment;
  final ValueChanged<CoreZone> onToggleZone;
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
        selectedRegions.isNotEmpty ||
        selectedCompartments.isNotEmpty ||
        selectedZones.isNotEmpty;
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
                      fontSize: 13,
                      color: AppColors.activation,
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
                      crossAxisAlignment: CrossAxisAlignment.stretch,
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
                          onCoreZoneTap: (zone) =>
                              selectedRegions.contains(MuscleRegion.core)
                              ? onToggleZone(zone)
                              : onToggleRegion(MuscleRegion.core),
                          coreZoneScale:
                              selectedRegions.contains(MuscleRegion.core) &&
                                  selectedZones.isNotEmpty
                              ? {
                                  for (final z in CoreZone.values)
                                    z: selectedZones.contains(z) ? 1.0 : 0.3,
                                }
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (selectedRegions.contains(MuscleRegion.core)) ...[
          const SizedBox(height: AppSpace.md),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Text(
                  MuscleRegion.core.label,
                  style: AppText.caption.copyWith(color: AppColors.textMid),
                ),
              ),
              for (final zone in CoreZone.values)
                _RegionPill(
                  key: ValueKey('library-core-zone-${zone.name}'),
                  label: zone.label,
                  compact: true,
                  isSelected: selectedZones.contains(zone),
                  onTap: () => onToggleZone(zone),
                ),
            ],
          ),
        ],
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
    super.key,
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
          alignment: compact ? null : Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                : compact
                ? AppColors.surface
                : AppColors.isDark
                ? Colors.transparent
                : AppColors.surfaceRaised,
            borderRadius: radius,
            border: isSelected || (!compact && !AppColors.isDark)
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
              color: isSelected ? AppColors.onAccent : AppColors.textHigh,
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
    return AppSurface(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.lg,
      ),
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
                      width: 12,
                      height: 4,
                      margin: EdgeInsets.only(left: i == 1 ? 0 : 3),
                      decoration: BoxDecoration(
                        color: i <= step
                            ? AppColors.ring
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
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}
