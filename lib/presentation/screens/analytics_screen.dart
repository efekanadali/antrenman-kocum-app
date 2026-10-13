// lib/presentation/screens/analytics_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/workout_session_summary.dart';
import 'package:calisthenics_app/presentation/providers/workout_history_provider.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/muscle_recovery_card.dart';

// ─── Design Tokens (Nordic & Cyber-Athlete) ──────────────────────────────────
const Color _bg = AppColors.background; // #0A0C0E
const Color _surface = AppColors.surface; // #13171C
const Color _surfaceSoft = AppColors.surfaceSoft; // #181D24
const Color _border = AppColors.border; // #1E232A

const Color _volcanic = AppColors.volcanic; // #FF5533
const Color _volcanicSoft = AppColors.volcanicSoft; // #FF7733
const Color _emerald = AppColors.emerald; // #10B981
const Color _nordicIce = AppColors.nordicIce; // #38BDF8
const Color _amber = AppColors.amber; // #F59E0B

const Color _textHigh = AppColors.textHigh; // #F1F5F9
const Color _textMid = AppColors.textMid; // #94A3B8
const Color _textMuted = AppColors.textMuted; // #64748B

const List<String> _muscleLabels = [
  'Göğüs',
  'Sırt',
  'Omuz',
  'Kol',
  'Karın',
  'Bacak',
];

// Mat Nordic kas paleti
const List<Color> _muscleColors = [
  _volcanic, // Göğüs (Volkanik Turuncu)
  _emerald, // Sırt (Toparlanma Yeşili)
  _nordicIce, // Omuz (Buz Mavisi)
  _amber, // Kol (Kehribar)
  Color(0xFFFF6B6B), // Karın (Mat Mercan)
  Color(0xFF34D399), // Bacak (Mat Nane Yeşili)
];

const List<String> _weekdayShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

enum AnalyticsRange { weekly, monthly }

int? _muscleBucket(String rawKey) {
  final key = rawKey.toLowerCase().trim();
  const map = <String, int>{
    'chest': 0, 'göğüs': 0, 'gogus': 0,
    'back': 1, 'sırt': 1, 'sirt': 1,
    'shoulders': 2, 'shoulder': 2, 'omuz': 2,
    'biceps': 3, 'triceps': 3, 'kol': 3, 'arms': 3,
    'core': 4, 'abs': 4, 'karın': 4, 'karin': 4,
    'legs': 5, 'quads': 5, 'hamstrings': 5, 'glutes': 5, 'calves': 5,
    'bacak': 5,
  };
  return map[key];
}

class _AnalyticsData {
  _AnalyticsData({
    required this.dailyLoad,
    required this.dayLabels,
    required this.sessionCount,
    required this.totalLoad,
    required this.muscleTotals,
  });

  final List<double> dailyLoad;
  final List<String> dayLabels;
  final int sessionCount;
  final double totalLoad;
  final List<double> muscleTotals;

  double get muscleSum => muscleTotals.fold(0.0, (a, b) => a + b);

  int? get topMuscleIndex {
    if (muscleSum <= 0) return null;
    var best = 0;
    for (var i = 1; i < muscleTotals.length; i++) {
      if (muscleTotals[i] > muscleTotals[best]) best = i;
    }
    return best;
  }
}

