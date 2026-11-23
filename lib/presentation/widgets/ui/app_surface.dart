// lib/presentation/widgets/ui/app_surface.dart

import 'package:flutter/material.dart';

import 'package:calisthenics_app/presentation/theme/app_theme.dart';

/// Birincil kart yüzeyi: [AppColors.surface] + 0.5px hairline kenar.
class AppSurface extends StatelessWidget {
  const AppSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.card),
    this.onTap,
    this.color = AppColors.surface,
    this.radius = AppRadius.card,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color color;
  final double radius;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: showBorder
          ? const BorderSide(
              color: AppColors.hairline,
              width: AppSpace.hairline,
            )
          : BorderSide.none,
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: onTap,
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}
