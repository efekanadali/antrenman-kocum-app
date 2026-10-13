// lib/presentation/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

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

  // ─── Nordic & Cyber-Athlete Spacing & Radius ──────────────────────────────
  static const double _radiusLg = 16.0;
  static const double _radiusMd = 12.0;
  static const double _spaceSm = 12.0;
  static const double _spaceMd = 16.0;
  static const double _spaceLg = 24.0;

  // ─── Design Tokens ────────────────────────────────────────────────────────
  static const Color _bg = AppColors.background; // #0A0C0E
  static const Color _cardSurface = AppColors.surface; // #13171C
  static const Color _cardSurfaceSoft = AppColors.surfaceSoft; // #181D24
  static const Color _border = AppColors.border; // #1E232A
  static const Color _volcanic = AppColors.volcanic; // #FF5533
  static const Color _emerald = AppColors.emerald; // #10B981
  static const Color _amber = AppColors.amber; // #F59E0B
  static const Color _textHigh = AppColors.textHigh; // #F1F5F9
  static const Color _textMid = AppColors.textMid; // #94A3B8
  static const Color _textMuted = AppColors.textMuted; // #64748B

  static const HomeInsightData _mockInsightData = HomeInsightData(
    hasWorkoutToday: true,
    workoutTitle: 'Push Day',
    workoutFocus: 'Göğüs + Triceps Hedefli Güç & Hipertrofi',
    lastWorkoutLoad: 320,
    weeklyTrendPercent: 12,
    recoveryItems: [
      RecoveryStatusItem(muscle: 'Göğüs', statusLabel: 'Hazır', indicator: '100%'),
      RecoveryStatusItem(muscle: 'Sırt', statusLabel: 'Toparlanıyor', indicator: '70%'),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _spaceMd,
                  _spaceMd,
                  _spaceMd,
                  _spaceSm,
                ),
                child: GreetingAppBar(),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _spaceMd,
                  _spaceSm,
                  _spaceMd,
                  _spaceSm,
                ),
                child: EnergeticHeadline(),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _spaceMd,
                  _spaceSm,
                  _spaceMd,
                  _spaceSm,
                ),
                child: WeeklyActivityCard(),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  _spaceMd,
                  _spaceSm,
                  _spaceMd,
                  0,
                ),
                child: HomeInsightsSection(data: _mockInsightData),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: _spaceMd),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: _spaceMd),
                child: QuickStatsCard(),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: _spaceLg),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80.0)),
          ],
        ),
      ),
      bottomNavigationBar:
          showBottomNav ? const AppBottomNav(selectedIndex: 0) : null,
    );
  }
}

/// Hero Kart: "Bugün: Push Day"
/// Devasa, heyecan verici ve net metriklerle donatılmış mat Cyber-Athlete HUD kartı.
class HomeInsightsSection extends StatelessWidget {
  const HomeInsightsSection({super.key, required this.data});

  final HomeInsightData data;

