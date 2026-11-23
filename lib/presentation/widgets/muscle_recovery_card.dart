// lib/presentation/widgets/muscle_recovery_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery_state.dart';
import 'package:calisthenics_app/presentation/providers/muscle_recovery_provider.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/biomechanics_info_sheet.dart';

/// 6 ana bölgenin toparlanma durumunu gösterir; bir bölgeye dokunulduğunda
/// kompartıman (17 alt bölge) ayrıntısı açılır.
///
/// Bölge durumu tüm kompartımanlarından türetilir: herhangi bir kompartımanı
/// çalıştırılmış bölge "toparlanıyor" görünür ve hazır olma zamanı en geç
/// toparlanan kompartımandır.
class MuscleRecoveryCard extends ConsumerStatefulWidget {
  const MuscleRecoveryCard({super.key});

  static const Color _surface = AppColors.surface; // #13171C
  static const Color _border = AppColors.border; // #1E232A
  static const Color _ready = AppColors.emerald; // Mat Toparlanma Yeşili
  static const Color _recovering = AppColors.volcanic; // Mat Volkanik Turuncu
  static const Color _volcanic = AppColors.volcanic;
  static const Color _textHigh = AppColors.textHigh; // #F1F5F9
  static const Color _textMid = AppColors.textMid; // #94A3B8

  @override
  ConsumerState<MuscleRecoveryCard> createState() => _MuscleRecoveryCardState();
}

class _MuscleRecoveryCardState extends ConsumerState<MuscleRecoveryCard> {
  final Set<MuscleRegion> _expanded = {};

  void _toggle(MuscleRegion region) {
    setState(() {
      if (!_expanded.remove(region)) _expanded.add(region);
    });
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(muscleRecoveryProvider);
    final state = async.valueOrNull ?? const MuscleRecoveryState();
    final regions = state.regions;
    final now = DateTime.now();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MuscleRecoveryCard._surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: MuscleRecoveryCard._border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.healing_rounded,
                color: MuscleRecoveryCard._ready,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Kas Toparlanma Durumu',
                  style: TextStyle(
                    color: MuscleRecoveryCard._textHigh,
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
                    color: MuscleRecoveryCard._volcanic,
                  ),
                ),
              IconButton(
                icon: const Icon(
                  Icons.info_outline,
                  color: MuscleRecoveryCard._textMid,
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
            'RIR\'e ve kas büyüklüğüne göre kişiselleştirilmiş toparlanma · '
            'ayrıntı için bölgeye dokun',
            style: TextStyle(color: MuscleRecoveryCard._textMid, fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          for (final region in MuscleRegion.values) ...[
            InkWell(
              key: ValueKey('recovery-region-${region.name}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => _toggle(region),
              child: _RecoveryBar(
                label: region.label,
                labelWidth: 52,
                now: now,
                trainedAt: regions[region]?.lastTrainedAt,
                readyAt: regions[region]?.readyAt,
                recoveryHours: regions[region]?.recoveryHours,
                averageRir: regions[region]?.averageRir,
                trailing: Icon(
                  _expanded.contains(region)
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  size: 18,
                  color: MuscleRecoveryCard._textMid,
                ),
              ),
            ),
            if (_expanded.contains(region))
              Padding(
                padding: const EdgeInsets.only(left: 14, top: 6),
                child: Column(
                  children: [
                    for (final c in region.compartments) ...[
                      _RecoveryBar(
                        key: ValueKey('recovery-compartment-${c.firestoreKey}'),
                        label: c.label,
                        labelWidth: 108,
                        compact: true,
                        now: now,
                        trainedAt: state.compartments[c]?.lastTrainedAt,
                        readyAt: state.compartments[c]?.readyAt,
                        recoveryHours: state.compartments[c]?.recoveryHours,
                        averageRir: state.compartments[c]?.averageRir,
                      ),
                      const SizedBox(height: 6),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _RecoveryBar extends StatelessWidget {
  const _RecoveryBar({
    super.key,
    required this.label,
    required this.labelWidth,
    required this.now,
    required this.trainedAt,
    required this.readyAt,
    required this.recoveryHours,
    required this.averageRir,
    this.trailing,
    this.compact = false,
  });

  final String label;
  final double labelWidth;
  final DateTime now;
  final DateTime? trainedAt;
  final DateTime? readyAt;
  final double? recoveryHours;
  final double? averageRir;
  final Widget? trailing;
  final bool compact;

  String _remainingLabel(Duration d) {
    if (d.inHours >= 1) {
      return '${d.inHours} sa ${d.inMinutes.remainder(60)} dk kaldı';
    }
    return '${d.inMinutes.clamp(1, 59)} dk kaldı';
  }

  @override
  Widget build(BuildContext context) {
    final ready = readyAt == null || !now.isBefore(readyAt!);
    double progress = 1.0;
    if (!ready && trainedAt != null && (recoveryHours ?? 0) > 0) {
      final elapsed = now.difference(trainedAt!).inMinutes;
      progress = (elapsed / (recoveryHours! * 60)).clamp(0.0, 1.0).toDouble();
    }
    final color =
        ready ? MuscleRecoveryCard._ready : MuscleRecoveryCard._recovering;
    final percent = (progress * 100).round();

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: compact
                      ? MuscleRecoveryCard._textMid
                      : MuscleRecoveryCard._textHigh,
                  fontSize: compact ? 11.5 : 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: compact ? 4 : 6,
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
            if (trailing != null) ...[
              const SizedBox(width: 4),
              trailing!,
            ],
          ],
        ),
        if (!ready)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                'Toparlanıyor · ${_remainingLabel(readyAt!.difference(now))}'
                '${averageRir != null ? ' · RIR ${averageRir!.toStringAsFixed(1)}' : ''}',
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
