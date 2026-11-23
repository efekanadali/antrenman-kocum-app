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
    this.activeColor,
    this.height = 220,
    this.showCaptions = true,
    this.spacing = 8,
    this.normalize = true,
    this.onCompartmentTap,
    this.coreZoneScale,
    this.onCoreZoneTap,
  });

  final Map<MuscleCompartment, double> intensities;
  final List<AnatomyView> views;
  final Color? activeColor;
  final double height;
  final bool showCaptions;
  final double spacing;

  /// `true`: değerler en yükseğe göre ölçeklenir (dağılım). `false`: değerler
  /// zaten 0–1 aralığında mutlak yoğunluktur (ör. yorgunluk).
  final bool normalize;

  /// Verilirse silüet üzerindeki bir kasa dokunulduğunda o kompartımanla
  /// çağrılır (ör. filtreleme). Kas dışı alanlara dokunuş yok sayılır.
  final ValueChanged<MuscleCompartment>? onCompartmentTap;

  /// Ön gövdedeki karın alt bölgelerinin (Karın / Oblik) yoğunluk çarpanı.
  /// `null` ise ikisi de `core` yoğunluğuyla boyanır. Ör. yalnızca oblik
  /// seçiliyken `{CoreZone.abs: 0.3}`.
  final Map<CoreZone, double>? coreZoneScale;

  /// Verilirse karın şekillerine dokunuş [onCompartmentTap] yerine bu
  /// geri çağrıya hangi alt bölgeye dokunulduğuyla gider.
  final ValueChanged<CoreZone>? onCoreZoneTap;

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
                    onTapUp: onCompartmentTap == null && onCoreZoneTap == null
                        ? null
                        : (details) {
                            final scale = figureHeight / _kHeight;
                            final width = figureHeight * _kWidth / _kHeight;
                            final hit = _hitTestShape(
                              view,
                              (details.localPosition -
                                      Offset(
                                        (width - _kWidth * scale) / 2,
                                        0,
                                      )) /
                                  scale,
                            );
                            if (hit == null) return;
                            final zone = hit.zone;
                            if (zone != null && onCoreZoneTap != null) {
                              onCoreZoneTap!(zone);
                            } else if (hit.compartment != null) {
                              onCompartmentTap?.call(hit.compartment!);
                            }
                          },
                    child: CustomPaint(
                      painter: _AnatomyPainter(
                        view: view,
                        intensities: normalized,
                        activeColor: activeColor ?? AppColors.activation,
                        coreZoneScale: coreZoneScale ?? const {},
                        gapColor: AppColors.surface,
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
// Şekiller figürün sol yarısı için tanımlanır ve aynalanır. Kaslar anatomik
// başlarına ayrılmıştır (ör. quadriceps 3 baş, hamstring 2 baş, karın 4 sıra);
// aynı kompartımana ait başlar birlikte boyanır, aralarındaki ince boşluk
// kontur olarak görünür.
// ---------------------------------------------------------------------------

const double _kWidth = 200;
const double _kHeight = 370;

typedef _Pts = List<Offset>;

/// Ön gövdede karın bölgesinin görsel alt bölgeleri. Biyomekanik modelde
/// ikisi de tek `MuscleCompartment.core` kompartımanıdır; ayrım yalnızca
/// harita ve filtre içindir.
enum CoreZone {
  abs('Karın'),
  obliques('Oblik');

  const CoreZone(this.label);

  /// Türkçe görünen ad.
  final String label;
}

class _Shape {
  const _Shape(this.points, [this.compartment, this.zone]);
  final _Pts points;
  final MuscleCompartment? compartment;
  final CoreZone? zone;
}

const _Pts _neck = [
  Offset(91, 42),
  Offset(100, 44),
  Offset(100, 61),
  Offset(89, 59),
];

const _Pts _hand = [
  Offset(46, 175),
  Offset(53, 175),
  Offset(55, 188),
  Offset(49, 195),
  Offset(42, 187),
];

const _Pts _knee = [
  Offset(77, 264),
  Offset(92, 264),
  Offset(93, 281),
  Offset(79, 282),
];

const _Pts _foot = [
  Offset(79, 349),
  Offset(91, 349),
  Offset(95, 361),
  Offset(77, 362),
];

const _Pts _lateralDelt = [
  Offset(58, 71),
  Offset(62, 67),
  Offset(61, 88),
  Offset(56, 98),
  Offset(51, 90),
  Offset(52, 80),
];

// Ön kol: brachioradialis (üst-dış) ve fleksör/ekstansör grubu.
const _Pts _forearmTop = [
  Offset(53, 133),
  Offset(61, 134),
  Offset(59, 145),
  Offset(53, 157),
  Offset(48, 150),
];

const _Pts _forearmBottom = [
  Offset(49, 155),
  Offset(57, 148),
  Offset(58, 155),
  Offset(54, 172),
  Offset(46, 172),
  Offset(46, 162),
];

final List<_Shape> _frontShapes = [
  const _Shape(_neck),
  const _Shape([
    Offset(90, 53),
    Offset(91, 62),
    Offset(76, 64),
  ], MuscleCompartment.upperBackTraps),
  const _Shape([
    Offset(76, 64),
    Offset(86, 66),
    Offset(79, 73),
    Offset(71, 83),
    Offset(65, 92),
    Offset(61, 89),
    Offset(62, 74),
    Offset(68, 66),
  ], MuscleCompartment.anteriorDeltoid),
  const _Shape(_lateralDelt, MuscleCompartment.lateralDeltoid),
  // Göğüs: klaviküler / sternal / abdominal baş.
  const _Shape([
    Offset(88, 66),
    Offset(99, 66),
    Offset(99, 76),
    Offset(80, 78),
    Offset(75, 76),
    Offset(81, 70),
  ], MuscleCompartment.upperChest),
  const _Shape([
    Offset(74, 79),
    Offset(99, 79),
    Offset(99, 91),
    Offset(86, 94),
    Offset(74, 90),
    Offset(71, 85),
  ], MuscleCompartment.midChest),
  const _Shape([
    Offset(75, 93),
    Offset(86, 97),
    Offset(99, 94),
    Offset(99, 103),
    Offset(86, 105),
    Offset(78, 101),
  ], MuscleCompartment.lowerChest),
  // Serratus dişleri (nötr).
  const _Shape([
    Offset(70, 97),
    Offset(75, 100),
    Offset(75, 104),
    Offset(69, 103),
  ]),
  const _Shape([
    Offset(69, 106),
    Offset(75, 107),
    Offset(75, 111),
    Offset(69, 111),
  ]),
  const _Shape([
    Offset(70, 114),
    Offset(75, 115),
    Offset(75, 119),
    Offset(71, 119),
  ]),
  // Biseps (uzun + kısa baş) ve ön kol.
  const _Shape([
    Offset(59, 94),
    Offset(65, 99),
    Offset(66, 116),
    Offset(62, 130),
    Offset(58, 130),
    Offset(58, 108),
  ], MuscleCompartment.biceps),
  const _Shape([
    Offset(57, 97),
    Offset(57, 110),
    Offset(57, 130),
    Offset(53, 130),
    Offset(51, 114),
    Offset(53, 101),
  ], MuscleCompartment.biceps),
  const _Shape(_forearmTop, MuscleCompartment.forearms),
  const _Shape(_forearmBottom, MuscleCompartment.forearms),
  const _Shape(_hand),
  // Karın (rectus abdominis): 3 sıra "six-pack" + alt karın.
  const _Shape(
    [Offset(88, 107), Offset(98.6, 107), Offset(98.6, 119), Offset(87, 120)],
    MuscleCompartment.core,
    CoreZone.abs,
  ),
  const _Shape(
    [Offset(87, 122), Offset(98.6, 122), Offset(98.6, 134), Offset(87, 135)],
    MuscleCompartment.core,
    CoreZone.abs,
  ),
  const _Shape(
    [Offset(87, 137), Offset(98.6, 137), Offset(98.6, 149), Offset(87, 150)],
    MuscleCompartment.core,
    CoreZone.abs,
  ),
  const _Shape(
    [Offset(87, 152), Offset(98.6, 152), Offset(98.6, 171), Offset(92, 166)],
    MuscleCompartment.core,
    CoreZone.abs,
  ),
  // Oblikler (dış yan karın).
  const _Shape(
    [
      Offset(78, 106),
      Offset(85, 108),
      Offset(85, 153),
      Offset(81, 163),
      Offset(75, 159),
      Offset(74, 139),
      Offset(76, 123),
    ],
    MuscleCompartment.core,
    CoreZone.obliques,
  ),
  // Kasık (nötr).
  const _Shape([
    Offset(75, 164),
    Offset(84, 165),
    Offset(98, 174),
    Offset(98, 186),
    Offset(79, 178),
  ]),
  // Quadriceps: vastus lateralis / rectus femoris / vastus medialis.
  const _Shape([
    Offset(74, 181),
    Offset(80, 185),
    Offset(82, 214),
    Offset(81, 248),
    Offset(78, 259),
    Offset(72, 238),
    Offset(71, 206),
  ], MuscleCompartment.quads),
  const _Shape([
    Offset(83, 186),
    Offset(92, 191),
    Offset(93, 214),
    Offset(89, 243),
    Offset(85, 245),
    Offset(84, 214),
  ], MuscleCompartment.quads),
  const _Shape([
    Offset(94, 212),
    Offset(97, 214),
    Offset(97, 238),
    Offset(92, 262),
    Offset(84, 262),
    Offset(86, 250),
    Offset(91, 244),
  ], MuscleCompartment.quads),
  // Adduktör (nötr).
  const _Shape([
    Offset(94, 190),
    Offset(98, 192),
    Offset(98, 209),
    Offset(95, 207),
  ]),
  const _Shape(_knee),
  // Baldır (dış ve iç gastroknemius) + tibialis (nötr).
  const _Shape([
    Offset(77, 286),
    Offset(82, 286),
    Offset(81, 312),
    Offset(78, 322),
    Offset(75, 304),
  ], MuscleCompartment.calves),
  const _Shape([
    Offset(83, 287),
    Offset(86, 288),
    Offset(87, 318),
    Offset(86, 345),
    Offset(81, 345),
    Offset(81, 318),
  ]),
  const _Shape([
    Offset(88, 286),
    Offset(93, 285),
    Offset(94, 309),
    Offset(90, 330),
    Offset(88, 314),
  ], MuscleCompartment.calves),
  const _Shape(_foot),
];

final List<_Shape> _backShapes = [
  const _Shape(_neck),
  // Trapez: üst ve orta-alt (elmas).
  const _Shape([
    Offset(99, 45),
    Offset(99, 67),
    Offset(78, 66),
    Offset(90, 58),
    Offset(92, 47),
  ], MuscleCompartment.upperBackTraps),
  const _Shape([
    Offset(99, 69),
    Offset(87, 71),
    Offset(85, 85),
    Offset(99, 107),
  ], MuscleCompartment.upperBackTraps),
  const _Shape([
    Offset(76, 66),
    Offset(85, 69),
    Offset(79, 77),
    Offset(68, 90),
    Offset(61, 90),
    Offset(63, 73),
  ], MuscleCompartment.posteriorDeltoid),
  const _Shape(_lateralDelt, MuscleCompartment.lateralDeltoid),
  // Infraspinatus / teres (üst sırt).
  const _Shape([
    Offset(84, 73),
    Offset(84, 86),
    Offset(77, 96),
    Offset(70, 93),
    Offset(73, 81),
  ], MuscleCompartment.upperBackTraps),
  const _Shape([
    Offset(85, 89),
    Offset(97, 111),
    Offset(97, 127),
    Offset(90, 141),
    Offset(80, 130),
    Offset(72, 108),
    Offset(77, 98),
  ], MuscleCompartment.lats),
  // Erector spinae.
  const _Shape([
    Offset(91, 131),
    Offset(98.6, 121),
    Offset(98.6, 166),
    Offset(88, 162),
    Offset(88, 145),
  ], MuscleCompartment.lowerBack),
  // Triseps: uzun + lateral baş.
  const _Shape([
    Offset(58, 95),
    Offset(65, 100),
    Offset(65, 122),
    Offset(60, 128),
    Offset(57, 112),
  ], MuscleCompartment.triceps),
  const _Shape([
    Offset(52, 96),
    Offset(56, 97),
    Offset(55, 112),
    Offset(58, 129),
    Offset(53, 130),
    Offset(51, 113),
  ], MuscleCompartment.triceps),
  const _Shape(_forearmTop, MuscleCompartment.forearms),
  const _Shape(_forearmBottom, MuscleCompartment.forearms),
  const _Shape(_hand),
  // Kalça: gluteus medius + maximus.
  const _Shape([
    Offset(76, 151),
    Offset(86, 160),
    Offset(84, 168),
    Offset(74, 175),
    Offset(73, 160),
  ], MuscleCompartment.glutes),
  const _Shape([
    Offset(85, 168),
    Offset(99, 170),
    Offset(99, 198),
    Offset(82, 198),
    Offset(75, 186),
    Offset(77, 176),
  ], MuscleCompartment.glutes),
  // Hamstring: biceps femoris + semitendinosus.
  const _Shape([
    Offset(74, 202),
    Offset(85, 202),
    Offset(86, 236),
    Offset(84, 258),
    Offset(78, 260),
    Offset(71, 232),
  ], MuscleCompartment.hamstrings),
  const _Shape([
    Offset(87, 202),
    Offset(97, 202),
    Offset(96, 236),
    Offset(91, 260),
    Offset(86, 258),
    Offset(88, 236),
  ], MuscleCompartment.hamstrings),
  const _Shape(_knee),
  // Baldır: lateral + medial gastroknemius.
  const _Shape([
    Offset(78, 285),
    Offset(85, 285),
    Offset(85, 316),
    Offset(81, 327),
    Offset(75, 305),
  ], MuscleCompartment.calves),
  const _Shape([
    Offset(87, 285),
    Offset(93, 285),
    Offset(95, 305),
    Offset(91, 327),
    Offset(87, 316),
  ], MuscleCompartment.calves),
  // Aşil (nötr).
  const _Shape([
    Offset(81, 331),
    Offset(90, 331),
    Offset(89, 347),
    Offset(82, 347),
  ]),
  const _Shape(_foot),
];

/// Köşeleri yumuşatılmış kapalı çokgen (organik kas formu).
Path _polygon(_Pts pts, {required bool mirror}) {
  final p = [for (final o in pts) mirror ? Offset(_kWidth - o.dx, o.dy) : o];
  const r = 0.26;
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
MuscleCompartment? hitTestCompartment(AnatomyView view, Offset designPoint) =>
    _hitTestShape(view, designPoint)?.compartment;

/// Noktanın düştüğü karın alt bölgesi (yalnızca ön görünümde karın
/// şekilleri için); diğer durumlarda `null`.
@visibleForTesting
CoreZone? hitTestCoreZone(AnatomyView view, Offset designPoint) =>
    _hitTestShape(view, designPoint)?.zone;

_Shape? _hitTestShape(AnatomyView view, Offset designPoint) {
  final shapes = view == AnatomyView.front ? _frontShapes : _backShapes;
  // Kas aralarındaki ince boşluklara düşen dokunuşlar için küçük tolerans.
  const probes = [
    Offset.zero,
    Offset(3, 0),
    Offset(-3, 0),
    Offset(0, 3),
    Offset(0, -3),
    Offset(6, 0),
    Offset(-6, 0),
  ];
  for (final d in probes) {
    final p = designPoint + d;
    for (final s in shapes.reversed) {
      if (s.compartment == null) continue;
      for (final mirror in const [false, true]) {
        if (_polygon(s.points, mirror: mirror).contains(p)) return s;
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
    required this.coreZoneScale,
    required this.gapColor,
  });

  final AnatomyView view;
  final Map<MuscleCompartment, double> intensities;
  final Color activeColor;
  final Map<CoreZone, double> coreZoneScale;
  final Color gapColor;

  double _intensityOf(_Shape s) {
    final c = s.compartment;
    if (c == null) return 0;
    final t = intensities[c] ?? 0;
    final zone = s.zone;
    if (zone == null) return t;
    return (t * (coreZoneScale[zone] ?? 1)).clamp(0.0, 1.0).toDouble();
  }

  static Color get _base => AppColors.anatomyMuscle;
  static Color get _neutral => AppColors.anatomyBase;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / _kHeight;
    canvas.save();
    canvas.translate((size.width - _kWidth * scale) / 2, 0);
    canvas.scale(scale);

    // Kas araları: kartın yüzey renginde keskin kontur (anatomik bölütleme).
    final gap = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeJoin = StrokeJoin.round
      ..color = gapColor;
    // Aktif kasın kendi kenarı: biraz koyulaştırılmış vurgu tonu.
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7
      ..strokeJoin = StrokeJoin.round
      ..color = Color.lerp(activeColor, Colors.black, 0.28)!;

    // Baş.
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(100, 26), width: 28, height: 36),
      Paint()..color = _neutral,
    );

    final shapes = view == AnatomyView.front ? _frontShapes : _backShapes;

    // 1) Işıltı (yalnızca yüksek yük).
    final glow = Paint()
      ..maskFilter = const ui.MaskFilter.blur(BlurStyle.normal, 6);
    for (final s in shapes) {
      final t = _intensityOf(s);
      if (t < 0.6) continue;
      glow.color = activeColor.withValues(alpha: 0.35 * t);
      for (final mirror in const [false, true]) {
        canvas.drawPath(_polygon(s.points, mirror: mirror), glow);
      }
    }

    // 2) Dolgu + bölütleme + aktif kontur.
    final fill = Paint()..isAntiAlias = true;
    for (final s in shapes) {
      final t = _intensityOf(s);
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
        if (t >= 0.6) canvas.drawPath(path, edge);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnatomyPainter old) =>
      old.view != view ||
      old.activeColor != activeColor ||
      old.gapColor != gapColor ||
      !_mapEquals(old.intensities, intensities) ||
      !_zoneEquals(old.coreZoneScale, coreZoneScale);

  static bool _zoneEquals(Map<CoreZone, double> a, Map<CoreZone, double> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }

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
