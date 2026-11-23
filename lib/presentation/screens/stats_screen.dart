// lib/presentation/screens/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/presentation/providers/custom_program_provider.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';
import 'package:calisthenics_app/domain/enums/exercise_type.dart';
import 'package:calisthenics_app/domain/enums/muscle_compartment.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/domain/models/workout_session_summary.dart';
import 'package:calisthenics_app/domain/services/program_preview.dart';
import 'package:calisthenics_app/presentation/providers/exercise_list_provider.dart';
import 'package:calisthenics_app/presentation/providers/muscle_recovery_provider.dart';
import 'package:calisthenics_app/presentation/providers/workout_history_provider.dart';
import 'package:calisthenics_app/presentation/screens/custom_program_day_session_screen.dart';
import 'package:calisthenics_app/presentation/widgets/ui/ui.dart';

class StatsScreen extends ConsumerStatefulWidget {
  const StatsScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  ConsumerState<StatsScreen> createState() => _StatsScreenState();
}

const List<String> _dayShort = [
  'Pzt',
  'Sal',
  'Çar',
  'Per',
  'Cum',
  'Cmt',
  'Paz',
];
const List<String> _monthUpper = [
  'OCAK',
  'ŞUBAT',
  'MART',
  'NİSAN',
  'MAYIS',
  'HAZİRAN',
  'TEMMUZ',
  'AĞUSTOS',
  'EYLÜL',
  'EKİM',
  'KASIM',
  'ARALIK',
];

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

class _StatsScreenState extends ConsumerState<StatsScreen> {
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final programs = ref.watch(customProgramProvider);
    final sessions =
        ref.watch(workoutHistoryProvider).valueOrNull ??
        const <WorkoutSessionSummary>[];
    final catalog =
        ref.watch(exerciseListProvider).valueOrNull ?? const <Exercise>[];
    final resolver = ref.watch(exerciseMliResolverProvider).valueOrNull;

    final today = _dayOf(DateTime.now());
    final monday = today.subtract(Duration(days: today.weekday - 1));
    final weekDays = [
      for (var i = 0; i < 7; i++) monday.add(Duration(days: i)),
    ];
    final selected = _selectedDay ?? today;
    final doneDays = {for (final s in sessions) _dayOf(s.completedAt)};
    final doneThisWeek = doneDays.where((d) => !d.isBefore(monday)).length;
    final weekOfMonth = ((today.day - 1) ~/ 7) + 1;

