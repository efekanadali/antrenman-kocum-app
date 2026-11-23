// lib/domain/services/push_pull_balance.dart
//
// İtiş / çekiş dengesi – 17 kompartıman üzerinden açık sınıflandırma.

import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';

/// Bir kompartımanın hareket örüntüsü.
enum MovementPattern { push, pull, neutral }

/// İtiş / çekiş sınıflandırması.
///
/// * İTİŞ (push): yük vücuttan uzağa itilir / eklem ekstansiyonu "iterek":
///   üst, orta ve alt göğüs; ön ve yan omuz; triseps; quadriceps
///   (diz ekstansiyonu); baldır (plantar fleksiyon).
/// * ÇEKİŞ (pull): yük vücuda doğru çekilir / arka zincir: lats, üst sırt /
///   trapez, bel, arka omuz, biseps, ön kol (kavrama), hamstring, kalça.
/// * NÖTR: karın (stabilizasyon; dengeye katılmaz).
MovementPattern movementPatternOf(MuscleCompartment compartment) {
  switch (compartment) {
    case MuscleCompartment.upperChest:
    case MuscleCompartment.midChest:
    case MuscleCompartment.lowerChest:
    case MuscleCompartment.anteriorDeltoid:
    case MuscleCompartment.lateralDeltoid:
    case MuscleCompartment.triceps:
    case MuscleCompartment.quads:
    case MuscleCompartment.calves:
      return MovementPattern.push;
    case MuscleCompartment.lats:
    case MuscleCompartment.upperBackTraps:
    case MuscleCompartment.lowerBack:
    case MuscleCompartment.posteriorDeltoid:
    case MuscleCompartment.biceps:
    case MuscleCompartment.forearms:
    case MuscleCompartment.hamstrings:
    case MuscleCompartment.glutes:
      return MovementPattern.pull;
    case MuscleCompartment.core:
      return MovementPattern.neutral;
  }
}

/// Biri diğerini bu oranda aşarsa denge bozuk sayılır.
const double kPushPullDominanceRatio = 1.15;

enum PushPullVerdict { balanced, pushDominant, pullDominant }

class PushPullBalance {
  const PushPullBalance({required this.push, required this.pull});

  final double push;
  final double pull;

  PushPullVerdict get verdict {
    if (push > pull * kPushPullDominanceRatio) {
      return PushPullVerdict.pushDominant;
    }
    if (pull > push * kPushPullDominanceRatio) {
      return PushPullVerdict.pullDominant;
    }
    return PushPullVerdict.balanced;
  }

  String get message {
    switch (verdict) {
      case PushPullVerdict.pushDominant:
        return 'Push muscles are dominant. Pull muscles are lacking.';
      case PushPullVerdict.pullDominant:
        return 'Pull muscles are dominant. Push muscles are lacking.';
      case PushPullVerdict.balanced:
        return 'Balanced training';
    }
  }

  /// Arayüzde gösterilen Türkçe karşılık ([message] İngilizce sözleşme olarak
  /// korunur).
  String get turkishMessage {
    switch (verdict) {
      case PushPullVerdict.pushDominant:
        return 'İtiş kasları baskın. Çekiş kasları geride kalıyor.';
      case PushPullVerdict.pullDominant:
        return 'Çekiş kasları baskın. İtiş kasları geride kalıyor.';
      case PushPullVerdict.balanced:
        return 'Dengeli antrenman';
    }
  }
}

/// Kompartıman yüklerinden itiş / çekiş toplamlarını hesaplar.
PushPullBalance computePushPullBalance(Map<MuscleCompartment, double> loads) {
  var push = 0.0;
  var pull = 0.0;
  loads.forEach((c, load) {
    switch (movementPatternOf(c)) {
      case MovementPattern.push:
        push += load;
      case MovementPattern.pull:
        pull += load;
      case MovementPattern.neutral:
        break;
    }
  });
  return PushPullBalance(push: push, pull: pull);
}
