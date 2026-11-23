// lib/presentation/widgets/ui/segmented_ring.dart

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:calisthenics_app/presentation/theme/app_theme.dart';

/// WHOOP tarzı dairesel, segmentli ilerleme halkası (ör. Readiness).
///
/// [value] 0–1 arasıdır; ortada [child] (genellikle yüzde) gösterilir.
class SegmentedRing extends StatelessWidget {
  const SegmentedRing({
    super.key,
    required this.value,
    this.size = 76,
    this.strokeWidth = 5,
    this.segments = 30,
    this.gapDegrees = 3,
    this.color = AppColors.accent,
    this.trackColor = AppColors.hairlineStrong,
    this.child,
  });

  final double value;
  final double size;
  final double strokeWidth;
  final int segments;
  final double gapDegrees;
  final Color color;
  final Color trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0).toDouble()),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, v, child) => CustomPaint(
          painter: _RingPainter(
            value: v,
            strokeWidth: strokeWidth,
            segments: segments,
            gapDegrees: gapDegrees,
            color: color,
            trackColor: trackColor,
          ),
          child: child,
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.segments,
    required this.gapDegrees,
    required this.color,
    required this.trackColor,
  });

  final double value;
  final double strokeWidth;
  final int segments;
  final double gapDegrees;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - strokeWidth) / 2,
    );
    final step = 2 * math.pi / segments;
    final gap = gapDegrees * math.pi / 180;
    final sweep = step - gap;
    final filled = (value * segments).round();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    for (var i = 0; i < segments; i++) {
      paint.color = i < filled ? color : trackColor;
      canvas.drawArc(
        rect,
        -math.pi / 2 + i * step + gap / 2,
        sweep,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.color != color || old.segments != segments;
}
