// lib/presentation/widgets/empty_state.dart

import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const EmptyState({
    super.key,
    this.icon = Icons.favorite_border,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface.withOpacity(0.6);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 72.0, color: color),
          const SizedBox(height: 16.0),
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: color),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8.0),
            Text(
              subtitle!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
