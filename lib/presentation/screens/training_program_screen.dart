// lib/presentation/screens/training_program_screen.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';

class TrainingProgramScreen extends StatelessWidget {
  const TrainingProgramScreen({super.key});

  static const List<Map<String, dynamic>> _programData = [
    {
      "level": "beginner",
      "week": 1,
      "days": [
        {
          "name": "Gun 1",
          "focus": "Itis + Core",
          "warmup": [
            "Eklem isinmasi (boyun-omuz-dirsek-bilek) 3 dk",
            "Hafif yerde yuruyus + kol salinimi 2 dk",
            "Duvara itis 2 x 10"
          ],
          "workout": [
            {
              "exercise": "Diz Ustu Sinav",
              "sets": "3",
              "reps_or_time": "8-12 tekrar",
              "rest": "60 sn",
              "progression": "Tam sinava gec",
              "regression": "Eğimli (yukseltiye) sinav"
            },
            {
              "exercise": "Sandalyeye Triceps Dip (dizler bukulu)",
              "sets": "3",
              "reps_or_time": "8-10 tekrar",
              "rest": "60 sn",
              "progression": "Bacaklari duzlestir",
              "regression": "Daha kisa hareket araligi"
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
          "name": "Gun 2",
          "focus": "Bacak + Core",
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
              "regression": "Kisa adimli lunge"
            },
            {
              "exercise": "Dead Bug",
              "sets": "3",
              "reps_or_time": "8-10 tekrar/yan",
              "rest": "45 sn",
              "progression": "Bacaklari daha duz tut",
              "regression": "Daha kisa hareket"
            }
          ],
          "cooldown": [
            "Quadriceps esnetme 30 sn",
            "Hamstring esnetme 30 sn",
            "Bel gevsetme 30 sn"
          ]
        },
        {
          "name": "Gun 3",
          "focus": "Cekis + Core",
          "warmup": [
            "Sirt-omuz mobilite 2 dk",
            "Duvar sirt aktivasyonu 2 x 8",
            "Kollari daire 1 dk"
          ],
          "workout": [
            {
              "exercise": "Ters Sinav (Floor Row simulasyonu)",
              "sets": "3",
              "reps_or_time": "10-12 tekrar",
              "rest": "60 sn",
              "progression": "Daha yavas inis",
              "regression": "Daha kisa hareket araligi"
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
      "level": "intermediate",
      "week": 1,
      "days": [
        {
          "name": "Gun 1",
          "focus": "Itis + Core",
          "warmup": [
            "Eklem isinmasi 3 dk",
            "Yavas sinav 2 x 6",
            "Omuz mobilite 1 dk"
          ],
          "workout": [
            {
              "exercise": "Sinav",
              "sets": "4",
              "reps_or_time": "10-15 tekrar",
              "rest": "60 sn",
              "progression": "Ayak yukselt",
              "regression": "Egimli sinav"
            },
            {
              "exercise": "Pike Push-up",
              "sets": "3",
              "reps_or_time": "8-10 tekrar",
              "rest": "60 sn",
              "progression": "Ayak yukselt pike",
              "regression": "Diz pike"
            },
            {
              "exercise": "Hollow Hold",
              "sets": "3",
              "reps_or_time": "25-35 sn",
              "rest": "45 sn",
              "progression": "Kollari bas ustune al",
              "regression": "Dizler bukulu hollow"
            }
          ],
          "cooldown": [
            "Gogus esnetme 30 sn",
            "Omuz esnetme 30 sn",
            "Cocuk pozu 45 sn"
          ]
        },
        {
          "name": "Gun 2",
          "focus": "Bacak + Core",
          "warmup": [
            "Dinamik squat 2 x 10",
            "Kalca daire 1 dk",
            "Bacak savurma 1 dk"
          ],
          "workout": [
            {
              "exercise": "Tempo Squat (3 sn inis)",
              "sets": "4",
              "reps_or_time": "10-12 tekrar",
              "rest": "60 sn",
              "progression": "Pause squat (altta 2 sn)",
              "regression": "Normal squat"
            },
            {
              "exercise": "Bulgarian Split Squat",
              "sets": "3",
              "reps_or_time": "8-10 tekrar/ayak",
              "rest": "75 sn",
              "progression": "Daha yavas inis",
              "regression": "Split squat (arka ayak yerde)"
            },
            {
              "exercise": "Leg Raise",
              "sets": "3",
              "reps_or_time": "10-12 tekrar",
              "rest": "60 sn",
              "progression": "Yavas negatif",
              "regression": "Diz cekme"
            }
          ],
          "cooldown": [
            "Quadriceps esnetme 30 sn",
            "Hamstring esnetme 30 sn",
            "Bel gevsetme 30 sn"
          ]
        },
        {
          "name": "Gun 3",
          "focus": "Cekis + Core",
          "warmup": [
            "Sirt mobilite 2 dk",
            "Yuzustu kurek simulasyonu 2 x 8",
            "Omuz daire 1 dk"
          ],
          "workout": [
            {
              "exercise": "Ters Sinav (Strict)",
              "sets": "4",
              "reps_or_time": "10-12 tekrar",
              "rest": "60 sn",
              "progression": "Tempolu 3 sn inis",
              "regression": "Daha kisa hareket"
            },
            {
              "exercise": "Superman Hold",
              "sets": "3",
              "reps_or_time": "25-35 sn",
              "rest": "45 sn",
              "progression": "Kollari bas ustunde tut",
              "regression": "Tek kol/tek bacak"
            },
            {
              "exercise": "Side Plank Reach",
              "sets": "3",
              "reps_or_time": "8-10 tekrar/yan",
              "rest": "45 sn",
              "progression": "Daha yavas tempo",
              "regression": "Klasik yan plank"
            }
          ],
          "cooldown": [
            "Lat esnetme 30 sn",
            "Gogus acma 30 sn",
            "Kedi-inek 45 sn"
          ]
        },
        {
          "name": "Gun 4 (Opsiyonel HIIT)",
          "focus": "Tam vucut kondisyon",
          "warmup": [
            "Hafif ziplama 2 dk",
            "Dinamik mobilite 2 dk"
          ],
          "workout": [
            {
              "exercise": "Jumping Jack",
              "sets": "4 tur",
              "reps_or_time": "30 sn",
              "rest": "20 sn",
              "progression": "Daha hizli tempo",
              "regression": "Adimli jumping jack"
            },
            {
              "exercise": "Dag Tirmanisi",
              "sets": "4 tur",
              "reps_or_time": "30 sn",
              "rest": "20 sn",
              "progression": "Daha hizli tempo",
              "regression": "Yavas tempo"
            },
            {
              "exercise": "Squat Jump",
              "sets": "4 tur",
              "reps_or_time": "20 sn",
              "rest": "40 sn",
              "progression": "Daha yuksek ziplama",
              "regression": "Normal squat"
            }
          ],
          "cooldown": [
            "Yuruyus 2 dk",
            "Tam vucut esneme 2-3 dk"
          ]
        }
      ]
    },
    {
      "level": "advanced",
      "week": 1,
      "days": [
        {
          "name": "Gun 1",
          "focus": "Itis + Core",
          "warmup": [
            "Omuz mobilite 3 dk",
            "Yavas sinav 2 x 8",
            "El bilegi isinma 1 dk"
          ],
          "workout": [
            {
              "exercise": "Archer Push-up",
              "sets": "4",
              "reps_or_time": "6-8 tekrar/yan",
              "rest": "75 sn",
              "progression": "Tek kol sinav yolu",
              "regression": "Genis sinav"
            },
            {
              "exercise": "Pike Push-up (Ayak yukselt)",
              "sets": "4",
              "reps_or_time": "8-10 tekrar",
              "rest": "75 sn",
              "progression": "Handstand push-up negatif",
              "regression": "Duz pike"
            },
            {
              "exercise": "Hollow Rocks",
              "sets": "3",
              "reps_or_time": "20-25 tekrar",
              "rest": "60 sn",
              "progression": "Daha genis salinim",
              "regression": "Hollow hold"
            }
          ],
          "cooldown": [
            "Gogus esnetme 30 sn",
            "Omuz esnetme 30 sn",
            "Cocuk pozu 45 sn"
          ]
        },
        {
          "name": "Gun 2",
          "focus": "Bacak + Core",
          "warmup": [
            "Dinamik squat 2 x 12",
            "Kalca mobilite 2 dk"
          ],
          "workout": [
            {
              "exercise": "Pistol Squat (Yardimli)",
              "sets": "4",
              "reps_or_time": "5-6 tekrar/ayak",
              "rest": "90 sn",
              "progression": "Pistol squat tam",
              "regression": "Box pistol"
            },
            {
              "exercise": "Jump Lunge",
              "sets": "3",
              "reps_or_time": "8-10 tekrar/ayak",
              "rest": "75 sn",
              "progression": "Daha hizli tempo",
              "regression": "Geri lunge"
            },
            {
              "exercise": "V-Up",
              "sets": "3",
              "reps_or_time": "10-12 tekrar",
              "rest": "60 sn",
              "progression": "Hollow to V-Up",
              "regression": "Diz cekme"
            }
          ],
          "cooldown": [
            "Quadriceps esnetme 30 sn",
            "Hamstring esnetme 30 sn",
            "Bel gevsetme 30 sn"
          ]
        },
        {
          "name": "Gun 3",
          "focus": "Cekis + Core (Ekipmansiz)",
          "warmup": [
            "Sirt aktivasyon 2 dk",
            "Yuzustu kurek 2 x 10"
          ],
          "workout": [
            {
              "exercise": "Ters Sinav (Tempo 3-1-1)",
              "sets": "4",
              "reps_or_time": "10-12 tekrar",
              "rest": "75 sn",
              "progression": "Daha yavas inis",
              "regression": "Daha kisa hareket"
            },
            {
              "exercise": "Superman Pull",
              "sets": "3",
              "reps_or_time": "10-12 tekrar",
              "rest": "60 sn",
              "progression": "Ustte 2 sn tut",
              "regression": "Superman"
            },
            {
              "exercise": "Side Plank Reach + Rotasyon",
              "sets": "3",
              "reps_or_time": "10 tekrar/yan",
              "rest": "60 sn",
              "progression": "Daha yavas tempo",
              "regression": "Klasik yan plank"
            }
          ],
          "cooldown": [
            "Lat esnetme 30 sn",
            "Gogus acma 30 sn",
            "Kedi-inek 45 sn"
          ]
        },
        {
          "name": "Gun 4 (Opsiyonel HIIT)",
          "focus": "Kondisyon + Core",
          "warmup": [
            "Hafif ziplama 2 dk",
            "Dinamik mobilite 2 dk"
          ],
          "workout": [
            {
              "exercise": "Burpee",
              "sets": "4 tur",
              "reps_or_time": "20 sn",
              "rest": "40 sn",
              "progression": "Daha hizli tempo",
              "regression": "Burpee (sinavsiz)"
            },
            {
              "exercise": "Dag Tirmanisi",
              "sets": "4 tur",
              "reps_or_time": "30 sn",
              "rest": "30 sn",
              "progression": "Daha hizli tempo",
              "regression": "Yavas tempo"
            },
            {
              "exercise": "Plank Jack",
              "sets": "4 tur",
              "reps_or_time": "20 sn",
              "rest": "40 sn",
              "progression": "Daha hizli tempo",
              "regression": "Plank hold"
            }
          ],
          "cooldown": [
            "Yuruyus 2 dk",
            "Tam vucut esneme 2-3 dk"
          ]
        },
        {
          "name": "Gun 5 (Opsiyonel Skill)",
          "focus": "Skill Pratik",
          "warmup": [
            "Omuz mobilite 2 dk",
            "El bilegi isinma 1 dk"
          ],
          "workout": [
            {
              "exercise": "Handstand Kick-up",
              "sets": "5",
              "reps_or_time": "3-5 deneme",
              "rest": "45 sn",
              "progression": "Duvara handstand hold",
              "regression": "Duvara yuz donuk kick-up"
            },
            {
              "exercise": "L-Sit Tuck",
              "sets": "4",
              "reps_or_time": "10-15 sn",
              "rest": "60 sn",
              "progression": "L-Sit",
              "regression": "Dizler bukulu"
            }
          ],
          "cooldown": [
            "Bilek esnetme 30 sn",
            "Omuz esnetme 30 sn"
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
              label: 'Antrenman Programi',
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
              label: 'Kullanici',
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
        title: const Text('Antrenman Programi'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 24.0),
        children: [
          Text(
            'Haftalik Rutin',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Tamamen vucut agirligi ile evde uygulanabilir program.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16.0),
          for (final program in _programData)
            _LevelSection(program: program),
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
            _DayCard(day: day as Map<String, dynamic>),
        ],
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day});

  final Map<String, dynamic> day;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final warmup = (day["warmup"] as List<dynamic>).cast<String>();
    final workout = day["workout"] as List<dynamic>;
    final cooldown = (day["cooldown"] as List<dynamic>).cast<String>();

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
        ],
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
            'Progression: ${item["progression"]}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            'Regression: ${item["regression"]}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}
