import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calisthenics_app/core/utils/exercise_unit.dart';
import 'package:calisthenics_app/core/local_storage/workout_summary_storage.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:calisthenics_app/data/services/auth_service.dart';
import 'package:calisthenics_app/data/services/firestore_service.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/muscle_recovery_card.dart';

class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(showBottomNav: showBottomNav);
  }
}

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  static const Color _bgBottom = AppColors.background; // #0A0C0E
  static const Color _cardSurface = AppColors.surface; // #13171C
  static const Color _cardSurfaceSoft = AppColors.surfaceSoft; // #181D24
  static const Color _accentPurple = AppColors.volcanic; // #FF5533
  static const Color _accentBlue = AppColors.emerald; // #10B981
  static const Color _textHigh = AppColors.textHigh; // #F1F5F9
  static const Color _textMid = AppColors.textMid; // #94A3B8
  static const Color _border = AppColors.border; // #1E232A

  static const String _heightKey = 'profile_height_cm';
  static const String _weightKey = 'profile_weight_kg';
  static const String _goalWeightKey = 'profile_goal_weight_kg';
  static const String _targetWorkoutsKey = 'profile_target_workouts_weekly';
  static const String _genderKey = 'profile_gender';
  static const String _birthDateKey = 'profile_birth_date';
  static const String _personalRecordsKey = 'profile_personal_records_v1';
  static const int _minRecordValue = 1;
  static const int _maxRecordValue = 300;
  static const double _minExtraWeightKg = 0.5;
  static const double _maxExtraWeightKg = 200.0;

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

  late Future<List<WorkoutSummaryEntry>> _summaryFuture;
  double _heightCm = 175.0;
  double _weightKg = 70.0;
  double _goalWeightKg = 68.0;
  int _targetWorkoutsPerWeek = 4;
  String _gender = 'Belirtilmedi';
  DateTime? _birthDate;
  List<PersonalRecordEntry> _personalRecords = const [];
  int _syncedStreak = 0;
  int _syncedTotalWorkouts = 0;
  bool _isLinkingGoogle = false;

  @override
  void initState() {
    super.initState();
    _summaryFuture = _loadSummaries();
    _loadBodyMetrics();
    _syncUserStreakAndStats();
  }

  Future<void> _syncUserStreakAndStats() async {
    try {
      final storage = WorkoutSummaryStorage();
      final summaries = await storage.loadSummaries();
      final localTotal = summaries.length;
      final localStreak = calculateWorkoutStreak(summaries);
      final lastDate = summaries.isNotEmpty
          ? summaries.map((s) => s.date).reduce((a, b) => a.isAfter(b) ? a : b)
          : null;

      final result = await ref
          .read(firestoreServiceProvider)
          .syncUserStreakAndWorkouts(
            localTotalWorkouts: localTotal,
            localStreak: localStreak,
            localLastWorkoutDate: lastDate,
          );

      if (!mounted) return;
      setState(() {
        _syncedStreak = result['streak'] ?? localStreak;
        _syncedTotalWorkouts = result['totalWorkouts'] ?? localTotal;
      });
    } catch (_) {
      // Ağ veya Firestore hatasında UI akışını engellemez
    }
  }

  Future<List<WorkoutSummaryEntry>> _loadSummaries() async {
    final storage = WorkoutSummaryStorage();
    final summaries = await storage.loadSummaries();
    if (summaries.isNotEmpty) {
      return summaries;
    }
    return buildMockWorkoutSummaries();
  }

  Future<void> _refreshSummaries() async {
    setState(() {
      _summaryFuture = _loadSummaries();
    });
    await _syncUserStreakAndStats();
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
    bool selectedIsTimed = isTimedExercise(exerciseName: selectedExercise);
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
              child: Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: _cardSurface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: _border, width: 1.0),
                ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kisisel Rekor Ekle',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: _textHigh,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 12.0),
                        DropdownButtonFormField<String>(
                          value: selectedExercise,
                          dropdownColor: _cardSurfaceSoft,
                          decoration: _dialogInputDecoration(label: 'Hareket'),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: _textHigh),
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
                              selectedIsTimed = isTimedExercise(
                                exerciseName: selectedExercise,
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 10.0),
                        TextField(
                          controller: repsController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: _textHigh),
                          decoration: _dialogInputDecoration(
                            label: selectedIsTimed
                                ? 'Rekor (saniye)'
                                : 'Rekor (tekrar)',
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        SwitchListTile.adaptive(
                          value: hasExtraWeight,
                          activeColor: _accentBlue,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Ekstra agirlik var',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
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
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(5),
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d{0,3}([\.,]\d{0,1})?$'),
                              ),
                            ],
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(color: _textHigh),
                            decoration: _dialogInputDecoration(
                              label: 'Ekstra agirlik (kg)',
                            ),
                          ),
                        ],
                        if (errorText != null) ...[
                          const SizedBox(height: 8.0),
                          Text(
                            errorText!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
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
                                  side: const BorderSide(color: _border),
                                ),
                                child: const Text('İptal'),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  final repsText = repsController.text.trim();
                                  final extraWeightText = extraWeightController
                                      .text
                                      .trim()
                                      .replaceAll(',', '.');
                                  final reps = int.tryParse(repsText);
                                  final extraWeight =
                                      hasExtraWeight &&
                                          extraWeightText.isNotEmpty
                                      ? double.tryParse(extraWeightText)
                                      : null;

                                  if (reps == null) {
                                    setDialogState(() {
                                      errorText = selectedIsTimed
                                          ? 'Rekor suresini sadece sayi olarak gir.'
                                          : 'Rekor tekrarini sadece sayi olarak gir.';
                                    });
                                    return;
                                  }

                                  if (reps < _minRecordValue ||
                                      reps > _maxRecordValue) {
                                    setDialogState(() {
                                      errorText = selectedIsTimed
                                          ? 'Rekor suresi $_minRecordValue-$_maxRecordValue saniye araliginda olmali.'
                                          : 'Rekor tekrari $_minRecordValue-$_maxRecordValue araliginda olmali.';
                                    });
                                    return;
                                  }

                                  if (hasExtraWeight && extraWeight == null) {
                                    setDialogState(() {
                                      errorText =
                                          'Ekstra agirlik degerini girmelisin (ornek: 12.5).';
                                    });
                                    return;
                                  }

                                  if (hasExtraWeight &&
                                      (extraWeight! < _minExtraWeightKg ||
                                          extraWeight > _maxExtraWeightKg)) {
                                    setDialogState(() {
                                      errorText =
                                          'Ekstra agirlik $_minExtraWeightKg-$_maxExtraWeightKg kg araliginda olmali.';
                                    });
                                    return;
                                  }

                                  Navigator.of(context).pop(
                                    PersonalRecordEntry(
                                      exerciseName: selectedExercise,
                                      recordValue: reps,
                                      isTimed: selectedIsTimed,
                                      hasExtraWeight: hasExtraWeight,
                                      extraWeightKg: hasExtraWeight
                                          ? double.parse(
                                              extraWeight!.toStringAsFixed(1),
                                            )
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
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12.0)),
        borderSide: BorderSide(color: _accentPurple),
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
          .where(_isValidPersonalRecord)
          .toList();
      records.sort((a, b) => a.exerciseName.compareTo(b.exerciseName));
      return records;
    } catch (_) {
      return const <PersonalRecordEntry>[];
    }
  }

  bool _isValidPersonalRecord(PersonalRecordEntry record) {
    if (record.exerciseName.trim().isEmpty) {
      return false;
    }

    if (record.recordValue < _minRecordValue ||
        record.recordValue > _maxRecordValue) {
      return false;
    }

    if (!record.hasExtraWeight) {
      return true;
    }

    final weight = record.extraWeightKg;
    if (weight == null) {
      return false;
    }

    return weight >= _minExtraWeightKg && weight <= _maxExtraWeightKg;
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
          child: Container(
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              color: _cardSurface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: _border, width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cinsiyet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _textHigh,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10.0),
                ...genders.map(
                  (item) => RadioListTile<String>(
                    value: item,
                    groupValue: _gender,
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    activeColor: _accentPurple,
                    title: Text(
                      item,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: _textHigh),
                    ),
                    onChanged: (value) => Navigator.of(context).pop(value),
                  ),
                ),
                const SizedBox(height: 8.0),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: _textMid),
                    child: const Text('İptal'),
                  ),
                ),
              ],
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
    final initialDate =
        _birthDate ?? DateTime(now.year - 25, now.month, now.day);
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
          dialogTheme: const DialogThemeData(
            backgroundColor: _cardSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16.0)),
              side: BorderSide(color: _border, width: 1.0),
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
            todayForegroundColor: const WidgetStatePropertyAll<Color>(
              _accentBlue,
            ),
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
              child: Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: _cardSurface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: _border, width: 1.0),
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
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(
                            color: _textHigh,
                            fontWeight: FontWeight.w600,
                          ),
                      decoration: InputDecoration(
                        hintText: unit,
                        hintStyle: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: _textMid),
                        filled: true,
                        fillColor: _cardSurfaceSoft,
                        errorText: errorText,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 12.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: _accentPurple),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _border),
                              foregroundColor: _textMid,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: const Text('İptal'),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
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
              child: Container(
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: _cardSurface,
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: _border, width: 1.0),
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
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: controller,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      style: Theme.of(context).textTheme.bodyLarge
                          ?.copyWith(
                            color: _textHigh,
                            fontWeight: FontWeight.w600,
                          ),
                      decoration: InputDecoration(
                        hintText: unit,
                        hintStyle: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: _textMid),
                        filled: true,
                        fillColor: _cardSurfaceSoft,
                        errorText: errorText,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14.0,
                          vertical: 12.0,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: const BorderSide(color: _accentPurple),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: _border),
                              foregroundColor: _textMid,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                            ),
                            child: const Text('İptal'),
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
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12.0,
                                  ),
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

  Future<void> _linkGoogleAccount() async {
    if (_isLinkingGoogle) return;
    setState(() => _isLinkingGoogle = true);
    String? message;
    try {
      final result = await ref
          .read(authServiceProvider)
          .linkAnonymousWithGoogle();
      switch (result.status) {
        case GoogleLinkStatus.linked:
          message = 'Hesabin Google ile baglandi. Verilerin korundu.';
          break;
        case GoogleLinkStatus.conflict:
          if (mounted) {
            await _showAccountConflictDialog();
          }
          break;
        case GoogleLinkStatus.signedInExisting:
          message = 'Mevcut Google hesabinla giris yapildi.';
          _syncUserStreakAndStats();
          break;
        case GoogleLinkStatus.alreadyLinked:
        case GoogleLinkStatus.cancelled:
          break;
      }
    } on FirebaseAuthException catch (e) {
      message = e.message ?? 'Google ile baglama basarisiz oldu.';
    } catch (_) {
      message = 'Google ile baglama basarisiz oldu. Lutfen tekrar dene.';
    } finally {
      if (mounted) {
        setState(() => _isLinkingGoogle = false);
      }
    }
    if (message != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showAccountConflictDialog() async {
    final signIn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardSurface,
        title: const Text(
          'Hesap zaten kullanimda',
          style: TextStyle(color: _textHigh),
        ),
        content: const Text(
          'Bu Google hesabi daha once baska bir profile baglanmis. '
          'Bu hesapla giris yaparsan su anki anonim verilerin bu cihazda '
          'gorunmez olur ve Google hesabindaki verilerin yuklenir.',
          style: TextStyle(color: _textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgec'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hesapla giris yap'),
          ),
        ],
      ),
    );
    if (signIn != true) return;
    try {
      await ref
          .read(authServiceProvider)
          .linkAnonymousWithGoogle(signInIfAlreadyInUse: true);
      _syncUserStreakAndStats();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Giris basarisiz oldu.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giris basarisiz oldu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser =
        ref.watch(authUserProvider).valueOrNull ??
        FirebaseAuth.instance.currentUser;
    final isGoogleLinked =
        authUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;
    final headerName = (isGoogleLinked &&
            (authUser?.displayName?.trim().isNotEmpty ?? false))
        ? authUser!.displayName!.trim()
        : 'Calisthenics Athlete';
    return Scaffold(
      backgroundColor: _bgBottom,
      body: SafeArea(
        child: FutureBuilder<List<WorkoutSummaryEntry>>(
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final summaries =
                    snapshot.data ?? const <WorkoutSummaryEntry>[];
                if (summaries.isEmpty) {
                  return Center(
                    child: Text(
                      'Henuz antrenman verisi yok.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: _textMid),
                    ),
                  );
                }

                final totalWorkouts = calculateTotalWorkouts(summaries);
                final lastWorkoutDate = calculateLastWorkoutDate(summaries);
                final lastWorkoutRelativeLabel = relativeDayLabel(
                  lastWorkoutDate,
                );
                final trend = calculateSevenDayTrend(summaries);
                final muscleDistribution = calculateMuscleDistribution(
                  summaries,
                );
                final balanceText = calculateBalanceText(muscleDistribution);
                return RefreshIndicator(
                  onRefresh: _refreshSummaries,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 24.0),
                    children: [
                      _UserHeader(
                        username: headerName,
                        email: isGoogleLinked ? authUser?.email : null,
                        photoUrl: isGoogleLinked ? authUser?.photoURL : null,
                      ),
                      const SizedBox(height: 16.0),
                      _GoogleLinkCard(
                        isLinked: isGoogleLinked,
                        isLoading: _isLinkingGoogle,
                        onPressed: _linkGoogleAccount,
                      ),
                      const SizedBox(height: 12.0),
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
                        totalWorkouts: _syncedTotalWorkouts > totalWorkouts
                            ? _syncedTotalWorkouts
                            : totalWorkouts,
                        streak: _syncedStreak > calculateWorkoutStreak(summaries)
                            ? _syncedStreak
                            : calculateWorkoutStreak(summaries),
                        lastWorkoutDate: formatDate(lastWorkoutDate),
                        lastWorkoutRelativeLabel: lastWorkoutRelativeLabel,
                        onStreakTap: () {
                          Navigator.pushNamed(context, AppRoutes.streakDetails);
                        },
                        onHistoryTap: () {
                          Navigator.pushNamed(context, AppRoutes.workoutHistory);
                        },
                      ),
                      const SizedBox(height: 12.0),
                      _WorkoutHistoryProfileCard(
                        totalWorkouts: _syncedTotalWorkouts > totalWorkouts
                            ? _syncedTotalWorkouts
                            : totalWorkouts,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.workoutHistory);
                        },
                      ),
                      const SizedBox(height: 12.0),
                      const MuscleRecoveryCard(),
                      const SizedBox(height: 12.0),
                      TrendCard(
                        currentSevenDayLoad: trend.current,
                        previousSevenDayLoad: trend.previous,
                      ),
                      const SizedBox(height: 12.0),
                      if (muscleDistribution.isNotEmpty) ...[
                        MuscleDistributionCard(
                          distribution: muscleDistribution,
                        ),
                        const SizedBox(height: 12.0),
                      ],
                      BalanceCard(message: balanceText),
                      const SizedBox(height: 12.0),
                      PersonalRecordsCard(
                        records: _personalRecords,
                        onAddRecord: _showAddPersonalRecordDialog,
                        onDeleteRecord: _deletePersonalRecord,
                      ),
                      const SizedBox(height: 24.0),
                    ],
                  ),
                );
              },
            ),
          ),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(selectedIndex: 3)
          : null,
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
      borderRadius: 14.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vücut Ölçüleri',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _ProfileScreenState._textHigh,
                fontWeight: FontWeight.w600,
                fontSize: 15.0,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12.0),
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
              label: 'Doğum Tarihi',
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
        borderRadius: BorderRadius.circular(12.0),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: _ProfileScreenState._cardSurfaceSoft,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(color: _ProfileScreenState._border, width: 1.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _ProfileScreenState._textMid,
                    fontSize: 13.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _ProfileScreenState._textHigh,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(width: 8.0),
              const Icon(
                Icons.edit_rounded,
                size: 15.0,
                color: _ProfileScreenState._textMid,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleLinkCard extends StatelessWidget {
  const _GoogleLinkCard({
    required this.isLinked,
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLinked;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = isLinked || isLoading;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14.0),
        color: _ProfileScreenState._cardSurface,
        border: Border.all(
          color: isLinked
              ? _ProfileScreenState._accentBlue.withValues(alpha: 0.35)
              : _ProfileScreenState._border,
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14.0),
          onTap: disabled ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 13.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 18.0,
                    height: 18.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: _ProfileScreenState._accentPurple,
                    ),
                  )
                else if (isLinked)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: _ProfileScreenState._accentBlue,
                    size: 19.0,
                  )
                else
                  Container(
                    width: 22.0,
                    height: 22.0,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Text(
                      'G',
                      style: TextStyle(
                        color: Color(0xFF4285F4),
                        fontWeight: FontWeight.w900,
                        fontSize: 14.0,
                        height: 1.0,
                      ),
                    ),
                  ),
                const SizedBox(width: 10.0),
                Text(
                  isLoading
                      ? 'Bağlanıyor...'
                      : isLinked
                      ? 'Google Hesabı Bağlı'
                      : 'Google ile Hesabını Bağla',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: isLinked
                        ? _ProfileScreenState._accentBlue
                        : _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader({required this.username, this.email, this.photoUrl});

  final String username;
  final String? email;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final hasEmail = email != null && email!.isNotEmpty;
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: _ProfileScreenState._cardSurfaceSoft,
          backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
          child: hasPhoto
              ? null
              : const Icon(
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
                hasEmail ? email! : 'Workout Insights',
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
    this.streak = 0,
    this.onStreakTap,
    this.onHistoryTap,
  });

  final int totalWorkouts;
  final String lastWorkoutDate;
  final String lastWorkoutRelativeLabel;
  final int streak;
  final VoidCallback? onStreakTap;
  final VoidCallback? onHistoryTap;

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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Genel Istatistikler',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _ProfileScreenState._textHigh,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (onStreakTap != null)
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onStreakTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'Detaylar',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: _ProfileScreenState._accentBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: _ProfileScreenState._accentBlue,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            _StatRow(
              label: 'Mevcut Seri (Streak)',
              value: '$streak gün 🔥',
              labelColor: _ProfileScreenState._textMid,
              valueColor: streak > 0 ? const Color(0xFFFF9800) : _ProfileScreenState._textHigh,
            ),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onHistoryTap,
              child: _StatRow(
                label: 'Toplam antrenman',
                value: '$totalWorkouts ›',
                labelColor: _ProfileScreenState._textMid,
                valueColor: _ProfileScreenState._accentBlue,
              ),
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

class _WorkoutHistoryProfileCard extends StatelessWidget {
  const _WorkoutHistoryProfileCard({
    required this.totalWorkouts,
    required this.onTap,
  });

  final int totalWorkouts;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      borderRadius: 22.0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC2F13A).withAlpha(35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: Color(0xFFC2F13A),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Antrenman Geçmişi',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _ProfileScreenState._textHigh,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        totalWorkouts > 0
                            ? '$totalWorkouts tamamlanan seans ve MLI puanları'
                            : 'Tamamlanan seansların dökümü',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: _ProfileScreenState._textMid,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _ProfileScreenState._textMid,
                  size: 15,
                ),
              ],
            ),
          ),
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
      borderRadius: 14.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hedefler',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: _ProfileScreenState._textHigh,
                fontWeight: FontWeight.w600,
                fontSize: 15.0,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 12.0),
            _MetricEditRow(
              label: 'Hedef Kilo',
              value: '${goalWeightKg.toStringAsFixed(1)} kg',
              onTap: onEditGoalWeight,
            ),
            const SizedBox(height: 8.0),
            _MetricEditRow(
              label: 'Haftalık Hedef',
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    required this.isTimed,
    required this.hasExtraWeight,
    required this.extraWeightKg,
  });

  final String exerciseName;
  final int recordValue;
  final bool isTimed;
  final bool hasExtraWeight;
  final double? extraWeightKg;

  factory PersonalRecordEntry.fromJson(Map<String, dynamic> json) {
    return PersonalRecordEntry(
      exerciseName: json['exerciseName'] as String? ?? 'Unknown',
      recordValue: (json['recordValue'] as num?)?.toInt() ?? 0,
      isTimed:
          (json['isTimed'] as bool?) ??
          isTimedExercise(exerciseName: json['exerciseName'] as String? ?? ''),
      hasExtraWeight: json['hasExtraWeight'] as bool? ?? false,
      extraWeightKg: (json['extraWeightKg'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseName': exerciseName,
      'recordValue': recordValue,
      'isTimed': isTimed,
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
                    textStyle: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
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
              ...records.asMap().entries.map((entry) {
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
                      border: Border.all(color: _ProfileScreenState._border),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.exerciseName,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: _ProfileScreenState._textHigh,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                '${record.recordValue} ${record.isTimed ? 'sn' : 'tekrar'}$extraWeightLabel',
                                style: Theme.of(context).textTheme.bodySmall
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
              }),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: labelColor),
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
  const _GlassCard({required this.child, this.borderRadius = 14.0});

  final Widget child;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _ProfileScreenState._cardSurface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: _ProfileScreenState._border, width: 1.0),
      ),
      child: child,
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
