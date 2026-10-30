// lib/presentation/screens/workout_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/core/local_storage/workout_history_storage.dart';
import 'package:calisthenics_app/core/local_storage/workout_summary_storage.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
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
    this.averageRir,
  });

  final String exerciseName;
  final Duration totalTime;
  final int setsCompleted;
  final int totalSets;
  final double totalLoad;
  final Map<String, double> muscleLoad;
  final Map<String, double> muscleRir;
  final double? averageRir;
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
        'muscleWorkloads': widget.args.muscleLoad,
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
        'muscleLoad': widget.args.muscleLoad,
        'setsCompleted': widget.args.setsCompleted,
        'totalSets': widget.args.totalSets,
      };

      final firestore = ref.read(firestoreServiceProvider);
      final recovery = buildSessionRecovery(
        muscleLoad: widget.args.muscleLoad,
        muscleRir: widget.args.muscleRir,
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
      muscleLoad: widget.args.muscleLoad,
      duration: widget.args.totalTime.inSeconds,
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
          backgroundColor: AppColors.surface,
          behavior: SnackBarBehavior.floating,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
            side: const BorderSide(color: AppColors.border, width: 1.0),
          ),
          content: const Row(
            children: [
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.emerald,
                size: 20,
              ),
              SizedBox(width: 10),
              Text(
                'Seans kaydedildi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Kaydetme başarısız',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
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

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sortedMuscles = widget.args.muscleLoad.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalMuscleLoad = widget.args.muscleLoad.values.fold(
      0.0,
      (sum, v) => sum + v,
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
            // ── Header ────────────────────────────────────────────────────
            _buildHeader(context),
            const SizedBox(height: 28),

            // ── Metric Grid ───────────────────────────────────────────────
            _buildMetricGrid(),
            const SizedBox(height: 24),

            // ── Muscle Load Card ──────────────────────────────────────────
            _buildMuscleCard(sortedMuscles, totalMuscleLoad),
            const SizedBox(height: 32),

            // ── Primary CTA ───────────────────────────────────────────────
            _SaveButton(
              onPressed: () async {
                await _saveSession(context);
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.home,
                  (route) => false,
                );
              },
            ),
            const SizedBox(height: 12),

            // ── Secondary Actions ─────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _OutlineActionButton(
                    icon: Icons.replay_rounded,
                    label: 'Tekrar Başlat',
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (route) => false,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _OutlineActionButton(
                    icon: Icons.exit_to_app_rounded,
                    label: 'Kaydetmeden Çık',
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (route) => false,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(
              color: AppColors.emerald.withValues(alpha: 0.65),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 42,
            color: AppColors.emerald,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Antrenman Tamamlandı!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textHigh,
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.args.exerciseName,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textMid,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ── Metric Grid ─────────────────────────────────────────────────────────
  Widget _buildMetricGrid() {
    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            icon: Icons.timer_outlined,
            iconColor: AppColors.iceBlue,
            label: 'Toplam Süre',
            value: _formatDuration(widget.args.totalTime),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.fitness_center_rounded,
            iconColor: AppColors.emerald,
            label: 'Setler',
            value: '${widget.args.setsCompleted} / ${widget.args.totalSets}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.bolt_rounded,
            iconColor: AppColors.volcanic,
            label: 'Toplam Yük',
            value: '${widget.args.totalLoad.round()} MLI',
          ),
        ),
      ],
    );
  }

  // ── Muscle Load Card ────────────────────────────────────────────────────
  Widget _buildMuscleCard(
    List<MapEntry<String, double>> sortedMuscles,
    double totalMuscleLoad,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.iceBlue.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: AppColors.iceBlue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Kas Grubu Yük Dağılımı',
                style: TextStyle(
                  color: AppColors.textHigh,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (sortedMuscles.isEmpty)
            _buildEmptyMuscleState()
          else
            ...sortedMuscles.map(
              (entry) => _MuscleLoadRow(
                muscleName: entry.key,
                load: entry.value,
                ratio: totalMuscleLoad > 0
                    ? entry.value / totalMuscleLoad
                    : 0.0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyMuscleState() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.textMid, size: 18),
          SizedBox(width: 8),
          Text(
            'Kas yükü verisi mevcut değil.',
            style: TextStyle(color: AppColors.textMid, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.textHigh,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textMid,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MuscleLoadRow extends StatelessWidget {
  const _MuscleLoadRow({
    required this.muscleName,
    required this.load,
    required this.ratio,
  });

  final String muscleName;
  final double load;
  final double ratio;

  @override
  Widget build(BuildContext context) {
    final evaluation = evaluateMuscleLoad(load);

    final Color badgeBg;
    final Color badgeFg;
    switch (evaluation.level) {
      case MliStimulusLevel.optimal:
        badgeBg = AppColors.emerald.withValues(alpha: 0.16);
        badgeFg = AppColors.emerald;
      case MliStimulusLevel.understimulated:
        badgeBg = AppColors.iceBlue.withValues(alpha: 0.14);
        badgeFg = AppColors.iceBlue;
      case MliStimulusLevel.overload:
        badgeBg = AppColors.volcanic.withValues(alpha: 0.16);
        badgeFg = AppColors.volcanic;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  muscleName,
                  style: const TextStyle(
                    color: AppColors.textHigh,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  evaluation.label,
                  style: TextStyle(
                    color: badgeFg,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${load.round()} pts',
                style: const TextStyle(
                  color: AppColors.volcanic,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: AppColors.surfaceSoft,
              valueColor: AlwaysStoppedAnimation<Color>(badgeFg),
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.save_alt_rounded, size: 20),
        label: const Text(
          'Seansı Kaydet & Bitir',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.volcanic,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
        ),
      ),
    );
  }
}

class _OutlineActionButton extends StatelessWidget {
  const _OutlineActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 17),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textMid,
          side: const BorderSide(color: AppColors.border),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }
}