    final items = programs.valueOrNull ?? const <CustomProgram>[];
    CustomProgram? active;
    for (final p in items) {
      if (active == null || p.createdAt.isAfter(active.createdAt)) active = p;
    }
    final others = [
      for (final p in items)
        if (!identical(p, active)) p,
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.page,
            AppSpace.lg,
            AppSpace.page,
            AppSpace.section,
          ),
          children: [
            Text('Program', style: AppText.pageTitle),
            const SizedBox(height: AppSpace.xl),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_monthUpper[today.month - 1]} · $weekOfMonth. HAFTA',
                        style: AppText.sectionLabel.copyWith(
                          color: AppColors.activation,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Haftalık antrenman planın',
                        style: AppText.body.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
                Semantics(
                  button: true,
                  label: 'Yeni program oluştur',
                  child: Material(
                    color: AppColors.activation,
                    shape: const CircleBorder(),
                    child: InkWell(
                      key: const ValueKey('program-add'),
                      customBorder: const CircleBorder(),
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.customPlan),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(
                          Icons.add_rounded,
                          size: 26,
                          color: AppColors.onActivation,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            Row(
              children: [
                for (var i = 0; i < 7; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _DayPill(
                      label: _dayShort[i],
                      day: weekDays[i].day,
                      selected: weekDays[i] == selected,
                      isToday: weekDays[i] == today,
                      done: doneDays.contains(weekDays[i]),
                      onTap: () => setState(() => _selectedDay = weekDays[i]),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpace.xxl),
            if (programs.isLoading && !programs.hasValue)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (programs.hasError && !programs.hasValue)
              _ErrorProgramCard(message: '${programs.error}')
            else if (active == null)
              _CustomPlanHeroCard()
            else ...[
              _ActiveProgramCard(
                program: active,
                catalog: catalog,
                doneThisWeek: doneThisWeek,
              ),
              const SizedBox(height: AppSpace.section),
              SectionHeader(
                'Haftalık seanslar',
                trailing: Text(
                  '${active.days.length} Antrenman',
                  style: AppText.caption.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMid,
                  ),
                ),
              ),
              for (var i = 0; i < active.days.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpace.md),
                _SessionCard(
                  programName: active.name,
                  day: active.days[i],
                  catalog: catalog,
                  preview: resolver == null
                      ? null
                      : estimateProgramPreview(
                          active.days[i].exercises,
                          resolver,
                        ),
                  isNext:
                      active.days.isNotEmpty &&
                      i == doneThisWeek % active.days.length,
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              Align(
                alignment: Alignment.centerLeft,
                child: GhostButton(
                  label: 'Program detayı',
                  icon: Icons.tune_rounded,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    AppRoutes.customProgramDetail,
                    arguments: active,
                  ),
                ),
              ),
            ],
            if (others.isNotEmpty) ...[
              const SizedBox(height: AppSpace.section),
              SectionHeader(
                'Diğer programlarım',
                trailing: Text(
                  '${others.length} Özel Plan',
                  style: AppText.caption.copyWith(color: AppColors.textMid),
                ),
              ),
              for (final program in others)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _CustomProgramCard(program: program),
                ),
            ],
            const SizedBox(height: AppSpace.section),
            const SectionHeader('Hazır rutinler'),
            _ProgramTypeCard(
              title: 'Evde Antrenman',
              subtitle: 'Ekipmansız saf vücut ağırlığı ve kaldıraç planı.',
              schedule: '3 Gün / Hafta',
              duration: '35-45 dk',
              location: 'Ev & Park',
              icon: Icons.home_outlined,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.trainingProgram),
            ),
            const SizedBox(height: 12.0),
            _ProgramTypeCard(
              title: 'Spor Salonu',
              subtitle: 'Barfiks barı, paralel bar ve ağırlık yeleği odaklı.',
              schedule: '3 Gün / Hafta',
              duration: '45-60 dk',
              location: 'Spor Salonu',
              icon: Icons.fitness_center_outlined,
              onTap: () =>
                  Navigator.pushNamed(context, AppRoutes.trainingProgram),
            ),
          ],
        ),
      ),
      bottomNavigationBar: widget.showBottomNav
          ? const AppBottomNav(selectedIndex: 2)
          : null,
    );
  }
}

class _DayPill extends StatelessWidget {
  const _DayPill({
    required this.label,
    required this.day,
    required this.selected,
    required this.isToday,
    required this.done,
    required this.onTap,
  });

  final String label;
  final int day;
  final bool selected;
  final bool isToday;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onAccent : AppColors.textHigh;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 64,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: selected
              ? null
              : Border.all(
                  color: isToday ? AppColors.textMid : AppColors.hairline,
                  width: 1,
                ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: AppText.caption.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? fg : AppColors.textMuted,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$day',
              style: AppText.metricS.copyWith(fontSize: 17, color: fg),
            ),
            const SizedBox(height: 3),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done
                    ? (selected ? fg : AppColors.emerald)
                    : Colors.transparent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bir program gününün baskın bölgeleri (kompartıman ağırlıklarından).
List<MuscleRegion> _dayRegions(
  CustomProgramDay day,
  Map<String, Exercise> byId,
) {
  final totals = <MuscleRegion, double>{};
  for (final item in day.exercises) {
    final exercise = byId[item.exerciseId];
    if (exercise == null) continue;
    exercise.compartmentWeights.forEach((c, w) {
      totals[c.region] = (totals[c.region] ?? 0) + w * item.sets;
    });
  }
  final sorted = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return [for (final e in sorted.take(3)) e.key];
}

class _ActiveProgramCard extends StatelessWidget {
  const _ActiveProgramCard({
    required this.program,
    required this.catalog,
    required this.doneThisWeek,
  });

  final CustomProgram program;
  final List<Exercise> catalog;
  final int doneThisWeek;

