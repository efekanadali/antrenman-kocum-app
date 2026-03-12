// lib/presentation/screens/main_swipe_shell.dart

import 'package:flutter/material.dart';
import 'package:calisthenics_app/presentation/screens/home_screen.dart';
import 'package:calisthenics_app/presentation/screens/workout_library_screen.dart';
import 'package:calisthenics_app/presentation/screens/stats_screen.dart';
import 'package:calisthenics_app/presentation/screens/user_profile_screen.dart';

class MainSwipeShell extends StatefulWidget {
  const MainSwipeShell({super.key});

  @override
  State<MainSwipeShell> createState() => _MainSwipeShellState();
}

class _MainSwipeShellState extends State<MainSwipeShell> {
  late final PageController _pageController;
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomeScreen(showBottomNav: false),
    WorkoutLibraryScreen(showBottomNav: false),
    StatsScreen(showBottomNav: false),
    UserProfileScreen(showBottomNav: false),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    if (index == _selectedIndex) {
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    if (index == _selectedIndex) {
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: AppBottomNav(
        selectedIndex: _selectedIndex,
        onItemSelected: _onNavTap,
      ),
    );
  }
}
