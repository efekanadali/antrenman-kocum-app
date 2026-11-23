// lib/presentation/screens/analytics_screen.dart

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/workout_session_summary.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/presentation/providers/workout_history_provider.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/muscle_recovery_card.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';

/// `MuscleRegion.values` sırasıyla bölge etiketleri.
final List<String> _muscleLabels = [
  for (final region in MuscleRegion.values) region.label,
];

const List<String> _weekdayShort = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

enum AnalyticsRange { weekly, monthly }

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
    // Kompartıman verisi (v2) ya da bölünmüş eski anahtarlar → 6 bölge.
    s.regionWorkloads.forEach((region, value) {
      muscles[region.index] += value;
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
    final canPop = Navigator.of(context).canPop();

    final header = Padding(
      padding: EdgeInsets.fromLTRB(
        canPop ? AppSpace.sm : AppSpace.page,
        AppSpace.sm,
        AppSpace.page,
        AppSpace.xxl,
      ),
      child: Row(
        children: [
          if (canPop)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              tooltip: 'Geri',
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textHigh,
                size: 22,
              ),
            ),
          const Expanded(child: Text('Analiz', style: AppText.pageTitle)),
          SizedBox(
            width: 168,
            child: AppSegmentedControl<AnalyticsRange>(
              values: AnalyticsRange.values,
              labelOf: (r) => r == AnalyticsRange.weekly ? '7 Gün' : '30 Gün',
              selected: _range,
              onChanged: (r) => setState(() => _range = r),
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: historyAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: AppColors.textMuted,
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
                padding: const EdgeInsets.only(bottom: AppSpace.section),
                children: [
                  header,
                  const _MessageView(
                    icon: Icons.insights_outlined,
                    title: 'Henüz yeterli antrenman verisi yok',
                    message:
                        'Seans tamamladıkça grafikler ve analizler otomatik güncellenecek.',
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpace.page),
                    child: MuscleRecoveryCard(),
                  ),
                ],
              );
            }
            final days = _range == AnalyticsRange.weekly ? 7 : 30;
            final data = _compute(sessions, days);
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpace.section),
              children: [
                header,
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpace.page,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SummaryRow(data: data),
                      const SizedBox(height: AppSpace.section),
                      _LoadChartCard(
                        key: ValueKey(_range),
                        data: data,
                        weekly: _range == AnalyticsRange.weekly,
                      ),
                      const SizedBox(height: AppSpace.section),
                      _MuscleDistributionCard(data: data),
                      const SizedBox(height: AppSpace.section),
                      const MuscleRecoveryCard(),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _formatThousands(num value) {
  final v = value.round();
  final s = v.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return v < 0 ? '-$buf' : buf.toString();
}

// ─── Özet Metrikler ───────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.data});

  final _AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final top = data.topMuscleIndex;
    return AppSurface(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpace.xxl),
            child: MetricValue(
              value: _formatThousands(data.totalLoad),
              unit: 'MLI',
              label: 'Toplam iş yükü',
              style: AppText.metricXL,
            ),
          ),
          const Hairline(),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    child: MetricValue(
                      value: '${data.sessionCount}',
                      unit: 'seans',
                      label: 'Toplam seans',
                    ),
                  ),
                ),
                const Hairline.vertical(),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    child: MetricValue(
                      value: top == null ? '—' : _muscleLabels[top],
                      label: 'Ağırlıklı kas',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Günlük İş Yükü Grafiği ──────────────────────────────────────────────────
class _LoadChartCard extends StatefulWidget {
  const _LoadChartCard({super.key, required this.data, required this.weekly});

  final _AnalyticsData data;
  final bool weekly;

  @override
  State<_LoadChartCard> createState() => _LoadChartCardState();
}

class _LoadChartCardState extends State<_LoadChartCard> {
  int? _touched;

  static const TextStyle _axisStyle = TextStyle(
    color: AppColors.textMuted,
    fontSize: 10,
    fontFeatures: AppText.tabular,
  );

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final weekly = widget.weekly;
    final maxY = data.dailyLoad.fold<double>(0, (a, b) => b > a ? b : a);
    final top = maxY <= 0 ? 10.0 : maxY * 1.15;
    final activeDays = data.dailyLoad.where((v) => v > 0).toList();
    final average = activeDays.isEmpty
        ? 0.0
        : activeDays.fold<double>(0, (a, b) => a + b) / activeDays.length;
    final labelStep = weekly ? 1 : 5;
    final todayIndex = data.dailyLoad.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Günlük iş yükü',
          trailing: Text(
            average <= 0
                ? (weekly ? 'Son 7 gün' : 'Son 30 gün')
                : 'ort. ${_formatThousands(average)} MLI',
            style: AppText.caption,
          ),
          padding: const EdgeInsets.only(bottom: AppSpace.md),
        ),
        AppSurface(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.xxl,
            AppSpace.sm,
            AppSpace.md,
          ),
          child: SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                maxY: top,
                alignment: BarChartAlignment.spaceBetween,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: top / 2,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.hairline,
                    strokeWidth: AppSpace.hairline,
                    dashArray: [2, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    if (average > 0)
                      HorizontalLine(
                        y: average,
                        color: AppColors.textMuted,
                        strokeWidth: 0.75,
                        dashArray: [4, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topLeft,
                          padding: const EdgeInsets.only(left: 2, bottom: 2),
                          style: _axisStyle,
                          labelResolver: (_) => 'ort.',
                        ),
                      ),
                  ],
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(),
                  leftTitles: const AxisTitles(),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: top / 2,
                      getTitlesWidget: (v, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            _formatThousands(v),
                            style: _axisStyle,
                          ),
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
                            (i % labelStep != 0 &&
                                i != data.dayLabels.length - 1)) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            data.dayLabels[i],
                            style: _axisStyle.copyWith(
                              color: i == todayIndex
                                  ? AppColors.textHigh
                                  : AppColors.textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchCallback: (event, response) {
                    final index = event.isInterestedForInteractions
                        ? response?.spot?.touchedBarGroupIndex
                        : null;
                    if (index != _touched) setState(() => _touched = index);
                  },
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.surfaceRaised,
                    tooltipBorderRadius: BorderRadius.circular(10),
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    tooltipMargin: 8,
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItem: (group, gi, rod, ri) => BarTooltipItem(
                      '${_formatThousands(rod.toY)} MLI\n',
                      const TextStyle(
                        color: AppColors.textHigh,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFeatures: AppText.tabular,
                      ),
                      children: [
                        TextSpan(
                          text: data.dayLabels[group.x],
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFeatures: AppText.tabular,
                          ),
                        ),
                      ],
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
                          width: weekly ? 14 : 5,
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(weekly ? 3 : 1.5),
                          ),
                          color: i == _touched
                              ? AppColors.accent
                              : i == todayIndex
                              ? AppColors.textHigh
                              : AppColors.chartNeutral,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Kas Grubu Dağılımı ──────────────────────────────────────────────────────
