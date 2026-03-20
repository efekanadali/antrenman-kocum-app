import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:calisthenics_app/core/local_storage/workout_summary_storage.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(showBottomNav: showBottomNav);
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _bgTop = Color(0xFF151028);
  static const Color _bgBottom = Color(0xFF0E0A1D);
  static const Color _cardSurface = Color(0xFF201836);
  static const Color _cardSurfaceSoft = Color(0xFF2A2048);
  static const Color _accentPurple = Color(0xFF6D5BFF);
  static const Color _accentBlue = Color(0xFF4FC3F7);
  static const Color _textHigh = Color(0xFFEDE9FF);
  static const Color _textMid = Color(0xFFB4A9D8);

  static const String _heightKey = 'profile_height_cm';
  static const String _weightKey = 'profile_weight_kg';

  late final Future<List<WorkoutSummaryEntry>> _summaryFuture;
  double _heightCm = 175.0;
  double _weightKg = 70.0;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummaries();
    _loadBodyMetrics();
  }

  Future<List<WorkoutSummaryEntry>> _loadSummaries() async {
    final storage = WorkoutSummaryStorage();
    final summaries = await storage.loadSummaries();
    if (summaries.isNotEmpty) {
      return summaries;
    }
    return buildMockWorkoutSummaries();
  }

  Future<void> _loadBodyMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHeight = prefs.getDouble(_heightKey);
    final savedWeight = prefs.getDouble(_weightKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _heightCm = savedHeight ?? _heightCm;
      _weightKg = savedWeight ?? _weightKg;
    });
  }

  Future<void> _saveBodyMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_heightKey, _heightCm);
    await prefs.setDouble(_weightKey, _weightKg);
  }

  Future<void> _editMetric({
    required String title,
    required String unit,
    required double currentValue,
    required ValueChanged<double> onApply,
  }) async {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(1),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: unit,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Iptal'),
            ),
            TextButton(
              onPressed: () {
                final parsed =
                    double.tryParse(controller.text.trim().replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  Navigator.of(context).pop();
                  return;
                }
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (value == null) {
      return;
    }

    setState(() {
      onApply(value);
    });
    await _saveBodyMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBottom,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_bgTop, _bgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -120.0,
            right: -70.0,
            child: Container(
              width: 240.0,
              height: 240.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentPurple.withOpacity(0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -120.0,
            left: -60.0,
            child: Container(
              width: 220.0,
              height: 220.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentBlue.withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            child: FutureBuilder<List<WorkoutSummaryEntry>>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final summaries = snapshot.data ?? const <WorkoutSummaryEntry>[];
                if (summaries.isEmpty) {
                  return Center(
                    child: Text(
                      'Henuz antrenman verisi yok.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _textMid,
                          ),
                    ),
                  );
                }

                final totalWorkouts = calculateTotalWorkouts(summaries);
                final totalLoad = calculateTotalLoad(summaries);
                final lastWorkoutDate = calculateLastWorkoutDate(summaries);
                final muscleDistribution = calculateMuscleDistribution(summaries);
                final trend = calculateSevenDayTrend(summaries);
                final balanceText = calculateBalanceText(muscleDistribution);

                return ListView(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 24.0),
                  children: [
                    const _UserHeader(username: 'Calisthenics Athlete'),
                    const SizedBox(height: 16.0),
                    BodyMetricsCard(
                      heightCm: _heightCm,
                      weightKg: _weightKg,
                      onEditHeight: () => _editMetric(
                        title: 'Boy (cm)',
                        unit: 'cm',
                        currentValue: _heightCm,
                        onApply: (value) => _heightCm = value,
                      ),
                      onEditWeight: () => _editMetric(
                        title: 'Kilo (kg)',
                        unit: 'kg',
                        currentValue: _weightKg,
                        onApply: (value) => _weightKg = value,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    StatsCard(
                      totalWorkouts: totalWorkouts,
                      totalLoad: totalLoad,
                      lastWorkoutDate: formatDate(lastWorkoutDate),
                    ),
                    const SizedBox(height: 12.0),
                    MuscleDistributionCard(distribution: muscleDistribution),
                    const SizedBox(height: 12.0),
                    TrendCard(
                      currentSevenDayLoad: trend.current,
                      previousSevenDayLoad: trend.previous,
                    ),
                    const SizedBox(height: 12.0),
                    BalanceCard(message: balanceText),
                    const SizedBox(height: 24.0),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          widget.showBottomNav ? const AppBottomNav(selectedIndex: 3) : null,
    );
  }
}

class BodyMetricsCard extends StatelessWidget {
  const BodyMetricsCard({
    super.key,
    required this.heightCm,
    required this.weightKg,
    required this.onEditHeight,
    required this.onEditWeight,
  });

  final double heightCm;
  final double weightKg;
  final VoidCallback onEditHeight;
  final VoidCallback onEditWeight;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vucut Olculeri',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10.0),
            _MetricEditRow(
              label: 'Boy',
              value: '${heightCm.toStringAsFixed(1)} cm',
              onTap: onEditHeight,
            ),
            const SizedBox(height: 8.0),
            _MetricEditRow(
              label: 'Kilo',
              value: '${weightKg.toStringAsFixed(1)} kg',
              onTap: onEditWeight,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricEditRow extends StatelessWidget {
  const _MetricEditRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.0),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: _ProfileScreenState._cardSurfaceSoft,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _ProfileScreenState._textMid,
                      ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ProfileScreenState._textHigh,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 6.0),
              const Icon(
                Icons.edit_rounded,
                size: 16.0,
                color: _ProfileScreenState._textMid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _ProfileScreenState._cardSurfaceSoft,
          child: const Icon(
            Icons.person,
            size: 30,
            color: _ProfileScreenState._textHigh,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _ProfileScreenState._textHigh,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Workout Insights',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _ProfileScreenState._textMid,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.totalWorkouts,
    required this.totalLoad,
    required this.lastWorkoutDate,
  });

  final int totalWorkouts;
  final double totalLoad;
  final String lastWorkoutDate;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel Istatistikler',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'Toplam antrenman',
              value: '$totalWorkouts',
              labelColor: _ProfileScreenState._textMid,
              valueColor: _ProfileScreenState._textHigh,
            ),
            _StatRow(
              label: 'Toplam birikmis yuk',
              value: totalLoad.toStringAsFixed(1),
              labelColor: _ProfileScreenState._textMid,
              valueColor: _ProfileScreenState._textHigh,
            ),
            _StatRow(
              label: 'Son antrenman',
              value: lastWorkoutDate,
              labelColor: _ProfileScreenState._textMid,
              valueColor: _ProfileScreenState._textHigh,
            ),
          ],
        ),
      ),
    );
  }
}

