import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:calisthenics_app/core/utils/exercise_unit.dart';
import 'package:calisthenics_app/core/local_storage/workout_summary_storage.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/workout_session_summary.dart';
import 'package:calisthenics_app/domain/services/muscle_key_mapper.dart';
import 'package:calisthenics_app/domain/services/push_pull_balance.dart';
import 'package:calisthenics_app/presentation/providers/theme_mode_provider.dart';
import 'package:calisthenics_app/presentation/providers/workout_history_provider.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:calisthenics_app/data/services/auth_service.dart';
import 'package:calisthenics_app/data/services/firestore_service.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/presentation/widgets/muscle_recovery_card.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';

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
  static Color get _bgBottom => AppColors.background; // #0A0C0E
  static Color get _cardSurface => AppColors.surface; // #13171C
  static Color get _cardSurfaceSoft => AppColors.surfaceSoft; // #181D24
  static Color get _accentPurple => AppColors.accent; // #A3E635
  static Color get _accentBlue => AppColors.emerald; // #10B981
  static Color get _textHigh => AppColors.textHigh; // #F1F5F9
  static Color get _textMid => AppColors.textMid; // #94A3B8
  static Color get _border => AppColors.border; // #1E232A

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
  final GlobalKey _settingsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadBodyMetrics();
    _syncUserStreakAndStats();
  }

  List<WorkoutSummaryEntry> _mapSessionsToSummaries(
    List<WorkoutSessionSummary> sessions,
  ) {
    return sessions
        .map(
          (session) => WorkoutSummaryEntry(
            date: session.completedAt,
            totalLoad: session.totalMliWorkload,
            muscleLoad: session.muscleWorkloads,
            duration: session.durationSeconds,
            load: session.load,
            schemaVersion: session.schemaVersion,
          ),
        )
        .toList();
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

  Future<void> _refreshSummaries() async {
    ref.invalidate(workoutHistoryProvider);
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

    try {
      await ref.read(firestoreServiceProvider).syncUserProfile({
        'heightCm': _heightCm,
        'weightKg': _weightKg,
        'goalWeightKg': _goalWeightKg,
        'targetWorkoutsPerWeek': _targetWorkoutsPerWeek,
        'gender': _gender,
        'birthDate': _birthDate?.toIso8601String(),
      });
    } catch (_) {
      // Ağ veya Firestore hatasında yerel veriler korunur, UI akışı kesilmez.
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
                      'Kişisel Rekor Ekle',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _textHigh,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    DropdownButtonFormField<String>(
                      initialValue: selectedExercise,
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
                      activeThumbColor: _accentBlue,
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Ekstra ağırlık var',
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
                          label: 'Ekstra ağırlık (kg)',
                        ),
                      ),
                    ],
                    if (errorText != null) ...[
                      const SizedBox(height: 8.0),
                      Text(
                        errorText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.danger,
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
                              side: BorderSide(color: _border),
                            ),
                            child: const Text('İptal'),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final repsText = repsController.text.trim();
                              final extraWeightText = extraWeightController.text
                                  .trim()
                                  .replaceAll(',', '.');
                              final reps = int.tryParse(repsText);
                              final extraWeight =
                                  hasExtraWeight && extraWeightText.isNotEmpty
                                  ? double.tryParse(extraWeightText)
                                  : null;

                              if (reps == null) {
                                setDialogState(() {
                                  errorText = selectedIsTimed
                                      ? 'Rekor süresini yalnızca sayı olarak gir.'
                                      : 'Rekor tekrarını yalnızca sayı olarak gir.';
                                });
                                return;
                              }

                              if (reps < _minRecordValue ||
                                  reps > _maxRecordValue) {
                                setDialogState(() {
                                  errorText = selectedIsTimed
                                      ? 'Rekor süresi $_minRecordValue-$_maxRecordValue saniye aralığında olmalı.'
                                      : 'Rekor tekrarı $_minRecordValue-$_maxRecordValue aralığında olmalı.';
                                });
                                return;
                              }

                              if (hasExtraWeight && extraWeight == null) {
                                setDialogState(() {
                                  errorText =
                                      'Ekstra ağırlık değerini girmelisin (örnek: 12.5).';
                                });
                                return;
                              }

                              if (hasExtraWeight &&
                                  (extraWeight! < _minExtraWeightKg ||
                                      extraWeight > _maxExtraWeightKg)) {
                                setDialogState(() {
                                  errorText =
                                      'Ekstra ağırlık $_minExtraWeightKg-$_maxExtraWeightKg kg aralığında olmalı.';
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
                              foregroundColor: AppColors.onAccent,
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
      labelStyle: TextStyle(color: _textMid),
      filled: true,
      fillColor: _cardSurfaceSoft,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
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
    const genders = <String>['Kadın', 'Erkek', 'Belirtmek istemiyorum'];

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
                  (item) => RadioGroup<String>(
                    groupValue: _gender,
                    onChanged: (value) => Navigator.of(context).pop(value),
                    child: RadioListTile<String>(
                      value: item,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: _accentPurple,
                      title: Text(
                        item,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: _textHigh),
                      ),
                    ),
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
      helpText: 'Doğum tarihi seç',
      cancelText: 'İptal',
      confirmText: 'Kaydet',
      builder: (context, child) {
        final baseTheme = Theme.of(context);
        final themed = baseTheme.copyWith(
          colorScheme: ColorScheme.dark(
            primary: _accentBlue,
            onPrimary: _textHigh,
            surface: _cardSurface,
            onSurface: _textHigh,
          ),
          dialogTheme: DialogThemeData(
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
            weekdayStyle: TextStyle(color: _textMid),
            dayStyle: TextStyle(color: _textHigh),
            yearStyle: TextStyle(color: _textHigh),
            dividerColor: AppColors.hairline,
            dayForegroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.onAccent;
              }
              return _textHigh;
            }),
            dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _accentPurple;
              }
              return Colors.transparent;
            }),
            todayForegroundColor: WidgetStatePropertyAll<Color>(_accentBlue),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
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
                          borderSide: BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: _accentPurple),
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
                              side: BorderSide(color: _border),
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
                                  errorText = 'Geçerli bir değer gir.';
                                });
                                return;
                              }
                              Navigator.of(context).pop(parsed);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentPurple,
                              foregroundColor: AppColors.onAccent,
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _textHigh,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12.0),
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
                          borderSide: BorderSide(color: _border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: _border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.0),
                          borderSide: BorderSide(color: _accentPurple),
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
                              side: BorderSide(color: _border),
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
                                  errorText = 'Geçerli bir değer gir.';
                                });
                                return;
                              }
                              Navigator.of(context).pop(parsed);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accentPurple,
                              foregroundColor: AppColors.onAccent,
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
          message = 'Hesabın Google ile bağlandı. Verilerin korundu.';
          break;
        case GoogleLinkStatus.conflict:
          if (mounted) {
            await _showAccountConflictDialog();
          }
          break;
        case GoogleLinkStatus.signedInExisting:
          message = 'Mevcut Google hesabınla giriş yapıldı.';
          _syncUserStreakAndStats();
          break;
        case GoogleLinkStatus.alreadyLinked:
        case GoogleLinkStatus.cancelled:
          break;
      }
    } on FirebaseAuthException catch (e) {
      message = e.message ?? 'Google ile bağlama başarısız oldu.';
    } catch (_) {
      message = 'Google ile bağlama başarısız oldu. Lütfen tekrar dene.';
    } finally {
      if (mounted) {
        setState(() => _isLinkingGoogle = false);
      }
    }
    if (message != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _showAccountConflictDialog() async {
    final signIn = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardSurface,
        title: Text(
          'Hesap zaten kullanımda',
          style: TextStyle(color: _textHigh),
        ),
        content: Text(
          'Bu Google hesabı daha önce başka bir profile bağlanmış. '
          'Bu hesapla giriş yaparsan şu anki anonim verilerin bu cihazda '
          'görünmez olur ve Google hesabındaki verilerin yüklenir.',
          style: TextStyle(color: _textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Hesapla giriş yap'),
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
        SnackBar(content: Text(e.message ?? 'Giriş başarısız oldu.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Giriş başarısız oldu.')));
    }
  }

  /// Firebase başlatılmamışsa (ör. test/çevrimdışı ilk açılış) `null`.
  User? _currentUserOrNull() {
    try {
      return FirebaseAuth.instance.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authUser =
        ref.watch(authUserProvider).valueOrNull ?? _currentUserOrNull();
    final isGoogleLinked =
        authUser?.providerData.any((p) => p.providerId == 'google.com') ??
        false;
    final headerName =
        (isGoogleLinked && (authUser?.displayName?.trim().isNotEmpty ?? false))
        ? authUser!.displayName!.trim()
        : 'Sporcu';

    final historyAsync = ref.watch(workoutHistoryProvider);

    return Scaffold(
      backgroundColor: _bgBottom,
      body: SafeArea(
        child: historyAsync.isLoading && !historyAsync.hasValue
            ? const Center(child: CircularProgressIndicator())
            : Builder(
                builder: (context) {
                  final sessions =
                      historyAsync.valueOrNull ??
                      const <WorkoutSessionSummary>[];
                  final summaries = _mapSessionsToSummaries(sessions);

                  final totalWorkouts = calculateTotalWorkouts(summaries);
                  final lastWorkoutDate = summaries.isEmpty
                      ? null
                      : calculateLastWorkoutDate(summaries);
                  final lastWorkoutDateLabel = lastWorkoutDate != null
                      ? formatDate(lastWorkoutDate)
                      : 'Henüz yok';
                  final lastWorkoutRelativeLabel = lastWorkoutDate != null
                      ? relativeDayLabel(lastWorkoutDate)
                      : '-';
                  final trend = calculateSevenDayTrend(summaries);
                  final compartmentDistribution =
                      calculateCompartmentDistribution(summaries);
                  final muscleDistribution = aggregateToRegions(
                    compartmentDistribution,
                  );
                  final balanceText = summaries.isEmpty
                      ? 'Henüz yeterli antrenman verisi yok.'
                      : calculateBalanceText(compartmentDistribution);

                  return RefreshIndicator(
                    onRefresh: _refreshSummaries,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpace.page,
                        AppSpace.xxl,
                        AppSpace.page,
                        AppSpace.xxl,
                      ),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Profil', style: AppText.pageTitle),
                            ),
                            IconButton(
                              key: const ValueKey('profile-settings-button'),
                              tooltip: 'Tercihler',
                              onPressed: () {
                                final ctx = _settingsKey.currentContext;
                                if (ctx != null) {
                                  Scrollable.ensureVisible(
                                    ctx,
                                    duration: const Duration(milliseconds: 350),
                                    curve: Curves.easeOutCubic,
                                  );
                                }
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                side: BorderSide(
                                  color: AppColors.hairline,
                                  width: 1,
                                ),
                              ),
                              icon: Icon(
                                Icons.settings_outlined,
                                size: 20,
                                color: AppColors.textMid,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.xl),
                        _ProfileHeroCard(
                          username: headerName,
                          email: isGoogleLinked ? authUser?.email : null,
                          photoUrl: isGoogleLinked ? authUser?.photoURL : null,
                          totalWorkouts: _syncedTotalWorkouts > totalWorkouts
                              ? _syncedTotalWorkouts
                              : totalWorkouts,
                          totalSeconds: sessions.fold<int>(
                            0,
                            (sum, s) => sum + s.durationSeconds,
                          ),
                          streak:
                              _syncedStreak > calculateWorkoutStreak(summaries)
                              ? _syncedStreak
                              : calculateWorkoutStreak(summaries),
                          targetWorkoutsPerWeek: _targetWorkoutsPerWeek,
                          lastWorkoutLabel: lastWorkoutRelativeLabel == '-'
                              ? lastWorkoutDateLabel
                              : lastWorkoutRelativeLabel,
                          onStreakTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.streakDetails,
                          ),
                          onHistoryTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.workoutHistory,
                          ),
                        ),
                        const SizedBox(height: AppSpace.section),
                        const MuscleRecoveryCard(),
                        const SizedBox(height: AppSpace.section),
                        TrendCard(
                          currentSevenDayLoad: trend.current,
                          previousSevenDayLoad: trend.previous,
                        ),
                        const SizedBox(height: AppSpace.section),
                        if (muscleDistribution.isNotEmpty) ...[
                          MuscleDistributionCard(
                            distribution: muscleDistribution,
                          ),
                          const SizedBox(height: AppSpace.section),
                        ],
                        BalanceCard(message: balanceText),
                        const SizedBox(height: AppSpace.section),
                        PersonalRecordsCard(
                          records: _personalRecords,
                          onAddRecord: _showAddPersonalRecordDialog,
                          onDeleteRecord: _deletePersonalRecord,
                        ),
                        const SizedBox(height: AppSpace.section),
                        BodyMetricsCard(
                          heightCm: _heightCm,
                          weightKg: _weightKg,
                          gender: _gender,
                          birthDateLabel: _birthDate == null
                              ? 'Seçilmedi'
                              : '${formatDate(_birthDate!)} (${calculateAge(_birthDate!)} yaş)',
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
                        const SizedBox(height: AppSpace.section),
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
                            title: 'Haftalık Hedef Antrenman',
                            unit: 'adet',
                            currentValue: _targetWorkoutsPerWeek,
                            onApply: (value) => _targetWorkoutsPerWeek = value,
                          ),
                        ),
                        const SizedBox(height: AppSpace.section),
                        _GoogleLinkCard(
                          isLinked: isGoogleLinked,
                          isLoading: _isLinkingGoogle,
                          onPressed: _linkGoogleAccount,
                        ),
                        const SizedBox(height: AppSpace.section),
                        _SettingsSection(
                          key: _settingsKey,
                          onHistoryTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.workoutHistory,
                          ),
                          onAthleteTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.athleteProfile,
                          ),
                          onWeeklyGoalTap: () => Navigator.pushNamed(
                            context,
                            AppRoutes.weeklyGoal,
                          ),
                        ),
                        const SizedBox(height: AppSpace.section),
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

/// Profil kimlik kartı: zümrüt halkalı avatar, gerçek ad, seviye ve
/// Antrenman / Toplam Süre / Seri metrik kutusu.
class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.username,
    required this.email,
    required this.photoUrl,
    required this.totalWorkouts,
    required this.totalSeconds,
    required this.streak,
    required this.targetWorkoutsPerWeek,
    required this.lastWorkoutLabel,
    required this.onStreakTap,
    required this.onHistoryTap,
  });

  final String username;
  final String? email;
  final String? photoUrl;
  final int totalWorkouts;
  final int totalSeconds;
  final int streak;
  final int targetWorkoutsPerWeek;
  final String lastWorkoutLabel;
  final VoidCallback onStreakTap;
  final VoidCallback onHistoryTap;

  String get _level {
    if (totalWorkouts >= 60) return 'İleri Seviye';
    if (totalWorkouts >= 15) return 'Orta Seviye';
    return 'Başlangıç Seviyesi';
  }

  String get _initials {
    final parts = username
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    final last = parts.length > 1 ? parts.last.characters.first : '';
    return trUpper('$first$last');
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoUrl != null && photoUrl!.isNotEmpty;
    final hours = totalSeconds / 3600;
    return AppSurface(
      radius: AppRadius.card + 4,
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.xxl,
        AppSpace.xl,
        AppSpace.xl,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: AppColors.hairline,
                    width: AppSpace.hairline,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusDot(color: AppColors.emerald),
                    const SizedBox(width: 6),
                    Text(
                      trUpper('Aktif üye'),
                      style: AppText.sectionLabel.copyWith(
                        fontSize: 10,
                        color: AppColors.textHigh,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'Son: $lastWorkoutLabel',
                style: AppText.caption.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.emerald, width: 2.5),
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: AppColors.surfaceRaised,
                  backgroundImage: hasPhoto ? NetworkImage(photoUrl!) : null,
                  child: hasPhoto
                      ? null
                      : Text(
                          _initials,
                          style: AppText.metricL.copyWith(
                            fontSize: 28,
                            color: AppColors.textHigh,
                          ),
                        ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 2,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.emerald,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            username,
            key: const ValueKey('profile-name'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.pageTitle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            email != null && email!.isNotEmpty
                ? '$_level · ${email!}'
                : '$_level · Hibrit Antrenman',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppText.caption.copyWith(
              fontSize: 13,
              color: AppColors.textMid,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.hairline, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.track_changes_outlined,
                  size: 15,
                  color: AppColors.activation,
                ),
                const SizedBox(width: 6),
                Text(
                  'Hedef: Haftada $targetWorkoutsPerWeek antrenman',
                  style: AppText.caption.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHigh,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.hairline,
                width: AppSpace.hairline,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      key: const ValueKey('profile-metric-workouts'),
                      value: '$totalWorkouts',
                      label: 'Antrenman',
                      onTap: onHistoryTap,
                    ),
                  ),
                  const Hairline.vertical(),
                  Expanded(
                    child: _HeroMetric(
                      key: const ValueKey('profile-metric-duration'),
                      value: hours >= 10
                          ? hours.toStringAsFixed(0)
                          : hours.toStringAsFixed(1),
                      unit: 'sa',
                      label: 'Toplam Süre',
                      onTap: onHistoryTap,
                    ),
                  ),
                  const Hairline.vertical(),
                  Expanded(
                    child: _HeroMetric(
                      key: const ValueKey('profile-metric-streak'),
                      value: '$streak',
                      unit: 'Gün',
                      label: 'Seri',
                      color: streak > 0 ? AppColors.activation : null,
                      onTap: onStreakTap,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    super.key,
    required this.value,
    required this.label,
    required this.onTap,
    this.unit,
    this.color,
  });

  final String value;
  final String? unit;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textHigh;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: value,
                    style: AppText.metricM.copyWith(color: c),
                  ),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: AppText.unit.copyWith(
                        color: color ?? AppColors.textMid,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppText.caption),
        ],
      ),
    );
  }
}

