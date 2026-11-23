// lib/presentation/widgets/ui/anatomical_muscle_map.dart

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

/// Hangi silüetlerin çizileceği.
enum AnatomyView { front, back }

/// Ön ve arka insan silüeti üzerinde 17 kas kompartımanını yoğunluğa göre
/// boyayan minimalist vektörel harita.
///
/// [intensities] kompartıman başına ham ağırlık/yük alır (ölçek fark etmez);
/// widget en yüksek değere göre 0–1 aralığına normalize eder. Yüksek yük
/// [activeColor] ile tam doygun ve hafif ışıltılı, ikincil yük aynı rengin
/// soluk tonuyla çizilir. Yük olmayan kaslar nötr yüzey tonunda kalır.
class AnatomicalMuscleMap extends StatelessWidget {
  const AnatomicalMuscleMap({
    super.key,
    required this.intensities,
    this.views = const [AnatomyView.front, AnatomyView.back],
    this.activeColor = AppColors.accent,
    this.height = 220,
    this.showCaptions = true,
    this.spacing = 8,
    this.normalize = true,
    this.onCompartmentTap,
  });

  final Map<MuscleCompartment, double> intensities;
  final List<AnatomyView> views;
  final Color activeColor;
  final double height;
  final bool showCaptions;
  final double spacing;

  /// `true`: değerler en yükseğe göre ölçeklenir (dağılım). `false`: değerler
  /// zaten 0–1 aralığında mutlak yoğunluktur (ör. yorgunluk).
  final bool normalize;

  /// Verilirse silüet üzerindeki bir kasa dokunulduğunda o kompartımanla
  /// çağrılır (ör. filtreleme). Kas dışı alanlara dokunuş yok sayılır.
  final ValueChanged<MuscleCompartment>? onCompartmentTap;

  /// Ham değerleri en yükseğe göre 0–1 aralığına çeker.
  static Map<MuscleCompartment, double> normalizeValues(
    Map<MuscleCompartment, double> raw,
  ) {
    var max = 0.0;
    for (final v in raw.values) {
      if (v > max) max = v;
    }
    if (max <= 0) return const {};
    return {
      for (final e in raw.entries)
        if (e.value > 0) e.key: (e.value / max).clamp(0.0, 1.0).toDouble(),
    };
  }

  /// Normalize yoğunluk için dolgu rengi (null = yük yok).
  static Color? fillFor(double t, Color active) {
    if (t <= 0) return null;
    if (t >= 0.6) return active;
    // İkincil yük: soluk ton, yoğunlukla birlikte artar.
    return active.withValues(alpha: 0.28 + t * 0.6);
  }

