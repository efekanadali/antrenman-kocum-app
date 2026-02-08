// lib/presentation/providers/exercise_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- DEĞİŞİKLİK BURADA: Paket içi mutlak yollar kullanıldı ---
import 'package:calisthenics_app/data/repositories/exercise_repository.dart';
import 'package:calisthenics_app/data/repositories/fake_exercise_repository.dart';
// -------------------------------------------------------------

/// Bu provider, uygulamanın hangi ExerciseRepository implementasyonunu kullanacağını belirler.
///
/// Clean Architecture'da bu soyutlama, Data katmanını tamamen değiştirilebilir kılar.
/// Yarın bir API'ye veya veritabanına geçtiğimizde, uygulamanın geri kalanında
/// tek bir satır bile değiştirmeden sadece bu provider'ın içini güncellememiz yeterli olacaktır.
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  // Şu an için sahte (fake) repository'yi kullanıyoruz.
  return FakeExerciseRepository();
});
