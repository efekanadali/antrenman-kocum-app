// test/widgets/muscle_recovery_card_test.dart

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/models/mli_models.dart';
import 'package:calisthenics_app/domain/models/muscle_recovery_state.dart';
import 'package:calisthenics_app/domain/services/mli_calculator.dart';
import 'package:calisthenics_app/domain/services/recovery_calculator.dart';
import 'package:calisthenics_app/presentation/providers/muscle_recovery_provider.dart';
import 'package:calisthenics_app/presentation/widgets/muscle_recovery_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, MuscleRecoveryState state) async {
  tester.view.physicalSize = const Size(1200, 4000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        muscleRecoveryProvider.overrideWith((ref) => Stream.value(state)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: MuscleRecoveryCard()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('shows 6 regions and expands to compartments', (tester) async {
    await _pump(tester, const MuscleRecoveryState());
    for (final region in MuscleRegion.values) {
      expect(find.text(region.label), findsWidgets);
    }
    expect(find.text('Hazır'), findsNWidgets(6));

    // Hiçbiri açık değilken kompartıman satırı yok.
    expect(find.byKey(const ValueKey('recovery-compartment-lats')), findsNothing);

    // Tüm bölgeleri aç → 17 kompartıman satırı erişilebilir.
    for (final region in MuscleRegion.values) {
      await tester.tap(find.byKey(ValueKey('recovery-region-${region.name}')));
      await tester.pump();
    }
    for (final c in MuscleCompartment.values) {
      expect(
        find.byKey(ValueKey('recovery-compartment-${c.firestoreKey}')),
        findsOneWidget,
        reason: c.name,
      );
    }
  });

  testWidgets('HSPU session: shoulders region is recovering', (tester) async {
    final now = DateTime.now();
    final hspu = exerciseDatabase['handstand_push_up']!;
    const set = WorkoutSet(reps: 8, rir: 1);
    final records = buildCompartmentRecovery(
      compartmentLoad: calculateCompartmentLoad(exercise: hspu, set: set),
      compartmentRir: const {},
      completedAt: now,
    );
    await _pump(tester, MuscleRecoveryState(compartments: records));

    // Omuz, kol (triseps), sırt (trapez) ve karın (%10 ≥ %25 × %35)
    // toparlanıyor; göğüs (%5 < eşik) ve bacak hazır.
    expect(find.text('Hazır'), findsNWidgets(2));
    expect(find.textContaining('Toparlanıyor'), findsNWidgets(4));

    await tester.tap(find.byKey(const ValueKey('recovery-region-shoulders')));
    await tester.pump();
    expect(find.text('Ön Omuz'), findsOneWidget);
    expect(find.text('Yan Omuz'), findsOneWidget);
    expect(find.text('Arka Omuz'), findsOneWidget);
  });
}
