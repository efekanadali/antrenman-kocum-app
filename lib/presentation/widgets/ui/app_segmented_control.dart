// lib/presentation/widgets/ui/app_segmented_control.dart

import 'package:flutter/material.dart';

import 'package:calisthenics_app/presentation/theme/app_theme.dart';

/// Tek parça segment kontrol: [AppColors.surfaceRaised] ray üzerinde kayan
/// küpür. Seçili segment metni atletik yeşildir (aktif seçili öğe).
class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.height = 36,
  });

  final List<T> values;
  final String Function(T value) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final index = values.indexOf(selected).clamp(0, values.length - 1);
    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(10),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segWidth = constraints.maxWidth / values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: segWidth * index,
                top: 0,
                bottom: 0,
                width: segWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: AppColors.hairline,
                      width: AppSpace.hairline,
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final v in values)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => onChanged(v),
                        child: Center(
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 160),
                            style: DefaultTextStyle.of(context).style
                                .merge(AppText.caption)
                                .copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: v == selected
                                      ? AppColors.accent
                                      : AppColors.textMid,
                                ),
                            child: Text(
                              labelOf(v),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
