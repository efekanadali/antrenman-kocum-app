// lib/presentation/screens/exercise_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level
            Text(
              'Level: ${exercise.level.name.toUpperCase()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            // Difficulty Chip
            Chip(
              label: Text('Difficulty: ${exercise.difficulty.name.toUpperCase()}'),
            ),
            const SizedBox(height: 16.0),
            // Target Muscle Groups
            Text(
              'Target Muscle Groups:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: exercise.targetMuscleGroups.map((muscle) {
                return Chip(
                  label: Text(muscle.name.toUpperCase()),
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),
            // Description
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              exercise.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}