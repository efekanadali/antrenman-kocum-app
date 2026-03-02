// lib/presentation/screens/user_profile_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  static const Color _bgTop = Color(0xFF151028);
  static const Color _bgBottom = Color(0xFF0E0A1D);
  static const Color _cardSurface = Color(0xFF201836);
  static const Color _cardSurfaceSoft = Color(0xFF2A2048);
  static const Color _cardSurfaceTint = Color(0xFF2E2552);
  static const Color _accentPurple = Color(0xFF6D5BFF);
  static const Color _accentBlue = Color(0xFF4FC3F7);
  static const Color _textHigh = Color(0xFFEDE9FF);
  static const Color _textMid = Color(0xFFB4A9D8);

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
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 12.0),
                    child: _ProfileHeader(),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: _StreakCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16.0),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: _GoalsCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16.0),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: _RecentSessionsCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32.0),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 3),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 64.0,
          height: 64.0,
          decoration: BoxDecoration(
            color: UserProfileScreen._cardSurfaceSoft,
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
          ),
          child: const Icon(
            Icons.person,
            color: UserProfileScreen._textHigh,
            size: 32.0,
          ),
        ),
        const SizedBox(width: 14.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Efekan K.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: UserProfileScreen._textHigh,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Calisthenics Level: Intermediate',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: UserProfileScreen._textMid,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: UserProfileScreen._accentPurple.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Text(
            'PRO',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: UserProfileScreen._accentPurple,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 54.0,
              height: 54.0,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6D5BFF), Color(0xFF4FC3F7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 28.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '7-Day Streak',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: UserProfileScreen._textHigh,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Keep the momentum going',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: UserProfileScreen._textMid,
                        ),
                  ),
                ],
              ),
            ),
            Text(
              '77%',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: UserProfileScreen._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Goals',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: UserProfileScreen._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12.0),
            const _GoalRow(label: 'Workouts', value: '4 / 5'),
            const SizedBox(height: 10.0),
            const _GoalRow(label: 'Total Time', value: '3h 10m / 4h'),
            const SizedBox(height: 10.0),
            const _GoalRow(label: 'Mobility', value: '2 / 3'),
          ],
        ),
      ),
    );
  }
}

class _RecentSessionsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Sessions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: UserProfileScreen._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12.0),
            const _SessionRow(
              title: 'Upper Body Strength',
              meta: '42 min - Chest + Triceps',
            ),
            const SizedBox(height: 10.0),
            const _SessionRow(
              title: 'Pull Focus',
              meta: '35 min - Back + Biceps',
            ),
            const SizedBox(height: 10.0),
            const _SessionRow(
              title: 'Core Finisher',
              meta: '18 min - Core + Mobility',
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: UserProfileScreen._textMid,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: UserProfileScreen._cardSurfaceSoft,
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: UserProfileScreen._textHigh,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ],
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42.0,
          height: 42.0,
          decoration: BoxDecoration(
            color: UserProfileScreen._cardSurfaceSoft,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: const Icon(
            Icons.fitness_center,
            color: UserProfileScreen._textHigh,
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: UserProfileScreen._textHigh,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                meta,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: UserProfileScreen._textMid,
                    ),
              ),
            ],
          ),
        ),
        const Icon(
          Icons.chevron_right,
          color: UserProfileScreen._textMid,
        ),
      ],
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
            color: UserProfileScreen._cardSurface.withOpacity(0.78),
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