_AnalyticsData _compute(List<WorkoutSessionSummary> sessions, int days) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final start = today.subtract(Duration(days: days - 1));

  final daily = List<double>.filled(days, 0.0);
  final labels = List<String>.generate(days, (i) {
    final d = start.add(Duration(days: i));
    return days <= 7
        ? _weekdayShort[d.weekday - 1]
        : '${d.day}/${d.month}';
  });
  final muscles = List<double>.filled(_muscleLabels.length, 0.0);
  var count = 0;
  var total = 0.0;

  for (final s in sessions) {
    final c = s.completedAt;
    final day = DateTime(c.year, c.month, c.day);
    if (day.isBefore(start) || day.isAfter(today)) continue;
    final idx = day.difference(start).inDays;
    daily[idx] += s.totalMliWorkload;
    total += s.totalMliWorkload;
    count++;
    s.muscleWorkloads.forEach((key, value) {
      final bucket = _muscleBucket(key);
      if (bucket != null) muscles[bucket] += value;
    });
  }

  return _AnalyticsData(
    dailyLoad: daily,
    dayLabels: labels,
    sessionCount: count,
    totalLoad: total,
    muscleTotals: muscles,
  );
}

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  AnalyticsRange _range = AnalyticsRange.weekly;

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Analitik & Kas Yükü',
          style: TextStyle(
            color: _textHigh,
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.2,
          ),
        ),
        iconTheme: const IconThemeData(color: _textHigh),
      ),
      body: historyAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: _volcanic,
          ),
        ),
        error: (e, _) => _MessageView(
          icon: Icons.wifi_off_rounded,
          title: 'Veriler yüklenemedi',
          message: 'Bağlantını kontrol edip tekrar dene.',
          actionLabel: 'Tekrar Dene',
          onAction: () => ref.invalidate(workoutHistoryProvider),
        ),
        data: (sessions) {
          if (sessions.length < 2) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: const [
                _MessageView(
                  icon: Icons.insights_rounded,
                  title: 'Henüz yeterli antrenman verisi bulunmuyor',
                  message: 'Seans tamamladıkça grafikler ve analizler otomatik güncellenecektir.',
                ),
                SizedBox(height: 16),
                MuscleRecoveryCard(),
              ],
            );
          }
          final days = _range == AnalyticsRange.weekly ? 7 : 30;
          final data = _compute(sessions, days);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              _RangeToggle(
                value: _range,
                onChanged: (r) => setState(() => _range = r),
              ),
              const SizedBox(height: 12),
              _SummaryRow(data: data),
              const SizedBox(height: 12),
              _LoadChartCard(data: data, weekly: _range == AnalyticsRange.weekly),
              const SizedBox(height: 12),
              _MuscleDistributionCard(data: data),
              const SizedBox(height: 12),
              const MuscleRecoveryCard(),
            ],
          );
        },
      ),
    );
  }
}

// ─── Range Toggle (Nordic Mat Seçici) ─────────────────────────────────────────
class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.value, required this.onChanged});

  final AnalyticsRange value;
  final ValueChanged<AnalyticsRange> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget item(AnalyticsRange r, String label) {
      final selected = value == r;
      return Expanded(
        child: GestureDetector(
          onTap: () => onChanged(r),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              color: selected ? _surfaceSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: selected
                  ? Border.all(color: _volcanic.withValues(alpha: 0.35), width: 1)
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? _textHigh : _textMid,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Row(
        children: [
          item(AnalyticsRange.weekly, 'Son 7 Gün'),
          item(AnalyticsRange.monthly, 'Son 30 Gün'),
        ],
      ),
    );
  }
}

// ─── Summary Cards (Özet Kartları - Minimalist Mat İkonlar) ────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.data});

  final _AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final top = data.topMuscleIndex;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: _emerald,
            value: '${data.sessionCount}',
            label: 'Toplam Seans',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.bolt_rounded,
            iconColor: _volcanic,
            value: data.totalLoad.round().toString(),
            label: 'Toplam MLI',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.fitness_center_rounded,
            iconColor: _nordicIce,
            value: top == null ? '-' : _muscleLabels[top],
            label: 'Ağırlıklı Kas',
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        children: [
          // Minimalist, mat renkli ikon rozeti
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.24),
                width: 1,
              ),
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: _textHigh,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: _textMid,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bar Chart (Günlük MLI İş Yükü - Mat Volkanik Turuncu Gradyan) ────────────
class _LoadChartCard extends StatelessWidget {
  const _LoadChartCard({required this.data, required this.weekly});

  final _AnalyticsData data;
  final bool weekly;

