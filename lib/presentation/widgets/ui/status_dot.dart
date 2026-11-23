// lib/presentation/widgets/ui/status_dot.dart

import 'package:flutter/material.dart';

/// Durum bildiren küçük nokta (hazır / toparlanıyor / pasif).
class StatusDot extends StatelessWidget {
  const StatusDot({super.key, required this.color, this.size = 6});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
