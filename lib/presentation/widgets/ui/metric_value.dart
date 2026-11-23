// lib/presentation/widgets/ui/metric_value.dart

import 'package:flutter/material.dart';

import 'package:calisthenics_app/presentation/theme/app_theme.dart';

/// Büyük tabular değer + küçük birim + altında etiket. İkon kullanılmaz.
class MetricValue extends StatelessWidget {
  const MetricValue({
    super.key,
    required this.value,
    this.unit,
    this.label,
    this.style = AppText.metricM,
    this.valueColor,
    this.leading,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final String value;
  final String? unit;
  final String? label;
  final TextStyle style;
  final Color? valueColor;

  /// Değerin soluna yerleşen küçük öğe (ör. [StatusDot]).
  final Widget? leading;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final valueStyle =
        valueColor == null ? style : style.copyWith(color: valueColor);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: value, style: valueStyle),
                    if (unit != null && unit!.isNotEmpty)
                      TextSpan(text: ' $unit', style: AppText.unit),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        if (label != null) ...[
          const SizedBox(height: 4),
          Text(
            label!,
            style: AppText.caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}
