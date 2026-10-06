// lib/presentation/screens/workout_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/workout_session_summary.dart';
import 'package:calisthenics_app/presentation/providers/workout_history_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const Color _bg = Color(0xFF0C101B);
const Color _surface = Color(0xFF161C2C);
const Color _card = Color(0xFF1E263B);
const Color _cardBorder = Color(0xFF28324C);
const Color _accent = Color(0xFFC2F13A); // Lime green fitness accent
const Color _accentBlue = Color(0xFF4FC3F7);
const Color _textPrimary = Color(0xFFFFFFFF);
const Color _textSecondary = Color(0xFF8E9BAE);
const Color _textMuted = Color(0xFF5F6E84);

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary, size: 20),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Antrenman Geçmişi',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _accent, size: 22),
            tooltip: 'Yenile',
            onPressed: () => ref.invalidate(workoutHistoryProvider),
          ),
        ],
      ),
      body: historyAsync.when(
        loading: () => const _LoadingView(),
        error: (error, stack) => _ErrorView(
          errorMessage: error.toString(),
          onRetry: () => ref.invalidate(workoutHistoryProvider),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const _EmptyHistoryView();
          }
          return _HistoryListView(sessions: sessions);
        },
      ),
    );
  }
}

// ─── Loading View ─────────────────────────────────────────────────────────────
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(_accent),
            strokeWidth: 3,
          ),
          SizedBox(height: 16),
          Text(
            'Antrenman geçmişi yükleniyor...',
            style: TextStyle(color: _textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Error View ───────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.errorMessage,
    required this.onRetry,
  });

  final String errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: Colors.redAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Geçmiş Yüklenemedi',
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ağ bağlantısı kurulamadı veya bir hata oluştu. Lütfen tekrar deneyin.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _bg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Empty State View ─────────────────────────────────────────────────────────
class _EmptyHistoryView extends StatelessWidget {
  const _EmptyHistoryView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _cardBorder, width: 1.5),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 40,
                color: _accent,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Henüz tamamlanmış antrenman yok',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tamamladığınız antrenmanların süreleri, egzersiz detayları ve MLI iş yükü puanları burada listelenecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.workoutLibrary);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: const Text(
                'Antrenmana Başla',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: _bg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── History List View ────────────────────────────────────────────────────────
class _HistoryListView extends StatelessWidget {
  const _HistoryListView({required this.sessions});

  final List<WorkoutSessionSummary> sessions;

  @override
  Widget build(BuildContext context) {
    // Toplam istatistikler
    final totalCount = sessions.length;
    final totalSeconds = sessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);
    final totalLoad = sessions.fold<double>(0.0, (sum, s) => sum + s.totalMliWorkload);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      children: [
        // İstatistik Özeti Banner'ı
        _HeaderOverviewCard(
          totalCount: totalCount,
          totalSeconds: totalSeconds,
          totalLoad: totalLoad,
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tüm Seanslar',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$totalCount kayıt',
              style: const TextStyle(
                color: _textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Seans Kartları
        ...sessions.map((session) => _WorkoutSessionCard(session: session)),
      ],
    );
  }
}

// ─── Header Overview Card ─────────────────────────────────────────────────────
class _HeaderOverviewCard extends StatelessWidget {
  const _HeaderOverviewCard({
    required this.totalCount,
    required this.totalSeconds,
    required this.totalLoad,
  });

  final int totalCount;
  final int totalSeconds;
  final double totalLoad;

  String _formatTotalTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '$hours sa $minutes dk';
    }
    return '$minutes dk';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewStat(
              icon: Icons.check_circle_outline_rounded,
              value: '$totalCount',
              label: 'Toplam Seans',
              iconColor: _accent,
            ),
          ),
          Container(width: 1, height: 40, color: _cardBorder),
          Expanded(
            child: _OverviewStat(
              icon: Icons.timer_outlined,
              value: _formatTotalTime(totalSeconds),
              label: 'Toplam Süre',
              iconColor: _accentBlue,
            ),
          ),
          Container(width: 1, height: 40, color: _cardBorder),
          Expanded(
            child: _OverviewStat(
              icon: Icons.bolt_rounded,
              value: '${totalLoad.round()} pts',
              label: 'Toplam Yük',
              iconColor: const Color(0xFFFFB74D),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: _textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ─── Workout Session Card ─────────────────────────────────────────────────────
class _WorkoutSessionCard extends StatelessWidget {
  const _WorkoutSessionCard({required this.session});

  final WorkoutSessionSummary session;

  String _formatDate(DateTime dt) {
    final months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık'
    ];
    final day = dt.day;
    final month = months[dt.month - 1];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year, $hour:$minute';
  }

  String _relativeDayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Dün';
    if (diff > 1 && diff < 7) return '$diff gün önce';
    return '${diff ~/ 7} hafta önce';
  }

  String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s dk';
  }

  @override
  Widget build(BuildContext context) {
    final exerciseCount = session.exercisesDone.isNotEmpty
        ? session.exercisesDone.length
        : 1;

    final exerciseTitle = session.exercisesDone.isNotEmpty
        ? session.exercisesDone.join(', ')
        : 'Antrenman Seansı';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst Satır: Tarih & Göreli Etiket
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: _textMuted),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(session.completedAt),
                    style: const TextStyle(
                      color: _textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withAlpha(25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _relativeDayLabel(session.completedAt),
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Egzersiz Başlığı
          Text(
            exerciseTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 14),

          // Alt Metrikler Satırı
          Row(
            children: [
              // Süre
              _MetricPill(
                icon: Icons.timer_outlined,
                label: _formatDuration(session.durationSeconds),
                color: _accentBlue,
              ),
              const SizedBox(width: 8),

              // Tamamlanan Egzersiz Sayısı
              _MetricPill(
                icon: Icons.fitness_center_rounded,
                label: '$exerciseCount Egzersiz',
                color: _textSecondary,
              ),
              const Spacer(),

              // MLI İş Yükü Puanı
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF23321D),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _accent.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.bolt_rounded, size: 14, color: _accent),
                    const SizedBox(width: 4),
                    Text(
                      '${session.totalMliWorkload.round()} MLI',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Hedeflenen Kas Grupları (varsa)
          if (session.muscleWorkloads.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: session.muscleWorkloads.entries.take(4).map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _cardBorder.withAlpha(120)),
                  ),
                  child: Text(
                    '${entry.key}: ${entry.value.round()}p',
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
