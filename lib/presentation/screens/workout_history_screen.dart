// lib/presentation/screens/workout_history_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/workout_session_summary.dart';
import 'package:calisthenics_app/presentation/providers/workout_history_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

// ─── Design Tokens (Nordic & Cyber-Athlete) ──────────────────────────────────
const Color _bg = AppColors.background; // #0A0C0E
const Color _surface = AppColors.surface; // #13171C
const Color _surfaceSoft = AppColors.surfaceSoft; // #181D24
const Color _border = AppColors.border; // #1E232A
const Color _volcanic = AppColors.volcanic; // #FF5533
const Color _emerald = AppColors.emerald; // #10B981
const Color _nordicIce = AppColors.nordicIce; // #38BDF8

const Color _textPrimary = AppColors.textHigh; // #F1F5F9
const Color _textSecondary = AppColors.textMid; // #94A3B8
const Color _textMuted = AppColors.textMuted; // #64748B

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
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textPrimary, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'Antrenman Geçmişi',
          style: TextStyle(
            color: _textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.insights_rounded, color: _volcanic, size: 20),
            tooltip: 'Analitik',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.analytics),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _textSecondary, size: 20),
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
            valueColor: AlwaysStoppedAnimation<Color>(_volcanic),
            strokeWidth: 2.5,
          ),
          SizedBox(height: 16),
          Text(
            'Antrenman geçmişi yükleniyor...',
            style: TextStyle(color: _textSecondary, fontSize: 13),
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
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _border, width: 1),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: _volcanic,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Geçmiş Yüklenemedi',
              style: TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ağ bağlantısı kurulamadı veya bir hata oluştu. Lütfen tekrar deneyin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _volcanic,
                foregroundColor: Colors.white,
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
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: _border, width: 1),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                size: 34,
                color: _volcanic,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Henüz tamamlanmış antrenman yok',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tamamladığınız antrenmanların süreleri, egzersiz detayları ve MLI iş yükü puanları burada listelenecektir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textSecondary,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.workoutLibrary);
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: const Text(
                'Antrenmana Başla',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _volcanic,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Tüm Seanslar',
              style: TextStyle(
                color: _textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            Text(
              '$totalCount kayıt',
              style: const TextStyle(
                color: _textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Seans Kartları
        ...sessions.map((session) => _WorkoutSessionCard(session: session)),
      ],
    );
  }
}

// ─── Header Overview Card (Nordic Mat Özet Bölmesi) ────────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewStat(
              icon: Icons.check_circle_outline_rounded,
              value: '$totalCount',
              label: 'Toplam Seans',
              iconColor: _emerald,
            ),
          ),
          Container(width: 1, height: 36, color: _border),
          Expanded(
            child: _OverviewStat(
              icon: Icons.timer_outlined,
              value: _formatTotalTime(totalSeconds),
              label: 'Toplam Süre',
              iconColor: _nordicIce,
            ),
          ),
          Container(width: 1, height: 36, color: _border),
          Expanded(
            child: _OverviewStat(
              icon: Icons.bolt_rounded,
              value: '${totalLoad.round()} pts',
              label: 'Toplam Yük',
              iconColor: _volcanic,
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
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
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

// ─── Workout Session Card (Sol Şeritli & Mat Kapsüllü) ─────────────────────────
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
    return '$day $month $year · $hour:$minute';
  }

  String _relativeDayLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Bugün';
    if (diff == 1) return 'Dün';
    if (diff > 1 && diff < 7) return '$diff gün önce';
    return '${diff ~/ 7} hf önce';
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sol Taraf: Çok İnce, Volkanik Turuncu (#FF5533) Renkli Şerit
            Container(
              width: 3.5,
              color: _volcanic,
            ),

            // Kartın Ana Gövdesi
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst Satır: Tarih & Göreli Durum Rozeti
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 13,
                              color: _textMuted,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _formatDate(session.completedAt),
                              style: const TextStyle(
                                color: _textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: _surfaceSoft,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _border,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _relativeDayLabel(session.completedAt),
                            style: const TextStyle(
                              color: _emerald,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Egzersiz Başlığı
                    Text(
                      exerciseTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Yan Yana Mat, Küçük Kapsüller (Zaman, Seans, MLI)
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        // Süre Kapsülü
                        _NordicCapsule(
                          icon: Icons.timer_outlined,
                          label: _formatDuration(session.durationSeconds),
                          accentColor: _nordicIce,
                        ),

                        // Seans / Egzersiz Sayısı Kapsülü
                        _NordicCapsule(
                          icon: Icons.fitness_center_rounded,
                          label: '$exerciseCount Egzersiz',
                          accentColor: _textSecondary,
                        ),

                        // MLI İş Yükü Kapsülü
                        _NordicCapsule(
                          icon: Icons.bolt_rounded,
                          label: '${session.totalMliWorkload.round()} MLI',
                          accentColor: _volcanic,
                          highlight: true,
                        ),
                      ],
                    ),

                    // Kas Grupları Dağılımı (varsa)
                    if (session.muscleWorkloads.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: session.muscleWorkloads.entries.take(4).map((entry) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _surfaceSoft,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _border, width: 1),
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Nordic Mat Kapsül Bileşeni ───────────────────────────────────────────────
class _NordicCapsule extends StatelessWidget {
  const _NordicCapsule({
    required this.icon,
    required this.label,
    required this.accentColor,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final Color accentColor;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? accentColor.withValues(alpha: 0.12) : _surfaceSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: highlight ? accentColor.withValues(alpha: 0.35) : _border,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accentColor),
          const SizedBox(width: 4.5),
          Text(
            label,
            style: TextStyle(
              color: highlight ? accentColor : _textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}