  @override
  Widget build(BuildContext context) {
    final maxY = data.dailyLoad.fold<double>(0, (a, b) => b > a ? b : a);
    final top = maxY <= 0 ? 10.0 : maxY * 1.2;
    final labelStep = weekly ? 1 : 5;

    return _Panel(
      title: 'MLI İş Yükü Dağılımı',
      subtitle: weekly ? 'Son 7 günün seans yükleri' : 'Son 30 günün seans yükleri',
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            maxY: top,
            alignment: BarChartAlignment.spaceBetween,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: top / 4,
              getDrawingHorizontalLine: (_) => const FlLine(
                color: _border,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 34,
                  interval: top / 4,
                  getTitlesWidget: (v, meta) {
                    if (v == meta.max) return const SizedBox.shrink();
                    return Text(
                      v.round().toString(),
                      style: const TextStyle(color: _textMuted, fontSize: 10),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (v, meta) {
                    final i = v.toInt();
                    if (i < 0 ||
                        i >= data.dayLabels.length ||
                        (i % labelStep != 0 && i != data.dayLabels.length - 1)) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        data.dayLabels[i],
                        style: const TextStyle(color: _textMid, fontSize: 10),
                      ),
                    );
                  },
                ),
              ),
            ),
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipColor: (_) => _surfaceSoft,
                tooltipBorder: const BorderSide(color: _border, width: 1),
                tooltipBorderRadius: BorderRadius.circular(8),
                getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                  '${data.dayLabels[group.x]}\n${rod.toY.round()} MLI',
                  const TextStyle(
                    color: _textHigh,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            barGroups: [
              for (var i = 0; i < data.dailyLoad.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: data.dailyLoad[i],
                      width: weekly ? 18 : 5,
                      borderRadius: BorderRadius.circular(weekly ? 5 : 2.5),
                      // Mat Volkanik Turuncu Gradyan (#FF5533 -> #FF7733)
                      gradient: const LinearGradient(
                        colors: [_volcanic, _volcanicSoft],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: top,
                        color: _surfaceSoft,
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
}

// ─── Muscle Distribution (Kas Grubu Dağılımı) ────────────────────────────────
class _MuscleDistributionCard extends StatelessWidget {
  const _MuscleDistributionCard({required this.data});

  final _AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final sum = data.muscleSum;

    if (sum <= 0) {
      return const _Panel(
        title: 'Kas Grubu Dağılımı',
        subtitle: 'Seçili dönem iş yükü',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'Bu dönemde kas grubu verisi yok.',
              style: TextStyle(color: _textMid, fontSize: 13),
            ),
          ),
        ),
      );
    }

    final order = List<int>.generate(_muscleLabels.length, (i) => i)
      ..sort((a, b) => data.muscleTotals[b].compareTo(data.muscleTotals[a]));

    return _Panel(
      title: 'Kas Grubu Dağılımı',
      subtitle: 'Seçili dönemin toplam iş yükü payı',
      child: Column(
        children: [
          SizedBox(
            height: 175,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 44,
                sections: [
                  for (final i in order)
                    if (data.muscleTotals[i] > 0)
                      PieChartSectionData(
                        value: data.muscleTotals[i],
                        color: _muscleColors[i],
                        radius: 28,
                        title: '${(data.muscleTotals[i] / sum * 100).round()}%',
                        titleStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          for (final i in order) ...[
            _MuscleBar(
              label: _muscleLabels[i],
              color: _muscleColors[i],
              fraction: data.muscleTotals[i] / sum,
              value: data.muscleTotals[i],
            ),
            const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }
}

class _MuscleBar extends StatelessWidget {
  const _MuscleBar({
    required this.label,
    required this.color,
    required this.fraction,
    required this.value,
  });

  final String label;
  final Color color;
  final double fraction;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(color: _textHigh, fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _textMid,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Shared Nordic Panel ─────────────────────────────────────────────────────
class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textHigh,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: _textMuted, fontSize: 11.5),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _surface,
                border: Border.all(color: _border, width: 1),
              ),
              child: Icon(icon, size: 36, color: _textMid),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textHigh,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMid, fontSize: 13, height: 1.4),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _volcanic,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
