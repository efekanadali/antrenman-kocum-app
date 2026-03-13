// lib/presentation/screens/training_program_screen.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/presentation/screens/training_day_session_screen.dart';

class TrainingProgramScreen extends StatelessWidget {
  const TrainingProgramScreen({super.key});

  static const List<Map<String, dynamic>> _programData = [
    {
      "level": "evde",
      "week": 1,
      "days": [
        {
          "name": "Gün 1",
          "focus": "İtiş + Karın",
          "warmup": [
            "Eklem isinmasi 3 dk",
            "Hafif yuruyus + kol acma 2 dk",
            "Duvara itis 2 x 10"
          ],
          "workout": [
            {
              "exercise": "Diz Ustu Sinav",
              "sets": "3",
              "reps_or_time": "8-12 tekrar",
              "rest": "60 sn",
              "progression": "Tam sinava gec",
              "regression": "Egimli sinav"
            },
            {
              "exercise": "Sandalyeye Triceps Dip",
              "sets": "3",
              "reps_or_time": "8-10 tekrar",
              "rest": "60 sn",
              "progression": "Bacaklari duzlestir",
              "regression": "Kisa hareket araligi"
            },
            {
              "exercise": "Plank",
              "sets": "3",
              "reps_or_time": "20-30 sn",
              "rest": "45 sn",
              "progression": "Plank sureyi artir",
              "regression": "Diz plank"
            }
          ],
          "cooldown": [
            "Gogus esnetme 30 sn",
            "Omuz esnetme 30 sn",
            "Cocuk pozu 45 sn"
          ]
        },
        {
          "name": "Gün 2",
          "focus": "Bacak + Karın",
          "warmup": [
            "Dinamik kalca acma 1 dk",
            "Hafif squat 2 x 10",
            "Bacak savurma 1 dk"
          ],
          "workout": [
            {
              "exercise": "Vucut Agirligi Squat",
              "sets": "3",
              "reps_or_time": "12-15 tekrar",
              "rest": "60 sn",
              "progression": "Tempo squat (3 sn inis)",
              "regression": "Sandalyeye otur-kalk"
            },
            {
              "exercise": "Geri Lunge",
              "sets": "3",
              "reps_or_time": "10 tekrar/ayak",
              "rest": "60 sn",
              "progression": "Split squat",
              "regression": "Kisa adim"
            },
            {
              "exercise": "Dead Bug",
              "sets": "3",
              "reps_or_time": "8-10 tekrar/yan",
              "rest": "45 sn",
              "progression": "Bacaklari duz tut",
              "regression": "Kisa hareket"
            }
          ],
          "cooldown": [
            "Quadriceps esnetme 30 sn",
            "Hamstring esnetme 30 sn",
            "Bel gevsetme 30 sn"
          ]
        },
        {
          "name": "Gün 3",
          "focus": "Çekiş + Karın",
          "warmup": [
            "Sirt-omuz mobilite 2 dk",
            "Ters sinav 2 x 8",
            "Kollari daire 1 dk"
          ],
          "workout": [
            {
              "exercise": "Ters Sinav (Row)",
              "sets": "3",
              "reps_or_time": "10-12 tekrar",
              "rest": "60 sn",
              "progression": "Daha yavas inis",
              "regression": "Kisa hareket"
            },
            {
              "exercise": "Superman",
              "sets": "3",
              "reps_or_time": "12 tekrar",
              "rest": "45 sn",
              "progression": "3 sn ustte tut",
              "regression": "Tek kol/tek bacak"
            },
            {
              "exercise": "Yan Plank",
              "sets": "2",
              "reps_or_time": "20 sn/yan",
              "rest": "45 sn",
              "progression": "Kalca dusur-kaldir",
              "regression": "Diz yan plank"
            }
          ],
          "cooldown": [
            "Lat esnetme 30 sn",
            "Gogus acma 30 sn",
            "Kedi-inek 45 sn"
          ]
        }
      ]
    },
    {
      "level": "spor salonu",
      "week": 1,
      "days": [
        {
          "name": "Gün 1",
          "focus": "İtiş + Karın",
          "warmup": [
            "Kardiyo 5 dk",
            "Omuz mobilite 2 dk",
            "Bos bar ile itis 2 x 10"
          ],
          "workout": [
            {
              "exercise": "Bench Press",
              "sets": "4",
              "reps_or_time": "8-10 tekrar",
              "rest": "90 sn",
              "progression": "Agirligi artir",
              "regression": "Dumbbell press"
            },
            {
              "exercise": "Incline Dumbbell Press",
              "sets": "3",
              "reps_or_time": "10-12 tekrar",
              "rest": "75 sn",
              "progression": "Yavas inis",
              "regression": "Daha hafif agirlik"
            },
            {
              "exercise": "Cable Triceps Pushdown",
              "sets": "3",
              "reps_or_time": "12-15 tekrar",
              "rest": "60 sn",
              "progression": "Agirligi artir",
              "regression": "Band pushdown"
            }
          ],
          "cooldown": [
            "Gogus esnetme 30 sn",
            "Omuz esnetme 30 sn",
            "Cocuk pozu 45 sn"
          ]
        },
        {
          "name": "Gün 2",
          "focus": "Bacak + Karın",
          "warmup": [
            "Bisiklet 5 dk",
            "Dinamik squat 2 x 10",
            "Kalca mobilite 1 dk"
          ],
          "workout": [
            {
              "exercise": "Leg Press",
              "sets": "4",
              "reps_or_time": "10-12 tekrar",
              "rest": "90 sn",
              "progression": "Agirligi artir",
              "regression": "Daha hafif agirlik"
            },
            {
              "exercise": "Romanian Deadlift",
              "sets": "3",
              "reps_or_time": "8-10 tekrar",
              "rest": "90 sn",
              "progression": "Yavas negatif",
              "regression": "Dumbbell RDL"
            },
            {
              "exercise": "Hanging Knee Raise",
              "sets": "3",
              "reps_or_time": "10-12 tekrar",
              "rest": "60 sn",
              "progression": "Leg raise",
              "regression": "Kapitli knee raise"
            }
          ],
          "cooldown": [
            "Quadriceps esnetme 30 sn",
            "Hamstring esnetme 30 sn",
            "Bel gevsetme 30 sn"
          ]
        },
        {
          "name": "Gün 3",
          "focus": "Çekiş + Karın",
          "warmup": [
            "Kardiyo 5 dk",
            "Sirt-omuz mobilite 2 dk",
            "Bos bar row 2 x 10"
          ],
          "workout": [
            {
              "exercise": "Lat Pulldown",
              "sets": "4",
              "reps_or_time": "10-12 tekrar",
              "rest": "90 sn",
              "progression": "Agirligi artir",
              "regression": "Band pulldown"
            },
            {
              "exercise": "Seated Cable Row",
              "sets": "3",
              "reps_or_time": "10-12 tekrar",
              "rest": "75 sn",
              "progression": "Yavas inis",
              "regression": "Daha hafif agirlik"
            },
            {
              "exercise": "Face Pull",
              "sets": "3",
              "reps_or_time": "12-15 tekrar",
              "rest": "60 sn",
              "progression": "Agirligi artir",
              "regression": "Band face pull"
            }
          ],
          "cooldown": [
            "Lat esnetme 30 sn",
            "Gogus acma 30 sn",
            "Kedi-inek 45 sn"
          ]
        }
      ]
    }
  ];

