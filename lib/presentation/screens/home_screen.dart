// lib/presentation/screens/home_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    return HomeTodayScreen(showBottomNav: showBottomNav);
  }
}

class HomeTodayScreen extends StatelessWidget {
  const HomeTodayScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  static const double _radiusLg = 24.0;
  static const double _radiusMd = 18.0;
  static const double _spaceXs = 8.0;
  static const double _spaceSm = 12.0;
  static const double _spaceMd = 16.0;
  static const double _spaceLg = 24.0;

  static const Color _bgTop = Color(0xFF1A1230);
  static const Color _bgBottom = Color(0xFF120A22);
  static const Color _cardSurface = Color(0xFF231A3B);
  static const Color _cardSurfaceSoft = Color(0xFF2A2048);
  static const Color _cardSurfaceTint = Color(0xFF2E2552);
  static const Color _accentPurple = Color(0xFF6D5BFF);
  static const Color _accentBlue = Color(0xFF4FC3F7);
  static const Color _textHigh = Color(0xFFEDE9FF);
  static const Color _textMid = Color(0xFFB4A9D8);

  static const HomeInsightData _mockInsightData = HomeInsightData(
    hasWorkoutToday: true,
    workoutTitle: 'Push Day',
    workoutFocus: 'Chest + Triceps',
    lastWorkoutLoad: 320,
    weeklyTrendPercent: 12,
    recoveryItems: [
      RecoveryStatusItem(muscle: 'Chest', statusLabel: 'Ready', indicator: '🟢'),
      RecoveryStatusItem(
        muscle: 'Back',
        statusLabel: 'Recovering',
        indicator: '🟡',
      ),
    ],
  );

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
            right: -80.0,
            child: Container(
              width: 260.0,
              height: 260.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentPurple.withOpacity(0.18),
              ),
            ),
          ),
          Positioned(
            top: 140.0,
            left: -120.0,
            child: Container(
              width: 240.0,
              height: 240.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentBlue.withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _spaceMd,
                      _spaceLg,
                      _spaceMd,
                      _spaceSm,
                    ),
                    child: const EnergeticHeadline(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _spaceMd,
                      _spaceSm,
                      _spaceMd,
                      _spaceSm,
                    ),
                    child: const GreetingAppBar(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _spaceMd,
                      _spaceSm,
                      _spaceMd,
                      _spaceSm,
                    ),
                    child: const WeeklyActivityCard(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      _spaceMd,
                      _spaceSm,
                      _spaceMd,
                      0,
                    ),
                    child: const HomeInsightsSection(data: _mockInsightData),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: _spaceLg),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: _spaceMd),
                    child: const QuickStatsCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: _spaceLg),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 96.0)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          showBottomNav ? const AppBottomNav(selectedIndex: 0) : null,
    );
  }
}

class HomeInsightsSection extends StatelessWidget {
  const HomeInsightsSection({super.key, required this.data});

  final HomeInsightData data;

