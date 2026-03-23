import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:calisthenics_app/core/local_storage/workout_summary_storage.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(showBottomNav: showBottomNav);
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _bgTop = Color(0xFF151028);
  static const Color _bgBottom = Color(0xFF0E0A1D);
  static const Color _cardSurface = Color(0xFF201836);
  static const Color _cardSurfaceSoft = Color(0xFF2A2048);
  static const Color _accentPurple = Color(0xFF6D5BFF);
  static const Color _accentBlue = Color(0xFF4FC3F7);
  static const Color _textHigh = Color(0xFFEDE9FF);
  static const Color _textMid = Color(0xFFB4A9D8);

  static const String _heightKey = 'profile_height_cm';
  static const String _weightKey = 'profile_weight_kg';
  static const String _goalWeightKey = 'profile_goal_weight_kg';
  static const String _targetWorkoutsKey = 'profile_target_workouts_weekly';
  static const String _genderKey = 'profile_gender';
  static const String _birthDateKey = 'profile_birth_date';
  static const String _personalRecordsKey = 'profile_personal_records_v1';

  static const List<String> _recordExerciseOptions = [
    'Pull-up',
    'Push-up',
    'Dip',
    'Muscle-up',
    'Pistol Squat',
    'Handstand Push-up',
    'L-sit Hold',
    'Front Lever Hold',
  ];

  late final Future<List<WorkoutSummaryEntry>> _summaryFuture;
  double _heightCm = 175.0;
  double _weightKg = 70.0;
  double _goalWeightKg = 68.0;
  int _targetWorkoutsPerWeek = 4;
  String _gender = 'Belirtilmedi';
  DateTime? _birthDate;
  List<PersonalRecordEntry> _personalRecords = const [];

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummaries();
    _loadBodyMetrics();
  }

  Future<List<WorkoutSummaryEntry>> _loadSummaries() async {
    final storage = WorkoutSummaryStorage();
    final summaries = await storage.loadSummaries();
    if (summaries.isNotEmpty) {
      return summaries;
    }
    return buildMockWorkoutSummaries();
  }

  Future<void> _loadBodyMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    final savedHeight = prefs.getDouble(_heightKey);
    final savedWeight = prefs.getDouble(_weightKey);
    final savedGoalWeight = prefs.getDouble(_goalWeightKey);
    final savedTargetWorkouts = prefs.getInt(_targetWorkoutsKey);
    final savedGender = prefs.getString(_genderKey);
    final savedBirthDateIso = prefs.getString(_birthDateKey);
    final parsedBirthDate = savedBirthDateIso != null
        ? DateTime.tryParse(savedBirthDateIso)
        : null;

    if (!mounted) {
      return;
    }

    setState(() {
      _heightCm = savedHeight ?? _heightCm;
      _weightKg = savedWeight ?? _weightKg;
      _goalWeightKg = savedGoalWeight ?? _goalWeightKg;
      _targetWorkoutsPerWeek = savedTargetWorkouts ?? _targetWorkoutsPerWeek;
      _gender = savedGender ?? _gender;
      _birthDate = parsedBirthDate ?? _birthDate;
      _personalRecords = _decodePersonalRecords(
        prefs.getString(_personalRecordsKey),
      );
    });
  }

  Future<void> _saveBodyMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_heightKey, _heightCm);
    await prefs.setDouble(_weightKey, _weightKg);
    await prefs.setDouble(_goalWeightKey, _goalWeightKg);
    await prefs.setInt(_targetWorkoutsKey, _targetWorkoutsPerWeek);
    await prefs.setString(_genderKey, _gender);
    if (_birthDate != null) {
      await prefs.setString(_birthDateKey, _birthDate!.toIso8601String());
    } else {
      await prefs.remove(_birthDateKey);
    }
  }

  Future<void> _savePersonalRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _personalRecords.map((item) => item.toJson()).toList(),
    );
    await prefs.setString(_personalRecordsKey, encoded);
  }

  Future<void> _showAddPersonalRecordDialog() async {
    final repsController = TextEditingController();
    final extraWeightController = TextEditingController();

    String selectedExercise = _recordExerciseOptions.first;
    bool hasExtraWeight = false;
    String? errorText;

    final result = await showDialog<PersonalRecordEntry>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 24.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: _cardSurface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(22.0),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kisisel Rekor Ekle',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: _textHigh,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12.0),
                        DropdownButtonFormField<String>(
                          value: selectedExercise,
                          dropdownColor: _cardSurfaceSoft,
                          decoration: _dialogInputDecoration(
                            label: 'Hareket',
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _textHigh,
                              ),
                          items: _recordExerciseOptions
                              .map(
                                (exercise) => DropdownMenuItem<String>(
                                  value: exercise,
                                  child: Text(exercise),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) {
                              return;
                            }
                            setDialogState(() {
                              selectedExercise = value;
                            });
                          },
                        ),
                        const SizedBox(height: 10.0),
                        TextField(
                          controller: repsController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _textHigh,
                              ),
                          decoration: _dialogInputDecoration(
                            label: 'Rekor (tekrar/sure sayisi)',
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        SwitchListTile.adaptive(
                          value: hasExtraWeight,
                          activeColor: _accentBlue,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Ekstra agirlik var',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _textHigh,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          onChanged: (value) {
                            setDialogState(() {
                              hasExtraWeight = value;
                              if (!hasExtraWeight) {
                                extraWeightController.clear();
                              }
                            });
                          },
                        ),
                        if (hasExtraWeight) ...[
                          TextField(
                            controller: extraWeightController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: _textHigh),
                            decoration: _dialogInputDecoration(
                              label: 'Ekstra agirlik (kg)',
                            ),
                          ),
                        ],
                        if (errorText != null) ...[
                          const SizedBox(height: 8.0),
                          Text(
                            errorText!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: const Color(0xFFFF8E8E),
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                        const SizedBox(height: 12.0),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _textMid,
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.12),
                                  ),
                                ),
                                child: const Text('Iptal'),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final reps = int.tryParse(repsController.text.trim());
                                  final extraWeight = double.tryParse(
                                    extraWeightController.text.trim(),
                                  );

                                  if (reps == null || reps <= 0) {
                                    setDialogState(() {
                                      errorText = 'Rekor degeri 1 veya daha buyuk olmali.';
                                    });
                                    return;
                                  }

                                  if (hasExtraWeight && (extraWeight == null || extraWeight < 0)) {
                                    setDialogState(() {
                                      errorText = 'Ekstra agirlik 0 veya daha buyuk olmali.';
                                    });
                                    return;
                                  }

                                  Navigator.of(context).pop(
                                    PersonalRecordEntry(
                                      exerciseName: selectedExercise,
                                      recordValue: reps,
                                      hasExtraWeight: hasExtraWeight,
                                      extraWeightKg: hasExtraWeight
                                          ? (extraWeight ?? 0)
                                          : null,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentPurple,
                                  foregroundColor: _textHigh,
                                ),
                                child: const Text('Kaydet'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      final updated = [..._personalRecords];
      final existingIndex = updated.indexWhere(
        (item) => item.exerciseName == result.exerciseName,
      );

      if (existingIndex >= 0) {
        updated[existingIndex] = result;
      } else {
        updated.add(result);
      }

      updated.sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
      _personalRecords = updated;
    });

    await _savePersonalRecords();
  }

  Future<void> _deletePersonalRecord(int index) async {
    setState(() {
      final updated = [..._personalRecords]..removeAt(index);
      _personalRecords = updated;
    });
    await _savePersonalRecords();
  }

  InputDecoration _dialogInputDecoration({required String label}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: _textMid),
      filled: true,
      fillColor: _cardSurfaceSoft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: _accentBlue),
      ),
    );
  }

  List<PersonalRecordEntry> _decodePersonalRecords(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <PersonalRecordEntry>[];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const <PersonalRecordEntry>[];
      }

      final records = decoded
          .whereType<Map<String, dynamic>>()
          .map(PersonalRecordEntry.fromJson)
          .toList();
      records.sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
      return records;
    } catch (_) {
      return const <PersonalRecordEntry>[];
    }
  }

  Future<void> _editGender() async {
    const genders = <String>['Kadin', 'Erkek', 'Belirtmek istemiyorum'];

    final selected = await showDialog<String>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24.0,
            vertical: 24.0,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22.0),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _cardSurface.withOpacity(0.88),
                  borderRadius: BorderRadius.circular(22.0),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cinsiyet',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _textHigh,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10.0),
                    ...genders.map(
                      (item) => RadioListTile<String>(
                        value: item,
                        groupValue: _gender,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: _accentBlue,
                        title: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: _textHigh,
                              ),
                        ),
                        onChanged: (value) => Navigator.of(context).pop(value),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Iptal'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _gender = selected;
    });
    await _saveBodyMetrics();
  }

  Future<void> _editBirthDate() async {
    final now = DateTime.now();
    final initialDate = _birthDate ?? DateTime(now.year - 25, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950, 1, 1),
      lastDate: now,
      helpText: 'Dogum tarihi sec',
      cancelText: 'Iptal',
      confirmText: 'Kaydet',
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        final themed = baseTheme.copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _accentBlue,
            onPrimary: _textHigh,
            surface: _cardSurface,
            onSurface: _textHigh,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: _cardSurface.withOpacity(0.94),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22.0),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: _accentBlue),
          ),
          datePickerTheme: DatePickerThemeData(
            backgroundColor: _cardSurface,
            headerBackgroundColor: _cardSurfaceSoft,
            headerForegroundColor: _textHigh,
            weekdayStyle: const TextStyle(color: _textMid),
            dayStyle: const TextStyle(color: _textHigh),
            yearStyle: const TextStyle(color: _textHigh),
            dividerColor: Colors.white12,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _textHigh;
              }
              return _textHigh;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _accentPurple;
              }
              return Colors.transparent;
            }),
            todayForegroundColor:
                const WidgetStatePropertyAll<Color>(_accentBlue),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22.0),
            ),
          ),
        );

        return Theme(data: themed, child: child ?? const SizedBox.shrink());
      },
    );

    if (selected == null) {
      return;
    }

    setState(() {
      _birthDate = selected;
    });
    await _saveBodyMetrics();
  }

  Future<void> _editMetric({
    required String title,
    required String unit,
    required double currentValue,
    required ValueChanged<double> onApply,
  }) async {
    final controller = TextEditingController(
      text: currentValue.toStringAsFixed(1),
    );

    final value = await showDialog<double>(
      context: context,
      builder: (context) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: _cardSurface.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(22.0),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 20.0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _textHigh,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 10.0),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: _textHigh,
                                fontWeight: FontWeight.w600,
                              ),
                          decoration: InputDecoration(
                            hintText: unit,
                            hintStyle:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _textMid,
                                    ),
                            filled: true,
                            fillColor: _cardSurfaceSoft,
                            errorText: errorText,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 12.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.0),
                              borderSide:
                                  BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.0),
                              borderSide:
                                  BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.0),
                              borderSide: const BorderSide(color: _accentBlue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.18),
                                  ),
                                  foregroundColor: _textMid,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: const Text('Iptal'),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final parsed = double.tryParse(
                                    controller.text.trim().replaceAll(',', '.'),
                                  );
                                  if (parsed == null || parsed <= 0) {
                                    setDialogState(() {
                                      errorText = 'Gecerli bir deger gir.';
                                    });
                                    return;
                                  }
                                  Navigator.of(context).pop(parsed);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentPurple,
                                  foregroundColor: _textHigh,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: const Text('Kaydet'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (value == null) {
      return;
    }

    setState(() {
      onApply(value);
    });
    await _saveBodyMetrics();
  }

  Future<void> _editIntMetric({
    required String title,
    required String unit,
    required int currentValue,
    required ValueChanged<int> onApply,
  }) async {
    final controller = TextEditingController(text: currentValue.toString());

    final value = await showDialog<int>(
      context: context,
      builder: (context) {
        String? errorText;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24.0,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22.0),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: _cardSurface.withOpacity(0.88),
                      borderRadius: BorderRadius.circular(22.0),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.35),
                          blurRadius: 20.0,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _textHigh,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 10.0),
                        TextField(
                          controller: controller,
                          autofocus: true,
                          keyboardType: TextInputType.number,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: _textHigh,
                                fontWeight: FontWeight.w600,
                              ),
                          decoration: InputDecoration(
                            hintText: unit,
                            hintStyle:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: _textMid,
                                    ),
                            filled: true,
                            fillColor: _cardSurfaceSoft,
                            errorText: errorText,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 12.0,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.0),
                              borderSide:
                                  BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.0),
                              borderSide:
                                  BorderSide(color: Colors.white.withOpacity(0.08)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14.0),
                              borderSide: const BorderSide(color: _accentBlue),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14.0),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                    color: Colors.white.withOpacity(0.18),
                                  ),
                                  foregroundColor: _textMid,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: const Text('Iptal'),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final parsed = int.tryParse(
                                    controller.text.trim(),
                                  );
                                  if (parsed == null || parsed <= 0) {
                                    setDialogState(() {
                                      errorText = 'Gecerli bir deger gir.';
                                    });
                                    return;
                                  }
                                  Navigator.of(context).pop(parsed);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentPurple,
                                  foregroundColor: _textHigh,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12.0),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                ),
                                child: const Text('Kaydet'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (value == null) {
      return;
    }

    setState(() {
      onApply(value);
    });
    await _saveBodyMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgBottom,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_bgTop, _bgBottom],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Positioned(
            top: -120.0,
            right: -70.0,
            child: Container(
              width: 240.0,
              height: 240.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentPurple.withOpacity(0.16),
              ),
            ),
          ),
          Positioned(
            bottom: -120.0,
            left: -60.0,
            child: Container(
              width: 220.0,
              height: 220.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _accentBlue.withOpacity(0.12),
              ),
            ),
          ),
          SafeArea(
            child: FutureBuilder<List<WorkoutSummaryEntry>>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final summaries = snapshot.data ?? const <WorkoutSummaryEntry>[];
                if (summaries.isEmpty) {
                  return Center(
                    child: Text(
                      'Henuz antrenman verisi yok.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: _textMid,
                          ),
                    ),
                  );
                }

                final totalWorkouts = calculateTotalWorkouts(summaries);
                final lastWorkoutDate = calculateLastWorkoutDate(summaries);
                final lastWorkoutRelativeLabel = relativeDayLabel(lastWorkoutDate);
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 24.0),
                  children: [
                    const _UserHeader(username: 'Calisthenics Athlete'),
                    const SizedBox(height: 16.0),
                    BodyMetricsCard(
                      heightCm: _heightCm,
                      weightKg: _weightKg,
                      gender: _gender,
                      birthDateLabel: _birthDate == null
                          ? 'Secilmedi'
                          : '${formatDate(_birthDate!)} (${calculateAge(_birthDate!)} yas)',
                      onEditHeight: () => _editMetric(
                        title: 'Boy (cm)',
                        unit: 'cm',
                        currentValue: _heightCm,
                        onApply: (value) => _heightCm = value,
                      ),
                      onEditWeight: () => _editMetric(
                        title: 'Kilo (kg)',
                        unit: 'kg',
                        currentValue: _weightKg,
                        onApply: (value) => _weightKg = value,
                      ),
                      onEditGender: _editGender,
                      onEditBirthDate: _editBirthDate,
                    ),
                    const SizedBox(height: 12.0),
                    GoalsCard(
                      goalWeightKg: _goalWeightKg,
                      targetWorkoutsPerWeek: _targetWorkoutsPerWeek,
                      onEditGoalWeight: () => _editMetric(
                        title: 'Hedef Kilo (kg)',
                        unit: 'kg',
                        currentValue: _goalWeightKg,
                        onApply: (value) => _goalWeightKg = value,
                      ),
                      onEditTargetWorkouts: () => _editIntMetric(
                        title: 'Haftalik Hedef Antrenman',
                        unit: 'adet',
                        currentValue: _targetWorkoutsPerWeek,
                        onApply: (value) => _targetWorkoutsPerWeek = value,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    StatsCard(
                      totalWorkouts: totalWorkouts,
                      lastWorkoutDate: formatDate(lastWorkoutDate),
                      lastWorkoutRelativeLabel: lastWorkoutRelativeLabel,
                    ),
                    const SizedBox(height: 12.0),
                    PersonalRecordsCard(
                      records: _personalRecords,
                      onAddRecord: _showAddPersonalRecordDialog,
                      onDeleteRecord: _deletePersonalRecord,
                    ),
                    const SizedBox(height: 24.0),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar:
          widget.showBottomNav ? const AppBottomNav(selectedIndex: 3) : null,
    );
  }
}