  @override
  Widget build(BuildContext context) {
    final normalized = normalize
        ? AnatomicalMuscleMap.normalizeValues(intensities)
        : {
            for (final e in intensities.entries)
              if (e.value > 0) e.key: e.value.clamp(0.0, 1.0).toDouble(),
          };
    final figureHeight = showCaptions ? height - 18 : height;
    return SizedBox(
      height: height,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (i, view) in views.indexed) ...[
            if (i > 0) SizedBox(width: spacing),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: figureHeight,
                  width: figureHeight * _kWidth / _kHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: onCompartmentTap == null
                        ? null
                        : (details) {
                            final hit = hitTestCompartment(
                              view,
                              details.localPosition / (figureHeight / _kHeight),
                            );
                            if (hit != null) onCompartmentTap!(hit);
                          },
                    child: CustomPaint(
                      painter: _AnatomyPainter(
                        view: view,
                        intensities: normalized,
                        activeColor: activeColor,
                      ),
                    ),
                  ),
                ),
                if (showCaptions) ...[
                  const SizedBox(height: 4),
                  Text(
                    view == AnatomyView.front ? 'ÖN' : 'ARKA',
                    style: AppText.sectionLabel.copyWith(fontSize: 9),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Geometri: 200 × 370 tasarım tuvali, gövde x = 100 ekseninde simetrik.
// Şekiller figürün sol yarısı için tanımlanır ve aynalanır.
// ---------------------------------------------------------------------------

const double _kWidth = 200;
const double _kHeight = 370;

typedef _Pts = List<Offset>;

class _Shape {
  const _Shape(this.points, [this.compartment]);
  final _Pts points;
  final MuscleCompartment? compartment;
}

const _Pts _neck = [
  Offset(92, 44),
  Offset(100, 46),
  Offset(100, 62),
  Offset(90, 60),
];

const _Pts _hand = [
  Offset(46, 174),
  Offset(53, 174),
  Offset(54, 188),
  Offset(48, 194),
  Offset(42, 186),
];

const _Pts _knee = [
  Offset(78, 264),
  Offset(92, 264),
  Offset(93, 280),
  Offset(80, 281),
];

const _Pts _foot = [
  Offset(80, 348),
  Offset(92, 348),
  Offset(95, 360),
  Offset(78, 361),
];

// Kollar ön ve arkada aynı yerde; ön görünümde biseps, arkada triseps.
const _Pts _upperArm = [
  Offset(59, 94),
  Offset(66, 100),
  Offset(66, 120),
  Offset(61, 132),
  Offset(53, 130),
  Offset(51, 112),
];

const _Pts _forearm = [
  Offset(52, 134),
  Offset(61, 136),
  Offset(58, 154),
  Offset(53, 172),
  Offset(46, 171),
  Offset(46, 152),
];

const _Pts _lateralDelt = [
  Offset(57, 70),
  Offset(62, 68),
  Offset(60, 90),
  Offset(53, 98),
  Offset(51, 84),
];

final List<_Shape> _frontShapes = [
  const _Shape(_neck),
  const _Shape([
    Offset(91, 56),
    Offset(91, 63),
    Offset(78, 64),
  ], MuscleCompartment.upperBackTraps),
  const _Shape([
    Offset(77, 63),
    Offset(86, 65),
    Offset(74, 76),
    Offset(66, 92),
    Offset(61, 90),
    Offset(63, 70),
  ], MuscleCompartment.anteriorDeltoid),
  const _Shape(_lateralDelt, MuscleCompartment.lateralDeltoid),
  const _Shape([
    Offset(89, 65),
    Offset(99, 65),
    Offset(99, 76),
    Offset(76, 77),
  ], MuscleCompartment.upperChest),
  const _Shape([
    Offset(75, 79),
    Offset(99, 78),
    Offset(99, 92),
    Offset(82, 94),
    Offset(72, 89),
  ], MuscleCompartment.midChest),
  const _Shape([
    Offset(76, 93),
    Offset(84, 96),
    Offset(99, 94),
    Offset(99, 103),
    Offset(84, 104),
  ], MuscleCompartment.lowerChest),
  const _Shape(_upperArm, MuscleCompartment.biceps),
  const _Shape(_forearm, MuscleCompartment.forearms),
  const _Shape(_hand),
  // Karın (rektus) üç sıra + oblik.
  const _Shape([
    Offset(87, 107),
    Offset(99, 107),
    Offset(99, 124),
    Offset(86, 124),
  ], MuscleCompartment.core),
  const _Shape([
    Offset(86, 126),
    Offset(99, 126),
    Offset(99, 143),
    Offset(86, 143),
  ], MuscleCompartment.core),
  const _Shape([
    Offset(86, 145),
    Offset(99, 145),
    Offset(99, 166),
    Offset(88, 160),
  ], MuscleCompartment.core),
  const _Shape([
    Offset(74, 104),
    Offset(84, 106),
    Offset(84, 154),
    Offset(77, 160),
    Offset(74, 132),
    Offset(70, 108),
  ], MuscleCompartment.core),
  // Kalça önü (nötr).
  const _Shape([
    Offset(76, 162),
    Offset(86, 162),
    Offset(99, 170),
    Offset(99, 184),
    Offset(78, 176),
  ]),
  const _Shape([
    Offset(76, 178),
    Offset(97, 188),
    Offset(96, 234),
    Offset(90, 262),
    Offset(78, 262),
    Offset(71, 236),
    Offset(71, 204),
  ], MuscleCompartment.quads),
  const _Shape(_knee),
  const _Shape([
    Offset(79, 284),
    Offset(92, 283),
    Offset(93, 312),
    Offset(89, 346),
    Offset(81, 346),
    Offset(76, 312),
  ], MuscleCompartment.calves),
  const _Shape(_foot),
];

final List<_Shape> _backShapes = [
  const _Shape(_neck),
  const _Shape([
    Offset(99, 48),
    Offset(99, 104),
    Offset(90, 82),
    Offset(78, 64),
    Offset(90, 58),
  ], MuscleCompartment.upperBackTraps),
  const _Shape([
    Offset(76, 63),
    Offset(86, 68),
    Offset(76, 80),
    Offset(66, 92),
    Offset(61, 90),
    Offset(63, 70),
  ], MuscleCompartment.posteriorDeltoid),
  const _Shape(_lateralDelt, MuscleCompartment.lateralDeltoid),
  const _Shape([
    Offset(88, 84),
    Offset(97, 108),
    Offset(97, 128),
    Offset(88, 140),
    Offset(78, 128),
    Offset(71, 104),
    Offset(77, 88),
  ], MuscleCompartment.lats),
  const _Shape([
    Offset(89, 142),
    Offset(99, 132),
    Offset(99, 166),
    Offset(86, 162),
  ], MuscleCompartment.lowerBack),
  const _Shape(_upperArm, MuscleCompartment.triceps),
  const _Shape(_forearm, MuscleCompartment.forearms),
  const _Shape(_hand),
  const _Shape([
    Offset(80, 150),
    Offset(85, 164),
    Offset(99, 169),
    Offset(99, 198),
    Offset(82, 198),
    Offset(74, 184),
    Offset(75, 162),
  ], MuscleCompartment.glutes),
  const _Shape([
    Offset(74, 200),
    Offset(97, 201),
    Offset(96, 236),
    Offset(90, 262),
    Offset(78, 262),
    Offset(71, 234),
  ], MuscleCompartment.hamstrings),
  const _Shape(_knee),
  const _Shape([
    Offset(78, 283),
    Offset(93, 283),
    Offset(95, 306),
    Offset(90, 334),
    Offset(81, 334),
    Offset(75, 306),
  ], MuscleCompartment.calves),
  const _Shape([
    Offset(81, 336),
    Offset(90, 336),
    Offset(89, 347),
    Offset(82, 347),
  ]),
  const _Shape(_foot),
];

/// Köşeleri yumuşatılmış kapalı çokgen (organik kas formu).
Path _polygon(_Pts pts, {required bool mirror}) {
  final p = [for (final o in pts) mirror ? Offset(_kWidth - o.dx, o.dy) : o];
  const r = 0.32;
  final n = p.length;
  final path = Path();
  for (var i = 0; i < n; i++) {
    final prev = p[(i - 1 + n) % n];
    final cur = p[i];
    final next = p[(i + 1) % n];
    final a = Offset.lerp(cur, prev, r)!;
    final b = Offset.lerp(cur, next, r)!;
    if (i == 0) {
      path.moveTo(a.dx, a.dy);
    } else {
      path.lineTo(a.dx, a.dy);
    }
    path.quadraticBezierTo(cur.dx, cur.dy, b.dx, b.dy);
  }
  return path..close();
}

/// Tasarım tuvali koordinatındaki ([_kWidth] × [_kHeight]) noktanın üzerine
/// düştüğü kompartıman; kas dışı alanlarda `null`.
@visibleForTesting
MuscleCompartment? hitTestCompartment(AnatomyView view, Offset designPoint) {
  final shapes = view == AnatomyView.front ? _frontShapes : _backShapes;
  // Kas aralarındaki ince boşluklara düşen dokunuşlar için küçük tolerans.
  const probes = [
    Offset.zero,
    Offset(5, 0),
    Offset(-5, 0),
    Offset(0, 5),
    Offset(0, -5),
  ];
  for (final d in probes) {
    final p = designPoint + d;
    for (final s in shapes.reversed) {
      final c = s.compartment;
      if (c == null) continue;
      for (final mirror in const [false, true]) {
        if (_polygon(s.points, mirror: mirror).contains(p)) return c;
      }
    }
  }
  return null;
}

class _AnatomyPainter extends CustomPainter {
  _AnatomyPainter({
    required this.view,
    required this.intensities,
    required this.activeColor,
  });

  final AnatomyView view;
  final Map<MuscleCompartment, double> intensities;
  final Color activeColor;

  static const Color _base = AppColors.anatomyMuscle;
  static const Color _neutral = AppColors.anatomyBase;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / _kHeight;
    canvas.save();
    canvas.translate((size.width - _kWidth * scale) / 2, 0);
    canvas.scale(scale);

    // Kas araları: arka plan renginde ince kontur (anatomik bölütleme).
    final gap = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.background;

    // Baş.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 26), width: 28, height: 36),
      Paint()..color = _neutral,
    );

    final shapes = view == AnatomyView.front ? _frontShapes : _backShapes;

    // 1) Işıltı (yalnızca yüksek yük).
    final glow = Paint()
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 7);
    for (final s in shapes) {
      final t = s.compartment == null ? 0.0 : (intensities[s.compartment] ?? 0);
      if (t < 0.6) continue;
      glow.color = activeColor.withValues(alpha: 0.45 * t);
      for (final mirror in const [false, true]) {
        canvas.drawPath(_polygon(s.points, mirror: mirror), glow);
      }
    }

    // 2) Dolgu + bölütleme.
    final fill = Paint()..isAntiAlias = true;
    for (final s in shapes) {
      final t = s.compartment == null ? 0.0 : (intensities[s.compartment] ?? 0);
      final active = AnatomicalMuscleMap.fillFor(t, activeColor);
      fill.color = s.compartment == null
          ? _neutral
          : active == null
          ? _base
          : Color.alphaBlend(active, _base);
      for (final mirror in const [false, true]) {
        final path = _polygon(s.points, mirror: mirror);
        canvas.drawPath(path, fill);
        canvas.drawPath(path, gap);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnatomyPainter old) =>
      old.view != view ||
      old.activeColor != activeColor ||
      !_mapEquals(old.intensities, intensities);

  static bool _mapEquals(
    Map<MuscleCompartment, double> a,
    Map<MuscleCompartment, double> b,
  ) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