  Widget _buildNavIcon(
    BuildContext context, {
    required IconData icon,
    required bool selected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: selected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Container(
          padding: const EdgeInsets.all(6.0),
          decoration: BoxDecoration(
            color: Color.lerp(
              Colors.transparent,
              colorScheme.primary.withOpacity(0.12),
              value,
            ),
            borderRadius: BorderRadius.circular(12.0),
            boxShadow: value == 0.0
                ? []
                : [
                    BoxShadow(
                      color: colorScheme.primary.withOpacity(0.25 * value),
                      blurRadius: 12.0,
                      spreadRadius: 1.0,
                    ),
                  ],
          ),
          child: Transform.scale(
            scale: 1.0 + (0.06 * value),
            child: Icon(
              icon,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }

  void _showSoonSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, {required int selectedIndex}) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 12.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.08),
              blurRadius: 16.0,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: NavigationBar(
          height: 68.0,
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) {
            if (index == selectedIndex) {
              return;
            }

            if (index == 0) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.home,
                (route) => false,
              );
            } else if (index == 1) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.trainingProgram,
                (route) => false,
              );
            } else if (index == 2) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.favorites,
                (route) => false,
              );
            } else {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.userProfile,
                (route) => false,
              );
            }
          },
          destinations: [
            NavigationDestination(
              icon: _buildNavIcon(
                context,
                icon: Icons.fitness_center_outlined,
                selected: false,
              ),
              selectedIcon: _buildNavIcon(
                context,
                icon: Icons.fitness_center,
                selected: true,
              ),
              label: 'Hareketler',
            ),
            NavigationDestination(
              icon: _buildNavIcon(
                context,
                icon: Icons.event_note_outlined,
                selected: false,
              ),
              selectedIcon: _buildNavIcon(
                context,
                icon: Icons.event_note,
                selected: true,
              ),
              label: 'Antrenman Programı',
            ),
            NavigationDestination(
              icon: _buildNavIcon(
                context,
                icon: Icons.favorite_border,
                selected: false,
              ),
              selectedIcon: _buildNavIcon(
                context,
                icon: Icons.favorite,
                selected: true,
              ),
              label: 'Favoriler',
            ),
            NavigationDestination(
              icon: _buildNavIcon(
                context,
                icon: Icons.person_outline,
                selected: false,
              ),
              selectedIcon: _buildNavIcon(
                context,
                icon: Icons.person,
                selected: true,
              ),
              label: 'Kullanıcı',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomPlanCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20.0),
      onTap: () {
        Navigator.pushNamed(context, AppRoutes.customPlan);
      },
      child: Container(
        padding: const EdgeInsets.all(18.0),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: colorScheme.primary.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Senin Planin',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 6.0),
                  Text(
                    'Kendi antrenman programini olustur ve kaydet.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),
            OutlinedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.customPlan);
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: colorScheme.primary,
                side: BorderSide(color: colorScheme.primary.withOpacity(0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
              ),
              child: const Text('Olustur'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Antrenman Programı'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 112.0),
        children: [
          Text(
            'Programlar',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Evde ve spor salonunda uygulanacak iki plan.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16.0),
          for (final program in _programData)
            _LevelSection(program: program),
          const SizedBox(height: 8.0),
          _buildCustomPlanCard(context),
        ],
      ),
      bottomNavigationBar: _buildBottomNavBar(context, selectedIndex: 1),
    );
  }
}

