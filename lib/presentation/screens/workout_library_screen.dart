// lib/presentation/screens/workout_library_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';

class WorkoutLibraryScreen extends StatefulWidget {
  const WorkoutLibraryScreen({super.key});

  static const Color _bgTop = Color(0xFF151028);
  static const Color _bgBottom = Color(0xFF0E0A1D);
  static const Color _cardSurface = Color(0xFF201836);
  static const Color _cardSurfaceSoft = Color(0xFF2A2048);
  static const Color _accentPurple = Color(0xFF6D5BFF);
  static const Color _accentBlue = Color(0xFF4FC3F7);
  static const Color _textHigh = Color(0xFFEDE9FF);
  static const Color _textMid = Color(0xFFB4A9D8);

  static const List<_WorkoutCardData> _workouts = [
    _WorkoutCardData(
      title: 'Push-up',
      description: 'Klasik itis hareketi. Govdeyi sabit tutarak kontrollu calis.',
      muscleGroups: ['Gogus', 'Omuz', 'Triceps', 'Core'],
      level: 'Beginner',
    ),
    _WorkoutCardData(
      title: 'Pull-up',
      description: 'Bar cekisi. Sirt ve kol kuvveti icin temel hareket.',
      muscleGroups: ['Sirt', 'Biceps', 'Core'],
      level: 'Intermediate',
    ),
    _WorkoutCardData(
      title: 'Dips',
      description: 'Paralel bar itis. Gogus ve triceps odakli.',
      muscleGroups: ['Gogus', 'Triceps', 'Omuz'],
      level: 'Intermediate',
    ),
    _WorkoutCardData(
      title: 'Pike Push-up',
      description: 'Omuzlara yuklenen bir itis varyasyonu.',
      muscleGroups: ['Omuz', 'Triceps', 'Ust Gogus'],
      level: 'Intermediate',
    ),
    _WorkoutCardData(
      title: 'Squat',
      description: 'Vucut agirligi squat ile temel bacak kuvveti.',
      muscleGroups: ['Quadriceps', 'Glute', 'Hamstring'],
      level: 'Beginner',
    ),
    _WorkoutCardData(
      title: 'Hollow Hold',
      description: 'Core stabilitesi icin sabit tutus.',
      muscleGroups: ['Core', 'Alt Karin'],
      level: 'Beginner',
    ),
  ];

  @override
  State<WorkoutLibraryScreen> createState() => _WorkoutLibraryScreenState();
}

class _WorkoutLibraryScreenState extends State<WorkoutLibraryScreen> {
  final Set<String> _selectedMuscleGroups = {};

  List<String> get _allMuscleGroups {
    final groups = <String>{};
    for (final workout in WorkoutLibraryScreen._workouts) {
      groups.addAll(workout.muscleGroups);
    }
    final sorted = groups.toList()..sort();
    return sorted;
  }

