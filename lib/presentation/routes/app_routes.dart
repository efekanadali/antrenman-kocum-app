// lib/presentation/routes/app_routes.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/domain/models/exercise.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:calisthenics_app/presentation/screens/exercise_detail_screen.dart';
import 'package:calisthenics_app/presentation/screens/favorites_screen.dart';
import 'package:calisthenics_app/presentation/screens/training_program_screen.dart';
import 'package:calisthenics_app/presentation/screens/user_profile_screen.dart';
import 'package:calisthenics_app/presentation/screens/athlete_profile_screen.dart';
import 'package:calisthenics_app/presentation/screens/streak_details_screen.dart';
import 'package:calisthenics_app/presentation/screens/weekly_goal_screen.dart';
import 'package:calisthenics_app/presentation/screens/total_time_screen.dart';
import 'package:calisthenics_app/presentation/screens/workout_session_screen.dart';
import 'package:calisthenics_app/presentation/screens/workout_summary_screen.dart';
import 'package:calisthenics_app/presentation/screens/workout_library_screen.dart';
import 'package:calisthenics_app/presentation/screens/stats_screen.dart';
import 'package:calisthenics_app/presentation/screens/custom_plan_screen.dart';

class AppRoutes {
  static const String home = '/';
  static const String detail = '/detail';
  static const String favorites = '/favorites';
  static const String trainingProgram = '/program';
  static const String userProfile = '/profile';
  static const String workoutSession = '/workout';
  static const String workoutSummary = '/workout-summary';
  static const String workoutLibrary = '/workout-library';
  static const String stats = '/stats';
  static const String customPlan = '/custom-plan';
  static const String athleteProfile = '/profile/athlete';
  static const String streakDetails = '/profile/streak';
  static const String weeklyGoal = '/profile/weekly-goal';
  static const String totalTime = '/profile/total-time';

  static const List<String> _tabOrder = [
    home,
    workoutLibrary,
    stats,
    trainingProgram,
    favorites,
    userProfile,
  ];

  static String? _lastRouteName;

  static PageRouteBuilder _buildSlideRoute({
    required Widget page,
    required RouteSettings settings,
  }) {
    final currentName = settings.name;
    final fromIndex = _tabOrder.indexOf(_lastRouteName ?? '');
    final toIndex = _tabOrder.indexOf(currentName ?? '');

    Offset begin = const Offset(1.0, 0.0);
    if (fromIndex >= 0 && toIndex >= 0 && fromIndex != toIndex) {
      begin = toIndex > fromIndex
          ? const Offset(1.0, 0.0)
          : const Offset(-1.0, 0.0);
    }

    _lastRouteName = currentName;

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return SlideTransition(
          position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curve),
          child: child,
        );
      },
    );
  }

  static PageRouteBuilder _buildFadeSlideRoute({
    required Widget page,
    required RouteSettings settings,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curve,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.04),
              end: Offset.zero,
            ).animate(curve),
            child: child,
          ),
        );
      },
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _buildSlideRoute(
          page: const HomeScreen(),
          settings: settings,
        );
      case favorites:
        return _buildSlideRoute(
          page: const FavoritesScreen(),
          settings: settings,
        );
      case trainingProgram:
        return _buildSlideRoute(
          page: const TrainingProgramScreen(),
          settings: settings,
        );
      case userProfile:
        return _buildSlideRoute(
          page: const UserProfileScreen(),
          settings: settings,
        );
      case detail:
        final exercise = settings.arguments as Exercise;
        return _buildSlideRoute(
          page: ExerciseDetailScreen(exercise: exercise),
          settings: settings,
        );
      case workoutSession:
        final exercise = settings.arguments as Exercise;
        return _buildSlideRoute(
          page: WorkoutSessionScreen(exercise: exercise),
          settings: settings,
        );
      case workoutSummary:
        final args = settings.arguments as WorkoutSummaryArgs;
        return _buildSlideRoute(
          page: WorkoutSummaryScreen(args: args),
          settings: settings,
        );
      case workoutLibrary:
        return _buildSlideRoute(
          page: const WorkoutLibraryScreen(),
          settings: settings,
        );
      case stats:
        return _buildSlideRoute(
          page: const StatsScreen(),
          settings: settings,
        );
      case customPlan:
        return _buildSlideRoute(
          page: const CustomPlanScreen(),
          settings: settings,
        );
      case athleteProfile:
        return _buildSlideRoute(
            page: const AthleteProfileScreen(),
          settings: settings,
        );
      case streakDetails:
        return _buildSlideRoute(
            page: const StreakDetailsScreen(),
          settings: settings,
        );
      case weeklyGoal:
        return _buildSlideRoute(
            page: const WeeklyGoalScreen(),
          settings: settings,
        );
      case totalTime:
        return _buildSlideRoute(
            page: const TotalTimeScreen(),
          settings: settings,
        );
      default:
        return _buildSlideRoute(
          page: Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
          settings: settings,
        );
    }
  }
}