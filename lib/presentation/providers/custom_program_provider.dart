// lib/presentation/providers/custom_program_provider.dart

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';

const _storageKey = 'custom_programs';

final customProgramProvider =
    AsyncNotifierProvider<CustomProgramNotifier, List<CustomProgram>>(
  CustomProgramNotifier.new,
);

class CustomProgramNotifier extends AsyncNotifier<List<CustomProgram>> {
  @override
  Future<List<CustomProgram>> build() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey) ?? <String>[];
    return raw
        .map((item) =>
            CustomProgram.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .toList();
  }

  Future<void> addProgram(CustomProgram program) async {
    final current = state.value ?? <CustomProgram>[];
    final updated = [program, ...current];
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> removeProgram(String id) async {
    final current = state.value ?? <CustomProgram>[];
    final updated = current.where((item) => item.id != id).toList();
    state = AsyncData(updated);
    await _save(updated);
  }

  Future<void> _save(List<CustomProgram> programs) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = programs
        .map((item) => jsonEncode(item.toJson()))
        .toList(growable: false);
    await prefs.setStringList(_storageKey, raw);
  }
}