class BodyMetricsCard extends StatelessWidget {
  const BodyMetricsCard({
    super.key,
    required this.heightCm,
    required this.weightKg,
    required this.gender,
    required this.birthDateLabel,
    required this.onEditHeight,
    required this.onEditWeight,
    required this.onEditGender,
    required this.onEditBirthDate,
  });

  final double heightCm;
  final double weightKg;
  final String gender;
  final String birthDateLabel;
  final VoidCallback onEditHeight;
  final VoidCallback onEditWeight;
  final VoidCallback onEditGender;
  final VoidCallback onEditBirthDate;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vucut Olculeri',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10.0),
            _MetricEditRow(
              label: 'Boy',
              value: '${heightCm.toStringAsFixed(1)} cm',
              onTap: onEditHeight,
            ),
            const SizedBox(height: 8.0),
            _MetricEditRow(
              label: 'Kilo',
              value: '${weightKg.toStringAsFixed(1)} kg',
              onTap: onEditWeight,
            ),
            const SizedBox(height: 8.0),
            _MetricEditRow(
              label: 'Cinsiyet',
              value: gender,
              onTap: onEditGender,
            ),
            const SizedBox(height: 8.0),
            _MetricEditRow(
              label: 'Dogum Tarihi',
              value: birthDateLabel,
              onTap: onEditBirthDate,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricEditRow extends StatelessWidget {
  const _MetricEditRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14.0),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: _ProfileScreenState._cardSurfaceSoft,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _ProfileScreenState._textMid,
                      ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ProfileScreenState._textHigh,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(width: 6.0),
              const Icon(
                Icons.edit_rounded,
                size: 16.0,
                color: _ProfileScreenState._textMid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _ProfileScreenState._cardSurfaceSoft,
          child: const Icon(
            Icons.person,
            size: 30,
            color: _ProfileScreenState._textHigh,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: _ProfileScreenState._textHigh,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Workout Insights',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _ProfileScreenState._textMid,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.totalWorkouts,
    required this.lastWorkoutDate,
    required this.lastWorkoutRelativeLabel,
  });

  final int totalWorkouts;
  final String lastWorkoutDate;
  final String lastWorkoutRelativeLabel;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Genel Istatistikler',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'Toplam antrenman',
              value: '$totalWorkouts',
              labelColor: _ProfileScreenState._textMid,
              valueColor: _ProfileScreenState._textHigh,
            ),
            _StatRow(
              label: 'Son antrenman',
              value: '$lastWorkoutDate ($lastWorkoutRelativeLabel)',
              labelColor: _ProfileScreenState._textMid,
              valueColor: _ProfileScreenState._textHigh,
            ),
          ],
        ),
      ),
    );
  }
}

