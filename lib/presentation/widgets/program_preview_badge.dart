// lib/presentation/widgets/program_preview_badge.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/services/program_preview.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/biomechanics_info_sheet.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';

/// Programın canlı biyomekanik önizlemesi: tahmini toplam MLI (büyük,
/// animasyonlu, tabular), ağırlıklı hedef kas, ortalama kaldıraç ve kas
/// paylarının tek tonlu yığılmış barı.
class ProgramPreviewBadge extends StatelessWidget {
  const ProgramPreviewBadge({
    super.key,
    required this.preview,
    this.title = 'Biyomekanik Önizleme',
    this.footnote,
    this.compact = false,
    this.docked = false,
  });

  final ProgramPreview preview;
  final String title;
  final String? footnote;

  /// Yalnızca üst satır (MLI + hedef kas), bar ve legend yok.
  final bool compact;

  /// Kart yüzeyi olmadan çizer (sabit alt şerit içinde kullanım için).
  final bool docked;

  @override
  Widget build(BuildContext context) {
    final top = preview.topMuscle;
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: SectionHeader(title)),
            SizedBox(
              width: 28,
              height: 20,
              child: IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                tooltip: 'Biyomekanik Bilgisi',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => showBiomechanicsInfoSheet(
                  context,
                  initialTopic: BiomechanicsTopic.mli,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? AppSpace.sm : AppSpace.md),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(end: preview.totalMli),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: _formatThousands(value.round()),
                      style: (compact ? AppText.metricL : AppText.metricXL)
                          .copyWith(
                            color: preview.isEmpty
                                ? AppColors.textMuted
                                : AppColors.textHigh,
                          ),
                    ),
                    TextSpan(text: ' MLI', style: AppText.unit),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  preview.isEmpty
                      ? 'Egzersiz ekledikçe güncellenir'
                      : [
                          if (top != null)
                            '${top.label} %${(preview.topMuscleShare * 100).round()}',
                          'Kaldıraç ${preview.averageLeverage.toStringAsFixed(2)}',
                        ].join('  ·  '),
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  style: AppText.caption.copyWith(color: AppColors.textMid),
                ),
              ),
            ),
          ],
        ),
        if (!compact) ...[
          const SizedBox(height: AppSpace.md),
          _StackedShareBar(preview: preview),
          if (!preview.isEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            _ShareLegend(preview: preview),
          ],
        ],
        if (footnote != null && !docked) ...[
          const SizedBox(height: AppSpace.md),
          Text(footnote!, style: AppText.caption.copyWith(fontSize: 11)),
        ],
      ],
    );

    if (docked) return content;
    return AppSurface(
      padding: EdgeInsets.all(compact ? AppSpace.lg : AppSpace.card),
      child: content,
    );
  }
}

String _formatThousands(int v) {
  final s = v.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return v < 0 ? '-$buf' : buf.toString();
}

List<MapEntry<RecoveryMuscle, double>> _sortedShares(ProgramPreview p) {
  final entries = p.muscleLoad.entries.where((e) => e.value > 0).toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return entries;
}

class _StackedShareBar extends StatelessWidget {
  const _StackedShareBar({required this.preview});

  final ProgramPreview preview;

  @override
  Widget build(BuildContext context) {
    final entries = _sortedShares(preview);
    final total = entries.fold<double>(0, (a, e) => a + e.value);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        child: total <= 0
            ? Container(color: AppColors.hairlineStrong)
            : Row(
                children: [
                  for (final (i, e) in entries.indexed) ...[
                    if (i > 0) const SizedBox(width: 2),
                    Expanded(
                      flex: (e.value / total * 1000).round().clamp(1, 1000),
                      child: Container(
                        color: AppColors.chartSteps[
                            i.clamp(0, AppColors.chartSteps.length - 1)],
                      ),
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}

class _ShareLegend extends StatelessWidget {
  const _ShareLegend({required this.preview});

  final ProgramPreview preview;

  @override
  Widget build(BuildContext context) {
    final entries = _sortedShares(preview).take(4).toList();
    final total = _sortedShares(preview).fold<double>(0, (a, e) => a + e.value);
    return Wrap(
      spacing: AppSpace.md,
      runSpacing: 4,
      children: [
        for (final (i, e) in entries.indexed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusDot(
                color: AppColors.chartSteps[
                    i.clamp(0, AppColors.chartSteps.length - 1)],
              ),
              const SizedBox(width: 5),
              Text(
                '${e.key.label} %${total <= 0 ? 0 : (e.value / total * 100).round()}',
                style: AppText.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
      ],
    );
  }
}
