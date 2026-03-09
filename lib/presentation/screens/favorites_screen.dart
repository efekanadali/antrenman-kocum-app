// lib/presentation/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/providers/favorite_provider.dart';
import 'package:calisthenics_app/presentation/providers/filter_provider.dart';
import 'package:calisthenics_app/presentation/widgets/exercise_card.dart';
import 'package:calisthenics_app/presentation/widgets/empty_state.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Widget _buildNavIcon(
    BuildContext context, {
    required IconData icon,
    required bool selected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: selected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.transparent,
              colorScheme.primary.withOpacity(0.12),
              value,
            ),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: value == 0.0
                ? []
                : [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.25 * value),
                      blurRadius: 12.0,
                      spreadRadius: 1.0,
                    ),
                  ],
          ),
          child: Transform.scale(
            scale: 1.0 + (0.06 * value),
            child: Icon(
              icon,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  void _showSoonSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, {required int selectedIndex}) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
              blurRadius: 16.0,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68.0,
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            if (index == selectedIndex) {
              return;
            }

            if (index == 0) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            } else if (index == 1) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.trainingProgram,
                (route) => false,
              );
            } else if (index == 2) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.favorites,
                (route) => false,
              );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.userProfile,
                (route) => false,
              );
            }
          },
          destinations: [
            NavigationDestination(
              icon: _buildNavIcon(
                context,
                icon: Icons.fitness_center_outlined,
                selected: false,
              ),
              selectedIcon: _buildNavIcon(
                context,
                icon: Icons.fitness_center,
                selected: true,
              ),
              label: 'Hareketler',
            ),
            NavigationDestination(
              icon: _buildNavIcon(
                context,
                icon: Icons.event_note_outlined,
                selected: false,
              ),
              selectedIcon: _buildNavIcon(
                context,
                icon: Icons.event_note,
                selected: true,
              ),
              label: 'Antrenman Programı',
            ),
            NavigationDestination(
              icon: _buildNavIcon(
                context,
                icon: Icons.favorite_border,
                selected: false,
              ),
              selectedIcon: _buildNavIcon(
                context,
                icon: Icons.favorite,
                selected: true,
              ),
              label: 'Favoriler',
            ),
            NavigationDestination(
              icon: _buildNavIcon(
                context,
                icon: Icons.person_outline,
                selected: false,
              ),
              selectedIcon: _buildNavIcon(
                context,
                icon: Icons.person,
                selected: true,
              ),
              label: 'Kullanıcı',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseRepository = ref.watch(exerciseRepositoryProvider);
    final favorites = ref.watch(favoriteProvider);
    final filterState = ref.watch(filterStateNotifierProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 190,
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 28.0,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primaryContainer,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Favorilerin 💪',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Daha akıllı çalış. Güçlü kal.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withAlpha(230),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8.0),
            // Filter Section
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withAlpha(128),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Level Dropdown
                  DropdownButtonFormField<ExerciseLevel?>(
                    initialValue: filterState.level,
                    decoration: InputDecoration(
                      labelText: 'Seviyeye göre filtrele',
                      labelStyle: Theme.of(context).textTheme.bodyMedium,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 14.0,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<ExerciseLevel?>(
                        value: null,
                        child: Text('Tüm seviyeler'),
                      ),
                      ...ExerciseLevel.values.map(
                        (level) => DropdownMenuItem(
                          value: level,
                          child: Text(level.label.toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      ref
                          .read(filterStateNotifierProvider.notifier)
                          .setLevel(value);
                    },
                  ),
                  const SizedBox(height: 16.0),
                  // Muscle Group Chips
                  Text(
                    'Hedef Kas Grupları',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  Wrap(
                    spacing: 12.0,
                    runSpacing: 12.0,
                    children: MuscleGroup.values.map((muscle) {
                      final isSelected = filterState.muscleGroups.contains(
                        muscle,
                      );
                      return FilterChip(
                        label: Text(
                          muscle.label.toUpperCase(),
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: isSelected ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        selected: isSelected,
                        onSelected: (selected) {
                          ref
                              .read(filterStateNotifierProvider.notifier)
                              .toggleMuscleGroup(muscle);
                        },
                        backgroundColor: Colors.transparent,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        side: BorderSide(
                          color: isSelected
                              ? Colors.transparent
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withAlpha(102),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Exercise>>(
                future: exerciseRepository.getAllExercises(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Hata: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const EmptyState(title: 'Henüz favori eklemedin');
                  } else {
                    final exercises = snapshot.data!;
                    var favoriteExercises = exercises
                        .where((exercise) => favorites.contains(exercise.id))
                        .toList();

                    // Apply level filter
                    if (filterState.level != null) {
                      favoriteExercises = favoriteExercises
                          .where((ex) => ex.level == filterState.level)
                          .toList();
                    }

                    // Apply muscle group filters
                    if (filterState.muscleGroups.isNotEmpty) {
                      favoriteExercises = favoriteExercises
                          .where(
                            (ex) => ex.targetMuscleGroups.any(
                              (mg) => filterState.muscleGroups.contains(mg),
                            ),
                          )
                          .toList();
                    }

                    if (favoriteExercises.isEmpty) {
                      return const EmptyState(
                        title: 'Filtrelerle eşleşen favori yok',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 16.0,
                      ),
                      itemCount: favoriteExercises.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8.0),
                      itemBuilder: (context, index) {
                        final exercise = favoriteExercises[index];
                        final isFavorite = favorites.contains(exercise.id);
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(18.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withAlpha(31),
                                  blurRadius: 12.0,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18.0),
                              child: Material(
                                color: Colors.transparent,
                                child: ExerciseCard(
                                  exercise: exercise,
                                  isFavorite: isFavorite,
                                  onFavoriteToggle: () {
                                    ref
                                        .read(favoriteProvider.notifier)
                                        .toggleFavorite(exercise.id);
                                  },
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.detail,
                                      arguments: exercise,
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, selectedIndex: 2),
    );
  }
}