class GoalsCard extends StatelessWidget {
  const GoalsCard({
    super.key,
    required this.goalWeightKg,
    required this.targetWorkoutsPerWeek,
    required this.onEditGoalWeight,
    required this.onEditTargetWorkouts,
  });

  final double goalWeightKg;
  final int targetWorkoutsPerWeek;
  final VoidCallback onEditGoalWeight;
  final VoidCallback onEditTargetWorkouts;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hedefler',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10.0),
            _MetricEditRow(
              label: 'Hedef Kilo',
              value: '${goalWeightKg.toStringAsFixed(1)} kg',
              onTap: onEditGoalWeight,
            ),
            const SizedBox(height: 8.0),
            _MetricEditRow(
              label: 'Haftalik Hedef',
              value: '$targetWorkoutsPerWeek antrenman',
              onTap: onEditTargetWorkouts,
            ),
          ],
        ),
      ),
    );
  }
}

class MuscleDistributionCard extends StatelessWidget {
  const MuscleDistributionCard({super.key, required this.distribution});

  final Map<String, double> distribution;

  @override
  Widget build(BuildContext context) {
    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kas Dagilimi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            ...sorted.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: _StatRow(
                  label: muscleDisplayName(item.key),
                  value: item.value.toStringAsFixed(1),
                  labelColor: _ProfileScreenState._textMid,
                  valueColor: _ProfileScreenState._textHigh,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PersonalRecordEntry {
  const PersonalRecordEntry({
    required this.exerciseName,
    required this.recordValue,
    required this.hasExtraWeight,
    required this.extraWeightKg,
  });

  final String exerciseName;
  final int recordValue;
  final bool hasExtraWeight;
  final double? extraWeightKg;

  factory PersonalRecordEntry.fromJson(Map<String, dynamic> json) {
    return PersonalRecordEntry(
      exerciseName: json['exerciseName'] as String? ?? 'Unknown',
      recordValue: (json['recordValue'] as num?)?.toInt() ?? 0,
      hasExtraWeight: json['hasExtraWeight'] as bool? ?? false,
      extraWeightKg: (json['extraWeightKg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'recordValue': recordValue,
      'hasExtraWeight': hasExtraWeight,
      'extraWeightKg': extraWeightKg,
    };
  }
}

class PersonalRecordsCard extends StatelessWidget {
  const PersonalRecordsCard({
    super.key,
    required this.records,
    required this.onAddRecord,
    required this.onDeleteRecord,
  });

  final List<PersonalRecordEntry> records;
  final VoidCallback onAddRecord;
  final ValueChanged<int> onDeleteRecord;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kisisel Rekorlar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: _ProfileScreenState._textHigh,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: onAddRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _ProfileScreenState._accentPurple,
                    foregroundColor: _ProfileScreenState._textHigh,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                      vertical: 8.0,
                    ),
                    textStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  icon: const Icon(Icons.add, size: 16.0),
                  label: const Text('Ekle'),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            if (records.isEmpty)
              Text(
                'Henuz rekor eklenmedi. Hareket secip rekorunu kaydet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _ProfileScreenState._textMid,
                    ),
              )
            else
              ...records.asMap().entries.map(
                (entry) {
                  final index = entry.key;
                  final record = entry.value;
                  final extraWeightLabel =
                      record.hasExtraWeight && record.extraWeightKg != null
                      ? ' + ${record.extraWeightKg!.toStringAsFixed(1)} kg'
                      : '';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 10.0,
                      ),
                      decoration: BoxDecoration(
                        color: _ProfileScreenState._cardSurfaceSoft,
                        borderRadius: BorderRadius.circular(14.0),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.exerciseName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                        color: _ProfileScreenState._textHigh,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  '${record.recordValue} tekrar$extraWeightLabel',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: _ProfileScreenState._textMid,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => onDeleteRecord(index),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Color(0xFFFF8E8E),
                            ),
                            tooltip: 'Sil',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class TrendCard extends StatelessWidget {
  const TrendCard({
    super.key,
    required this.currentSevenDayLoad,
    required this.previousSevenDayLoad,
  });

  final double currentSevenDayLoad;
  final double previousSevenDayLoad;

  @override
  Widget build(BuildContext context) {
    final trendLabel = currentSevenDayLoad >= previousSevenDayLoad
        ? 'Increasing'
        : 'Decreasing';
    final trendIcon = currentSevenDayLoad >= previousSevenDayLoad
        ? Icons.trending_up
        : Icons.trending_down;
    final trendColor = currentSevenDayLoad >= previousSevenDayLoad
        ? const Color(0xFF3DDC84)
        : const Color(0xFFFF7A59);

    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Son 7 Gun Trendi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'Son 7 gun toplam yuk',
              value: currentSevenDayLoad.toStringAsFixed(1),
              labelColor: _ProfileScreenState._textMid,
              valueColor: _ProfileScreenState._textHigh,
            ),
            _StatRow(
              label: 'Onceki 7 gun toplam yuk',
              value: previousSevenDayLoad.toStringAsFixed(1),
              labelColor: _ProfileScreenState._textMid,
              valueColor: _ProfileScreenState._textHigh,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(trendIcon, size: 18.0, color: trendColor),
                const SizedBox(width: 6.0),
                Text(
                  trendLabel,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: trendColor,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Denge Analizi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _ProfileScreenState._textMid,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: labelColor,
                  ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  const _GlassCard({required this.child, this.borderRadius = 20.0});

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
        child: Container(
          decoration: BoxDecoration(
            color: _ProfileScreenState._cardSurface.withOpacity(0.78),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.35),
                blurRadius: 20.0,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

int calculateTotalWorkouts(List<WorkoutSummaryEntry> summaries) {
  return summaries.length;
}

double calculateTotalLoad(List<WorkoutSummaryEntry> summaries) {
  return summaries.fold<double>(0.0, (sum, item) => sum + item.totalLoad);
}

DateTime calculateLastWorkoutDate(List<WorkoutSummaryEntry> summaries) {
  final sorted = [...summaries]..sort((a, b) => b.date.compareTo(a.date));
  return sorted.first.date;
}

Map<String, double> calculateMuscleDistribution(
  List<WorkoutSummaryEntry> summaries,
) {
  final result = <String, double>{};
  for (final summary in summaries) {
    for (final entry in summary.muscleLoad.entries) {
      result.update(
        entry.key,
        (value) => value + entry.value,
        ifAbsent: () => entry.value,
      );
    }
  }
  return result;
}

({double current, double previous}) calculateSevenDayTrend(
  List<WorkoutSummaryEntry> summaries,
) {
  final now = DateTime.now();
  final startCurrent = now.subtract(const Duration(days: 7));
  final startPrevious = now.subtract(const Duration(days: 14));

  double current = 0.0;
  double previous = 0.0;

  for (final summary in summaries) {
    if (summary.date.isAfter(startCurrent)) {
      current += summary.totalLoad;
    } else if (summary.date.isAfter(startPrevious)) {
      previous += summary.totalLoad;
    }
  }

  return (current: current, previous: previous);
}

String calculateBalanceText(Map<String, double> distribution) {
  final pushMuscles = {'chest', 'shoulders', 'triceps', 'quads'};
  final pullMuscles = {'back', 'biceps', 'hamstrings', 'glutes'};

  double push = 0.0;
  double pull = 0.0;

  for (final entry in distribution.entries) {
    final key = entry.key.toLowerCase();
    if (pushMuscles.contains(key)) {
      push += entry.value;
    }
    if (pullMuscles.contains(key)) {
      pull += entry.value;
    }
  }

  if (push > pull * 1.15) {
    return 'Push muscles are dominant. Pull muscles are lacking.';
  }
  if (pull > push * 1.15) {
    return 'Pull muscles are dominant. Push muscles are lacking.';
  }
  return 'Balanced training';
}

String formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

int calculateAge(DateTime birthDate) {
  final now = DateTime.now();
  var age = now.year - birthDate.year;
  final hasBirthdayPassed =
      now.month > birthDate.month ||
      (now.month == birthDate.month && now.day >= birthDate.day);
  if (!hasBirthdayPassed) {
    age -= 1;
  }
  return age;
}

String relativeDayLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = today.difference(target).inDays;

  if (diff <= 0) {
    return 'Bugun';
  }
  if (diff == 1) {
    return 'Dun';
  }
  return '$diff gun once';
}

String muscleDisplayName(String key) {
  switch (key.toLowerCase()) {
    case 'chest':
      return 'Chest';
    case 'back':
      return 'Back';
    case 'shoulders':
      return 'Shoulders';
    case 'biceps':
      return 'Biceps';
    case 'triceps':
      return 'Triceps';
    case 'core':
      return 'Core';
    case 'quads':
      return 'Quads';
    case 'hamstrings':
      return 'Hamstrings';
    case 'glutes':
      return 'Glutes';
    case 'calves':
      return 'Calves';
    default:
      return key;
  }
}

List<WorkoutSummaryEntry> buildMockWorkoutSummaries() {
  final now = DateTime.now();
  return [
    WorkoutSummaryEntry(
      date: now.subtract(const Duration(days: 1)),
      totalLoad: 680,
      muscleLoad: const {
        'chest': 210,
        'triceps': 120,
        'shoulders': 140,
        'core': 60,
      },
      duration: 2100,
    ),
    WorkoutSummaryEntry(
      date: now.subtract(const Duration(days: 3)),
      totalLoad: 740,
      muscleLoad: const {
        'back': 280,
        'biceps': 170,
        'shoulders': 110,
        'core': 80,
      },
      duration: 2400,
    ),
    WorkoutSummaryEntry(
      date: now.subtract(const Duration(days: 9)),
      totalLoad: 520,
      muscleLoad: const {
        'quads': 170,
        'glutes': 140,
        'hamstrings': 120,
        'calves': 90,
      },
      duration: 1900,
    ),
  ];
}
