// tool/generate_mli_golden.dart
//
// 17 kompartımanlı modelin golden fixture'ını (v2) mevcut koddan (yeniden)
// üretir. v1 (test/fixtures/mli_golden_v1.json) göç öncesi modelin
// dondurulmuş tarihsel referansıdır; bu araç onu DEĞİŞTİRMEZ.
//
// Kullanım (proje kökünden):
//   C:\src\flutter\bin\dart.bat run tool/generate_mli_golden.dart
//
// DİKKAT: Fixture, hesaplama sonuçlarının değişmediğini doğrulayan güvenlik
// ağıdır. Yalnızca hesaplamadaki bir değişiklik bilinçli olarak onaylandıktan
// sonra yeniden üretilmelidir.

import 'dart:convert';
import 'dart:io';

import '../test/support/mli_golden_v2_builder.dart';

void main() {
  final golden = buildMliGoldenV2();
  final file = File(kMliGoldenV2FixturePath);
  file.parent.createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(golden)}\n');
  final cases = (golden['cases'] as List).length;
  stdout.writeln(
    'Wrote $kMliGoldenV2FixturePath '
    '(${golden['exerciseCount']} exercises, $cases cases).',
  );
}
