// lib/presentation/screens/analytics_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/workout_session_summary.dart';
import 'package:calisthenics_app/presentation/providers/workout_history_provider.dart';
import 'package:calisthenics_app/presentation/widgets/muscle_recovery_card.dart';

// ─── Design Tokens ───────────────────────────────────────────────────────────
const Color _bgTop = Color(0xFF151028);
const Color _bgBottom = Color(0xFF0E0A1D);
const Color _surface = Color(0xFF201836);
const Color _surfaceSoft = Color(0xFF2A2048);
const Color _purple = Color(0xFF6D5BFF);
const Color _blue = Color(0xFF4FC3F7);
const Color _neon = Color(0xFFC2F13A);
const Color _textHigh = Color(0xFFEDE9FF);
const Color _textMid = Color(0xFFB4A9D8);
const Color _textMuted = Color(0xFF7E73A3);

const List<String> _muscleLabels = [
  'Göğüs',
  'Sırt',
  'Omuz',
  'Kol',
  'Karın',
  'Bacak',
];

const List<Color> _muscleColors = [
  Color(0xFF6D5BFF),
  Color(0xFF4FC3F7),
  Color(0xFFC2F13A),
  Color(0xFFFF7ACB),
  Color(0xFFFFB84D),
  Color(0xFF3DDC97),
];

const List<String> _weekdayShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

enum AnalyticsRange { weekly, monthly }

/// Kas grubu anahtarını (enum adı / Türkçe ad) 6 ana gruptan birine eşler.
/// Eşleşmeyen anahtarlar (ör. "Genel") için `null` döner.
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
      backgroundColor: _bgBottom,
      appBar: AppBar(
        backgroundColor: _bgTop,
        elevation: 0,
        title: const Text(
          'Analitik & Kas Yükü',
          style: TextStyle(
            color: _textHigh,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: _textHigh),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [_bgTop, _bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: historyAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _purple),
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
                    message:
                        'Seans tamamladıkça grafikler güncellenecektir.',
                  ),
                  SizedBox(height: 16),
                  MuscleRecoveryCard(),
                ],
              );
            }
            final days = _range == AnalyticsRange.weekly ? 7 : 30;
            final data = _compute(sessions, days);
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _RangeToggle(
                  value: _range,
                  onChanged: (r) => setState(() => _range = r),
                ),
                const SizedBox(height: 14),
                _SummaryRow(data: data, weekly: _range == AnalyticsRange.weekly),
                const SizedBox(height: 14),
                _LoadChartCard(data: data, weekly: _range == AnalyticsRange.weekly),
                const SizedBox(height: 14),
                _MuscleDistributionCard(data: data),
                const SizedBox(height: 14),
                const MuscleRecoveryCard(),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ─── Range toggle ────────────────────────────────────────────────────────────
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
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: selected
                  ? const LinearGradient(colors: [_purple, _blue])
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : _textMid,
                fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
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

// ─── Summary cards ───────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.data, required this.weekly});

  final _AnalyticsData data;
  final bool weekly;

  @override
  Widget build(BuildContext context) {
    final top = data.topMuscleIndex;
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            icon: Icons.check_circle_outline_rounded,
            color: _neon,
            value: '${data.sessionCount}',
            label: 'Toplam Seans',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.bolt_rounded,
            color: _blue,
            value: data.totalLoad.round().toString(),
            label: 'Toplam MLI Yükü',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SummaryCard(
            icon: Icons.fitness_center_rounded,
            color: _purple,
            value: top == null ? '-' : _muscleLabels[top],
            label: 'En Çok Çalışan',
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                color: _textHigh,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
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

// ─── Bar chart ───────────────────────────────────────────────────────────────
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
      title: 'MLI İş Yükü',
      subtitle: weekly ? 'Günlük toplam (7 gün)' : 'Günlük toplam (30 gün)',
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            maxY: top,
            alignment: BarChartAlignment.spaceBetween,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: top / 4,
              getDrawingHorizontalLine: (_) => FlLine(
                color: Colors.white.withValues(alpha: 0.06),
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
                  reservedSize: 38,
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
                  reservedSize: 26,
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
                getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                  '${data.dayLabels[group.x]}\n${rod.toY.round()} MLI',
                  const TextStyle(
                    color: _textHigh,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
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
                      borderRadius: BorderRadius.circular(weekly ? 6 : 3),
                      gradient: const LinearGradient(
                        colors: [_purple, _blue],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: top,
                        color: Colors.white.withValues(alpha: 0.03),
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

// ─── Muscle distribution ─────────────────────────────────────────────────────
class _MuscleDistributionCard extends StatelessWidget {
  const _MuscleDistributionCard({required this.data});

  final _AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final sum = data.muscleSum;

    if (sum <= 0) {
      return const _Panel(
        title: 'Kas Grubu Dağılımı',
        subtitle: 'Seçili dönem',
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: Text(
              'Bu dönemde kas grubu verisi yok.',
              style: TextStyle(color: _textMid),
            ),
          ),
        ),
      );
    }

    final order = List<int>.generate(_muscleLabels.length, (i) => i)
      ..sort((a, b) => data.muscleTotals[b].compareTo(data.muscleTotals[a]));

    return _Panel(
      title: 'Kas Grubu Dağılımı',
      subtitle: 'Seçili dönem',
      child: Column(
        children: [
          SizedBox(
            height: 190,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 46,
                sections: [
                  for (final i in order)
                    if (data.muscleTotals[i] > 0)
                      PieChartSectionData(
                        value: data.muscleTotals[i],
                        color: _muscleColors[i],
                        radius: 32,
                        title:
                            '${(data.muscleTotals[i] / sum * 100).round()}%',
                        titleStyle: const TextStyle(
                          color: Color(0xFF0E0A1D),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
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
            const SizedBox(height: 10),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: const TextStyle(color: _textHigh, fontSize: 13),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
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

// ─── Shared widgets ──────────────────────────────────────────────────────────
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
        color: _surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textHigh,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: _textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
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
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    _purple.withValues(alpha: 0.35),
                    _blue.withValues(alpha: 0.25),
                  ],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Icon(icon, size: 42, color: _textHigh),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _textHigh,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: _textMid, fontSize: 14),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
