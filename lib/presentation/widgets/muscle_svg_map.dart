// lib/presentation/widgets/muscle_svg_map.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart';

class MuscleSvgMap extends StatefulWidget {
  const MuscleSvgMap({
    super.key,
    required this.assetPath,
    required this.selectedMuscleId,
    this.lowOpacity = 0.25,
    this.highlightColor = const Color(0xFF00FFFF),
    this.glowColor = const Color(0xFF00FFFF),
    this.glowBlur = 18.0,
    this.glowSpread = 2.0,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  final String assetPath;
  final String? selectedMuscleId;
  final double lowOpacity;
  final Color highlightColor;
  final Color glowColor;
  final double glowBlur;
  final double glowSpread;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<MuscleSvgMap> createState() => _MuscleSvgMapState();
}

class _MuscleSvgMapState extends State<MuscleSvgMap> {
  static final Map<String, String> _cache = <String, String>{};
  String? _svgString;
  String? _cacheKey;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadSvg();
  }

  @override
  void didUpdateWidget(MuscleSvgMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetPath != widget.assetPath ||
        oldWidget.selectedMuscleId != widget.selectedMuscleId ||
        oldWidget.lowOpacity != widget.lowOpacity ||
        oldWidget.highlightColor != widget.highlightColor) {
      _loadSvg();
    }
  }

  Future<void> _loadSvg() async {
    final key = _buildCacheKey(
      widget.assetPath,
      widget.selectedMuscleId,
      widget.lowOpacity,
      widget.highlightColor,
    );
    if (_cacheKey == key && _svgString != null) {
      return;
    }
    final cached = _cache[key];
    if (cached != null) {
      setState(() {
        _cacheKey = key;
        _svgString = cached;
      });
      return;
    }

    final raw = await rootBundle.loadString(widget.assetPath);
    final processed = _applyHighlights(
      raw,
      selectedId: widget.selectedMuscleId,
      lowOpacity: widget.lowOpacity,
      highlightColor: widget.highlightColor,
    );
    _cache[key] = processed;
    if (!mounted) {
      return;
    }
    setState(() {
      _cacheKey = key;
      _svgString = processed;
    });
  }

  String _applyHighlights(
    String raw, {
    required String? selectedId,
    required double lowOpacity,
    required Color highlightColor,
  }) {
    final document = XmlDocument.parse(raw);
    final opacityValue = lowOpacity.clamp(0.0, 1.0).toStringAsFixed(2);
    final highlightHex = _colorToHex(highlightColor);

    for (final node in document.findAllElements('path')) {
      final id = node.getAttribute('id');
      if (id == null) {
        continue;
      }

      if (selectedId != null && id == selectedId) {
        node.setAttribute('fill', highlightHex);
        node.setAttribute('fill-opacity', '1');
        node.setAttribute('opacity', '1');
      } else {
        node.setAttribute('fill-opacity', opacityValue);
        node.setAttribute('opacity', opacityValue);
      }
    }

    return document.toXmlString(pretty: false);
  }

  String _colorToHex(Color color) {
    final rgb = color.value.toRadixString(16).padLeft(8, '0').substring(2);
    return '#${rgb.toUpperCase()}';
  }

  String _buildCacheKey(
    String assetPath,
    String? selectedId,
    double lowOpacity,
    Color highlightColor,
  ) {
    return '${assetPath}_${selectedId ?? 'none'}_${lowOpacity.toStringAsFixed(2)}_${highlightColor.value}';
  }

  @override
  Widget build(BuildContext context) {
    final svg = _svgString;
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: widget.glowColor.withOpacity(0.25),
              blurRadius: widget.glowBlur,
              spreadRadius: widget.glowSpread,
            ),
          ],
        ),
        child: svg == null
            ? const SizedBox.shrink()
            : SvgPicture.string(
                svg,
                width: widget.width,
                height: widget.height,
                fit: widget.fit,
              ),
      ),
    );
  }
}
