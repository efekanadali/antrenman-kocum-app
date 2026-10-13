// lib/presentation/widgets/program_preview_badge.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/services/program_preview.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/biomechanics_info_sheet.dart';

/// Programın "Tahmini Toplam MLI İş Yükü" ve "Ağırlıklı Hedef Kas Grubu"
/// rozetlerini Nordic & Cyber-Athlete mat koyu temasında gösterir.
class ProgramPreviewBadge extends StatelessWidget {
  const ProgramPreviewBadge({
    super.key,
    required this.preview,
    this.title = 'Biyomekanik Önizleme',
    this.footnote,
    this.compact = false,
  });

  final ProgramPreview preview;
  final String title;
  final String? footnote;
  final bool compact;

  static const Color _surface = AppColors.surface; // #13171C
  static const Color _surfaceSoft = AppColors.surfaceSoft; // #181D24
  static const Color _border = AppColors.border; // #1E232A
  static const Color _volcanic = AppColors.volcanic; // #FF5533
  static const Color _emerald = AppColors.emerald; // #10B981
  static const Color _amber = AppColors.amber; // #F59E0B
  static const Color _textHigh = AppColors.textHigh; // #F1F5F9
  static const Color _textMid = AppColors.textMid; // #94A3B8
  static const Color _textMuted = AppColors.textMuted; // #64748B

  @override
  Widget build(BuildContext context) {
    final top = preview.topMuscle;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        border: Border.all(color: _border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.biotech_rounded, color: _volcanic, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textHigh,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  color: _textMid,
                  size: 18,
                ),
                tooltip: 'Biyomekanik Bilgisi',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                visualDensity: VisualDensity.compact,
                onPressed: () => showBiomechanicsInfoSheet(
                  context,
                  initialTopic: BiomechanicsTopic.mli,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (preview.isEmpty)
            const Text(
              'Egzersiz ekledikçe tahmini iş yükü burada görünecek.',
              style: TextStyle(color: _textMuted, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  icon: Icons.bolt_rounded,
                  color: _volcanic,
                  label: 'Tahmini MLI',
                  value: preview.totalMli.round().toString(),
                ),
                _Pill(
                  icon: Icons.fitness_center_rounded,
                  color: _emerald,
                  label: 'Hedef Kas',
                  value: top == null
                      ? '-'
                      : '${top.label} %${(preview.topMuscleShare * 100).round()}',
                ),
                _Pill(
                  icon: Icons.speed_rounded,
                  color: _amber,
                  label: 'Ort. Kaldıraç',
                  value: preview.averageLeverage.toStringAsFixed(2),
                ),
              ],
            ),
          if (!preview.isEmpty && !compact) ...[
            const SizedBox(height: 14),
            for (final muscle in _sortedMuscles(preview)) ...[
              _MuscleLine(
                label: muscle.key.label,
                fraction: preview.muscleLoad.values.fold(0.0, (a, b) => a + b) <=
                        0
                    ? 0
                    : muscle.value /
                        preview.muscleLoad.values.fold(0.0, (a, b) => a + b),
              ),
              const SizedBox(height: 6),
            ],
          ],
          if (footnote != null) ...[
            const SizedBox(height: 6),
            Text(
              footnote!,
              style: const TextStyle(color: _textMuted, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }

  List<MapEntry<RecoveryMuscle, double>> _sortedMuscles(ProgramPreview p) {
    final entries = p.muscleLoad.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.take(4).toList();
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: ProgramPreviewBadge._surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: ProgramPreviewBadge._border, width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: ProgramPreviewBadge._textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: ProgramPreviewBadge._textHigh,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MuscleLine extends StatelessWidget {
  const _MuscleLine({required this.label, required this.fraction});

  final String label;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(
              color: ProgramPreviewBadge._textHigh,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: ProgramPreviewBadge._surfaceSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                ProgramPreviewBadge._volcanic,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 34,
          child: Text(
            '%${(fraction * 100).round()}',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: ProgramPreviewBadge._textMid,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