class _MuscleDistributionCard extends StatelessWidget {
  const _MuscleDistributionCard({required this.data});

  final _AnalyticsData data;

  @override
  Widget build(BuildContext context) {
    final sum = data.muscleSum;
    const header = SectionHeader(
      'Kas grubu dağılımı',
      padding: EdgeInsets.only(bottom: AppSpace.md),
    );

    if (sum <= 0) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          AppSurface(
            child: Text(
              'Bu dönemde kas grubu verisi yok.',
              style: AppText.bodyMuted,
            ),
          ),
        ],
      );
    }

    final order = List<int>.generate(_muscleLabels.length, (i) => i)
      ..sort((a, b) => data.muscleTotals[b].compareTo(data.muscleTotals[a]));
    final max = data.muscleTotals[order.first];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        AppSurface(
          child: Column(
            children: [
              for (final (rank, i) in order.indexed) ...[
                if (rank > 0) const SizedBox(height: AppSpace.lg),
                _MuscleBar(
                  label: _muscleLabels[i],
                  highlight: rank == 0,
                  fraction: max <= 0 ? 0 : data.muscleTotals[i] / max,
                  share: data.muscleTotals[i] / sum,
                  value: data.muscleTotals[i],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MuscleBar extends StatelessWidget {
  const _MuscleBar({
    required this.label,
    required this.highlight,
    required this.fraction,
    required this.share,
    required this.value,
  });

  final String label;
  final bool highlight;
  final double fraction;
  final double share;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(
            label,
            style: AppText.body.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 3,
              backgroundColor: AppColors.hairline,
              valueColor: AlwaysStoppedAnimation<Color>(
                highlight ? AppColors.textHigh : AppColors.chartNeutral,
              ),
            ),
          ),
        ),
        SizedBox(
          width: 48,
          child: Text(
            '%${(share * 100).round()}',
            textAlign: TextAlign.right,
            style: AppText.metricS.copyWith(fontSize: 14),
          ),
        ),
        SizedBox(
          width: 56,
          child: Text(
            _formatThousands(value),
            textAlign: TextAlign.right,
            style: AppText.caption,
          ),
        ),
      ],
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
        padding: const EdgeInsets.all(AppSpace.section),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: AppColors.textMuted),
            const SizedBox(height: AppSpace.lg),
            Text(title, textAlign: TextAlign.center, style: AppText.cardTitle),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppText.bodyMuted,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpace.xl),
              GhostButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}
