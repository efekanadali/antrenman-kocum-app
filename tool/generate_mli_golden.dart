// tool/generate_mli_golden.dart
//
// MLI golden fixture'ını mevcut koddan (yeniden) üretir.
//
// Kullanım (proje kökünden):
//   C:\src\flutter\bin\dart.bat run tool/generate_mli_golden.dart
//
// DİKKAT: Fixture, hesaplama sonuçlarının değişmediğini doğrulayan güvenlik
// ağıdır. Yalnızca hesaplamadaki bir değişiklik bilinçli olarak onaylandıktan
// sonra yeniden üretilmelidir.

import 'dart:convert';
import 'dart:io';

import '../test/support/mli_golden_builder.dart';

void main() {
  final golden = buildMliGolden();
  final file = File(kMliGoldenFixturePath);
  file.parent.createSync(recursive: true);
  const encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync('${encoder.convert(golden)}\n');
  final cases = (golden['cases'] as List).length;
  stdout.writeln(
    'Wrote $kMliGoldenFixturePath '
    '(${golden['exerciseCount']} exercises, $cases cases).',
  );
}
