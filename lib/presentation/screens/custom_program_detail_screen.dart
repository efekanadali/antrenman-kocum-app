// lib/presentation/screens/custom_program_detail_screen.dart

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
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

class CustomProgramDetailScreen extends ConsumerWidget {
  const CustomProgramDetailScreen({
    super.key,
    required this.program,
  });

  final CustomProgram program;

  int _clampRating(int rating) {
    if (rating < 1) return 1;
    if (rating > 5) return 5;
    return rating;
  }

  Widget _buildStarRating(BuildContext context, int rating) {
    final clamped = _clampRating(rating);
    final stars = List.generate(5, (index) {
      final isFilled = index < clamped;
      return Icon(
        isFilled ? Icons.star_rounded : Icons.star_border_rounded,
        size: 15.0,
        color: isFilled ? AppColors.amber : AppColors.textMuted,
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _BackButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              const SizedBox(height: 14.0),
              Text(
                program.name,
                style: const TextStyle(
                  color: AppColors.textHigh,
                  fontSize: 22.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 3.0),
              const Text(
                'Özel Program Mimarisi & Gün Dağılımı',
                style: TextStyle(
                  color: AppColors.textMid,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16.0),

              // Metrik Kapsülleri (Gün & Egzersiz)
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Row(
                  children: [
                    _InfoPill(
                      label: 'Gün Sayısı',
                      value: '${program.daysCount} Gün',
                    ),
                    const SizedBox(width: 10.0),
                    _InfoPill(
                      label: 'Toplam Egzersiz',
                      value: '${program.totalExercises}',
                      accent: AppColors.volcanic,
                    ),
                  ],
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

              // Gün Kartları
              for (final day in program.days)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 32.0,
                              height: 32.0,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.volcanic.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: AppColors.volcanic.withValues(alpha: 0.35),
                                  width: 1.0,
                                ),
                              ),
                              child: Text(
                                '${day.dayIndex}',
                                style: const TextStyle(
                                  color: AppColors.volcanic,
                                  fontSize: 13.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: Text(
                                day.name,
                                style: const TextStyle(
                                  color: AppColors.textHigh,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12.0),
                        if (day.exercises.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 6.0),
                            child: Text(
                              'Bu gün için egzersiz eklenmedi.',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12.5,
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              for (final exercise in day.exercises)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12.0,
                                      vertical: 10.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceSoft,
                                      borderRadius: BorderRadius.circular(10.0),
                                      border: Border.all(
                                        color: AppColors.border,
                                        width: 1.0,
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
                                                style: const TextStyle(
                                                  color: AppColors.textHigh,
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 2.0),
                                              Text(
                                                exercise.isTimed
                                                    ? '${exercise.sets} set × ${exercise.value} sn'
                                                    : '${exercise.sets} set × ${exercise.value} tekrar',
                                                style: const TextStyle(
                                                  color: AppColors.textMid,
                                                  fontSize: 11.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.check_circle_rounded,
                                          color: AppColors.emerald,
                                          size: 18.0,
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
                          height: 42.0,
                          child: FilledButton.icon(
                            onPressed: day.exercises.isEmpty
                                ? null
                                : () {
                                    Navigator.pushNamed(
                                      context,
                                      AppRoutes.customProgramDaySession,
                                      arguments: CustomProgramDaySessionArgs(
                                        programName: program.name,
                                        day: day,
                                      ),
                                    );
                                  },
                            icon: const Icon(Icons.play_arrow_rounded, size: 18.0),
                            label: const Text(
                              'Antrenmana Başla',
                              style: TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.volcanic,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 8.0),

              // Kas Grubu Dağılımı Kartı
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: FutureBuilder<List<Exercise>>(
                  future: exerciseRepository.getAllExercises(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.volcanic,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return const Text(
                        'Bölge dağılımı yüklenemedi.',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 12.0,
                        ),
                      );
                    }

                    final exercises = snapshot.data ?? <Exercise>[];
                    final summaries = _buildMuscleSummaries(exercises);
                    if (summaries.isEmpty) {
                      return const Text(
                        'Bölge dağılımı için veri yok.',
                        style: TextStyle(
                          color: AppColors.textMid,
                          fontSize: 12.0,
                        ),
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
                        const Text(
                          'Bölge Dağılımı',
                          style: TextStyle(
                            color: AppColors.textHigh,
                            fontSize: 15.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        const Text(
                          'Her kas grubu için toplam set ve etki puanı.',
                          style: TextStyle(
                            color: AppColors.textMid,
                            fontSize: 12.0,
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
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
            ],
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          width: 40.0,
          height: 40.0,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: AppColors.border, width: 1.0),
          ),
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textHigh,
            size: 20.0,
          ),
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
    final accentColor = accent ?? AppColors.textHigh;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceSoft,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3.0),
            Text(
              value,
              style: TextStyle(
                color: accentColor,
                fontSize: 15.0,
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
      width: (MediaQuery.of(context).size.width - 60) / 2,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textHigh,
              fontSize: 13.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4.0),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$sets set',
                  style: const TextStyle(
                    color: AppColors.textMid,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              starBuilder(rating),
            ],
          ),
          const SizedBox(height: 6.0),
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
      height: 4.0,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.volcanic,
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
