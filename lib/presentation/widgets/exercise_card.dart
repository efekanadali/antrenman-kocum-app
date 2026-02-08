// lib/presentation/widgets/exercise_card.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';

class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  final Exercise exercise;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        title: Text(
          exercise.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Level: ${exercise.level.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              'Difficulty: ${exercise.difficulty.name}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Text(
              exercise.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : null,
          ),
          onPressed: onFavoriteToggle,
        ),
        onTap: onTap,
      ),
    );
  }
}