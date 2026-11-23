// lib/presentation/widgets/rounded_card.dart

import 'package:flutter/material.dart';

import 'package:calisthenics_app/presentation/widgets/ui/app_surface.dart';

/// Geriye dönük uyumluluk için [AppSurface] sarmalayıcısı.
class RoundedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final double borderRadius;
  final VoidCallback? onTap;

  const RoundedCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12.0),
    this.elevation = 0.0,
    this.borderRadius = 16.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurface(
      padding: padding,
      radius: borderRadius,
      onTap: onTap,
      child: child,
    );
  }
}
