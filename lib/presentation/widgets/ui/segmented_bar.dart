// lib/presentation/widgets/ui/segmented_bar.dart

import 'package:flutter/material.dart';

import 'package:calisthenics_app/presentation/theme/app_theme.dart';

/// WHOOP tarzı ince, segmentli ilerleme barı.
///
/// [value] 0–1 arasıdır; dolu segment sayısı `(value * segments).round()`.
class SegmentedBar extends StatelessWidget {
  const SegmentedBar({
    super.key,
    required this.value,
    this.segments = 10,
    this.height = 4,
    this.gap = 2,
    this.color = AppColors.textHigh,
    this.trackColor = AppColors.hairlineStrong,
  });

  final double value;
  final int segments;
  final double height;
  final double gap;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _SegmentedBarPainter(
          filled: (value.clamp(0.0, 1.0) * segments).round(),
          segments: segments,
          gap: gap,
          color: color,
          trackColor: trackColor,
        ),
      ),
    );
  }
}

class _SegmentedBarPainter extends CustomPainter {
  _SegmentedBarPainter({
    required this.filled,
    required this.segments,
    required this.gap,
    required this.color,
    required this.trackColor,
  });

  final int filled;
  final int segments;
  final double gap;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (segments <= 0 || size.width <= 0) return;
    final segWidth = (size.width - gap * (segments - 1)) / segments;
    final radius = Radius.circular(size.height / 2);
    final fill = Paint()..color = color;
    final track = Paint()..color = trackColor;
    for (var i = 0; i < segments; i++) {
      final left = i * (segWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, 0, segWidth, size.height),
          radius,
        ),
        i < filled ? fill : track,
      );
    }
  }

  @override
  bool shouldRepaint(_SegmentedBarPainter old) =>
      old.filled != filled ||
      old.segments != segments ||
      old.gap != gap ||
      old.color != color ||
      old.trackColor != trackColor;
}
