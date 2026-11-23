// lib/presentation/screens/exercise_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/enums/exercise_level.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/enums/muscle_group.dart';
import 'package:calisthenics_app/domain/services/muscle_filter.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';
import 'package:calisthenics_app/presentation/providers/exercise_repository_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';

final _allExercisesProvider = FutureProvider<List<Exercise>>((ref) {
  return ref.watch(exerciseRepositoryProvider).getAllExercises();
});

/// Bir bölgenin aktivasyon satırı. [percent] alt kompartıman yüzdelerinin
/// toplamıdır; böylece "Göğüs %55" ile "Üst %5 · Orta %30 · Alt %20" her
/// zaman tutarlıdır.
class _ActivationRow {
  const _ActivationRow({
    required this.name,
    required this.percent,
    required this.rating,
    required this.relative,
    required this.parts,
  });

  final String name;
  final int percent;
  final int rating;

  /// En baskın bölgeye göre 0–1.
  final double relative;
  final List<({String label, int percent})> parts;
}

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exercise});

  final Exercise exercise;

  int _clampRating(int rating) {
    if (rating < 1) return 1;
    if (rating > 5) return 5;
    return rating;
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

  /// Kompartıman ağırlıklarından bölge satırları. Kompartıman yüzdeleri tek
  /// tek yuvarlanır, bölge yüzdesi bunların toplamıdır.
  List<_ActivationRow> _activationRows() {
    final weights = exercise.compartmentWeights;
    if (weights.isEmpty) {
      // Eski veri: yalnızca 1–5 kas puanları var.
      return [
        for (final muscle in exercise.targetMuscleGroups)
          () {
            final rating = _clampRating(exercise.muscleRatings[muscle] ?? 1);
            return _ActivationRow(
              name: _localizedMuscleName(muscle),
              percent: rating * 20,
              rating: rating,
              relative: rating / 5,
              parts: const [],
            );
          }(),
      ];
    }
    final regions = targetRegions(weights);
    if (regions.isEmpty) return const [];

    final rows = <_ActivationRow>[];
    for (final region in regions) {
      final parts = [
        for (final c in region.compartments)
          if ((weights[c] ?? 0) > 0)
            (label: c.label, percent: ((weights[c] ?? 0) * 100).round()),
      ];
      rows.add(
        _ActivationRow(
          name: region.label,
          percent: parts.fold(0, (a, p) => a + p.percent),
          rating: 0,
          relative: 0,
          parts: parts,
        ),
      );
    }
    final maxPercent = rows.first.percent <= 0 ? 1 : rows.first.percent;
    return [
      for (final r in rows)
        _ActivationRow(
          name: r.name,
          percent: r.percent,
          rating: (r.percent / maxPercent * 5).round().clamp(1, 5).toInt(),
          relative: (r.percent / maxPercent).clamp(0.0, 1.0).toDouble(),
          parts: r.parts,
        ),
    ];
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
    final rows = _activationRows();
    final allExercisesAsync = ref.watch(_allExercisesProvider);
    final weights = exercise.compartmentWeights;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.sm,
            AppSpace.page,
            AppSpace.section,
          ),
          children: [
            _Header(title: exercise.name),
            const SizedBox(height: AppSpace.xl),
            Row(
              children: [
                Expanded(
                  child: _InfoTile(
                    label: 'Seviye',
                    value: exercise.level.label,
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: _InfoTile(
                    label: 'Zorluk',
                    value: exercise.difficulty.label,
                  ),
                ),
              ],
            ),
            if (exercise.prerequisiteExercises.isNotEmpty) ...[
              const SizedBox(height: AppSpace.section),
              SectionHeader(
                'Önce uzmanlaşman gerekenler',
                padding: const EdgeInsets.only(bottom: AppSpace.md),
                trailing: Text(
                  _prerequisiteLevelLabel(exercise.level),
                  style: AppText.caption.copyWith(color: AppColors.textMid),
                ),
              ),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  for (final name in exercise.prerequisiteExercises)
                    _PrerequisiteChip(
                      name: name,
                      target: allExercisesAsync.maybeWhen(
                        data: (all) =>
                            _findExerciseByName(allExercises: all, name: name),
                        orElse: () => null,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpace.section),
            _ActivationSection(
              rows: rows,
              weights: weights,
              activationLabel: _activationLabel,
            ),
            const SizedBox(height: AppSpace.section),
            const Hairline(),
            const SizedBox(height: AppSpace.xxl),
            Text(
              'Detaylı Açıklama & Form İpuçları',
              style: AppText.cardTitle,
            ),
            const SizedBox(height: AppSpace.lg),
            _FormattedDescription(description: exercise.description),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Başlık ve bilgi kutuları
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_rounded, size: 22),
          color: AppColors.textHigh,
          tooltip: 'Geri',
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          style: IconButton.styleFrom(alignment: Alignment.centerLeft),
        ),
        const SizedBox(width: AppSpace.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.pageTitle.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 2),
              Text(
                'Biyomekanik hareket detayı',
                style: AppText.bodyMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.md + 2,
      ),
      radius: AppRadius.control,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(trUpper(label), style: AppText.sectionLabel),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.cardTitle,
          ),
        ],
      ),
    );
  }
}

