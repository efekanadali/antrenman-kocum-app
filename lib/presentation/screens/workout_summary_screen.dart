// lib/presentation/screens/workout_summary_screen.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/core/local_storage/workout_history_storage.dart';

class WorkoutSummaryArgs {
  const WorkoutSummaryArgs({
    required this.exerciseName,
    required this.totalTime,
    required this.setsCompleted,
    required this.totalSets,
  });

  final String exerciseName;
  final Duration totalTime;
  final int setsCompleted;
  final int totalSets;
}

class WorkoutSummaryScreen extends StatelessWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.args,
  });

  final WorkoutSummaryArgs args;

  Future<void> _saveSession(BuildContext context) async {
    final storage = WorkoutHistoryStorage();
    final entry = WorkoutSessionEntry(
      exerciseName: args.exerciseName,
      totalTimeSeconds: args.totalTime.inSeconds,
      setsCompleted: args.setsCompleted,
      totalSets: args.totalSets,
      completedAt: DateTime.now(),
    );

    try {
      await storage.saveSession(entry);
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seans kaydedildi')),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kaydetme başarısız')),
      );
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seans Özeti'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        children: [
          Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withOpacity(0.16),
                  colorScheme.surface,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tebrikler!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6.0),
                Text(
                  args.exerciseName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16.0),
                _SummaryRow(
                  label: 'Toplam Süre',
                  value: _formatDuration(args.totalTime),
                ),
                const SizedBox(height: 10.0),
                _SummaryRow(
                  label: 'Tamamlanan Set',
                  value: '${args.setsCompleted} / ${args.totalSets}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20.0),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.home,
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tekrar Et'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Paylaşım yakında')),
                    );
                  },
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Paylaş'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          OutlinedButton.icon(
            onPressed: () => _saveSession(context),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Seansı Kaydet'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),
          const SizedBox(height: 12.0),
          TextButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            },
            icon: const Icon(Icons.home),
            label: const Text('Hareketlere Dön'),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}
