// lib/presentation/widgets/muscle_recovery_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery.dart';
import 'package:calisthenics_app/presentation/providers/muscle_recovery_provider.dart';

/// Kas gruplarının toparlanma durumunu (Hazır %100 / Toparlanıyor %xx) gösterir.
class MuscleRecoveryCard extends ConsumerWidget {
  const MuscleRecoveryCard({super.key});

  static const Color _surface = Color(0xFF201836);
  static const Color _purple = Color(0xFF6D5BFF);
  static const Color _ready = Color(0xFF3DDC97);
  static const Color _recovering = Color(0xFFFFB84D);
  static const Color _textHigh = Color(0xFFEDE9FF);
  static const Color _textMid = Color(0xFFB4A9D8);

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
        color: _surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.healing_rounded, color: _ready, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kas Toparlanma Durumu',
                  style: TextStyle(
                    color: _textHigh,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (async.isLoading)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _purple,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'RIR\'e göre kişiselleştirilmiş toparlanma süresi',
            style: TextStyle(color: _textMid, fontSize: 12),
          ),
          const SizedBox(height: 14),
          for (final muscle in RecoveryMuscle.values) ...[
            _RecoveryRow(record: byMuscle[muscle], muscle: muscle, now: now),
            const SizedBox(height: 10),
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
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                ready ? 'Hazır' : '%$percent',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
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