class _PrerequisiteChip extends StatelessWidget {
  const _PrerequisiteChip({required this.name, required this.target});

  final String name;
  final Exercise? target;

  @override
  Widget build(BuildContext context) {
    final enabled = target != null;
    return Material(
      color: AppColors.surfaceRaised,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.control),
        onTap: enabled
            ? () => Navigator.pushNamed(
                context,
                AppRoutes.detail,
                arguments: target,
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: AppText.caption.copyWith(
                  color: AppColors.textHigh,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (enabled) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hedef kaslar & aktivasyon
// ---------------------------------------------------------------------------

class _ActivationSection extends StatelessWidget {
  const _ActivationSection({
    required this.rows,
    required this.weights,
    required this.activationLabel,
  });

  final List<_ActivationRow> rows;
  final Map<MuscleCompartment, double> weights;
  final String Function(int rating) activationLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Hedef Kaslar & Aktivasyon', style: AppText.cardTitle),
        const SizedBox(height: AppSpace.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Wrap(
                direction: Axis.vertical,
                spacing: AppSpace.sm,
                children: [
                  for (final r in rows.take(6))
                    _MusclePill(label: r.name, primary: r.relative >= 0.6),
                ],
              ),
            ),
            if (weights.isNotEmpty)
              AnatomicalMuscleMap(intensities: weights, height: 236),
          ],
        ),
        const SizedBox(height: AppSpace.xxl),
        for (final (i, r) in rows.indexed) ...[
          if (i > 0) const SizedBox(height: AppSpace.lg + 2),
          _ActivationBar(row: r, label: activationLabel(r.rating)),
        ],
      ],
    );
  }
}

class _MusclePill extends StatelessWidget {
  const _MusclePill({required this.label, required this.primary});

  final String label;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 14, 7),
      decoration: BoxDecoration(
        color: primary ? AppColors.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: primary
            ? null
            : Border.all(color: AppColors.hairlineStrong, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            primary
                ? Icons.check_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 15,
            color: primary ? AppColors.onAccent : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppText.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: primary ? AppColors.onAccent : AppColors.textMid,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivationBar extends StatelessWidget {
  const _ActivationBar({required this.row, required this.label});

  final _ActivationRow row;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color =
        AnatomicalMuscleMap.fillFor(row.relative, AppColors.accent) ??
        AppColors.chartNeutral;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${row.name} ',
                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              ),
              TextSpan(
                text: '%${row.percent}',
                style: AppText.metricS.copyWith(fontSize: 15),
              ),
              TextSpan(text: '  ·  $label', style: AppText.caption),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        SegmentedBar(
          value: row.percent / 100,
          segments: 20,
          height: 4,
          gap: 2,
          color: color,
        ),
        if (row.parts.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            [
              for (final p in row.parts) '${p.label} %${p.percent}',
            ].join('  ·  '),
            style: AppText.caption.copyWith(fontSize: 11.5),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Açıklama
// ---------------------------------------------------------------------------

class _DescriptionSection {
  const _DescriptionSection({required this.title, required this.body});
  final String title;
  final String body;
}

class _FormattedDescription extends StatelessWidget {
  const _FormattedDescription({required this.description});

  final String description;

  static const _titles = [
    'Kurulum:',
    'Uygulama:',
    'Ipucu:',
    'İpucu:',
    'Sik hata:',
    'Sık hata:',
  ];

  List<_DescriptionSection> _parse() {
    final sections = <_DescriptionSection>[];
    var currentTitle = '';
    final currentLines = <String>[];

    for (final rawLine in description.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;
      if (_titles.any(line.startsWith)) {
        if (currentTitle.isNotEmpty || currentLines.isNotEmpty) {
          sections.add(
            _DescriptionSection(
              title: currentTitle,
              body: currentLines.join(' '),
            ),
          );
          currentLines.clear();
        }
        final colonIndex = line.indexOf(':');
        currentTitle = line.substring(0, colonIndex);
        final rest = line.substring(colonIndex + 1).trim();
        if (rest.isNotEmpty) currentLines.add(rest);
      } else {
        currentLines.add(line);
      }
    }
    if (currentTitle.isNotEmpty || currentLines.isNotEmpty) {
      sections.add(
        _DescriptionSection(title: currentTitle, body: currentLines.join(' ')),
      );
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final sections = _parse();
    if (sections.isEmpty) {
      return Text(description, style: AppText.bodyMuted.copyWith(height: 1.5));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, section) in sections.indexed) ...[
          if (i > 0) ...[
            const SizedBox(height: AppSpace.md),
            const Hairline(),
            const SizedBox(height: AppSpace.md),
          ],
          if (section.title.isNotEmpty) ...[
            Text(trUpper(section.title), style: AppText.sectionLabel),
            const SizedBox(height: 6),
          ],
          Text(
            section.body,
            style: AppText.body.copyWith(color: AppColors.textMid, height: 1.5),
          ),
        ],
      ],
    );
  }
}
