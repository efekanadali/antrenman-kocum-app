// lib/presentation/providers/exercise_repository_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:calisthenics_app/data/repositories/exercise_repository.dart';
import 'package:calisthenics_app/data/repositories/firestore_exercise_repository.dart';

/// Bu provider, uygulamanın hangi ExerciseRepository implementasyonunu kullanacağını belirler.
///
/// Varsayılan olarak FirestoreExerciseRepository kullanılır.
/// Firestore üzerinden 'exercises' koleksiyonunu okur ve hata veya çevrimdışı durumda
/// güvenli bir şekilde FakeExerciseRepository içeriğine geri düşer.
final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return FirestoreExerciseRepository();
});
