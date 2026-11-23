// lib/presentation/widgets/ui/hairline.dart

import 'package:flutter/material.dart';

import 'package:calisthenics_app/presentation/theme/app_theme.dart';

/// 0.5px düşük opaklıklı ayırıcı çizgi.
class Hairline extends StatelessWidget {
  const Hairline({super.key, this.indent = 0, this.color})
      : vertical = false,
        length = null;

  const Hairline.vertical({
    super.key,
    this.length,
    this.color,
  })  : vertical = true,
        indent = 0;

  final bool vertical;
  final double indent;
  final double? length;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    if (vertical) {
      return Container(
        width: AppSpace.hairline,
        height: length,
        color: color ?? AppColors.hairline,
      );
    }
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Container(height: AppSpace.hairline, color: color ?? AppColors.hairline),
    );
  }
}
