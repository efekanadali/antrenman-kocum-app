// lib/presentation/screens/workout_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';
import 'package:calisthenics_app/core/local_storage/workout_history_storage.dart';
import 'package:calisthenics_app/core/local_storage/workout_summary_storage.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/muscle_load_snapshot.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';
import 'package:calisthenics_app/domain/services/recovery_calculator.dart';
import 'package:calisthenics_app/data/services/firestore_service.dart';

// ─── Model ───────────────────────────────────────────────────────────────────
class WorkoutSummaryArgs {
  const WorkoutSummaryArgs({
    required this.exerciseName,
    required this.totalTime,
    required this.setsCompleted,
    required this.totalSets,
    required this.totalLoad,
    required this.muscleLoad,
    this.muscleRir = const {},
    this.compartmentLoad = const {},
    this.compartmentRir = const {},
    this.averageRir,
  });

  final String exerciseName;
  final Duration totalTime;
  final int setsCompleted;
  final int totalSets;
  final double totalLoad;
  final Map<String, double> muscleLoad;
  final Map<String, double> muscleRir;

  /// 17 kompartıman bazında seans yükü (v2). Boşsa [muscleLoad] bölünür.
  final Map<MuscleCompartment, double> compartmentLoad;

  /// Kompartıman bazında yük ağırlıklı ortalama RIR.
  final Map<MuscleCompartment, double> compartmentRir;
  final double? averageRir;

  /// Kompartıman + bölge görünümü (eşlenemeyen `Genel` vb. korunur).
  MuscleLoadSnapshot get load => compartmentLoad.isNotEmpty
      ? MuscleLoadSnapshot(compartments: compartmentLoad)
      : MuscleLoadSnapshot.parse(legacyRaw: muscleLoad);

  /// Eski sürümlerin okuduğu bölge anahtarlı harita (`chest` … `legs`);
  /// kompartıman verisi yoksa gelen harita (ör. `Genel`) aynen kullanılır.
  Map<String, double> get legacyMuscleLoad =>
      compartmentLoad.isNotEmpty ? load.legacyRegionLoad : muscleLoad;

  /// Kompartıman RIR'ı; yalnızca eski anahtarlar varsa her kompartıman,
  /// bölgesine eşlenen anahtarın RIR'ını alır.
  Map<MuscleCompartment, double> get effectiveCompartmentRir {
    if (compartmentRir.isNotEmpty) return compartmentRir;
    final result = <MuscleCompartment, double>{};
    muscleRir.forEach((key, rir) {
      for (final c in expandRecoveryKey(key)) {
        result[c] = rir;
      }
    });
    return result;
  }
}

// ─── Screen ──────────────────────────────────────────────────────────────────
class WorkoutSummaryScreen extends ConsumerStatefulWidget {
  const WorkoutSummaryScreen({super.key, required this.args});

  final WorkoutSummaryArgs args;

  @override
  ConsumerState<WorkoutSummaryScreen> createState() =>
      _WorkoutSummaryScreenState();
}

class _WorkoutSummaryScreenState extends ConsumerState<WorkoutSummaryScreen> {
  bool _firestoreSynced = false;

  Future<void> _syncToFirestore({required DateTime completedAt}) async {
    if (_firestoreSynced) return;

    try {
      final sessionData = <String, dynamic>{
        'completedAt': completedAt.toIso8601String(),
        'durationSeconds': widget.args.totalTime.inSeconds,
        'exercisesDone': [widget.args.exerciseName],
        'totalMliWorkload': widget.args.totalLoad,
        'muscleWorkloads': widget.args.legacyMuscleLoad,
        'compartmentWorkloads': widget.args.load.compartmentsByKey,
        'schemaVersion': kMuscleDataSchemaVersion,
        'exerciseName': widget.args.exerciseName,
        'totalDurationSeconds': widget.args.totalTime.inSeconds,
        'exercises': [
          {
            'name': widget.args.exerciseName,
            'setsCompleted': widget.args.setsCompleted,
            'totalSets': widget.args.totalSets,
          },
        ],
        'totalLoad': widget.args.totalLoad,
        'muscleLoad': widget.args.legacyMuscleLoad,
        'setsCompleted': widget.args.setsCompleted,
        'totalSets': widget.args.totalSets,
      };

      final firestore = ref.read(firestoreServiceProvider);
      final recovery = buildCompartmentRecovery(
        compartmentLoad: widget.args.load.compartments,
        compartmentRir: widget.args.effectiveCompartmentRir,
        completedAt: completedAt,
        defaultRir: widget.args.averageRir ?? kDefaultRir,
      );

      await Future.wait([
        firestore.saveWorkoutSession(sessionData),
        if (recovery.isNotEmpty) firestore.saveSessionRecovery(recovery),
      ]);
      _firestoreSynced = true;
    } catch (_) {
      // Sessiz hata yakalama: UI akışını engellemez, _firestoreSynced false kalır
    }
  }

