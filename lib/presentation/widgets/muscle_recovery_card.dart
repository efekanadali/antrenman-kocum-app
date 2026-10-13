// lib/presentation/widgets/muscle_recovery_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/presentation/providers/muscle_recovery_provider.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/biomechanics_info_sheet.dart';

/// Kas gruplarının toparlanma durumunu (Hazır %100 / Toparlanıyor %xx) gösterir.
class MuscleRecoveryCard extends ConsumerWidget {
  const MuscleRecoveryCard({super.key});

  static const Color _surface = AppColors.surface; // #13171C
  static const Color _border = AppColors.border; // #1E232A
  static const Color _ready = AppColors.emerald; // #10B981 Mat Toparlanma Yeşili
  static const Color _recovering = AppColors.volcanic; // #FF5533 Mat Volkanik Turuncu/Kırmızı
  static const Color _volcanic = AppColors.volcanic;
  static const Color _textHigh = AppColors.textHigh; // #F1F5F9
  static const Color _textMid = AppColors.textMid; // #94A3B8

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(muscleRecoveryProvider);
    final records = async.valueOrNull ?? const <MuscleRecoveryRecord>[];
    final byMuscle = {for (final r in records) r.muscle: r};
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.healing_rounded, color: _ready, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kas Toparlanma Durumu',
                  style: TextStyle(
                    color: _textHigh,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              if (async.isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _volcanic,
                  ),
                ),
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  color: _textMid,
                  size: 17,
                ),
                tooltip: 'Toparlanma & RIR Bilgisi',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                visualDensity: VisualDensity.compact,
                onPressed: () => showBiomechanicsInfoSheet(
                  context,
                  initialTopic: BiomechanicsTopic.recovery,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text(
            'RIR\'e göre kişiselleştirilmiş biyomekanik toparlanma süresi',
            style: TextStyle(color: _textMid, fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          for (final muscle in RecoveryMuscle.values) ...[
            _RecoveryRow(record: byMuscle[muscle], muscle: muscle, now: now),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _RecoveryRow extends StatelessWidget {
  const _RecoveryRow({
    required this.record,
    required this.muscle,
    required this.now,
  });

  final MuscleRecoveryRecord? record;
  final RecoveryMuscle muscle;
  final DateTime now;

  String _remainingLabel(Duration d) {
    if (d.inHours >= 1) {
      return '${d.inHours} sa ${d.inMinutes.remainder(60)} dk kaldı';
    }
    return '${d.inMinutes.clamp(1, 59)} dk kaldı';
  }

  @override
  Widget build(BuildContext context) {
    final progress = record?.progressAt(now) ?? 1.0;
    final ready = record == null || record!.isReadyAt(now);
    final color = ready ? MuscleRecoveryCard._ready : MuscleRecoveryCard._recovering;
    final percent = (progress * 100).round();

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(
                muscle.label,
                style: const TextStyle(
                  color: MuscleRecoveryCard._textHigh,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 6,
                  backgroundColor: MuscleRecoveryCard._border,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: color.withValues(alpha: 0.28),
                  width: 1,
                ),
              ),
              child: Text(
                ready ? 'Hazır' : '%$percent',
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (!ready)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Toparlanıyor · ${_remainingLabel(record!.remainingAt(now))}'
                ' · RIR ${record!.averageRir.toStringAsFixed(1)}',
                style: const TextStyle(
                  color: MuscleRecoveryCard._textMid,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
