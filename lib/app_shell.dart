import 'package:flutter/material.dart';

import 'features/tailgate_detail/tailgate_detail_screen.dart';
import 'features/tailgate_setup/create_tailgate_screen.dart';
import 'features/tailgate_setup/join_tailgate_screen.dart';
import 'screens/crew_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PageController _pageController;
  int _pageIndex = 0;
  bool _checkedIn = false;
  int get _crewCount => _checkedIn ? 9 : 8;

  void _openHomeAction(int index) {
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Crew')),
            body: SafeArea(child: CrewScreen(crewCount: _crewCount)),
          ),
        ),
      );
    } else {
      _goToPage(index);
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _openTailgate(int tabIndex) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TailgateDetailScreen(initialTab: tabIndex),
      ),
    );
  }

  Future<void> _hostTailgate() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateTailgateScreen()),
    );
    if (created == true && mounted) {
      _openTailgate(0);
    }
  }

  Future<void> _joinTailgate() async {
    final joined = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => const JoinTailgateScreen()));
    if (joined == true && mounted) {
      _openTailgate(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: PageView(
          key: const Key('main-page-view'),
          controller: _pageController,
          onPageChanged: (index) => setState(() => _pageIndex = index),
          children: [
            HomeScreen(
              onNavigate: _openHomeAction,
              checkedIn: _checkedIn,
              onCheckInChanged: (value) => setState(() => _checkedIn = value),
              onOpenTailgate: _openTailgate,
              onHostTailgate: _hostTailgate,
              onJoinTailgate: _joinTailgate,
            ),
            CrewScreen(crewCount: _crewCount),
            const MapScreen(),
            const ProfileScreen(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: _goToPage,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Crew',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
