// lib/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:calisthenics_app/core/local_storage/workout_summary_storage.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery_state.dart';
import 'package:calisthenics_app/domain/models/workout_session_summary.dart';
import 'package:calisthenics_app/presentation/providers/muscle_recovery_provider.dart';
import 'package:calisthenics_app/presentation/providers/workout_history_provider.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    return HomeTodayScreen(showBottomNav: showBottomNav);
  }
}

/// Günün antrenman başlığı. Program planlama verisi henüz olmadığı için
/// sabit kalır; haftalık durum, seri ve toparlanma gerçek veriden gelir.
class HomeInsightData {
  const HomeInsightData({
    required this.hasWorkoutToday,
    required this.workoutTitle,
    required this.workoutFocus,
  });

  final bool hasWorkoutToday;
  final String workoutTitle;
  final String workoutFocus;
}

/// Ana ekranın gösterdiği, provider'lardan salt okunarak türetilmiş özet.
class _DashboardData {
  _DashboardData({
    required this.weekDays,
    required this.doneDays,
    required this.today,
    required this.streak,
    required this.lastLoad,
    required this.weekLoad,
    required this.prevWeekLoad,
    required this.weekDurationSeconds,
  });

  final List<DateTime> weekDays;
  final Set<DateTime> doneDays;
  final DateTime today;
  final int streak;
  final double? lastLoad;
  final double weekLoad;
  final double prevWeekLoad;
  final int weekDurationSeconds;

  int get activeDays => doneDays.where((d) => weekDays.contains(d)).length;

  int? get trendPercent {
    if (prevWeekLoad <= 0) return null;
    return ((weekLoad - prevWeekLoad) / prevWeekLoad * 100).round();
  }

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  factory _DashboardData.from(List<WorkoutSessionSummary> sessions) {
    final now = DateTime.now();
    final today = _day(now);
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekDays = [
      for (var i = 0; i < 7; i++) monday.add(Duration(days: i)),
    ];
    final prevMonday = monday.subtract(const Duration(days: 7));

    double weekLoad = 0;
    double prevWeekLoad = 0;
    int weekDuration = 0;
    for (final s in sessions) {
      final d = _day(s.completedAt);
      if (!d.isBefore(monday)) {
        weekLoad += s.totalMliWorkload;
        weekDuration += s.durationSeconds;
      } else if (!d.isBefore(prevMonday)) {
        // Önceki haftanın aynı gün aralığıyla karşılaştır.
        if (d.difference(prevMonday).inDays <=
            today.difference(monday).inDays) {
          prevWeekLoad += s.totalMliWorkload;
        }
      }
    }

    DateTime? latest;
    double? lastLoad;
    for (final s in sessions) {
      if (latest == null || s.completedAt.isAfter(latest)) {
        latest = s.completedAt;
        lastLoad = s.totalMliWorkload;
      }
    }

    return _DashboardData(
      weekDays: weekDays,
      doneDays: {for (final s in sessions) _day(s.completedAt)},
      today: today,
      streak: calculateStreakFromDates(
        sessions.map((s) => s.completedAt).toList(),
      ),
      lastLoad: lastLoad,
      weekLoad: weekLoad,
      prevWeekLoad: prevWeekLoad,
      weekDurationSeconds: weekDuration,
    );
  }
}

/// Bir bölgenin toparlanma yüzdesi ve durumu (kartla aynı formül).
class _RegionStatus {
  const _RegionStatus(this.region, this.progress, this.ready);

  final MuscleRegion region;
  final double progress;
  final bool ready;

  static _RegionStatus of(
    MuscleRegion region,
    MuscleRecoveryState state,
    DateTime now,
  ) {
    final record = state.regions[region];
    final readyAt = record?.readyAt;
    final ready = readyAt == null || !now.isBefore(readyAt);
    var progress = 1.0;
    final hours = record?.recoveryHours ?? 0;
    if (!ready && record != null && hours > 0) {
      final elapsed = now.difference(record.lastTrainedAt).inMinutes;
      progress = (elapsed / (hours * 60)).clamp(0.0, 1.0).toDouble();
    }
    return _RegionStatus(region, progress, ready);
  }
}

const List<String> _weekdayLetters = ['P', 'S', 'Ç', 'P', 'C', 'C', 'P'];
const List<String> _weekdayNames = [
  'Pazartesi',
  'Salı',
  'Çarşamba',
  'Perşembe',
  'Cuma',
  'Cumartesi',
  'Pazar',
];
const List<String> _monthNames = [
  'Ocak',
  'Şubat',
  'Mart',
  'Nisan',
  'Mayıs',
  'Haziran',
  'Temmuz',
  'Ağustos',
  'Eylül',
  'Ekim',
  'Kasım',
  'Aralık',
];

class HomeTodayScreen extends ConsumerStatefulWidget {
  const HomeTodayScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  static const HomeInsightData _todayWorkout = HomeInsightData(
    hasWorkoutToday: true,
    workoutTitle: 'Push Day',
    workoutFocus: 'Göğüs + Triceps · Güç & Hipertrofi',
  );