  void _toggleMuscleGroup(String group) {
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
    final filteredWorkouts = _selectedMuscleGroups.isEmpty
        ? WorkoutLibraryScreen._workouts
        : WorkoutLibraryScreen._workouts
            .where(
              (workout) => _selectedMuscleGroups
                  .every((group) => workout.muscleGroups.contains(group)),
            )
            .toList();
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
            child: CustomScrollView(
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
                              'Workout Library',
                              style:
                                  Theme.of(context).textTheme.titleLarge?.copyWith(
                                        color: WorkoutLibraryScreen._textHigh,
                                        fontWeight: FontWeight.w800,
                                      ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Calisthenics hareketleri',
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
                      'Hareket kartlarina dokunup detayli bilgi alabilirsin.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: WorkoutLibraryScreen._textMid,
                          ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
                    child: _BodyMap(
                      availableGroups: _allMuscleGroups,
                      selectedGroups: _selectedMuscleGroups,
                      onToggleGroup: _toggleMuscleGroup,
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
                          child: _WorkoutCard(data: item),
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
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
    );
  }
}

class _WorkoutCardData {
  const _WorkoutCardData({
    required this.title,
    required this.description,
    required this.muscleGroups,
    required this.level,
  });

  final String title;
  final String description;
  final List<String> muscleGroups;
  final String level;
}

class _BodyMap extends StatelessWidget {
  const _BodyMap({
    required this.availableGroups,
    required this.selectedGroups,
    required this.onToggleGroup,
    required this.onClear,
  });

  final List<String> availableGroups;
  final Set<String> selectedGroups;
  final ValueChanged<String> onToggleGroup;
  final VoidCallback onClear;

  static const List<_MuscleMarker> _markers = [
    _MuscleMarker(group: 'Ust Gogus', position: Offset(0.50, 0.26)),
    _MuscleMarker(group: 'Gogus', position: Offset(0.50, 0.32)),
    _MuscleMarker(group: 'Omuz', position: Offset(0.32, 0.28)),
    _MuscleMarker(group: 'Biceps', position: Offset(0.22, 0.36)),
    _MuscleMarker(group: 'Triceps', position: Offset(0.78, 0.36)),
    _MuscleMarker(group: 'Core', position: Offset(0.50, 0.46)),
    _MuscleMarker(group: 'Alt Karin', position: Offset(0.50, 0.56)),
    _MuscleMarker(group: 'Sirt', position: Offset(0.80, 0.30)),
    _MuscleMarker(group: 'Glute', position: Offset(0.50, 0.64)),
    _MuscleMarker(group: 'Quadriceps', position: Offset(0.44, 0.76)),
    _MuscleMarker(group: 'Hamstring', position: Offset(0.56, 0.82)),
  ];

  @override
  Widget build(BuildContext context) {
    final activeMarkers = _markers
        .where((marker) => availableGroups.contains(marker.group))
        .toList();

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
                  'Vucut haritasi',
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
              'Kas gruplarinin yerini gor ve dokunarak filtrele.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WorkoutLibraryScreen._textMid,
                  ),
            ),
            const SizedBox(height: 14.0),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final height = width * 1.15;
                return SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.asset(
                          'assets/images/body_map.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Align(
                              alignment: Alignment.center,
                              child: _BodySilhouette(
                                color: WorkoutLibraryScreen._cardSurfaceSoft,
                              ),
                            );
                          },
                        ),
                      ),
                      for (final marker in activeMarkers)
                        _MuscleMarkerDot(
                          marker: marker,
                          size: Size(width, height),
                          isSelected: selectedGroups.contains(marker.group),
                          onTap: () => onToggleGroup(marker.group),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MuscleMarker {
  const _MuscleMarker({required this.group, required this.position});

  final String group;
  final Offset position;
}

class _MuscleMarkerDot extends StatelessWidget {
  const _MuscleMarkerDot({
    required this.marker,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  final _MuscleMarker marker;
  final Size size;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dotColor = isSelected
        ? WorkoutLibraryScreen._accentPurple
        : WorkoutLibraryScreen._textMid;
    final bgColor = isSelected
        ? WorkoutLibraryScreen._accentPurple.withOpacity(0.18)
        : WorkoutLibraryScreen._cardSurface.withOpacity(0.65);

    return Positioned(
      left: (size.width * marker.position.dx) - 24.0,
      top: (size.height * marker.position.dy) - 16.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: dotColor.withOpacity(0.6),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8.0,
                height: 8.0,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dotColor,
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                marker.group,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: WorkoutLibraryScreen._textHigh,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BodySilhouette extends StatelessWidget {
  const _BodySilhouette({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52.0,
          height: 52.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.55),
          ),
        ),
        const SizedBox(height: 8.0),
        Container(
          width: 120.0,
          height: 140.0,
          decoration: BoxDecoration(
            color: color.withOpacity(0.65),
            borderRadius: BorderRadius.circular(40.0),
          ),
          child: Stack(
            children: [
              Positioned(
                left: -30.0,
                top: 20.0,
                child: Container(
                  width: 40.0,
                  height: 90.0,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
              Positioned(
                right: -30.0,
                top: 20.0,
                child: Container(
                  width: 40.0,
                  height: 90.0,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10.0),
        Container(
          width: 86.0,
          height: 36.0,
          decoration: BoxDecoration(
            color: color.withOpacity(0.6),
            borderRadius: BorderRadius.circular(26.0),
          ),
        ),
        const SizedBox(height: 10.0),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.0,
              height: 110.0,
              decoration: BoxDecoration(
                color: color.withOpacity(0.55),
                borderRadius: BorderRadius.circular(26.0),
              ),
            ),
            const SizedBox(width: 12.0),
            Container(
              width: 40.0,
              height: 110.0,
              decoration: BoxDecoration(
                color: color.withOpacity(0.55),
                borderRadius: BorderRadius.circular(26.0),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({required this.data});

  final _WorkoutCardData data;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 20.0,
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
                        data.title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: WorkoutLibraryScreen._textHigh,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        data.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: WorkoutLibraryScreen._textMid,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                _LevelPill(level: data.level),
              ],
            ),
            const SizedBox(height: 12.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: data.muscleGroups
                  .map(
                    (group) => _MuscleChip(label: group),
                  )
                  .toList(),
            ),
          ],
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
