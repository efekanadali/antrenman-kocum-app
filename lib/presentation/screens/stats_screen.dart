// lib/presentation/screens/stats_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:calisthenics_app/domain/models/custom_program.dart';
import 'package:calisthenics_app/presentation/providers/custom_program_provider.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/theme/app_theme.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programs = ref.watch(customProgramProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Ekran Başlığı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 14.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Antrenman Programları',
                            style: TextStyle(
                              color: AppColors.textHigh,
                              fontSize: 22.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 3.0),
                          Text(
                            'Nordic rutinler ve özel sporcu planları',
                            style: TextStyle(
                              color: AppColors.textMid,
                              fontSize: 13.0,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hazır Programlar Başlığı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 8.0),
                child: Row(
                  children: const [
                    Text(
                      'Hazır Rutinler',
                      style: TextStyle(
                        color: AppColors.textHigh,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hazır Kart 1: Evde Antrenman
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: _ProgramTypeCard(
                  title: 'Evde Antrenman',
                  subtitle: 'Ekipmansız saf vücut ağırlığı ve kaldıraç planı.',
                  schedule: '3 Gün / Hafta',
                  duration: '35-45 dk',
                  location: 'Ev & Park',
                  icon: Icons.home_rounded,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.trainingProgram),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 12.0),
            ),

            // Hazır Kart 2: Spor Salonu
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: _ProgramTypeCard(
                  title: 'Spor Salonu',
                  subtitle: 'Barfiks barı, paralel bar ve ağırlık yeleği odaklı.',
                  schedule: '3 Gün / Hafta',
                  duration: '45-60 dk',
                  location: 'Spor Salonu',
                  icon: Icons.fitness_center_rounded,
                  onTap: () =>
                      Navigator.pushNamed(context, AppRoutes.trainingProgram),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24.0),
            ),

            // "Senin Planın" Hero Kartı
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: _CustomPlanHeroCard(),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24.0),
            ),

            // "Programlarım" Bölümü Başlığı
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 0.0, 20.0, 10.0),
                child: Row(
                  children: [
                    const Text(
                      'Programlarım',
                      style: TextStyle(
                        color: AppColors.textHigh,
                        fontSize: 15.0,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const Spacer(),
                    programs.maybeWhen(
                      data: (items) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(
                            color: AppColors.border,
                            width: 1.0,
                          ),
                        ),
                        child: Text(
                          '${items.length} Özel Plan',
                          style: const TextStyle(
                            color: AppColors.textMid,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),

            // Özel Programlar Listesi
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: programs.when(
                  data: (items) {
                    if (items.isEmpty) {
                      return const _EmptyProgramCard();
                    }
                    return Column(
                      children: [
                        for (final program in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: _CustomProgramCard(program: program),
                          ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.volcanic,
                      ),
                    ),
                  ),
                  error: (err, _) => _ErrorProgramCard(message: '$err'),
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 36.0),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          showBottomNav ? const AppBottomNav(selectedIndex: 2) : null,
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
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: AppColors.volcanic,
                        size: 22.0,
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: AppColors.textHigh,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            subtitle,
                            style: const TextStyle(
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
                        border: Border.all(
                          color: AppColors.border,
                          width: 1.0,
                        ),
                      ),
                      child: const Icon(
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
                      child: const Icon(
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
                                  color: AppColors.volcanic.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6.0),
                                ),
                                child: const Text(
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
                          const Text(
                            'Senin Planın',
                            style: TextStyle(
                              color: AppColors.textHigh,
                              fontSize: 17.0,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3.0),
                          const Text(
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
                      foregroundColor: Colors.white,
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
            side: const BorderSide(color: AppColors.border, width: 1.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
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
                  style: const TextStyle(
                    color: AppColors.textMid,
                    fontSize: 13.5,
                  ),
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
                      icon: const Icon(Icons.delete_outline_rounded, size: 16.0),
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
                Container(
                  width: 3.5,
                  color: AppColors.volcanic,
                ),
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
                          child: const Icon(
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
                                style: const TextStyle(
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

class _EmptyProgramCard extends StatelessWidget {
  const _EmptyProgramCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: const [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.textMuted,
            size: 20.0,
          ),
          SizedBox(width: 12.0),
          Expanded(
            child: Text(
              'Henüz kayıtlı özel programın yok. Yukarıdaki "Senin Planın" ile ilk planını oluşturabilirsin.',
              style: TextStyle(
                color: AppColors.textMid,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
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
        style: const TextStyle(
          color: Color(0xFFEF4444),
          fontSize: 13.0,
        ),
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
        style: const TextStyle(
          color: AppColors.textMid,
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
