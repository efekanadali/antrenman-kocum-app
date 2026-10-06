// lib/presentation/screens/workout_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/core/local_storage/workout_history_storage.dart';
import 'package:calisthenics_app/core/local_storage/workout_summary_storage.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/data/services/firestore_service.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const Color _bg = Color(0xFF0C101B);
const Color _surface = Color(0xFF161C2C);
const Color _card = Color(0xFF1E263B);
const Color _stroke = Color(0xFF28324C);
const Color _accent = Color(0xFFC2F13A);
const Color _textPrimary = Color(0xFFFFFFFF);
const Color _textMuted = Color(0xFF8E9BAE);

// ─── Model ───────────────────────────────────────────────────────────────────
class WorkoutSummaryArgs {
  const WorkoutSummaryArgs({
    required this.exerciseName,
    required this.totalTime,
    required this.setsCompleted,
    required this.totalSets,
    required this.totalLoad,
    required this.muscleLoad,
  });

  final String exerciseName;
  final Duration totalTime;
  final int setsCompleted;
  final int totalSets;
  final double totalLoad;
  final Map<String, double> muscleLoad;
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

  @override
  void initState() {
    super.initState();
    // Antrenman tamamlandığında Firestore senkronizasyonunu arka planda sessizce tetikle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncToFirestore();
    });
  }

  void _syncToFirestore() {
    if (_firestoreSynced) return;
    _firestoreSynced = true;

    try {
      final sessionData = <String, dynamic>{
        'completedAt': DateTime.now().toIso8601String(),
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

      ref
          .read(firestoreServiceProvider)
          .saveWorkoutSession(sessionData)
          .catchError((_) {});
    } catch (_) {
      // Sessiz hata yakalama: UI akışını engellemez
    }
  }

  // ── Business Logic ──────────────────────────────────────────────────────────
  Future<void> _saveSession(BuildContext context) async {
    _syncToFirestore();

    final storage = WorkoutHistoryStorage();
    final summaryStorage = WorkoutSummaryStorage();
    final entry = WorkoutSessionEntry(
      exerciseName: widget.args.exerciseName,
      totalTimeSeconds: widget.args.totalTime.inSeconds,
      setsCompleted: widget.args.setsCompleted,
      totalSets: widget.args.totalSets,
      completedAt: DateTime.now(),
    );

    final summaryEntry = WorkoutSummaryEntry(
      date: DateTime.now(),
      totalLoad: widget.args.totalLoad,
      muscleLoad: widget.args.muscleLoad,
      duration: widget.args.totalTime.inSeconds,
    );

    try {
      await storage.saveSession(entry);
      await summaryStorage.saveSummary(summaryEntry);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Seans kaydedildi'),
          backgroundColor: _accent.withAlpha(220),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Kaydetme başarısız'),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
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
      backgroundColor: _bg,
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
        // Trophy icon with glow ring
        Container(
          width: 88,
          height: 88,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _card,
            border: Border.all(color: _accent, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: _accent.withAlpha(60),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            size: 42,
            color: _accent,
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Antrenman Tamamlandı!',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textPrimary,
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
            color: _textMuted,
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
            label: 'Toplam Süre',
            value: _formatDuration(widget.args.totalTime),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.fitness_center_rounded,
            label: 'Setler',
            value: '${widget.args.setsCompleted} / ${widget.args.totalSets}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricCard(
            icon: Icons.bolt_rounded,
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
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _stroke),
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
                  color: _accent.withAlpha(28),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.analytics_outlined,
                  color: _accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Kas Grubu Yük Dağılımı',
                style: TextStyle(
                  color: _textPrimary,
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
          Icon(Icons.info_outline_rounded, color: _textMuted, size: 18),
          SizedBox(width: 8),
          Text(
            'Kas yükü verisi mevcut değil.',
            style: TextStyle(color: _textMuted, fontSize: 13),
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
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _stroke),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _accent, size: 22),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: _textPrimary,
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
              color: _textMuted,
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
        badgeBg = const Color(0xFFC2F13A).withAlpha(38);
        badgeFg = const Color(0xFFC2F13A);
      case MliStimulusLevel.understimulated:
        badgeBg = Colors.white10;
        badgeFg = const Color(0xFF8E9BAE);
      case MliStimulusLevel.overload:
        badgeBg = Colors.orange.withAlpha(38);
        badgeFg = Colors.orangeAccent;
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
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Stimulus badge
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
                  color: _accent,
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
              backgroundColor: _stroke,
              valueColor: AlwaysStoppedAnimation<Color>(
                badgeFg == const Color(0xFFC2F13A) ? _accent : badgeFg,
              ),
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
          backgroundColor: _accent,
          foregroundColor: const Color(0xFF0C101B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
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
          foregroundColor: _textMuted,
          side: const BorderSide(color: _stroke),
          backgroundColor: _surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }
}
