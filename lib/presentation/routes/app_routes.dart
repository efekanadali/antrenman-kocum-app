// lib/presentation/routes/app_routes.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:calisthenics_app/presentation/screens/exercise_detail_screen.dart';
import 'package:calisthenics_app/presentation/screens/favorites_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String detail = '/detail';
  static const String favorites = '/favorites';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case favorites:
        return MaterialPageRoute(builder: (_) => const FavoritesScreen());
      case detail:
        final exercise = settings.arguments as Exercise;
        return MaterialPageRoute(
          builder: (_) => ExerciseDetailScreen(exercise: exercise),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}