class _LevelSection extends StatelessWidget {
  const _LevelSection({required this.program});

  final Map<String, dynamic> program;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final level = (program["level"] as String).toUpperCase();
    final days = program["days"] as List<dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4.0,
                height: 20.0,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(width: 10.0),
              Text(
                level,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12.0),
          for (final day in days)
            _DayCard(
              day: day as Map<String, dynamic>,
              level: program["level"] as String,
              week: program["week"] as int,
            ),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.level,
    required this.week,
  });

  final Map<String, dynamic> day;
  final String level;
  final int week;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final warmup = (day["warmup"] as List<dynamic>).cast<String>();
    final workout = day["workout"] as List<dynamic>;
    final cooldown = (day["cooldown"] as List<dynamic>).cast<String>();
    const accent = Color(0xFFC7F54B);
    const accentText = Color(0xFF121600);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  day["name"] as String,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Text(
                day["focus"] as String,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          _SectionList(title: "Isinma", items: warmup),
          const SizedBox(height: 10.0),
          Text(
            "Ana Antrenman",
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8.0),
          for (final item in workout)
            _WorkoutItem(item: item as Map<String, dynamic>),
          const SizedBox(height: 10.0),
          _SectionList(title: "Esneme", items: cooldown),
          const SizedBox(height: 12.0),
          SizedBox(
            width: double.infinity,
            child: _StartWorkoutButton(
              accent: accent,
              textColor: accentText,
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.trainingDaySession,
                  arguments: TrainingDaySessionArgs(
                    level: level,
                    week: week,
                    day: day,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StartWorkoutButton extends StatelessWidget {
  const _StartWorkoutButton({
    required this.onPressed,
    required this.accent,
    required this.textColor,
  });

  final VoidCallback onPressed;
  final Color accent;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18.0),
      onTap: onPressed,
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent,
              accent.withOpacity(0.86),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18.0),
          boxShadow: [
            BoxShadow(
              color: accent.withOpacity(0.35),
              blurRadius: 16.0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 34.0,
              height: 34.0,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: textColor,
                size: 22.0,
              ),
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: Text(
                'Antrenmana Basla',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionList extends StatelessWidget {
  const _SectionList({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6.0),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              '- $item',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }
}

class _WorkoutItem extends StatelessWidget {
  const _WorkoutItem({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item["exercise"] as String,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4.0),
          Text(
            '${item["sets"]} set | ${item["reps_or_time"]} | Dinlenme: ${item["rest"]}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 6.0),
          Text(
            'İlerleme: ${item["progression"]}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            'Kolaylaştırma: ${item["regression"]}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
