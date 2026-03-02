// lib/presentation/widgets/exercise_card.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      color: colorScheme.surface,
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 0.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    Wrap(
                      spacing: 8.0,
                      runSpacing: 6.0,
                      children: [
                        _buildBadge(context, exercise.level.label),
                        _buildBadge(context, exercise.difficulty.label),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    Text(
                      _formatTargets(exercise.targetMuscleGroups),
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6.0),
                    Text(
                      exercise.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite
                      ? colorScheme.primary
                      : colorScheme.onSurface.withOpacity(0.6),
                ),
                iconSize: 22.0,
                onPressed: onFavoriteToggle,
                splashRadius: 22.0,
                padding: const EdgeInsets.all(6.0),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, String text) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  String _formatTargets(List<MuscleGroup> muscles) {
    if (muscles.isEmpty) {
      return 'Hedef: Genel';
    }
    final names = muscles.map(_localizedMuscleName).join(', ');
    return 'Hedef: $names';
  }

  String _localizedMuscleName(MuscleGroup muscle) {
    switch (muscle.label) {
      case 'chest':
        return 'Gogus';
      case 'back':
        return 'Sirt';
      case 'shoulders':
        return 'Omuz';
      case 'legs':
        return 'Bacak';
      case 'core':
        return 'Karin';
      default:
        return muscle.label.toUpperCase();
    }
  }
}