class MuscleDistributionCard extends StatelessWidget {
  const MuscleDistributionCard({super.key, required this.distribution});

  final Map<String, double> distribution;

  @override
  Widget build(BuildContext context) {
    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kas Dagilimi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ...sorted.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: _StatRow(
                  label: muscleDisplayName(item.key),
                  value: item.value.toStringAsFixed(1),
                  labelColor: _ProfileScreenState._textMid,
                  valueColor: _ProfileScreenState._textHigh,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TrendCard extends StatelessWidget {
  const TrendCard({
    super.key,
    required this.currentSevenDayLoad,
    required this.previousSevenDayLoad,
  });

  final double currentSevenDayLoad;
  final double previousSevenDayLoad;

  @override
  Widget build(BuildContext context) {
    final trendLabel = currentSevenDayLoad >= previousSevenDayLoad
        ? 'Increasing'
        : 'Decreasing';
    final trendIcon = currentSevenDayLoad >= previousSevenDayLoad
        ? Icons.trending_up
        : Icons.trending_down;
    final trendColor = currentSevenDayLoad >= previousSevenDayLoad
        ? const Color(0xFF3DDC84)
        : const Color(0xFFFF7A59);

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son 7 Gun Trendi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'Son 7 gun toplam yuk',
              value: currentSevenDayLoad.toStringAsFixed(1),
              labelColor: _ProfileScreenState._textMid,
              valueColor: _ProfileScreenState._textHigh,
            ),
            _StatRow(
              label: 'Onceki 7 gun toplam yuk',
              value: previousSevenDayLoad.toStringAsFixed(1),
              labelColor: _ProfileScreenState._textMid,
              valueColor: _ProfileScreenState._textHigh,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(trendIcon, size: 18.0, color: trendColor),
                const SizedBox(width: 6.0),
                Text(
                  trendLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Denge Analizi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _ProfileScreenState._textMid,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: labelColor,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.borderRadius = 20.0});

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: _ProfileScreenState._cardSurface.withOpacity(0.78),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

int calculateTotalWorkouts(List<WorkoutSummaryEntry> summaries) {
  return summaries.length;
}

double calculateTotalLoad(List<WorkoutSummaryEntry> summaries) {
  return summaries.fold<double>(0.0, (sum, item) => sum + item.totalLoad);
}

DateTime calculateLastWorkoutDate(List<WorkoutSummaryEntry> summaries) {
  final sorted = [...summaries]..sort((a, b) => b.date.compareTo(a.date));
  return sorted.first.date;
}

Map<String, double> calculateMuscleDistribution(
  List<WorkoutSummaryEntry> summaries,
) {
  final result = <String, double>{};
  for (final summary in summaries) {
    for (final entry in summary.muscleLoad.entries) {
      result.update(
        entry.key,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
    }
  }
  return result;
}

({double current, double previous}) calculateSevenDayTrend(
  List<WorkoutSummaryEntry> summaries,
) {
  final now = DateTime.now();
  final startCurrent = now.subtract(const Duration(days: 7));
  final startPrevious = now.subtract(const Duration(days: 14));

  double current = 0.0;
  double previous = 0.0;

  for (final summary in summaries) {
    if (summary.date.isAfter(startCurrent)) {
      current += summary.totalLoad;
    } else if (summary.date.isAfter(startPrevious)) {
      previous += summary.totalLoad;
    }
  }

  return (current: current, previous: previous);
}

String calculateBalanceText(Map<String, double> distribution) {
  final pushMuscles = {'chest', 'shoulders', 'triceps', 'quads'};
  final pullMuscles = {'back', 'biceps', 'hamstrings', 'glutes'};

  double push = 0.0;
  double pull = 0.0;

  for (final entry in distribution.entries) {
    final key = entry.key.toLowerCase();
    if (pushMuscles.contains(key)) {
      push += entry.value;
    }
    if (pullMuscles.contains(key)) {
      pull += entry.value;
    }
  }

  if (push > pull * 1.15) {
    return 'Push muscles are dominant. Pull muscles are lacking.';
  }
  if (pull > push * 1.15) {
    return 'Pull muscles are dominant. Push muscles are lacking.';
  }
  return 'Balanced training';
}

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String muscleDisplayName(String key) {
  switch (key.toLowerCase()) {
    case 'chest':
      return 'Chest';
    case 'back':
      return 'Back';
    case 'shoulders':
      return 'Shoulders';
    case 'biceps':
      return 'Biceps';
    case 'triceps':
      return 'Triceps';
    case 'core':
      return 'Core';
    case 'quads':
      return 'Quads';
    case 'hamstrings':
      return 'Hamstrings';
    case 'glutes':
      return 'Glutes';
    case 'calves':
      return 'Calves';
    default:
      return key;
  }
}

List<WorkoutSummaryEntry> buildMockWorkoutSummaries() {
  final now = DateTime.now();
  return [
    WorkoutSummaryEntry(
      date: now.subtract(const Duration(days: 1)),
      totalLoad: 680,
      muscleLoad: const {
        'chest': 210,
        'triceps': 120,
        'shoulders': 140,
        'core': 60,
      },
      duration: 2100,
    ),
    WorkoutSummaryEntry(
      date: now.subtract(const Duration(days: 3)),
      totalLoad: 740,
      muscleLoad: const {
        'back': 280,
        'biceps': 170,
        'shoulders': 110,
        'core': 80,
      },
      duration: 2400,
    ),
    WorkoutSummaryEntry(
      date: now.subtract(const Duration(days: 9)),
      totalLoad: 520,
      muscleLoad: const {
        'quads': 170,
        'glutes': 140,
        'hamstrings': 120,
        'calves': 90,
      },
      duration: 1900,
    ),
  ];
}
