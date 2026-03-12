// lib/presentation/screens/stats_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/presentation/providers/custom_program_provider.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

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
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(customProgramProvider);
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
                          'Antrenman Programı',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: _textHigh,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 6.0),
                        Text(
                          'Haftalık rutin ve günlük akış',
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
                    child: _ProgramTypeCard(
                      title: 'Evde Antrenman',
                      subtitle: 'Ekipmansız vücut ağırlığı plan',
                      schedule: '3 Gün',
                      duration: '35-45 dk',
                      location: 'Ev',
                      icon: Icons.home_rounded,
                      accent: StatsScreen._accentPurple,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16.0),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: _ProgramTypeCard(
                      title: 'Spor Salonu',
                      subtitle: 'Serbest ağırlık + makine plan',
                      schedule: '3 Gün',
                      duration: '45-60 dk',
                      location: 'Salon',
                      icon: Icons.fitness_center,
                      accent: StatsScreen._accentBlue,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32.0),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 8.0),
                    child: Text(
                      'Programlarım',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: programs.when(
                      data: (items) {
                        if (items.isEmpty) {
                          return const _EmptyProgramCard();
                        }
                        return Column(
                          children: [
                            for (final program in items)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: _CustomProgramCard(program: program),
                              ),
                          ],
                        );
                      },
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (err, _) => _ErrorProgramCard(message: '$err'),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(
                  child: SizedBox(height: 32.0),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverToBoxAdapter(
                    child: _CustomPlanCard(),
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
      bottomNavigationBar:
          showBottomNav ? const AppBottomNav(selectedIndex: 2) : null,
    );
  }
}

class _CustomPlanCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, AppRoutes.customPlan),
      child: _GlassCard(
        borderRadius: 22.0,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 44.0,
                height: 44.0,
                decoration: BoxDecoration(
                  color: StatsScreen._accentPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: StatsScreen._accentPurple,
                ),
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Senin Planin',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: StatsScreen._textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Kendi antrenman programını oluştur.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: StatsScreen._textMid,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8.0),
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.customPlan),
                style: OutlinedButton.styleFrom(
                  foregroundColor: StatsScreen._textHigh,
                  side: BorderSide(
                    color: Colors.white.withOpacity(0.24),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                ),
                child: const Text('Olustur'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomProgramCard extends ConsumerWidget {
  const _CustomProgramCard({required this.program});

  final CustomProgram program;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: _GlassCard(
            borderRadius: 22.0,
            child: Padding(
              padding: const EdgeInsets.all(18.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programi sil',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: StatsScreen._textHigh,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '"${program.name}" programini silmek istedigine emin misin?',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: StatsScreen._textMid,
                        ),
                  ),
                  const SizedBox(height: 16.0),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Vazgec'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Sil'),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await ref.read(customProgramProvider.notifier).removeProgram(program.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.customProgramDetail,
          arguments: program,
        ),
        borderRadius: BorderRadius.circular(22.0),
        splashColor: StatsScreen._accentBlue.withOpacity(0.12),
        highlightColor: StatsScreen._accentBlue.withOpacity(0.06),
        child: _GlassCard(
          borderRadius: 22.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: StatsScreen._accentPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: StatsScreen._accentPurple,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        program.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: StatsScreen._textHigh,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6.0),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: [
                          _InfoPill(label: '${program.daysCount} Gün'),
                          _InfoPill(label: '${program.totalExercises} Egzersiz'),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _confirmDelete(context, ref),
                  icon: const Icon(Icons.delete_outline),
                  color: Colors.redAccent,
                  splashRadius: 22.0,
                  tooltip: 'Programi sil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyProgramCard extends StatelessWidget {
  const _EmptyProgramCard();

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Henüz program yok. “Senin Planın” bölümünden oluşturabilirsin.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StatsScreen._textMid,
              ),
        ),
      ),
    );
  }
}

class _ErrorProgramCard extends StatelessWidget {
  const _ErrorProgramCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          'Programlar yüklenemedi: $message',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: StatsScreen._textMid,
              ),
        ),
      ),
    );
  }
}

class _ProgramTypeCard extends StatelessWidget {
  const _ProgramTypeCard({
    required this.title,
    required this.subtitle,
    required this.schedule,
    required this.duration,
    required this.location,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String schedule;
  final String duration;
  final String location;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14.0),
                  ),
                  child: Icon(
                    icon,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: StatsScreen._textHigh,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: StatsScreen._textMid,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                _InfoPill(label: schedule),
                _InfoPill(label: duration),
                _InfoPill(label: location),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: StatsScreen._cardSurfaceSoft,
        borderRadius: BorderRadius.circular(14.0),
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
