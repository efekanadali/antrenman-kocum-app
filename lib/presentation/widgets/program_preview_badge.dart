// lib/presentation/widgets/program_preview_badge.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/domain/services/program_preview.dart';

/// Programın "Tahmini Toplam MLI İş Yükü" ve "Ağırlıklı Hedef Kas Grubu"
/// rozetlerini gösterir.
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

  static const Color _purple = Color(0xFF6D5BFF);
  static const Color _blue = Color(0xFF4FC3F7);
  static const Color _surface = Color(0xFF201836);
  static const Color _textHigh = Color(0xFFEDE9FF);
  static const Color _textMid = Color(0xFFB4A9D8);

  @override
  Widget build(BuildContext context) {
    final top = preview.topMuscle;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 16 : 20),
        gradient: LinearGradient(
          colors: [
            _purple.withValues(alpha: 0.22),
            _blue.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.biotech_rounded, color: _blue, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  color: _textHigh,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (preview.isEmpty)
            const Text(
              'Egzersiz ekledikçe tahmini iş yükü burada görünecek.',
              style: TextStyle(color: _textMid, fontSize: 12),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Pill(
                  icon: Icons.bolt_rounded,
                  color: _blue,
                  label: 'Tahmini MLI',
                  value: preview.totalMli.round().toString(),
                ),
                _Pill(
                  icon: Icons.fitness_center_rounded,
                  color: _purple,
                  label: 'Hedef Kas',
                  value: top == null
                      ? '-'
                      : '${top.label} %${(preview.topMuscleShare * 100).round()}',
                ),
                _Pill(
                  icon: Icons.speed_rounded,
                  color: const Color(0xFFC2F13A),
                  label: 'Ort. Kaldıraç',
                  value: preview.averageLeverage.toStringAsFixed(2),
                ),
              ],
            ),
          if (!preview.isEmpty && !compact) ...[
            const SizedBox(height: 12),
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
            const SizedBox(height: 4),
            Text(
              footnote!,
              style: const TextStyle(color: _textMid, fontSize: 11),
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
        color: ProgramPreviewBadge._surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.35)),
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
                  color: ProgramPreviewBadge._textMid,
                  fontSize: 10,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: ProgramPreviewBadge._textHigh,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
          width: 48,
          child: Text(
            label,
            style: const TextStyle(
              color: ProgramPreviewBadge._textHigh,
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                ProgramPreviewBadge._blue,
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
            ),
          ),
        ),
      ],
    );
  }
}
