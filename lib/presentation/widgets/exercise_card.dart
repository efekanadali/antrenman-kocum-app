// lib/presentation/widgets/exercise_card.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

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

  Color _levelColor(ExerciseLevel level) {
    switch (level) {
      case ExerciseLevel.beginner:
        return AppColors.emerald;
      case ExerciseLevel.intermediate:
        return AppColors.amber;
      case ExerciseLevel.advanced:
        return AppColors.volcanic;
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
    final stripeColor = _levelColor(exercise.level);
    final levelName = _levelName(exercise.level);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 3px Zarif Dikey Seviye Şeridi
                Container(
                  width: 3.5,
                  color: stripeColor,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Koyu Mat Grafit İkon Kutusu
                        Container(
                          width: 42.0,
                          height: 42.0,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          child: const Icon(
                            Icons.fitness_center_rounded,
                            color: AppColors.textHigh,
                            size: 20.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercise.name,
                                style: const TextStyle(
                                  color: AppColors.textHigh,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 8.0),
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: [
                                  _buildBadge(levelName, stripeColor),
                                  _buildBadge(
                                    exercise.difficulty.label.toUpperCase(),
                                    AppColors.textMid,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8.0),
                              Text(
                                _formatTargets(exercise.targetMuscleGroups),
                                style: const TextStyle(
                                  color: AppColors.textMid,
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4.0),
                              Text(
                                '${exercise.name} hareketi için kas aktivasyon dağılımı.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        IconButton(
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite
                                ? AppColors.volcanic
                                : AppColors.textMuted,
                          ),
                          iconSize: 22.0,
                          onPressed: onFavoriteToggle,
                          padding: const EdgeInsets.all(4.0),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
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
    switch (muscle.label.toLowerCase()) {
      case 'chest':
        return 'Göğüs';
      case 'back':
        return 'Sırt';
      case 'shoulders':
        return 'Omuz';
      case 'legs':
        return 'Bacak';
      case 'core':
        return 'Karın';
      case 'biceps':
        return 'Biceps';
      case 'triceps':
        return 'Triceps';
      case 'quads':
        return 'Ön Bacak';
      case 'hamstrings':
        return 'Arka Bacak';
      case 'glutes':
        return 'Kalça';
      case 'calves':
        return 'Kalf';
      default:
        return muscle.label.toUpperCase();
    }
  }
}
