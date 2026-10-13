// lib/presentation/screens/exercise_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

final _allExercisesProvider = FutureProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).getAllExercises();
});

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  int _clampRating(int rating) {
    if (rating < 1) return 1;
    if (rating > 5) return 5;
    return rating;
  }

  double _ratingToPercent(int rating) {
    final clamped = _clampRating(rating);
    return clamped / 5.0;
  }

  Color _activationColor(double percent) {
    if (percent >= 0.8) {
      return AppColors.volcanic; // %80-100: Volkanik Turuncu (#FF5533)
    } else if (percent >= 0.5) {
      return AppColors.amber; // %50-70: Kehribar Sarı (#F59E0B)
    } else {
      return AppColors.emerald; // Düşük: Zümrüt Yeşili (#10B981)
    }
  }

  String _activationLabel(int rating) {
    switch (_clampRating(rating)) {
      case 1:
        return 'Çok Düşük Aktivasyon';
      case 2:
        return 'Düşük Aktivasyon';
      case 3:
        return 'Orta Aktivasyon';
      case 4:
        return 'Yüksek Aktivasyon';
      default:
        return 'Maksimum Aktivasyon';
    }
  }

  String _prerequisiteLevelLabel(ExerciseLevel level) {
    switch (level) {
      case ExerciseLevel.beginner:
        return 'Başlangıç';
      case ExerciseLevel.intermediate:
        return 'Orta Seviye';
      case ExerciseLevel.advanced:
        return 'İleri Seviye';
    }
  }

  String _localizedMuscleName(MuscleGroup group) {
    switch (group) {
      case MuscleGroup.chest:
        return 'Göğüs';
      case MuscleGroup.back:
        return 'Sırt';
      case MuscleGroup.shoulders:
        return 'Omuz';
      case MuscleGroup.biceps:
        return 'Biceps';
      case MuscleGroup.triceps:
        return 'Triceps';
      case MuscleGroup.core:
        return 'Karın / Core';
      case MuscleGroup.quads:
        return 'Ön Bacak';
      case MuscleGroup.hamstrings:
        return 'Arka Bacak';
      case MuscleGroup.glutes:
        return 'Kalça';
      case MuscleGroup.calves:
        return 'Kalf';
      case MuscleGroup.legs:
        return 'Bacak';
    }
  }

  Widget _buildActivationBar(BuildContext context, MuscleGroup muscle, int rating) {
    final clamped = _clampRating(rating);
    final percent = _ratingToPercent(clamped);
    final color = _activationColor(percent);
    final label = _activationLabel(clamped);
    final muscleName = _localizedMuscleName(muscle);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                muscleName,
                style: const TextStyle(
                  color: AppColors.textHigh,
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
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
                  '%${(percent * 100).round()} · $label',
                  style: TextStyle(
                    color: color,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(999.0),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 6.0,
              backgroundColor: AppColors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormattedDescription(BuildContext context, String description) {
    final rawLines = description.split('\n');
    final sections = <_DescriptionSection>[];

    String currentTitle = '';
    final currentLines = <String>[];

    for (final rawLine in rawLines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      if (line.startsWith('Kurulum:') ||
          line.startsWith('Uygulama:') ||
          line.startsWith('Ipucu:') ||
          line.startsWith('İpucu:') ||
          line.startsWith('Sik hata:') ||
          line.startsWith('Sık hata:')) {
        if (currentTitle.isNotEmpty || currentLines.isNotEmpty) {
          sections.add(_DescriptionSection(
            title: currentTitle,
            body: currentLines.join(' '),
          ));
          currentLines.clear();
        }
        final colonIndex = line.indexOf(':');
        currentTitle = line.substring(0, colonIndex + 1);
        final rest = line.substring(colonIndex + 1).trim();
        if (rest.isNotEmpty) {
          currentLines.add(rest);
        }
      } else {
        currentLines.add(line);
      }
    }

    if (currentTitle.isNotEmpty || currentLines.isNotEmpty) {
      sections.add(_DescriptionSection(
        title: currentTitle,
        body: currentLines.join(' '),
      ));
    }

    if (sections.isEmpty) {
      return Text(
        description,
        style: const TextStyle(
          color: AppColors.textMid,
          fontSize: 14.0,
          height: 1.5,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        Color dotColor = AppColors.nordicIce;
        final lower = section.title.toLowerCase();
        if (lower.contains('uygulama')) {
          dotColor = AppColors.volcanic;
        } else if (lower.contains('pucu')) {
          dotColor = AppColors.amber;
        } else if (lower.contains('hata')) {
          dotColor = const Color(0xFFEF4444);
        } else if (lower.contains('kurulum')) {
          dotColor = AppColors.nordicIce;
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 14.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Küçük mat renkli nokta
              Container(
                margin: const EdgeInsets.only(top: 6.0, right: 10.0),
                width: 6.0,
                height: 6.0,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    children: [
                      if (section.title.isNotEmpty)
                        TextSpan(
                          text: '${section.title} ',
                          style: const TextStyle(
                            color: AppColors.textHigh,
                            fontSize: 14.0,
                            fontWeight: FontWeight.w700,
                            height: 1.5,
                          ),
                        ),
                      TextSpan(
                        text: section.body,
                        style: const TextStyle(
                          color: AppColors.textMid,
                          fontSize: 13.5,
                          height: 1.55,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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
    final prerequisiteLevelLabel = _prerequisiteLevelLabel(exercise.level);
    final allExercisesAsync = ref.watch(_allExercisesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Üst Gezinme Başlığı
              Row(
                children: [
                  _BackButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exercise.name,
                          style: const TextStyle(
                            color: AppColors.textHigh,
                            fontSize: 22.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3.0),
                        const Text(
                          'Biyomekanik Hareket Detayı',
                          style: TextStyle(
                            color: AppColors.textMid,
                            fontSize: 13.0,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Uzmanlaşman Gereken Hareketler Bölümü (Prerequisites)
              if (exercise.prerequisiteExercises.isNotEmpty) ...[
                Container(
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
                          const Expanded(
                            child: Text(
                              'Uzmanlaşman Gereken Hareketler',
                              style: TextStyle(
                                color: AppColors.textHigh,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          // Volkanik Turuncu Seviye Kapsülü
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 4.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.volcanic.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(
                                color: AppColors.volcanic.withValues(alpha: 0.35),
                                width: 1.0,
                              ),
                            ),
                            child: Text(
                              prerequisiteLevelLabel,
                              style: const TextStyle(
                                color: AppColors.volcanic,
                                fontSize: 11.0,
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
                        children: exercise.prerequisiteExercises.map((name) {
                          final matchedExercise = allExercisesAsync.maybeWhen(
                            data: (allExercises) => _findExerciseByName(
                              allExercises: allExercises,
                              name: name,
                            ),
                            orElse: () => null,
                          );

                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10.0),
                              onTap: matchedExercise == null
                                  ? null
                                  : () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.detail,
                                        arguments: matchedExercise,
                                      );
                                    },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10.0,
                                  vertical: 6.0,
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
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline_rounded,
                                      size: 14.0,
                                      color: AppColors.volcanic,
                                    ),
                                    const SizedBox(width: 6.0),
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: AppColors.textHigh,
                                        fontSize: 12.0,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14.0),
              ],

              // 2 Sütunlu Minimalist Mat Grafit Seviye / Zorluk Bölmeleri
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'SEVİYE',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              exercise.level.label,
                              style: const TextStyle(
                                color: AppColors.textHigh,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 12.0,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ZORLUK',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              exercise.difficulty.label,
                              style: const TextStyle(
                                color: AppColors.volcanic,
                                fontSize: 15.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14.0),

              // Çalıştırdığı Bölgeler (Kas Aktivasyon Bölümü)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Çalıştırdığı Bölgeler',
                      style: TextStyle(
                        color: AppColors.textHigh,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Column(
                      children: muscleRatings.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: _buildActivationBar(
                            context,
                            entry.key,
                            entry.value,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14.0),

              // Detaylı Açıklama (Kurulum, Uygulama, İpucu, Sık Hata)
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border, width: 1.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detaylı Açıklama & Form İpuçları',
                      style: TextStyle(
                        color: AppColors.textHigh,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 14.0),
                    _buildFormattedDescription(
                      context,
                      exercise.description,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DescriptionSection {
  const _DescriptionSection({required this.title, required this.body});
  final String title;
  final String body;
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