  // ── Business Logic ──────────────────────────────────────────────────────────
  Future<void> _saveSession(BuildContext context) async {
    final completedAt = DateTime.now();
    final storage = WorkoutHistoryStorage();
    final summaryStorage = WorkoutSummaryStorage();
    final entry = WorkoutSessionEntry(
      exerciseName: widget.args.exerciseName,
      totalTimeSeconds: widget.args.totalTime.inSeconds,
      setsCompleted: widget.args.setsCompleted,
      totalSets: widget.args.totalSets,
      completedAt: completedAt,
    );

    final summaryEntry = WorkoutSummaryEntry(
      date: completedAt,
      totalLoad: widget.args.totalLoad,
      muscleLoad: widget.args.legacyMuscleLoad,
      duration: widget.args.totalTime.inSeconds,
      load: widget.args.load,
    );

    try {
      await Future.wait([
        storage.saveSession(entry),
        summaryStorage.saveSummary(summaryEntry),
        _syncToFirestore(completedAt: completedAt),
      ]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.emerald,
                size: 18,
              ),
              SizedBox(width: 10),
              Text('Seans kaydedildi'),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: AppColors.danger,
                size: 18,
              ),
              SizedBox(width: 10),
              Text('Kaydetme başarısız'),
            ],
          ),
        ),
      );
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _goHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final load = widget.args.load;
    final sortedMuscles = load.regions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalMuscleLoad = load.mappedTotal;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.xxl,
            AppSpace.page,
            AppSpace.xxl,
          ),
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpace.xxl),
            _buildMetricGrid(),
            const SizedBox(height: AppSpace.section),
            _buildMuscleCard(load, sortedMuscles, totalMuscleLoad),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.md,
            AppSpace.page,
            AppSpace.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border(
              top: BorderSide(
                color: AppColors.hairline,
                width: AppSpace.hairline,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PrimaryButton(
                label: 'Seansı Kaydet ve Bitir',
                onPressed: () async {
                  await _saveSession(context);
                  if (!context.mounted) return;
                  _goHome(context);
                },
              ),
              const SizedBox(height: AppSpace.sm),
              Row(
                children: [
                  Expanded(
                    child: GhostButton(
                      label: 'Tekrar Başlat',
                      icon: Icons.replay_rounded,
                      expand: true,
                      onPressed: () => _goHome(context),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: GhostButton(
                      label: 'Kaydetmeden Çık',
                      icon: Icons.logout_rounded,
                      expand: true,
                      onPressed: () => _goHome(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 16,
              color: AppColors.emerald,
            ),
            const SizedBox(width: 6),
            Text(
              trUpper('Antrenman tamamlandı'),
              style: AppText.sectionLabel.copyWith(color: AppColors.emerald),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Text(widget.args.exerciseName, style: AppText.pageTitle),
      ],
    );
  }

  // ── Metric Grid ─────────────────────────────────────────────────────────
  Widget _buildMetricGrid() {
    return AppSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetricValue(
            value: widget.args.totalLoad.round().toString(),
            unit: 'MLI',
            label: 'Toplam yük',
            style: AppText.metricXL,
          ),
          const SizedBox(height: AppSpace.xl),
          const Hairline(),
          const SizedBox(height: AppSpace.lg),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: MetricValue(
                    value: _formatDuration(widget.args.totalTime),
                    unit: 'dk',
                    label: 'Toplam süre',
                  ),
                ),
                const Hairline.vertical(),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: MetricValue(
                    value: '${widget.args.setsCompleted}',
                    unit: '/${widget.args.totalSets}',
                    label: 'Set',
                  ),
                ),
                if (widget.args.averageRir != null) ...[
                  const Hairline.vertical(),
                  const SizedBox(width: AppSpace.lg),
                  Expanded(
                    child: MetricValue(
                      value: widget.args.averageRir!.toStringAsFixed(1),
                      label: 'Ort. RIR',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Muscle Load Card ────────────────────────────────────────────────────
  Widget _buildMuscleCard(
    MuscleLoadSnapshot load,
    List<MapEntry<MuscleRegion, double>> sortedMuscles,
    double totalMuscleLoad,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Kas grubu yük dağılımı',
          padding: EdgeInsets.only(bottom: AppSpace.md),
        ),
        AppSurface(
          child: sortedMuscles.isEmpty
              ? _buildEmptyMuscleState()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (load.compartments.isNotEmpty) ...[
                      Center(
                        child: AnatomicalMuscleMap(
                          intensities: load.compartments,
                          height: 200,
                          spacing: AppSpace.xl,
                        ),
                      ),
                      const SizedBox(height: AppSpace.xl),
                      const Hairline(),
                      const SizedBox(height: AppSpace.lg),
                    ],
                    for (final (i, entry) in sortedMuscles.indexed) ...[
                      if (i > 0) const SizedBox(height: AppSpace.lg),
                      _MuscleLoadRow(
                        muscleName: entry.key.label,
                        load: entry.value,
                        ratio: totalMuscleLoad > 0
                            ? entry.value / totalMuscleLoad
                            : 0.0,
                        compartments: [
                          for (final c in entry.key.compartments)
                            if ((load.compartments[c] ?? 0) > 0)
                              MapEntry(c, load.compartments[c]!),
                        ]..sort((a, b) => b.value.compareTo(a.value)),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyMuscleState() {
    return Row(
      children: [
        Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
        SizedBox(width: AppSpace.sm),
        Text('Kas yükü verisi mevcut değil.', style: AppText.bodyMuted),
      ],
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _MuscleLoadRow extends StatelessWidget {
  const _MuscleLoadRow({
    required this.muscleName,
    required this.load,
    required this.ratio,
    this.compartments = const [],
  });

  final String muscleName;
  final double load;
  final double ratio;

  /// Bölgenin kompartıman ayrıntısı (Türkçe etiket + yük).
  final List<MapEntry<MuscleCompartment, double>> compartments;

  @override
  Widget build(BuildContext context) {
    final evaluation = evaluateMuscleLoad(load);
    final Color statusColor;
    switch (evaluation.level) {
      case MliStimulusLevel.optimal:
        statusColor = AppColors.emerald;
      case MliStimulusLevel.understimulated:
        statusColor = AppColors.textMuted;
      case MliStimulusLevel.overload:
        statusColor = AppColors.amber;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                muscleName,
                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            StatusDot(color: statusColor),
            const SizedBox(width: 6),
            Text(
              evaluation.label,
              style: AppText.caption.copyWith(fontSize: 11),
            ),
            const SizedBox(width: AppSpace.md),
            SizedBox(
              width: 44,
              child: Text(
                '${load.round()}',
                textAlign: TextAlign.right,
                style: AppText.metricS.copyWith(fontSize: 15),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        SegmentedBar(
          value: ratio.clamp(0.0, 1.0).toDouble(),
          segments: 20,
          color: AppColors.textHigh,
        ),
        if (compartments.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              [
                for (final c in compartments)
                  '${c.key.label} ${c.value.round()}',
              ].join('  ·  '),
              style: AppText.caption.copyWith(fontSize: 11.5),
            ),
          ),
      ],
    );
  }
}
