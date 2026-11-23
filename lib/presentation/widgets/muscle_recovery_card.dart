// lib/presentation/widgets/muscle_recovery_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery_state.dart';
import 'package:calisthenics_app/presentation/providers/muscle_recovery_provider.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/biomechanics_info_sheet.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';

/// 6 ana bölgenin toparlanma durumunu WHOOP tarzı segmentli barlarla gösterir;
/// bir bölgeye dokunulduğunda kompartıman (17 alt bölge) ayrıntısı açılır.
///
/// Bölge durumu tüm kompartımanlarından türetilir: herhangi bir kompartımanı
/// çalıştırılmış bölge "toparlanıyor" görünür ve hazır olma zamanı en geç
/// toparlanan kompartımandır.
class MuscleRecoveryCard extends ConsumerStatefulWidget {
  const MuscleRecoveryCard({super.key});

  static Color get _ready => AppColors.emerald;
  static Color get _recovering => AppColors.amber;

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

    final readyCount = MuscleRegion.values.where((r) {
      final readyAt = regions[r]?.readyAt;
      return readyAt == null || !now.isBefore(readyAt);
    }).length;

    return AppSurface(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.card,
        AppSpace.lg,
        AppSpace.md,
        AppSpace.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionHeader('Toparlanma')),
              if (async.isLoading)
                Padding(
                  padding: EdgeInsets.only(right: AppSpace.sm),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              Text(
                '$readyCount/${MuscleRegion.values.length} hazır',
                style: AppText.caption.copyWith(color: AppColors.textMid),
              ),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: AppColors.textMuted,
                  size: 16,
                ),
                tooltip: 'Toparlanma & RIR Bilgisi',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                visualDensity: VisualDensity.compact,
                onPressed: () => showBiomechanicsInfoSheet(
                  context,
                  initialTopic: BiomechanicsTopic.recovery,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          _FatigueMap(state: state, now: now),
          const SizedBox(height: AppSpace.md),
          const Padding(
            padding: EdgeInsets.only(right: AppSpace.sm),
            child: Hairline(),
          ),
          for (final (i, region) in MuscleRegion.values.indexed) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.only(right: AppSpace.sm),
                child: Hairline(),
              ),
            InkWell(
              key: ValueKey('recovery-region-${region.name}'),
              borderRadius: BorderRadius.circular(8),
              onTap: () => _toggle(region),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: _RecoveryBar(
                  label: region.label,
                  labelWidth: 64,
                  now: now,
                  trainedAt: regions[region]?.lastTrainedAt,
                  readyAt: regions[region]?.readyAt,
                  recoveryHours: regions[region]?.recoveryHours,
                  averageRir: regions[region]?.averageRir,
                  trailing: AnimatedRotation(
                    turns: _expanded.contains(region) ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more_rounded,
                      size: 18,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment.topCenter,
              child: _expanded.contains(region)
                  ? Padding(
                      padding: const EdgeInsets.only(
                        left: 4,
                        bottom: AppSpace.md,
                        right: AppSpace.sm,
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Hairline.vertical(
                              color: AppColors.hairlineStrong,
                            ),
                            const SizedBox(width: AppSpace.md),
                            Expanded(
                              child: Column(
                                children: [
                                  for (final c in region.compartments)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 6,
                                      ),
                                      child: _RecoveryBar(
                                        key: ValueKey(
                                          'recovery-compartment-${c.firestoreKey}',
                                        ),
                                        label: c.label,
                                        labelWidth: 96,
                                        compact: true,
                                        now: now,
                                        trainedAt: state
                                            .compartments[c]
                                            ?.lastTrainedAt,
                                        readyAt: state.compartments[c]?.readyAt,
                                        recoveryHours: state
                                            .compartments[c]
                                            ?.recoveryHours,
                                        averageRir:
                                            state.compartments[c]?.averageRir,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ön/arka silüet üzerinde kompartıman yorgunluğu (1 − toparlanma).
class _FatigueMap extends StatelessWidget {
  const _FatigueMap({required this.state, required this.now});

  final MuscleRecoveryState state;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final fatigue = <MuscleCompartment, double>{};
    state.compartments.forEach((c, r) {
      final readyAt = r.readyAt;
      if (!now.isBefore(readyAt)) return;
      final hours = r.recoveryHours;
      var progress = 0.0;
      if (hours > 0) {
        final elapsed = now.difference(r.lastTrainedAt).inMinutes;
        progress = (elapsed / (hours * 60)).clamp(0.0, 1.0).toDouble();
      }
      fatigue[c] = 1 - progress;
    });
    return Row(
      children: [
        AnatomicalMuscleMap(
          intensities: fatigue,
          activeColor: MuscleRecoveryCard._recovering,
          normalize: false,
          height: 170,
        ),
        const SizedBox(width: AppSpace.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fatigue.isEmpty ? 'Tüm kaslar hazır' : 'Yorgun bölgeler',
                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                fatigue.isEmpty
                    ? 'Son antrenmanlarının etkisi geçti.'
                    : '${fatigue.length} alt bölge toparlanma sürecinde.',
                style: AppText.caption,
              ),
              const SizedBox(height: AppSpace.md),
              _Legend(
                color: MuscleRecoveryCard._recovering,
                label: 'Yüksek yorgunluk',
              ),
              const SizedBox(height: 6),
              _Legend(
                color: MuscleRecoveryCard._recovering.withValues(alpha: 0.45),
                label: 'Kısmen toparlandı',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        StatusDot(color: color),
        const SizedBox(width: 6),
        Text(label, style: AppText.caption.copyWith(fontSize: 11)),
      ],
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
    final color = ready
        ? MuscleRecoveryCard._ready
        : MuscleRecoveryCard._recovering;
    final percent = (progress * 100).round();

    final valueStyle = compact
        ? AppText.caption.copyWith(
            fontWeight: FontWeight.w600,
            color: ready ? MuscleRecoveryCard._ready : AppColors.textMid,
          )
        : AppText.metricS.copyWith(
            fontSize: 14,
            color: ready ? MuscleRecoveryCard._ready : AppColors.textHigh,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: compact
                    ? AppText.caption.copyWith(
                        fontSize: 12.5,
                        color: AppColors.textMid,
                      )
                    : AppText.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: SegmentedBar(
                value: progress,
                height: compact ? 3 : 4,
                color: color,
              ),
            ),
            SizedBox(
              width: compact ? 48 : 56,
              child: Text(
                ready ? 'Hazır' : '%$percent',
                textAlign: TextAlign.right,
                style: valueStyle,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 6),
              trailing!,
            ] else if (!compact)
              const SizedBox(width: 24),
          ],
        ),
        if (!ready)
          Padding(
            padding: EdgeInsets.only(left: labelWidth, top: compact ? 3 : 6),
            child: Text(
              '${compact ? '' : 'Toparlanıyor · '}'
              '${_remainingLabel(readyAt!.difference(now))}'
              '${averageRir != null ? ' · RIR ${averageRir!.toStringAsFixed(1)}' : ''}',
              style: compact
                  ? AppText.caption.copyWith(fontSize: 11)
                  : AppText.caption,
            ),
          ),
      ],
    );
  }
}
