// lib/presentation/screens/stats_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Stats',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: _textHigh,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Progress at a glance',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _textMid,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: _StatSummaryCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16.0),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: _ConsistencyCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16.0),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: _MuscleFocusCard(),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16.0),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: _PersonalBestCard(),
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
      bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
    );
  }
}

class _StatSummaryCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: const [
            Expanded(
              child: _StatTile(
                value: '4h 20m',
                label: 'Weekly Time',
              ),
            ),
            _StatDivider(),
            Expanded(
              child: _StatTile(
                value: '5 Days',
                label: 'Active Days',
              ),
            ),
            _StatDivider(),
            Expanded(
              child: _StatTile(
                value: '2 PRs',
                label: 'New Records',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
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
              'Consistency',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: StatsScreen._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                _DayPill(label: 'M', active: true),
                _DayPill(label: 'T', active: true),
                _DayPill(label: 'W', active: true),
                _DayPill(label: 'T', active: true),
                _DayPill(label: 'F', active: true),
                _DayPill(label: 'S'),
                _DayPill(label: 'S'),
              ],
            ),
            const SizedBox(height: 10.0),
            Text(
              '5 of 7 days completed',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: StatsScreen._textMid,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MuscleFocusCard extends StatelessWidget {
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
              'Weekly Focus',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: StatsScreen._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: const [
                _FocusChip(label: 'Chest'),
                _FocusChip(label: 'Back'),
                _FocusChip(label: 'Core'),
                _FocusChip(label: 'Shoulders'),
                _FocusChip(label: 'Legs'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonalBestCard extends StatelessWidget {
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
              'Personal Bests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: StatsScreen._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 12.0),
            const _BestRow(title: 'Push-up max reps', value: '32'),
            const SizedBox(height: 10.0),
            const _BestRow(title: 'Pull-up max reps', value: '10'),
            const SizedBox(height: 10.0),
            const _BestRow(title: 'Plank hold', value: '2m 15s'),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: StatsScreen._textHigh,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 4.0),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: StatsScreen._textMid,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.0,
      height: 42.0,
      margin: const EdgeInsets.symmetric(horizontal: 12.0),
      color: StatsScreen._cardSurfaceTint,
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final bgColor = active
        ? StatsScreen._accentPurple
        : StatsScreen._cardSurfaceSoft;
    return Container(
      width: 30.0,
      height: 30.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: StatsScreen._textHigh,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  const _FocusChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: StatsScreen._cardSurfaceSoft,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: StatsScreen._textHigh,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _BestRow extends StatelessWidget {
  const _BestRow({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: StatsScreen._textMid,
                ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: StatsScreen._cardSurfaceSoft,
            borderRadius: BorderRadius.circular(14.0),
          ),
          child: Text(
            value,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: StatsScreen._textHigh,
                  fontWeight: FontWeight.w700,
                ),
          ),
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
            color: StatsScreen._cardSurface.withOpacity(0.78),
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
