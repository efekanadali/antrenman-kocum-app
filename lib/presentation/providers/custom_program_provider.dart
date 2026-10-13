// lib/presentation/providers/custom_program_provider.dart

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calisthenics_app/data/services/auth_service.dart';
import 'package:calisthenics_app/data/services/firestore_service.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';

const _storageKey = 'custom_programs';
const _deletedKey = 'custom_programs_pending_deletes';

final customProgramProvider =
    AsyncNotifierProvider<CustomProgramNotifier, List<CustomProgram>>(
  CustomProgramNotifier.new,
);

/// Özel programları yerelde (SharedPreferences, offline-first) tutar ve
/// `users/{uid}/custom_programs` altında Firestore ile senkronize eder.
class CustomProgramNotifier extends AsyncNotifier<List<CustomProgram>> {
  @override
  Future<List<CustomProgram>> build() async {
    // Hesap (uid) değişirse (ör. Google ile giriş) yeniden senkronize et.
    ref.watch(authUserProvider.select((user) => user.valueOrNull?.uid));

    final local = await _loadLocal();
    // Açılışı bekletmeden arka planda bulutla eşitle.
    Future.microtask(_syncWithCloud);
    return local;
  }

  Future<void> addProgram(CustomProgram program) async {
    final current = state.value ?? <CustomProgram>[];
    final updated = [program, ...current];
    state = AsyncData(updated);
    await _saveLocal(updated);
    await _pushToCloud(program);
  }

  Future<void> removeProgram(String id) async {
    final current = state.value ?? <CustomProgram>[];
    final updated = current.where((item) => item.id != id).toList();
    state = AsyncData(updated);
    await _saveLocal(updated);

    try {
      await ref.read(firestoreServiceProvider).deleteCustomProgram(id);
    } catch (_) {
      // Çevrimdışı: bir sonraki senkronizasyonda silinecek.
      await _addPendingDelete(id);
    }
  }

  /// Yerel ve bulut programlarını birleştirir:
  ///  * Bekleyen silmeler buluta uygulanır.
  ///  * Yalnızca bulutta olanlar yerele eklenir.
  ///  * Yalnızca yerelde olanlar buluta yüklenir.
  Future<void> _syncWithCloud() async {
    try {
      final service = ref.read(firestoreServiceProvider);

      final pendingDeletes = await _loadPendingDeletes();
      for (final id in pendingDeletes.toList()) {
        await service.deleteCustomProgram(id);
        pendingDeletes.remove(id);
      }
      await _savePendingDeletes(pendingDeletes);

      final cloud = await service.fetchCustomPrograms();
      final local = state.value ?? await _loadLocal();

      final localIds = local.map((p) => p.id).toSet();
      final cloudIds = cloud.map((p) => p.id).toSet();

      final merged = [
        ...local,
        ...cloud.where((p) => !localIds.contains(p.id)),
      ]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

      for (final program in local) {
        if (!cloudIds.contains(program.id)) {
          await service.upsertCustomProgram(program);
        }
      }

      if (merged.length != local.length) {
        state = AsyncData(merged);
        await _saveLocal(merged);
      }
    } catch (_) {
      // Ağ/Firestore hatası: yerel veriyle devam edilir.
    }
  }

  Future<void> _pushToCloud(CustomProgram program) async {
    try {
      await ref.read(firestoreServiceProvider).upsertCustomProgram(program);
    } catch (_) {
      // Yüklenemeyen program bir sonraki _syncWithCloud'da gönderilir.
    }
  }

  Future<List<CustomProgram>> _loadLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? <String>[];
    return raw
        .map((item) =>
            CustomProgram.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveLocal(List<CustomProgram> programs) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = programs
        .map((item) => jsonEncode(item.toJson()))
        .toList(growable: false);
    await prefs.setStringList(_storageKey, raw);
  }

  Future<Set<String>> _loadPendingDeletes() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_deletedKey) ?? <String>[]).toSet();
  }

  Future<void> _savePendingDeletes(Set<String> ids) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_deletedKey, ids.toList());
  }

  Future<void> _addPendingDelete(String id) async {
    final ids = await _loadPendingDeletes()
      ..add(id);
    await _savePendingDeletes(ids);
  }
}