  @override
  ConsumerState<HomeTodayScreen> createState() => _HomeTodayScreenState();
}

class _HomeTodayScreenState extends ConsumerState<HomeTodayScreen> {
  static const String _targetWorkoutsKey = 'profile_target_workouts_weekly';
  int _weeklyTarget = 5;

  @override
  void initState() {
    super.initState();
    _loadWeeklyTarget();
  }

  Future<void> _loadWeeklyTarget() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getInt(_targetWorkoutsKey);
      if (!mounted || value == null || value <= 0) return;
      setState(() => _weeklyTarget = value);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sessions =
        ref.watch(workoutHistoryProvider).valueOrNull ??
        const <WorkoutSessionSummary>[];
    final recovery =
        ref.watch(muscleRecoveryProvider).valueOrNull ??
        const MuscleRecoveryState();
    final data = _DashboardData.from(sessions);
    final now = DateTime.now();
    final statuses = [
      for (final r in MuscleRegion.values) _RegionStatus.of(r, recovery, now),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.xl,
            AppSpace.page,
            AppSpace.section * 2,
          ),
          children: [
            _DashboardHeader(today: data.today),
            const SizedBox(height: AppSpace.xxl),
            _TodayCard(
              workout: HomeTodayScreen._todayWorkout,
              data: data,
              statuses: statuses,
            ),
            const SizedBox(height: AppSpace.section),
            _WeekSection(data: data, weeklyTarget: _weeklyTarget),
            const SizedBox(height: AppSpace.xxl),
            const Hairline(),
            const SizedBox(height: AppSpace.xl),
            _QuickStats(data: data),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(selectedIndex: 0)
          : null,
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.today});

  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${_weekdayNames[today.weekday - 1]} · ${today.day} ${_monthNames[today.month - 1]}';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(trUpper(dateLabel), style: AppText.sectionLabel),
              const SizedBox(height: 6),
              const Text('Bugün', style: AppText.pageTitle),
            ],
          ),
        ),
        InkWell(
          customBorder: const CircleBorder(),
          onTap: () => Navigator.of(context).pushNamed(AppRoutes.userProfile),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.hairlineStrong,
                width: AppSpace.hairline,
              ),
            ),
            child: const Icon(
              Icons.person_outline_rounded,
              size: 18,
              color: AppColors.textMid,
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({
    required this.workout,
    required this.data,
    required this.statuses,
  });

  final HomeInsightData workout;
  final _DashboardData data;
  final List<_RegionStatus> statuses;

  @override
  Widget build(BuildContext context) {
    final readyCount = statuses.where((s) => s.ready).length;
    final recovering = statuses.where((s) => !s.ready).toList()
      ..sort((a, b) => a.progress.compareTo(b.progress));
    final mostFatigued = recovering.isEmpty ? null : recovering.first;
    final readiness = statuses.isEmpty
        ? 1.0
        : statuses.fold<double>(0, (a, s) => a + s.progress) / statuses.length;

    final radius = BorderRadius.circular(AppRadius.card + 4);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.heroTop, AppColors.surface],
          stops: [0, 0.55],
        ),
        border: Border.all(
          color: AppColors.hairlineStrong,
          width: AppSpace.hairline,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 28,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            // Üst kenardan sızan yumuşak ışık.
            Positioned(
              top: -120,
              left: -40,
              right: -40,
              height: 220,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.heroGlow,
                        AppColors.heroGlow.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.xxl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              'Bugünün antrenmanı',
                              padding: EdgeInsets.only(bottom: AppSpace.sm),
                            ),
                            Text(
                              workout.hasWorkoutToday
                                  ? workout.workoutTitle
                                  : 'Dinlenme günü',
                              style: AppText.pageTitle.copyWith(fontSize: 26),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              workout.hasWorkoutToday
                                  ? workout.workoutFocus
                                  : 'Aktif toparlanma ve esneme',
                              style: AppText.bodyMuted,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpace.lg),
                      Semantics(
                        label: 'Hazırlık yüzde ${(readiness * 100).round()}',
                        child: SegmentedRing(
                          value: readiness,
                          size: 78,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '%${(readiness * 100).round()}',
                                style: AppText.metricS.copyWith(fontSize: 17),
                              ),
                              Text(
                                'hazır',
                                style: AppText.caption.copyWith(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),
                  const Hairline(),
                  const SizedBox(height: AppSpace.xl),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: MetricValue(
                            value: data.lastLoad == null
                                ? '—'
                                : data.lastLoad!.round().toString(),
                            unit: data.lastLoad == null ? null : 'MLI',
                            label: 'Son yük',
                          ),
                        ),
                        const Hairline.vertical(),
                        const SizedBox(width: AppSpace.lg),
                        Expanded(
                          child: MetricValue(
                            value: '$readyCount',
                            unit: '/${statuses.length}',
                            label: 'Bölge hazır',
                          ),
                        ),
                        const Hairline.vertical(),
                        const SizedBox(width: AppSpace.lg),
                        Expanded(
                          child: mostFatigued == null
                              ? const MetricValue(
                                  value: 'Tümü',
                                  label: 'Toparlandı',
                                )
                              : MetricValue(
                                  leading: const StatusDot(
                                    color: AppColors.amber,
                                  ),
                                  value:
                                      '%${(mostFatigued.progress * 100).round()}',
                                  label: mostFatigued.region.label,
                                ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpace.xxl),
                  PrimaryButton(
                    label: 'Antrenmana Başla',
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.stats),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekSection extends StatelessWidget {
  const _WeekSection({required this.data, required this.weeklyTarget});

  final _DashboardData data;
  final int weeklyTarget;

  @override
  Widget build(BuildContext context) {
    final active = data.activeDays;
    final trend = data.trendPercent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Bu hafta',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (data.streak > 0) ...[
                const Icon(
                  Icons.local_fire_department_outlined,
                  size: 14,
                  color: AppColors.textMid,
                ),
                const SizedBox(width: 3),
                Text(
                  '${data.streak} gün seri',
                  style: AppText.caption.copyWith(color: AppColors.textMid),
                ),
              ],
              if (data.streak > 0 && trend != null)
                Text('  ·  ', style: AppText.caption),
              if (trend != null)
                Text(
                  '${trend >= 0 ? '+' : '−'}%${trend.abs()} yük',
                  style: AppText.caption.copyWith(
                    color: trend >= 0 ? AppColors.emerald : AppColors.textMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            for (var i = 0; i < data.weekDays.length; i++)
              Expanded(
                child: _WeekDay(
                  letter: _weekdayLetters[i],
                  day: data.weekDays[i],
                  done: data.doneDays.contains(data.weekDays[i]),
                  isToday: data.weekDays[i] == data.today,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        Row(
          children: [
            Expanded(
              child: SegmentedBar(
                value: weeklyTarget <= 0 ? 0 : active / weeklyTarget,
                segments: weeklyTarget.clamp(1, 14),
                height: 4,
                gap: 3,
                color: AppColors.textHigh,
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$active',
                    style: AppText.metricS.copyWith(fontSize: 15),
                  ),
                  TextSpan(
                    text: '/$weeklyTarget',
                    style: AppText.metricS.copyWith(
                      fontSize: 15,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _WeekDay extends StatelessWidget {
  const _WeekDay({
    required this.letter,
    required this.day,
    required this.done,
    required this.isToday,
  });

  final String letter;
  final DateTime day;
  final bool done;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isToday ? AppColors.accent : Colors.transparent,
            border: isToday
                ? null
                : Border.all(
                    color: done ? AppColors.textMid : AppColors.hairlineStrong,
                    width: 1,
                  ),
          ),
          child: Text(
            isToday ? '${day.day}' : letter,
            style: AppText.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isToday
                  ? AppColors.onAccent
                  : done
                  ? AppColors.textHigh
                  : AppColors.textMuted,
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: done ? AppColors.emerald : Colors.transparent,
          ),
        ),
      ],
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({required this.data});

  final _DashboardData data;

  String _duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return '$h:${m.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: MetricValue(
              value: _duration(data.weekDurationSeconds),
              unit: 'sa',
              label: 'Haftalık süre',
            ),
          ),
          const Hairline.vertical(),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: MetricValue(value: '${data.activeDays}', label: 'Aktif gün'),
          ),
          const Hairline.vertical(),
          const SizedBox(width: AppSpace.lg),
          Expanded(
            child: MetricValue(
              value: data.weekLoad.round().toString(),
              unit: 'MLI',
              label: 'Haftalık yük',
            ),
          ),
        ],
      ),
    );
  }
}

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.selectedIndex,
    this.onItemSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onItemSelected;

  void _go(BuildContext context, int index, String route) {
    if (onItemSelected != null) {
      onItemSelected?.call(index);
      return;
    }
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_outlined, 'Ana Sayfa', AppRoutes.home),
      (Icons.fitness_center_outlined, 'Hareketler', AppRoutes.workoutLibrary),
      (Icons.calendar_today_outlined, 'Program', AppRoutes.stats),
      (Icons.person_outline_rounded, 'Profil', AppRoutes.userProfile),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.hairline, width: AppSpace.hairline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.sm,
            vertical: 6,
          ),
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: AppBottomNavItem(
                    icon: items[i].$1,
                    label: items[i].$2,
                    selected: selectedIndex == i,
                    onTap: selectedIndex == i
                        ? null
                        : () => _go(context, i, items[i].$3),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppBottomNavItem extends StatelessWidget {
  const AppBottomNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: selected ? AppColors.accent : AppColors.textMuted,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.caption.copyWith(
                fontSize: 11,
                color: selected ? AppColors.textHigh : AppColors.textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
