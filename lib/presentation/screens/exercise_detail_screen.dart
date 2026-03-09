// lib/presentation/screens/exercise_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/presentation/routes/app_routes.dart';
import 'package:calisthenics_app/core/utils/enum_label.dart';

class ExerciseDetailScreen extends StatelessWidget {
  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  final Exercise exercise;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.workoutSession,
                  arguments: exercise,
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Antrenmanı Başlat'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
            ),
            const SizedBox(height: 16.0),
            // Level
            Text(
              'Seviye: ${exercise.level.label.toUpperCase()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            // Difficulty Chip
            Chip(
              label: Text('Zorluk: ${exercise.difficulty.label.toUpperCase()}'),
            ),
            const SizedBox(height: 16.0),
            // Target Muscle Groups
            Text(
              'Hedef Kas Grupları:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Wrap(
              spacing: 8.0,
              children: exercise.targetMuscleGroups.map((muscle) {
                return Chip(
                  label: Text(muscle.label.toUpperCase()),
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),
            // Description
            Text(
              'Description:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              exercise.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(context, selectedIndex: 0),
    );
  }
}