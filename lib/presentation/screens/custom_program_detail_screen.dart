// lib/presentation/screens/custom_program_detail_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/screens/custom_program_day_session_screen.dart';
import 'package:calisthenics_app/domain/services/program_preview.dart';
import 'package:calisthenics_app/presentation/providers/muscle_recovery_provider.dart';
import 'package:calisthenics_app/presentation/widgets/program_preview_badge.dart';

class CustomProgramDetailScreen extends ConsumerWidget {
  const CustomProgramDetailScreen({
    super.key,
    required this.program,
  });

  final CustomProgram program;

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

  Widget _buildStarRating(BuildContext context, int rating) {
    final clamped = _clampRating(rating);
    final stars = List.generate(5, (index) {
      final isFilled = index < clamped;
      return Icon(
        isFilled ? Icons.star_rounded : Icons.star_border_rounded,
        size: 16.0,
        color: isFilled ? _accentBlue : Colors.white.withOpacity(0.18),
      );
    });

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: stars,
    );
  }

  Map<MuscleGroup, _MuscleSummary> _buildMuscleSummaries(
    List<Exercise> exercises,
  ) {
    final totals = <MuscleGroup, int>{};
    final weighted = <MuscleGroup, int>{};
    final exerciseMap = {
      for (final exercise in exercises) exercise.id: exercise,
    };

    for (final day in program.days) {
      for (final entry in day.exercises) {
        final exercise = exerciseMap[entry.exerciseId];
        if (exercise == null) {
          continue;
        }
        for (final muscle in exercise.targetMuscleGroups) {
          totals[muscle] = (totals[muscle] ?? 0) + entry.sets;
          final rating = exercise.muscleRatings[muscle] ?? 1;
          weighted[muscle] =
              (weighted[muscle] ?? 0) + (rating * entry.sets);
        }
      }
    }

    final summaries = <MuscleGroup, _MuscleSummary>{};
    for (final entry in totals.entries) {
      final totalSets = entry.value;
      final weightedSum = weighted[entry.key] ?? totalSets;
      final avg = (weightedSum / totalSets).round();
      summaries[entry.key] = _MuscleSummary(
        sets: totalSets,
        rating: _clampRating(avg),
      );
    }

    return summaries;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exerciseRepository = ref.watch(exerciseRepositoryProvider);
    final resolver = ref.watch(exerciseMliResolverProvider).valueOrNull;
    ProgramPreview? previewFor(Iterable<CustomProgramExercise> items) {
      if (resolver == null) return null;
      return estimateProgramPreview(items, resolver);
    }

    final programPreview = previewFor(
      program.days.expand((day) => day.exercises),
    );
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
            top: -120.0,
            left: -60.0,
            child: Container(
              width: 240.0,
              height: 240.0,
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
              width: 220.0,
              height: 220.0,
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
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _BackButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  Text(
                    program.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: _textHigh,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Program Detayı',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _textMid,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 16.0),
                  _GlassCard(
                    borderRadius: 20.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          _InfoPill(
                            label: 'Gün',
                            value: '${program.daysCount}',
                          ),
                          const SizedBox(width: 10.0),
                          _InfoPill(
                            label: 'Egzersiz',
                            value: '${program.totalExercises}',
                            accent: _accentBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  if (programPreview != null) ...[
                    ProgramPreviewBadge(
                      title: 'Tahmini Haftalık İş Yükü',
                      preview: programPreview,
                      footnote:
                          'Tüm günlerin toplamı, RIR 2 varsayımıyla (kaldıraç × kas ağırlığı).',
                    ),
                    const SizedBox(height: 16.0),
                  ],
                  for (final day in program.days)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: _GlassCard(
                        borderRadius: 20.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36.0,
                                    height: 36.0,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _accentPurple.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      '${day.dayIndex}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: _textHigh,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Text(
                                    day.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: _textHigh,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12.0),
                              if (day.exercises.isEmpty)
                                Text(
                                  'Bu gün için egzersiz eklenmedi.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: _textMid),
                                )
                              else
                                Column(
                                  children: [
                                    for (final exercise in day.exercises)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10.0),
                                        child: Container(
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: BoxDecoration(
                                            color:
                                                _cardSurfaceSoft.withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(14.0),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.08),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      exercise.exerciseName,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            color: _textHigh,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4.0),
                                                    Text(
                                                      exercise.isTimed
                                                          ? '${exercise.sets} set x ${exercise.value} sn'
                                                          : '${exercise.sets} set x ${exercise.value} tekrar',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: _textMid,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.check_circle_outline,
                                                color:
                                                    _accentBlue.withOpacity(0.6),
                                                size: 20.0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 4.0),
                              if (previewFor(day.exercises) case final dayPreview?)
                                if (!dayPreview.isEmpty) ...[
                                  ProgramPreviewBadge(
                                    title: 'Gün Önizlemesi',
                                    preview: dayPreview,
                                    compact: true,
                                  ),
                                  const SizedBox(height: 10.0),
                                ],
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: day.exercises.isEmpty
                                      ? null
                                      : () {
                                          Navigator.pushNamed(
                                            context,
                                            AppRoutes.customProgramDaySession,
                                            arguments:
                                                CustomProgramDaySessionArgs(
                                              programName: program.name,
                                              day: day,
                                            ),
                                          );
                                        },
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Antrenmana Başla'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _accentPurple,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8.0),
                  _GlassCard(
                    borderRadius: 20.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FutureBuilder<List<Exercise>>(
                        future: exerciseRepository.getAllExercises(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          if (snapshot.hasError) {
                            return Text(
                              'Bölge dağılımı yüklenemedi.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: _textMid),
                            );
                          }

                          final exercises = snapshot.data ?? <Exercise>[];
                          final summaries = _buildMuscleSummaries(exercises);
                          if (summaries.isEmpty) {
                            return Text(
                              'Bölge dağılımı için veri yok.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: _textMid),
                            );
                          }

                          final sorted = summaries.entries.toList()
                            ..sort(
                              (a, b) => b.value.sets.compareTo(a.value.sets),
                            );
                          final maxSets = sorted.first.value.sets;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bölge Dağılımı',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: _textHigh,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 6.0),
                              Text(
                                'Her bölge için toplam set ve etki puanı.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: _textMid),
                              ),
                              const SizedBox(height: 12.0),
                              Wrap(
                                spacing: 10.0,
                                runSpacing: 10.0,
                                children: [
                                  for (final entry in sorted)
                                    _RegionSetChip(
                                      label: entry.key.label,
                                      sets: entry.value.sets,
                                      rating: entry.value.rating,
                                      maxSets: maxSets,
                                      starBuilder: (rating) =>
                                          _buildStarRating(context, rating),
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
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
          color: CustomProgramDetailScreen._cardSurface,
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: const SizedBox(
          width: 44.0,
          height: 44.0,
          child: Icon(
            Icons.arrow_back_rounded,
            color: CustomProgramDetailScreen._textHigh,
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
            color: CustomProgramDetailScreen._cardSurface.withOpacity(0.78),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? CustomProgramDetailScreen._accentPurple;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: CustomProgramDetailScreen._cardSurfaceSoft,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: CustomProgramDetailScreen._textMid,
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

class _RegionSetChip extends StatelessWidget {
  const _RegionSetChip({
    required this.label,
    required this.sets,
    required this.rating,
    required this.maxSets,
    required this.starBuilder,
  });

  final String label;
  final int sets;
  final int rating;
  final int maxSets;
  final Widget Function(int rating) starBuilder;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: CustomProgramDetailScreen._cardSurfaceSoft,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: CustomProgramDetailScreen._textHigh,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4.0),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$sets set',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: CustomProgramDetailScreen._textMid,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              starBuilder(rating),
            ],
          ),
          const SizedBox(height: 8.0),
          _ProgressBar(value: maxSets == 0 ? 0 : sets / maxSets),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    return Container(
      height: 6.0,
      decoration: BoxDecoration(
        color: CustomProgramDetailScreen._cardSurface,
        borderRadius: BorderRadius.circular(999.0),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: CustomProgramDetailScreen._accentBlue.withOpacity(0.9),
            borderRadius: BorderRadius.circular(999.0),
          ),
        ),
      ),
    );
  }
}

class _MuscleSummary {
  const _MuscleSummary({
    required this.sets,
    required this.rating,
  });

  final int sets;
  final int rating;
}
