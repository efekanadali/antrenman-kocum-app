// lib/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/presentation/providers/exercise_list_provider.dart';
import 'package:calisthenics_app/presentation/providers/filter_provider.dart';
import 'package:calisthenics_app/presentation/providers/favorite_provider.dart';
import 'package:calisthenics_app/presentation/widgets/exercise_card.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(filteredExerciseListProvider);
    final filterState = ref.watch(filterStateNotifierProvider);
    final favorites = ref.watch(favoriteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calisthenics Exercises'),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.favorites);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Level Selector
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<ExerciseLevel?>(
              value: filterState.level,
              decoration: InputDecoration(
                labelText: 'Select Level',
                labelStyle: Theme.of(context).textTheme.bodyMedium,
                border: const OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<ExerciseLevel?>(
                  value: null,
                  child: Text('All Levels'),
                ),
                ...ExerciseLevel.values.map((level) => DropdownMenuItem(
                      value: level,
                      child: Text(level.name.toUpperCase()),
                    )),
              ],
              onChanged: (value) {
                ref.read(filterStateNotifierProvider.notifier).setLevel(value);
              },
            ),
          ),
          // Muscle Group Filters
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Wrap(
              spacing: 8.0,
              children: MuscleGroup.values.map((muscle) {
                final isSelected = filterState.muscleGroups.contains(muscle);
                return FilterChip(
                  label: Text(muscle.name.toUpperCase()),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(filterStateNotifierProvider.notifier).toggleMuscleGroup(muscle);
                  },
                );
              }).toList(),
            ),
          ),
          // Exercise List
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (exercises) => ListView.builder(
                itemCount: exercises.length,
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  final isFavorite = favorites.contains(exercise.id);
                  return ExerciseCard(
                    exercise: exercise,
                    isFavorite: isFavorite,
                    onFavoriteToggle: () {
                      ref.read(favoriteProvider.notifier).toggleFavorite(exercise.id);
                    },
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        AppRoutes.detail,
                        arguments: exercise,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}