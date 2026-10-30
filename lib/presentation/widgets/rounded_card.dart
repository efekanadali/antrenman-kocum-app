// lib/presentation/widgets/rounded_card.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

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
    this.borderRadius = 14.0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: AppColors.surface,
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: const BorderSide(color: AppColors.border, width: 1.0),
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );

    if (onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(borderRadius),
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