/// Tercihler & Hesap: tema anahtarı ve kısayollar.
class _SettingsSection extends ConsumerWidget {
  const _SettingsSection({
    super.key,
    required this.onHistoryTap,
    required this.onAthleteTap,
    required this.onWeeklyGoalTap,
  });

  final VoidCallback onHistoryTap;
  final VoidCallback onAthleteTap;
  final VoidCallback onWeeklyGoalTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return _GroupSection(
      label: 'Tercihler & Hesap',
      children: [
        _SettingsRow(
          icon: Icons.straighten_outlined,
          label: 'Sporcu Profili & Ölçüler',
          onTap: onAthleteTap,
        ),
        _SettingsRow(
          icon: Icons.flag_outlined,
          label: 'Haftalık Hedef',
          onTap: onWeeklyGoalTap,
        ),
        _SettingsRow(
          icon: Icons.history_outlined,
          label: 'Antrenman Geçmişi',
          onTap: onHistoryTap,
        ),
        _SettingsRow(
          icon: Icons.dark_mode_outlined,
          label: 'Koyu Tema (Dark Mode)',
          trailing: Switch(
            key: const ValueKey('profile-dark-mode-switch'),
            value: isDark,
            activeThumbColor: AppColors.onAccent,
            activeTrackColor: AppColors.ring,
            inactiveThumbColor: AppColors.surface,
            inactiveTrackColor: AppColors.hairlineStrong,
            trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
            onChanged: (value) =>
                ref.read(themeModeProvider.notifier).setDark(value),
          ),
          onTap: () => ref.read(themeModeProvider.notifier).setDark(!isDark),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: 12,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: AppColors.textMid),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                label,
                style: AppText.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
          ],
        ),
      ),
    );
  }
}