  @override
  Widget build(BuildContext context) {
    final trendPrefix = data.weeklyTrendPercent >= 0 ? '+' : '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: HomeTodayScreen._cardSurface,
        borderRadius: BorderRadius.circular(HomeTodayScreen._radiusLg),
        border: Border.all(color: HomeTodayScreen._border, width: 1.0),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: Focus Tag + Weekly Momentum Trend ───────────────────
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: HomeTodayScreen._volcanic.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: HomeTodayScreen._volcanic.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.bolt_rounded,
                      color: HomeTodayScreen._volcanic,
                      size: 14.0,
                    ),
                    SizedBox(width: 4.0),
                    Text(
                      'BUGÜNÜN HEDEFİ',
                      style: TextStyle(
                        color: HomeTodayScreen._volcanic,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: HomeTodayScreen._emerald.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: HomeTodayScreen._emerald.withValues(alpha: 0.28),
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: HomeTodayScreen._emerald,
                      size: 14.0,
                    ),
                    const SizedBox(width: 4.0),
                    Text(
                      '$trendPrefix${data.weeklyTrendPercent}% Haftalık İvme',
                      style: const TextStyle(
                        color: HomeTodayScreen._emerald,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16.0),

          // ─── Hero Title & Focus ──────────────────────────────────────────
          Text(
            data.hasWorkoutToday ? data.workoutTitle.toUpperCase() : 'DİNLENME GÜNÜ',
            style: const TextStyle(
              color: HomeTodayScreen._textHigh,
              fontSize: 28.0,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6.0),
          Text(
            data.hasWorkoutToday
                ? data.workoutFocus
                : 'Bugün aktif toparlanma ve esneme günü',
            style: const TextStyle(
              color: HomeTodayScreen._textMid,
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
            ),
          ),

          const SizedBox(height: 20.0),

          // ─── Cyber-Athlete HUD Metric Compartments ───────────────────────
          Row(
            children: [
              Expanded(
                child: _HeroMetricCell(
                  icon: Icons.fitness_center_rounded,
                  iconColor: HomeTodayScreen._volcanic,
                  value: '${data.lastWorkoutLoad.toStringAsFixed(0)} MLI',
                  label: 'İş Yükü',
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _HeroMetricCell(
                  icon: Icons.shield_rounded,
                  iconColor: HomeTodayScreen._emerald,
                  value: 'Göğüs %100',
                  label: 'Toparlandı',
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: _HeroMetricCell(
                  icon: Icons.hourglass_bottom_rounded,
                  iconColor: HomeTodayScreen._amber,
                  value: 'Sırt %70',
                  label: 'Hazırlanıyor',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20.0),

          // ─── Massive Volcanic CTA Button ─────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50.0,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(AppRoutes.stats);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: HomeTodayScreen._volcanic,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.play_arrow_rounded, size: 24.0),
                  SizedBox(width: 8.0),
                  Text(
                    'Antrenmana Başla',
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Spacer(),
                  Icon(Icons.arrow_forward_rounded, size: 18.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetricCell extends StatelessWidget {
  const _HeroMetricCell({
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
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: HomeTodayScreen._cardSurfaceSoft,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: HomeTodayScreen._border,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 14.0),
              const SizedBox(width: 4.0),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: HomeTodayScreen._textMuted,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6.0),
          Text(
            value,
            style: const TextStyle(
              color: HomeTodayScreen._textHigh,
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
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
      children: [
        Container(
          width: 42.0,
          height: 42.0,
          decoration: BoxDecoration(
            color: HomeTodayScreen._cardSurface,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: HomeTodayScreen._border, width: 1.0),
          ),
          child: const Center(
            child: Icon(
              Icons.bolt_rounded,
              color: HomeTodayScreen._volcanic,
              size: 22.0,
            ),
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'CYBER-ATHLETE',
                style: TextStyle(
                  color: HomeTodayScreen._textMuted,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 2.0),
              Text(
                '7 Günlük Seri Aktif',
                style: TextStyle(
                  color: HomeTodayScreen._textHigh,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12.0),
          onTap: () {
            Navigator.of(context).pushNamed(AppRoutes.userProfile);
          },
          child: Container(
            width: 40.0,
            height: 40.0,
            decoration: BoxDecoration(
              color: HomeTodayScreen._cardSurface,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: HomeTodayScreen._border, width: 1.0),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Center(
                  child: Icon(
                    Icons.person_rounded,
                    color: HomeTodayScreen._textHigh,
                    size: 20.0,
                  ),
                ),
                Positioned(
                  right: 4.0,
                  bottom: 4.0,
                  child: Container(
                    width: 7.0,
                    height: 7.0,
                    decoration: const BoxDecoration(
                      color: HomeTodayScreen._emerald,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class EnergeticHeadline extends StatelessWidget {
  const EnergeticHeadline({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Text(
          'GÜNAYDIN',
          style: TextStyle(
            color: HomeTodayScreen._textMuted,
            fontSize: 12.0,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.4,
          ),
        ),
        SizedBox(height: 4.0),
        Text(
          'Bugünü domine edelim 💪',
          style: TextStyle(
            color: HomeTodayScreen._textHigh,
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
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
      _WeekDayChip(label: 'Pzt', dayOfMonth: '18', isDone: true),
      _WeekDayChip(label: 'Sal', dayOfMonth: '19', isDone: true),
      _WeekDayChip(label: 'Çar', dayOfMonth: '20', isActive: true),
      _WeekDayChip(label: 'Per', dayOfMonth: '21'),
      _WeekDayChip(label: 'Cum', dayOfMonth: '22'),
      _WeekDayChip(label: 'Cmt', dayOfMonth: '23'),
      _WeekDayChip(label: 'Paz', dayOfMonth: '24'),
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: HomeTodayScreen._cardSurface,
        borderRadius: BorderRadius.circular(HomeTodayScreen._radiusLg),
        border: Border.all(color: HomeTodayScreen._border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Antrenman Takvimi',
                style: TextStyle(
                  color: HomeTodayScreen._textHigh,
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 4.0,
                ),
                decoration: BoxDecoration(
                  color: HomeTodayScreen._volcanic.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: HomeTodayScreen._volcanic.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: const Text(
                  '7 Gün Seri 🔥',
                  style: TextStyle(
                    color: HomeTodayScreen._volcanic,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          const Text(
            'Mart 2026 • Bu hafta 3/5 seans tamamlandı',
            style: TextStyle(
              color: HomeTodayScreen._textMid,
              fontSize: 12.0,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 14.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: HomeTodayScreen._cardSurfaceSoft,
              borderRadius: BorderRadius.circular(HomeTodayScreen._radiusMd),
              border: Border.all(color: HomeTodayScreen._border, width: 1.0),
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
    );
  }
}

class QuickStatsCard extends StatelessWidget {
  const QuickStatsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: HomeTodayScreen._cardSurface,
        borderRadius: BorderRadius.circular(HomeTodayScreen._radiusLg),
        border: Border.all(color: HomeTodayScreen._border, width: 1.0),
      ),
      child: Row(
        children: const [
          Expanded(
            child: _QuickStatItem(
              value: '4s 20d',
              label: 'Haftalık Süre',
              icon: Icons.timer_outlined,
            ),
          ),
          _QuickStatDivider(),
          Expanded(
            child: _QuickStatItem(
              value: '5 Gün',
              label: 'Aktif Gün',
              icon: Icons.calendar_today_rounded,
            ),
          ),
          _QuickStatDivider(),
          Expanded(
            child: _QuickStatItem(
              value: '2 KR',
              label: 'Kişisel Rekor',
              icon: Icons.emoji_events_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatItem extends StatelessWidget {
  const _QuickStatItem({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: HomeTodayScreen._textMuted, size: 13.0),
            const SizedBox(width: 4.0),
            Text(
              label,
              style: const TextStyle(
                color: HomeTodayScreen._textMuted,
                fontSize: 11.0,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Text(
          value,
          style: const TextStyle(
            color: HomeTodayScreen._textHigh,
            fontSize: 16.0,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
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
      height: 36.0,
      margin: const EdgeInsets.symmetric(horizontal: 10.0),
      color: HomeTodayScreen._border,
    );
  }
}

class TodayWorkoutCard extends StatelessWidget {
  const TodayWorkoutCard({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: HomeTodayScreen._cardSurface,
        borderRadius: BorderRadius.circular(HomeTodayScreen._radiusLg),
        border: Border.all(color: HomeTodayScreen._border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: HomeTodayScreen._volcanic.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: HomeTodayScreen._volcanic.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: const Text(
                  'Günün Antrenmanı',
                  style: TextStyle(
                    color: HomeTodayScreen._volcanic,
                    fontSize: 11.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: HomeTodayScreen._textHigh,
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          const Text(
            'Tüm Vücut Güç',
            style: TextStyle(
              color: HomeTodayScreen._textHigh,
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4.0),
          const Text(
            '45 dk • Orta Seviye',
            style: TextStyle(
              color: HomeTodayScreen._textMid,
              fontSize: 12.0,
            ),
          ),
          const SizedBox(height: 12.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5.0,
              backgroundColor: HomeTodayScreen._cardSurfaceSoft,
              valueColor: const AlwaysStoppedAnimation<Color>(
                HomeTodayScreen._volcanic,
              ),
            ),
          ),
        ],
      ),
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
        const Text(
          'Kategorilere Göz At',
          style: TextStyle(
            color: HomeTodayScreen._textHigh,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12.0),
        SizedBox(
          height: 90.0,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: const [
              CategoryCard(label: 'Güç'),
              SizedBox(width: 10.0),
              CategoryCard(label: 'Kardiyo'),
              SizedBox(width: 10.0),
              CategoryCard(label: 'Mobilite'),
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
      children: const [
        Text(
          'Sana Özel Öneriler',
          style: TextStyle(
            color: HomeTodayScreen._textHigh,
            fontSize: 16.0,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12.0),
        RecommendedItem(
          title: 'Üst Vücut Güç',
          meta: '30 dk • İleri Seviye',
        ),
        SizedBox(height: 10.0),
        RecommendedItem(
          title: 'Gece Koşu Aralıkları',
          meta: '45 dk • Orta Seviye',
        ),
      ],
    );
  }
}

/// Cyber-Athlete Matte Bottom Navigation Bar
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
    return Container(
      decoration: const BoxDecoration(
        color: HomeTodayScreen._cardSurface,
        border: Border(
          top: BorderSide(color: HomeTodayScreen._border, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
                icon: Icons.fitness_center_rounded,
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
                icon: Icons.event_note_rounded,
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
                icon: Icons.person_rounded,
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
        selected ? HomeTodayScreen._volcanic : HomeTodayScreen._textMuted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22.0),
            const SizedBox(height: 3.0),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11.0,
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
      width: 110.0,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: HomeTodayScreen._cardSurface,
        borderRadius: BorderRadius.circular(HomeTodayScreen._radiusMd),
        border: Border.all(color: HomeTodayScreen._border, width: 1.0),
      ),
      child: Align(
        alignment: Alignment.bottomLeft,
        child: Text(
          label,
          style: const TextStyle(
            color: HomeTodayScreen._textHigh,
            fontSize: 13.0,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: HomeTodayScreen._cardSurface,
        borderRadius: BorderRadius.circular(HomeTodayScreen._radiusMd),
        border: Border.all(color: HomeTodayScreen._border, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            width: 44.0,
            height: 44.0,
            decoration: BoxDecoration(
              color: HomeTodayScreen._cardSurfaceSoft,
              borderRadius: BorderRadius.circular(10.0),
              border: Border.all(color: HomeTodayScreen._border, width: 1.0),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: HomeTodayScreen._volcanic,
              size: 20.0,
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: HomeTodayScreen._textHigh,
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  meta,
                  style: const TextStyle(
                    color: HomeTodayScreen._textMid,
                    fontSize: 12.0,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 32.0,
            height: 32.0,
            decoration: BoxDecoration(
              color: HomeTodayScreen._cardSurfaceSoft,
              shape: BoxShape.circle,
              border: Border.all(color: HomeTodayScreen._border, width: 1.0),
            ),
            child: const Icon(
              Icons.chevron_right_rounded,
              color: HomeTodayScreen._textMid,
              size: 20.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// Matte Nordic Card (Drop-in replacement for GlassCard with no neon blur)
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 16.0,
  });

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: HomeTodayScreen._cardSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: HomeTodayScreen._border, width: 1.0),
      ),
      child: child,
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
    final Color bgColor;
    final Color borderColor;
    final Color textColor;

    if (isActive) {
      bgColor = HomeTodayScreen._volcanic;
      borderColor = HomeTodayScreen._volcanic;
      textColor = Colors.white;
    } else if (isDone) {
      bgColor = HomeTodayScreen._emerald.withValues(alpha: 0.14);
      borderColor = HomeTodayScreen._emerald.withValues(alpha: 0.35);
      textColor = HomeTodayScreen._emerald;
    } else {
      bgColor = HomeTodayScreen._cardSurfaceSoft;
      borderColor = HomeTodayScreen._border;
      textColor = HomeTodayScreen._textMuted;
    }

    return Container(
      height: 56.0,
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: borderColor, width: 1.0),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white70 : HomeTodayScreen._textMid,
              fontSize: 10.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            dayOfMonth,
            style: TextStyle(
              color: textColor,
              fontSize: 13.0,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