  @override
  Widget build(BuildContext context) {
    final trendPrefix = data.weeklyTrendPercent >= 0 ? '+' : '';
    final trendEmoji = data.weeklyTrendPercent >= 0 ? '📈' : '📉';

    return GlassCard(
      borderRadius: HomeTodayScreen._radiusLg,
      child: Padding(
        padding: const EdgeInsets.all(HomeTodayScreen._spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bugun',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: HomeTodayScreen._textMid,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4.0),
            Text(
              data.hasWorkoutToday
                  ? 'Today: ${data.workoutTitle} 💪'
                  : 'No workout planned',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: HomeTodayScreen._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4.0),
            Text(
              data.hasWorkoutToday
                  ? 'Focus: ${data.workoutFocus}'
                  : 'Start a session',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HomeTodayScreen._textMid,
                  ),
            ),
            const SizedBox(height: 12.0),
            SizedBox(
              height: 38.0,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRoutes.stats);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HomeTodayScreen._accentPurple,
                  foregroundColor: HomeTodayScreen._textHigh,
                  textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
                child: const Text('Start Workout'),
              ),
            ),
            const SizedBox(height: 12.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                color: HomeTodayScreen._cardSurfaceSoft,
                borderRadius: BorderRadius.circular(14.0),
              ),
              child: Text(
                'Last workout: ${data.lastWorkoutLoad.toStringAsFixed(0)} load',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HomeTodayScreen._textHigh,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            const SizedBox(height: 10.0),
            ...data.recoveryItems.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Text(
                  '${item.muscle}: ${item.statusLabel} ${item.indicator}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: HomeTodayScreen._textMid,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              '$trendPrefix${data.weeklyTrendPercent}% this week $trendEmoji',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HomeTodayScreen._accentBlue,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeInsightData {
  const HomeInsightData({
    required this.hasWorkoutToday,
    required this.workoutTitle,
    required this.workoutFocus,
    required this.lastWorkoutLoad,
    required this.weeklyTrendPercent,
    required this.recoveryItems,
  });

  final bool hasWorkoutToday;
  final String workoutTitle;
  final String workoutFocus;
  final double lastWorkoutLoad;
  final int weeklyTrendPercent;
  final List<RecoveryStatusItem> recoveryItems;
}

class RecoveryStatusItem {
  const RecoveryStatusItem({
    required this.muscle,
    required this.statusLabel,
    required this.indicator,
  });

  final String muscle;
  final String statusLabel;
  final String indicator;
}

class GreetingAppBar extends StatelessWidget {
  const GreetingAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İvme',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: HomeTodayScreen._textMid,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                '7 Günlük Seri',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: HomeTodayScreen._textHigh,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12.0),
        Stack(
          children: [
            const CircleAvatar(
              radius: 20.0,
              backgroundColor: HomeTodayScreen._cardSurfaceTint,
              child: Icon(
                Icons.person,
                color: HomeTodayScreen._textHigh,
              ),
            ),
            Positioned(
              right: 2.0,
              bottom: 2.0,
              child: Container(
                width: 10.0,
                height: 10.0,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CD964),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: HomeTodayScreen._bgTop,
                    width: 2.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class TodayWorkoutCard extends StatelessWidget {
  const TodayWorkoutCard({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: HomeTodayScreen._radiusLg,
      child: Padding(
        padding: const EdgeInsets.all(HomeTodayScreen._spaceMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                    decoration: BoxDecoration(
                      color: HomeTodayScreen._accentPurple.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      'Günün Antrenmanı',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: HomeTodayScreen._accentPurple,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Text(
                    'Tüm Vücut Güç',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: HomeTodayScreen._textHigh,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    '45 dk • Orta seviye',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HomeTodayScreen._textMid,
                        ),
                  ),
                  const SizedBox(height: 14.0),
                  Row(
                    children: [
                      Text(
                        'İlerleme',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: HomeTodayScreen._textMid,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '${(progress * 100).round()}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: HomeTodayScreen._textHigh,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 6.0,
                            backgroundColor:
                                HomeTodayScreen._cardSurfaceSoft,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              HomeTodayScreen._accentBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12.0),
                    ],
                  ),
                  const SizedBox(height: 14.0),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _AvatarStack(
                            avatars: const [
                              Icons.person,
                              Icons.person_outline,
                              Icons.person_outline,
                            ],
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(
                              '+5 arkadaş şu an aktif',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: HomeTodayScreen._textMid,
                                  ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context)
                                .pushNamed(AppRoutes.workoutLibrary);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: HomeTodayScreen._textHigh,
                            backgroundColor: HomeTodayScreen._cardSurfaceSoft,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                              vertical: 8.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            textStyle: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          child: const Text('Hareketleri keşfet'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            const _PlayButton(),
          ],
        ),
      ),
    );
  }
}

class EnergeticHeadline extends StatelessWidget {
  const EnergeticHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Günaydın,',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: HomeTodayScreen._textMid,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6.0),
        Text(
          'Bugünü domine edelim 💪',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: HomeTodayScreen._textHigh,
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class WeeklyActivityCard extends StatelessWidget {
  const WeeklyActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    const weekData = [
      _WeekDayChip(
        label: 'Pzt',
        dayOfMonth: '18',
        isDone: true,
      ),
      _WeekDayChip(
        label: 'Sal',
        dayOfMonth: '19',
        isDone: true,
      ),
      _WeekDayChip(
        label: 'Car',
        dayOfMonth: '20',
        isActive: true,
      ),
      _WeekDayChip(
        label: 'Per',
        dayOfMonth: '21',
      ),
      _WeekDayChip(
        label: 'Cum',
        dayOfMonth: '22',
      ),
      _WeekDayChip(
        label: 'Cmt',
        dayOfMonth: '23',
      ),
      _WeekDayChip(
        label: 'Paz',
        dayOfMonth: '24',
      ),
    ];

    return GlassCard(
      borderRadius: HomeTodayScreen._radiusLg,
      child: Padding(
        padding: const EdgeInsets.all(HomeTodayScreen._spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Antrenman Takvimi',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: HomeTodayScreen._textHigh,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10.0,
                    vertical: 6.0,
                  ),
                  decoration: BoxDecoration(
                    color: HomeTodayScreen._accentPurple.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '7 gun seri',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: HomeTodayScreen._accentPurple,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6.0),
            Text(
              'Mart 2026 • Bu hafta 3/5 antrenman',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: HomeTodayScreen._textMid,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: HomeTodayScreen._cardSurfaceTint,
                border: Border.all(
                  color: Colors.white.withOpacity(0.06),
                ),
                borderRadius: BorderRadius.circular(HomeTodayScreen._radiusMd),
              ),
              child: Row(
                children: weekData
                    .map((day) => Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: day,
                          ),
                        ))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuickStatsCard extends StatelessWidget {
  const QuickStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: HomeTodayScreen._radiusLg,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: HomeTodayScreen._spaceMd,
          vertical: HomeTodayScreen._spaceSm,
        ),
        child: Row(
          children: const [
            Expanded(
              child: _QuickStatItem(
                value: '4s 20d',
                label: 'Haftalık süre',
              ),
            ),
            _QuickStatDivider(),
            Expanded(
              child: _QuickStatItem(
                value: '5 Days',
                label: 'Aktif Gün',
              ),
            ),
            _QuickStatDivider(),
            Expanded(
              child: _QuickStatItem(
                value: '2 KR',
                label: 'Yeni Rekor',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  const _QuickStatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: HomeTodayScreen._textHigh,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: HomeTodayScreen._textMid,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _QuickStatDivider extends StatelessWidget {
  const _QuickStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.0,
      height: 42.0,
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      color: HomeTodayScreen._cardSurfaceTint,
    );
  }
}

class BrowseCategoriesRow extends StatelessWidget {
  const BrowseCategoriesRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategorilere Göz At',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HomeTodayScreen._textHigh,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 120.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              CategoryCard(label: 'Güç'),
              SizedBox(width: 12.0),
              CategoryCard(label: 'Kardiyo'),
              SizedBox(width: 12.0),
              CategoryCard(label: 'YYA'),
            ],
          ),
        ),
      ],
    );
  }
}

class RecommendedList extends StatelessWidget {
  const RecommendedList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sana Özel Öneriler',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: HomeTodayScreen._textHigh,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12.0),
        const RecommendedItem(
          title: 'Üst Vücut Güç',
          meta: '30 dk • İleri',
        ),
        const SizedBox(height: 12.0),
        const RecommendedItem(
          title: 'Gece Koşu Aralıkları',
          meta: '45 dk • Orta seviye',
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: HomeTodayScreen._cardSurface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(HomeTodayScreen._radiusLg),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.35),
              blurRadius: 20.0,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            AppBottomNavItem(
              icon: Icons.home_rounded,
              label: 'Ana Sayfa',
              selected: selectedIndex == 0,
              onTap: selectedIndex == 0
                  ? null
                  : () {
                      if (onItemSelected != null) {
                        onItemSelected?.call(0);
                        return;
                      }
                      Navigator.of(context).pushNamed(AppRoutes.home);
                    },
            ),
            AppBottomNavItem(
              icon: Icons.fitness_center,
              label: 'Hareketler',
              selected: selectedIndex == 1,
              onTap: selectedIndex == 1
                  ? null
                  : () {
                      if (onItemSelected != null) {
                        onItemSelected?.call(1);
                        return;
                      }
                      Navigator.of(context)
                          .pushNamed(AppRoutes.workoutLibrary);
                    },
            ),
            AppBottomNavItem(
              icon: Icons.event_note,
              label: 'Program',
              selected: selectedIndex == 2,
              onTap: selectedIndex == 2
                  ? null
                  : () {
                      if (onItemSelected != null) {
                        onItemSelected?.call(2);
                        return;
                      }
                      Navigator.of(context).pushNamed(AppRoutes.stats);
                    },
            ),
            AppBottomNavItem(
              icon: Icons.person,
              label: 'Profil',
              selected: selectedIndex == 3,
              onTap: selectedIndex == 3
                  ? null
                  : () {
                      if (onItemSelected != null) {
                        onItemSelected?.call(3);
                        return;
                      }
                      Navigator.of(context)
                          .pushNamed(AppRoutes.userProfile);
                    },
            ),
          ],
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
    final color =
        selected ? HomeTodayScreen._accentPurple : HomeTodayScreen._textMid;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24.0),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryCard extends StatelessWidget {
  const CategoryCard({super.key, required this.label, this.image});

  final String label;
  final ImageProvider? image;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(HomeTodayScreen._radiusLg),
        image: image == null
            ? null
            : DecorationImage(
                image: image!,
                fit: BoxFit.cover,
              ),
        gradient: image == null
            ? const LinearGradient(
                colors: [
                  Color(0xFF2A2050),
                  Color(0xFF3A2F6C),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16.0,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 12.0,
            bottom: 12.0,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: HomeTodayScreen._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class RecommendedItem extends StatelessWidget {
  const RecommendedItem({
    super.key,
    required this.title,
    required this.meta,
    this.thumbnail,
  });

  final String title;
  final String meta;
  final ImageProvider? thumbnail;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: HomeTodayScreen._radiusLg,
      child: Padding(
        padding: const EdgeInsets.all(HomeTodayScreen._spaceSm),
        child: Row(
          children: [
            Container(
              width: 64.0,
              height: 64.0,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(HomeTodayScreen._radiusMd),
                image: thumbnail == null
                    ? null
                    : DecorationImage(
                        image: thumbnail!,
                        fit: BoxFit.cover,
                      ),
                gradient: thumbnail == null
                    ? const LinearGradient(
                        colors: [
                          Color(0xFF2C224E),
                          Color(0xFF453579),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: thumbnail == null
                  ? const Icon(
                      Icons.fitness_center,
                      color: HomeTodayScreen._textHigh,
                    )
                  : null,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: HomeTodayScreen._textHigh,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    meta,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: HomeTodayScreen._textMid,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            Container(
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(
                color: HomeTodayScreen._cardSurfaceSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: HomeTodayScreen._accentPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 20.0,
  });

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
            color: HomeTodayScreen._cardSurface.withOpacity(0.78),
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

class _PlayButton extends StatelessWidget {
  const _PlayButton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54.0,
      height: 54.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF3A8DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: HomeTodayScreen._accentBlue.withOpacity(0.45),
            blurRadius: 18.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
      child: const Icon(
        Icons.play_arrow,
        color: Colors.white,
        size: 28.0,
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.avatars});

  final List<IconData> avatars;

  @override
  Widget build(BuildContext context) {
    final width = 12.0 + (avatars.length - 1) * 16.0 + 24.0;
    return SizedBox(
      height: 26.0,
      width: width,
      child: Stack(
        children: List.generate(avatars.length, (index) {
          return Positioned(
            left: index * 16.0,
            child: CircleAvatar(
              radius: 12.0,
              backgroundColor: HomeTodayScreen._cardSurfaceSoft,
              child: Icon(
                avatars[index],
                size: 14.0,
                color: HomeTodayScreen._textHigh,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _WeekDayChip extends StatelessWidget {
  const _WeekDayChip({
    required this.label,
    required this.dayOfMonth,
    this.isActive = false,
    this.isDone = false,
  });

  final String label;
  final String dayOfMonth;
  final bool isActive;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    final bgColor = isActive
        ? HomeTodayScreen._accentPurple
        : (isDone
            ? HomeTodayScreen._accentBlue.withOpacity(0.2)
            : HomeTodayScreen._cardSurface);

    final borderColor = isActive
        ? HomeTodayScreen._accentPurple.withOpacity(0.85)
        : (isDone
            ? HomeTodayScreen._accentBlue.withOpacity(0.6)
            : Colors.white.withOpacity(0.08));

    return Container(
      height: 62.0,
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: HomeTodayScreen._textMid,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4.0),
          Text(
            dayOfMonth,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: HomeTodayScreen._textHigh,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