/// iOS "inset grouped" stilinde bölüm: etiket + hairline ile ayrılmış satırlar.
class _GroupSection extends StatelessWidget {
  const _GroupSection({
    required this.label,
    required this.children,
    this.trailing,
  });

  final String label;
  final List<Widget> children;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          label,
          trailing: trailing,
          padding: const EdgeInsets.only(left: 4, bottom: AppSpace.sm),
        ),
        AppSurface(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) const Hairline(indent: AppSpace.lg),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GroupRow extends StatelessWidget {
  const _GroupRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final chevron = onTap != null;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: 15,
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: AppText.bodyMuted)),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
            if (chevron) ...[
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: AppColors.textMuted,
              ),
            ],
          ],
        ),
      ),
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
    return _GroupSection(
      label: 'Vücut',
      children: [
        _GroupRow(
          label: 'Boy',
          value: '${heightCm.toStringAsFixed(1)} cm',
          onTap: onEditHeight,
        ),
        _GroupRow(
          label: 'Kilo',
          value: '${weightKg.toStringAsFixed(1)} kg',
          onTap: onEditWeight,
        ),
        _GroupRow(label: 'Cinsiyet', value: gender, onTap: onEditGender),
        _GroupRow(
          label: 'Doğum tarihi',
          value: birthDateLabel,
          onTap: onEditBirthDate,
        ),
      ],
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
    return _GroupSection(
      label: 'Hesap',
      children: [
        InkWell(
          onTap: disabled ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.lg,
              vertical: 15,
            ),
            child: Row(
              children: [
                if (isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.textMid,
                    ),
                  )
                else
                  Icon(
                    isLinked
                        ? Icons.check_circle_outline_rounded
                        : Icons.link_rounded,
                    size: 18,
                    color: isLinked ? AppColors.emerald : AppColors.textMid,
                  ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(
                    isLoading
                        ? 'Bağlanıyor…'
                        : isLinked
                        ? 'Google hesabı bağlı'
                        : 'Google ile hesabını bağla',
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                if (!disabled)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
              ],
            ),
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
    final lastLabel = lastWorkoutRelativeLabel == '-'
        ? lastWorkoutDate
        : lastWorkoutRelativeLabel;
    return AppSurface(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.xl),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _TapMetric(
                onTap: onHistoryTap,
                child: MetricValue(
                  value: '$totalWorkouts',
                  label: 'Antrenman',
                  style: AppText.metricL,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
              ),
            ),
            const Hairline.vertical(),
            Expanded(
              child: _TapMetric(
                onTap: onStreakTap,
                child: MetricValue(
                  value: '$streak',
                  unit: 'gün',
                  label: 'Seri',
                  style: AppText.metricL,
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
              ),
            ),
            const Hairline.vertical(),
            Expanded(
              child: MetricValue(
                value: lastLabel,
                label: 'Son antrenman',
                style: AppText.metricS,
                crossAxisAlignment: CrossAxisAlignment.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TapMetric extends StatelessWidget {
  const _TapMetric({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: Center(child: child),
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
    return _GroupSection(
      label: 'Hedefler',
      children: [
        _GroupRow(
          label: 'Hedef kilo',
          value: '${goalWeightKg.toStringAsFixed(1)} kg',
          onTap: onEditGoalWeight,
        ),
        _GroupRow(
          label: 'Haftalık hedef',
          value: '$targetWorkoutsPerWeek antrenman',
          onTap: onEditTargetWorkouts,
        ),
      ],
    );
  }
}

class MuscleDistributionCard extends StatelessWidget {
  const MuscleDistributionCard({super.key, required this.distribution});

  final Map<MuscleRegion, double> distribution;

  @override
  Widget build(BuildContext context) {
    final sorted = distribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<double>(0, (a, e) => a + e.value);
    final max = sorted.isEmpty ? 0.0 : sorted.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          'Kas dağılımı',
          padding: EdgeInsets.only(left: 4, bottom: AppSpace.sm),
        ),
        AppSurface(
          child: Column(
            children: [
              for (final (i, item) in sorted.indexed) ...[
                if (i > 0) const SizedBox(height: 14),
                Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: Text(
                        item.key.label,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: max <= 0 ? 0 : item.value / max,
                          minHeight: 3,
                          backgroundColor: AppColors.hairline,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            i == 0
                                ? AppColors.textHigh
                                : AppColors.chartNeutral,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 52,
                      child: Text(
                        total <= 0
                            ? '-'
                            : '%${(item.value / total * 100).round()}',
                        textAlign: TextAlign.right,
                        style: AppText.metricS.copyWith(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
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
    final addButton = TextButton.icon(
      onPressed: onAddRecord,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textMid,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: const Size(0, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: const Icon(Icons.add_rounded, size: 16),
      label: Text(
        'Ekle',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textMid,
        ),
      ),
    );

    if (records.isEmpty) {
      return _GroupSection(
        label: 'Kişisel rekorlar',
        trailing: addButton,
        children: [
          Padding(
            padding: EdgeInsets.all(AppSpace.lg),
            child: Text(
              'Henüz rekor eklenmedi. Hareket seçip rekorunu kaydet.',
              style: AppText.bodyMuted,
            ),
          ),
        ],
      );
    }

    return _GroupSection(
      label: 'Kişisel rekorlar',
      trailing: addButton,
      children: [
        for (final (index, record) in records.indexed)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, 6, 4, 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    record.exerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${record.recordValue}',
                        style: AppText.metricS,
                      ),
                      TextSpan(
                        text: record.isTimed ? ' sn' : ' tekrar',
                        style: AppText.unit,
                      ),
                      if (record.hasExtraWeight && record.extraWeightKg != null)
                        TextSpan(
                          text:
                              '  +${record.extraWeightKg!.toStringAsFixed(1)} kg',
                          style: AppText.unit,
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => onDeleteRecord(index),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                  tooltip: 'Sil',
                ),
              ],
            ),
          ),
      ],
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
    final up = currentSevenDayLoad >= previousSevenDayLoad;
    final delta = previousSevenDayLoad <= 0
        ? null
        : (currentSevenDayLoad - previousSevenDayLoad) /
              previousSevenDayLoad *
              100;
    final trendColor = up ? AppColors.emerald : AppColors.textMid;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          'Yük trendi',
          padding: const EdgeInsets.only(left: 4, bottom: AppSpace.sm),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 12,
                color: trendColor,
              ),
              const SizedBox(width: 2),
              Text(
                delta == null
                    ? (up ? 'Artış' : 'Düşüş')
                    : '%${delta.abs().round()} ${up ? 'artış' : 'düşüş'}',
                style: AppText.caption.copyWith(color: trendColor),
              ),
            ],
          ),
        ),
        AppSurface(
          child: IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: MetricValue(
                    value: currentSevenDayLoad.toStringAsFixed(1),
                    unit: 'MLI',
                    label: 'Son 7 gün',
                    style: AppText.metricL,
                  ),
                ),
                const Hairline.vertical(),
                const SizedBox(width: AppSpace.xl),
                Expanded(
                  child: MetricValue(
                    value: previousSevenDayLoad.toStringAsFixed(1),
                    unit: 'MLI',
                    label: 'Önceki 7 gün',
                    style: AppText.metricL.copyWith(color: AppColors.textMid),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return _GroupSection(
      label: 'Denge',
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Text(message, style: AppText.bodyMuted),
        ),
      ],
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

/// Özetlerin kompartıman yüklerini toplar (eski kayıtlar bölünerek okunur).
Map<MuscleCompartment, double> calculateCompartmentDistribution(
  List<WorkoutSummaryEntry> summaries,
) {
  final result = <MuscleCompartment, double>{};
  for (final summary in summaries) {
    summary.compartmentLoad.forEach((c, value) {
      result[c] = (result[c] ?? 0) + value;
    });
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

/// İtiş / çekiş dengesi mesajı (sınıflandırma: [movementPatternOf]).
String calculateBalanceText(Map<MuscleCompartment, double> distribution) {
  return computePushPullBalance(distribution).turkishMessage;
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
    return 'Bugün';
  }
  if (diff == 1) {
    return 'Dün';
  }
  return '$diff gün önce';
}