  String _typeLabel() {
    final byId = {for (final e in catalog) e.id: e};
    final types = <ExerciseType>{
      for (final day in program.days)
        for (final item in day.exercises)
          if (byId[item.exerciseId] case final e?) e.type,
    };
    if (types.length > 1) return 'Kalistenik & Ağırlık';
    if (types.contains(ExerciseType.bodybuilding)) return 'Vücut Geliştirme';
    return 'Kalistenik';
  }

  @override
  Widget build(BuildContext context) {
    final target = program.days.isEmpty ? 1 : program.days.length;
    final done = doneThisWeek.clamp(0, target);
    final week = (DateTime.now().difference(program.createdAt).inDays ~/ 7) + 1;
    return AppSurface(
      key: const ValueKey('program-active-card'),
      radius: AppRadius.card + 4,
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.customProgramDetail,
        arguments: program,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trUpper('Aktif program'),
                      style: AppText.sectionLabel.copyWith(
                        color: AppColors.activation,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      program.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.pageTitle.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${program.days.length} Gün/Hafta · ${_typeLabel()}',
                      style: AppText.bodyMuted.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
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
                    Icon(
                      Icons.bolt_outlined,
                      size: 15,
                      color: AppColors.activation,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$week. Hafta',
                      style: AppText.caption.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHigh,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Haftalık İlerleme',
                  style: AppText.caption.copyWith(
                    fontSize: 13,
                    color: AppColors.textMid,
                  ),
                ),
              ),
              Text(
                '$done / $target Tamamlandı',
                style: AppText.metricS.copyWith(fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          SegmentedBar(
            value: done / target,
            segments: target,
            height: 6,
            gap: 6,
            color: AppColors.ring,
          ),
        ],
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.programName,
    required this.day,
    required this.catalog,
    required this.preview,
    required this.isNext,
  });

  final String programName;
  final CustomProgramDay day;
  final List<Exercise> catalog;
  final ProgramPreview? preview;
  final bool isNext;

  int get _minutes {
    var seconds = 0;
    for (final item in day.exercises) {
      final work = item.isTimed ? item.value : item.value * 3;
      seconds += item.sets * (work + 90);
    }
    return (seconds / 60).round();
  }

  void _start(BuildContext context) {
    Navigator.pushNamed(
      context,
      AppRoutes.customProgramDaySession,
      arguments: CustomProgramDaySessionArgs(
        programName: programName,
        day: day,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final e in catalog) e.id: e};
    final regions = _dayRegions(day, byId);
    final regionText = regions.isEmpty
        ? '${day.exercises.length} hareket'
        : regions.map((r) => r.label).join(', ');
    final mli = preview?.totalMli.round();
    final meta = [
      '${day.exercises.length} hareket',
      '$_minutes dk',
      if (mli != null && mli > 0) '$mli MLI',
    ].join(' · ');

    return AppSurface(
      padding: EdgeInsets.zero,
      onTap: () => _start(context),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: isNext ? AppColors.emerald : Colors.transparent,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(AppRadius.card),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.md,
                  AppSpace.lg,
                  AppSpace.lg,
                  AppSpace.lg,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isNext
                            ? AppColors.emerald.withValues(alpha: 0.12)
                            : AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.fitness_center_outlined,
                        size: 20,
                        color: isNext ? AppColors.emerald : AppColors.textMid,
                      ),
                    ),
                    const SizedBox(width: AppSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  day.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppText.cardTitle,
                                ),
                              ),
                              if (isNext) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.emerald,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Hazır',
                                    style: AppText.caption.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            regionText,
                            style: AppText.caption.copyWith(
                              fontSize: 13,
                              color: AppColors.textMid,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            meta,
                            style: AppText.caption.copyWith(
                              fontSize: 13,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    if (isNext)
                      Material(
                        color: AppColors.accent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => _start(context),
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 24,
                              color: AppColors.onAccent,
                            ),
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 22,
                        color: AppColors.textMuted,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hazır Rutin Kartı (Ev / Salon) - Mat Grafit Yüzey ve Volkanik Turuncu Aksan
class _ProgramTypeCard extends StatelessWidget {
  const _ProgramTypeCard({
    required this.title,
    required this.subtitle,
    required this.schedule,
    required this.duration,
    required this.location,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String schedule;
  final String duration;
  final String location;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44.0,
                      height: 44.0,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: Icon(icon, color: AppColors.volcanic, size: 22.0),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: AppColors.textHigh,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    // Aksan Butonu / Oku
                    Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceSoft,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: AppColors.border, width: 1.0),
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.volcanic,
                        size: 16.0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: [
                    _InfoPill(label: schedule),
                    _InfoPill(label: duration),
                    _InfoPill(label: location),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Senin Planın / Oluştur" - Volkanik Turuncu Vurgulu Mat Hero Kartı
class _CustomPlanHeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.volcanic.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () => Navigator.pushNamed(context, AppRoutes.customPlan),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46.0,
                      height: 46.0,
                      decoration: BoxDecoration(
                        color: AppColors.volcanic.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(
                          color: AppColors.volcanic.withValues(alpha: 0.35),
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.volcanic,
                        size: 24.0,
                      ),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7.0,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.volcanic.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: Text(
                                  'KİŞİSEL MİMARİ',
                                  style: TextStyle(
                                    color: AppColors.volcanic,
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            'Senin Planın',
                            style: TextStyle(
                              color: AppColors.textHigh,
                              fontSize: 17.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          Text(
                            'Gün, egzersiz ve set sayılarını kendi hedefine göre baştan yarat.',
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),
                SizedBox(
                  width: double.infinity,
                  height: 42.0,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.customPlan),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.volcanic,
                      foregroundColor: AppColors.onAccent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 18.0),
                    label: const Text(
                      'Yeni Plan Oluştur',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
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

/// Özel Program Kartı - Sol Kenar Çizgili, Hap Etiketli Modern Nordic Kart
class _CustomProgramCard extends ConsumerWidget {
  const _CustomProgramCard({required this.program});

  final CustomProgram program;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
            side: BorderSide(color: AppColors.border, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Programı Sil',
                  style: TextStyle(
                    color: AppColors.textHigh,
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8.0),
                Text(
                  '"${program.name}" programını silmek istediğine emin misin?',
                  style: TextStyle(color: AppColors.textMid, fontSize: 13.5),
                ),
                const SizedBox(height: 20.0),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textMid,
                      ),
                      child: const Text('Vazgeç'),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(context).pop(true),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 16.0,
                      ),
                      label: const Text('Sil'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
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

    if (shouldDelete != true) {
      return;
    }

    await ref.read(customProgramProvider.notifier).removeProgram(program.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.customProgramDetail,
            arguments: program,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Sol Kenar 3.5px Volkanik Çizgi
                Container(width: 3.5, color: AppColors.volcanic),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 42.0,
                          height: 42.0,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceSoft,
                            borderRadius: BorderRadius.circular(10.0),
                            border: Border.all(
                              color: AppColors.border,
                              width: 1.0,
                            ),
                          ),
                          child: Icon(
                            Icons.event_note_rounded,
                            color: AppColors.volcanic,
                            size: 20.0,
                          ),
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                program.name,
                                style: TextStyle(
                                  color: AppColors.textHigh,
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6.0),
                              Wrap(
                                spacing: 6.0,
                                runSpacing: 6.0,
                                children: [
                                  _InfoPill(label: '${program.daysCount} Gün'),
                                  _InfoPill(
                                    label: '${program.totalExercises} Egzersiz',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Sadeleştirilmiş Çöp Kutusu İkonu
                        IconButton(
                          onPressed: () => _confirmDelete(context, ref),
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: AppColors.textMuted,
                          iconSize: 20.0,
                          splashRadius: 20.0,
                          padding: const EdgeInsets.all(6.0),
                          constraints: const BoxConstraints(),
                          tooltip: 'Programı sil',
                        ),
                      ],
                    ),
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

class _ErrorProgramCard extends StatelessWidget {
  const _ErrorProgramCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Text(
        'Programlar yüklenemedi: $message',
        style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13.0),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.5),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textMid,
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
