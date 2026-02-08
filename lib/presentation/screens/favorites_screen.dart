// lib/presentation/screens/favorites_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/providers/favorite_provider.dart';
import 'package:calisthenics_app/presentation/widgets/exercise_card.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseRepository = ref.watch(exerciseRepositoryProvider);
    final favorites = ref.watch(favoriteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Exercises'),
      ),
      body: FutureBuilder<List<Exercise>>(
        future: exerciseRepository.getAllExercises(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 64.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    'Henüz favori eklemedin',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          } else {
            final exercises = snapshot.data!;
            final favoriteExercises = exercises.where((exercise) => favorites.contains(exercise.id)).toList();

            if (favoriteExercises.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 64.0,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16.0),
                    Text(
                      'Henüz favori eklemedin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              itemCount: favoriteExercises.length,
              itemBuilder: (context, index) {
                final exercise = favoriteExercises[index];
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
            );
          }
        },
      ),
    );
  }
}