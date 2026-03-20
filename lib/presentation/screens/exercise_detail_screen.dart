// lib/presentation/screens/exercise_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';

final _allExercisesProvider = FutureProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).getAllExercises();
});

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  static const Color _bgTop = Color(0xFF151028);
  static const Color _bgBottom = Color(0xFF0E0A1D);
  static const Color _cardSurface = Color(0xFF201836);
  static const Color _cardSurfaceSoft = Color(0xFF2A2048);
  static const Color _accentPurple = Color(0xFF6D5BFF);
  static const Color _accentBlue = Color(0xFF4FC3F7);
  static const Color _textHigh = Color(0xFFEDE9FF);
  static const Color _textMid = Color(0xFFB4A9D8);

  int _clampRating(int rating) {
    if (rating < 1) {
      return 1;
    }
    if (rating > 5) {
      return 5;
    }
    return rating;
  }

  double _ratingToPercent(int rating) {
    final clamped = _clampRating(rating);
    return clamped / 5.0;
  }

  String _activationLabel(int rating) {
    switch (_clampRating(rating)) {
      case 1:
        return 'Cok Dusuk Aktivasyon';
      case 2:
        return 'Dusuk Aktivasyon';
      case 3:
        return 'Orta Aktivasyon';
      case 4:
        return 'Yuksek Aktivasyon';
      default:
        return 'Cok Yuksek Aktivasyon';
    }
  }

  Color _segmentColor(int segmentIndex) {
    switch (segmentIndex) {
      case 0:
        return const Color(0xFFEB5757);
      case 1:
        return const Color(0xFFF2994A);
      case 2:
        return const Color(0xFFF2C94C);
      case 3:
        return const Color(0xFF59D2FE);
      default:
        return const Color(0xFF3DDC84);
    }
  }

  Color _prerequisiteAccent(ExerciseLevel level) {
    switch (level) {
      case ExerciseLevel.beginner:
        return _accentBlue;
      case ExerciseLevel.intermediate:
        return const Color(0xFF36CFC9);
      case ExerciseLevel.advanced:
        return const Color(0xFFFF7A59);
    }
  }

  String _prerequisiteLevelLabel(ExerciseLevel level) {
    switch (level) {
      case ExerciseLevel.beginner:
        return 'Baslangic';
      case ExerciseLevel.intermediate:
        return 'Orta Seviye';
      case ExerciseLevel.advanced:
        return 'Ileri Seviye';
    }
  }

  Widget _buildRatingBar(BuildContext context, int rating) {
    final clamped = _clampRating(rating);
    final percent = _ratingToPercent(rating).clamp(0.0, 1.0);
    final activationLabel = _activationLabel(clamped);
    final segmentGap = 4.0;
    final segmentCount = 5;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(segmentCount, (index) {
              final isActive = index < clamped;
              return Expanded(
                child: Container(
                  height: 10.0,
                  margin: EdgeInsets.only(
                    right: index == segmentCount - 1 ? 0.0 : segmentGap,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? _segmentColor(index)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(999.0),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 8.0),
        Text(
          '${(percent * 100).round()}% · $activationLabel',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: ExerciseDetailScreen._textMid,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
        ),
      ],
    );
  }

  Exercise? _findExerciseByName({
    required List<Exercise> allExercises,
    required String name,
  }) {
    final normalizedName = name.trim().toLowerCase();
    for (final item in allExercises) {
      if (item.name.trim().toLowerCase() == normalizedName) {
        return item;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muscleRatings = exercise.targetMuscleGroups
        .map((muscle) => MapEntry(muscle, exercise.muscleRatings[muscle] ?? 1))
        .toList();
    final prerequisiteAccent = _prerequisiteAccent(exercise.level);
    final prerequisiteLevelLabel = _prerequisiteLevelLabel(exercise.level);
    final allExercisesAsync = ref.watch(_allExercisesProvider);

    return Scaffold(
      backgroundColor: _bgBottom,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_bgTop, _bgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -110.0,
            left: -70.0,
            child: Container(
              width: 220.0,
              height: 220.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentPurple.withOpacity(0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -120.0,
            right: -50.0,
            child: Container(
              width: 240.0,
              height: 240.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentBlue.withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _BackButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: _textHigh,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Hareket Detayı',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: _textMid,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  if (exercise.prerequisiteExercises.isNotEmpty) ...[
                    _GlassCard(
                      borderRadius: 20.0,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Uzmanlasman Gereken Hareketler',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: _textHigh,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 6.0,
                                  ),
                                  decoration: BoxDecoration(
                                    color: prerequisiteAccent.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(999.0),
                                    border: Border.all(
                                      color: prerequisiteAccent.withOpacity(
                                        0.4,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    prerequisiteLevelLabel,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: prerequisiteAccent,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12.0),
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: exercise.prerequisiteExercises
                                  .map(
                                    (name) {
                                      final matchedExercise =
                                          allExercisesAsync.maybeWhen(
                                            data: (allExercises) =>
                                                _findExerciseByName(
                                                  allExercises: allExercises,
                                                  name: name,
                                                ),
                                            orElse: () => null,
                                          );

                                      return Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          borderRadius: BorderRadius.circular(
                                            999.0,
                                          ),
                                          onTap: matchedExercise == null
                                              ? null
                                              : () {
                                                  Navigator.pushNamed(
                                                    context,
                                                    AppRoutes.detail,
                                                    arguments: matchedExercise,
                                                  );
                                                },
                                          child: Ink(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10.0,
                                              vertical: 6.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _cardSurfaceSoft,
                                              borderRadius:
                                                  BorderRadius.circular(999.0),
                                              border: Border.all(
                                                color: prerequisiteAccent
                                                    .withOpacity(0.28),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.check_circle_outline,
                                                  size: 14.0,
                                                  color: prerequisiteAccent,
                                                ),
                                                const SizedBox(width: 6.0),
                                                Text(
                                                  name,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: _textHigh,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                  ],
                  _GlassCard(
                    borderRadius: 20.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          _InfoPill(
                            label: 'Seviye',
                            value: exercise.level.label,
                          ),
                          const SizedBox(width: 10.0),
                          _InfoPill(
                            label: 'Zorluk',
                            value: exercise.difficulty.label,
                            accent: _accentBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _GlassCard(
                    borderRadius: 20.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Çalıştırdığı Bölgeler',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: _textHigh,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 12.0),
                          Column(
                            children: muscleRatings
                                .map(
                                  (entry) => Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 10.0,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: _RegionRatingChip(
                                        label: entry.key.label,
                                        rating: entry.value,
                                        barBuilder: (rating) =>
                                            _buildRatingBar(context, rating),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  _GlassCard(
                    borderRadius: 20.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detayli Aciklama',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: _textHigh,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            exercise.description,
                            style: Theme.of(
                              context,
                            ).textTheme.bodyLarge?.copyWith(color: _textMid),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
          color: ExerciseDetailScreen._cardSurface,
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: const SizedBox(
          width: 44.0,
          height: 44.0,
          child: Icon(
            Icons.arrow_back_rounded,
            color: ExerciseDetailScreen._textHigh,
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
      child: Container(
        decoration: BoxDecoration(
          color: ExerciseDetailScreen._cardSurface.withOpacity(0.78),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
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
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value, this.accent});

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? ExerciseDetailScreen._accentPurple;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: ExerciseDetailScreen._cardSurfaceSoft,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: ExerciseDetailScreen._textMid,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: accentColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RegionRatingChip extends StatelessWidget {
  const _RegionRatingChip({
    required this.label,
    required this.rating,
    required this.barBuilder,
  });

  final String label;
  final int rating;
  final Widget Function(int rating) barBuilder;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(16.0),
        splashColor: ExerciseDetailScreen._accentBlue.withOpacity(0.16),
        highlightColor: ExerciseDetailScreen._accentBlue.withOpacity(0.08),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: ExerciseDetailScreen._cardSurfaceSoft,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: ExerciseDetailScreen._textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6.0),
                barBuilder(rating),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
