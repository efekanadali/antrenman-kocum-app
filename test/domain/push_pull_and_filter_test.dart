// test/domain/push_pull_and_filter_test.dart

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/domain/models/exercise_database.dart';
import 'package:calisthenics_app/domain/services/muscle_filter.dart';
import 'package:calisthenics_app/domain/services/push_pull_balance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('push / pull classification', () {
    test('explicit table', () {
      const push = {
        MuscleCompartment.upperChest,
        MuscleCompartment.midChest,
        MuscleCompartment.lowerChest,
        MuscleCompartment.anteriorDeltoid,
        MuscleCompartment.lateralDeltoid,
        MuscleCompartment.triceps,
        MuscleCompartment.quads,
        MuscleCompartment.calves,
      };
      const pull = {
        MuscleCompartment.lats,
        MuscleCompartment.upperBackTraps,
        MuscleCompartment.lowerBack,
        MuscleCompartment.posteriorDeltoid,
        MuscleCompartment.biceps,
        MuscleCompartment.forearms,
        MuscleCompartment.hamstrings,
        MuscleCompartment.glutes,
      };
      for (final c in MuscleCompartment.values) {
        final expected = push.contains(c)
            ? MovementPattern.push
            : pull.contains(c)
                ? MovementPattern.pull
                : MovementPattern.neutral;
        expect(movementPatternOf(c), expected, reason: c.name);
      }
      expect(movementPatternOf(MuscleCompartment.core), MovementPattern.neutral);
    });

    test('arm and leg compartments count again', () {
      final balance = computePushPullBalance(const {
        MuscleCompartment.triceps: 10,
        MuscleCompartment.quads: 10,
        MuscleCompartment.biceps: 10,
        MuscleCompartment.hamstrings: 5,
        MuscleCompartment.glutes: 5,
        MuscleCompartment.core: 100,
      });
      expect(balance.push, 20);
      expect(balance.pull, 20);
      expect(balance.verdict, PushPullVerdict.balanced);
      expect(balance.message, 'Balanced training');
    });

    test('dominance uses the 1.15 ratio', () {
      expect(
        computePushPullBalance(const {
          MuscleCompartment.midChest: 12,
          MuscleCompartment.lats: 10,
        }).verdict,
        PushPullVerdict.pushDominant,
      );
      expect(
        computePushPullBalance(const {
          MuscleCompartment.midChest: 11,
          MuscleCompartment.lats: 10,
        }).verdict,
        PushPullVerdict.balanced,
      );
      expect(
        computePushPullBalance(const {
          MuscleCompartment.biceps: 12,
          MuscleCompartment.triceps: 10,
        }).message,
        'Pull muscles are dominant. Push muscles are lacking.',
      );
    });
  });

  group('muscle filter', () {
    final pushUp = exerciseDatabase['standard_push_up']!.compartments;
    final pullUp = exerciseDatabase['standard_pull_up']!.compartments;

    test('region and compartment targeting with 0.10 minimum', () {
      expect(targetsRegion(pushUp, MuscleRegion.chest), isTrue);
      expect(targetsRegion(pushUp, MuscleRegion.legs), isFalse);
      expect(targetsCompartment(pushUp, MuscleCompartment.midChest), isTrue);
      expect(targetsCompartment(pushUp, MuscleCompartment.lowerChest), isTrue);
      expect(targetsCompartment(pullUp, MuscleCompartment.forearms), isFalse);
      expect(targetRegions(pushUp).first, MuscleRegion.chest);
    });

    test('matchAll vs any', () {
      expect(
        matchesMuscleFilter(pushUp,
            regions: {MuscleRegion.chest, MuscleRegion.back}),
        isFalse,
      );
      expect(
        matchesMuscleFilter(pushUp,
            regions: {MuscleRegion.chest, MuscleRegion.back}, matchAll: false),
        isTrue,
      );
      expect(
        matchesMuscleFilter(pullUp,
            compartments: {MuscleCompartment.lats}),
        isTrue,
      );
      expect(matchesMuscleFilter(pushUp), isTrue);
    });

    test('every compartment is reachable by at least one exercise', () {
      for (final c in MuscleCompartment.values) {
        final hit = exerciseDatabase.values
            .any((e) => targetsCompartment(e.compartments, c));
        expect(hit, isTrue, reason: c.name);
      }
    });
  });

  group('loadKg input helpers', () {
    test('parseLoadKgInput', () {
      expect(parseLoadKgInput('60'), 60.0);
      expect(parseLoadKgInput('62,5'), 62.5);
      expect(parseLoadKgInput(' 40 kg '), 40.0);
      expect(parseLoadKgInput(''), isNull);
      expect(parseLoadKgInput('abc'), isNull);
      expect(parseLoadKgInput('0'), isNull);
    });

    test('formatLoadKgSuffix', () {
      expect(formatLoadKgSuffix(null), '');
      expect(formatLoadKgSuffix(60), ' • 60 kg');
      expect(formatLoadKgSuffix(62.5), ' • 62.5 kg');
    });
  });
}
