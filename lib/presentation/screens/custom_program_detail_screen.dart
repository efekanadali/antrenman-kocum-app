// lib/presentation/screens/custom_program_detail_screen.dart

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';

class CustomProgramDetailScreen extends StatelessWidget {
  const CustomProgramDetailScreen({
    super.key,
    required this.program,
  });

  final CustomProgram program;

  static const Color _bgTop = Color(0xFF151028);
  static const Color _bgBottom = Color(0xFF0E0A1D);
  static const Color _cardSurface = Color(0xFF201836);
  static const Color _cardSurfaceSoft = Color(0xFF2A2048);
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
            left: -60.0,
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
            right: -50.0,
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _BackButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12.0),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              program.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    color: _textHigh,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              'Program Detayi',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: _textMid,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16.0),
                  _GlassCard(
                    borderRadius: 20.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          _InfoPill(
                            label: 'Gun',
                            value: '${program.daysCount}',
                          ),
                          const SizedBox(width: 10.0),
                          _InfoPill(
                            label: 'Egzersiz',
                            value: '${program.totalExercises}',
                            accent: _accentBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  for (final day in program.days)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: _GlassCard(
                        borderRadius: 20.0,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36.0,
                                    height: 36.0,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: _accentPurple.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      '${day.dayIndex}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: _textHigh,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Text(
                                    'Gun ${day.dayIndex}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: _textHigh,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12.0),
                              if (day.exercises.isEmpty)
                                Text(
                                  'Bu gun icin egzersiz eklenmedi.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: _textMid),
                                )
                              else
                                Column(
                                  children: [
                                    for (final exercise in day.exercises)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10.0),
                                        child: Container(
                                          padding: const EdgeInsets.all(12.0),
                                          decoration: BoxDecoration(
                                            color:
                                                _cardSurfaceSoft.withOpacity(0.9),
                                            borderRadius:
                                                BorderRadius.circular(14.0),
                                            border: Border.all(
                                              color:
                                                  Colors.white.withOpacity(0.08),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      exercise.exerciseName,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .titleSmall
                                                          ?.copyWith(
                                                            color: _textHigh,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                    ),
                                                    const SizedBox(height: 4.0),
                                                    Text(
                                                      exercise.isTimed
                                                          ? '${exercise.sets} set x ${exercise.value} sn'
                                                          : '${exercise.sets} set x ${exercise.value} tekrar',
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall
                                                          ?.copyWith(
                                                            color: _textMid,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              Icon(
                                                Icons.check_circle_outline,
                                                color:
                                                    _accentBlue.withOpacity(0.6),
                                                size: 20.0,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8.0),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow_rounded),
                      label: const Text('Antrenmana Basla'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _accentPurple,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(14.0),
      child: Ink(
        decoration: BoxDecoration(
          color: CustomProgramDetailScreen._cardSurface,
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: const SizedBox(
          width: 44.0,
          height: 44.0,
          child: Icon(
            Icons.arrow_back_rounded,
            color: CustomProgramDetailScreen._textHigh,
          ),
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
            color: CustomProgramDetailScreen._cardSurface.withOpacity(0.78),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.label,
    required this.value,
    this.accent,
  });

  final String label;
  final String value;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accentColor = accent ?? CustomProgramDetailScreen._accentPurple;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: CustomProgramDetailScreen._cardSurfaceSoft,
          borderRadius: BorderRadius.circular(14.0),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: CustomProgramDetailScreen._textMid,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
