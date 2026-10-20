import 'package:flutter/material.dart';

import 'features/tailgate_detail/tailgate_detail_screen.dart';
import 'features/map/map_repository.dart';
import 'features/map/map_seed_data.dart';
import 'features/map/map_provider_config.dart';
import 'features/map/meetup_map.dart';
import 'features/map/meetup_spot_controller.dart';
import 'features/tailgate_setup/create_tailgate_screen.dart';
import 'features/tailgate_setup/join_tailgate_screen.dart';
import 'screens/crew_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/tailgates_screen.dart';
import 'features/tailgate_setup/tailgate_draft.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, this.mapBuilder});

  final MeetupMapBuilder? mapBuilder;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PageController _pageController;
  late final MeetupSpotController _meetupSpotController;
  int _pageIndex = 0;
  bool _checkedIn = false;
  final List<TailgateEntry> _tailgates = [
    TailgateEntry(
      id: 'gumbo',
      code: 'GEAUX7',
      joined: true,
      draft: TailgateDraft(
        game: 'LSU vs. Alabama',
        name: 'Gumbo & Geaux',
        date: DateTime(2026, 10, 24),
        kickoff: '6:30 PM',
        meetupTime: '11:00 AM',
        location: 'Oak Grove',
        vibe: 'Food & drinks',
      ),
    ),
    TailgateEntry(
      id: 'purple',
      code: 'PURPLE',
      joined: true,
      draft: TailgateDraft(
        game: 'LSU game day',
        name: 'The Purple Lot',
        date: DateTime(2026, 10, 31),
        kickoff: '6:30 PM',
        meetupTime: '12:00 PM',
        location: 'Parade Ground',
        vibe: 'Family friendly',
        isPublic: true,
      ),
    ),
    TailgateEntry(
      id: 'tigers',
      code: 'TIGERS',
      draft: TailgateDraft(
        game: 'LSU game day',
        name: 'Tigers Together',
        date: DateTime(2026, 10, 24),
        kickoff: '6:30 PM',
        meetupTime: '1:00 PM',
        location: 'Parade Ground',
        vibe: 'Family friendly',
        isPublic: true,
      ),
    ),
  ];

  void _viewEntry(TailgateEntry entry) {
    if (entry.id == 'gumbo') {
      _openTailgate(0);
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TailgateOverviewScreen(entry: entry),
      ),
    );
  }

  void _joinPublic(TailgateEntry entry) {
    if (!entry.draft.isPublic || entry.joined) return;
    setState(() => entry.joined = true);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Joined ${entry.draft.name}')));
  }

  void _leaveTailgate(TailgateEntry entry) {
    if (!entry.joined) return;
    setState(() {
      entry.joined = false;
      if (entry.id == 'gumbo') _checkedIn = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Left ${entry.draft.name}')));
  }

  int get _crewCount => _checkedIn ? 9 : 8;

  void _openHomeAction(int index) {
    if (index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Crew')),
            body: SafeArea(
              child: CrewScreen(crewCount: _crewCount, showBrandHeader: false),
            ),
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
    _meetupSpotController = MeetupSpotController(
      InMemoryMapRepository(developmentMeetupSpots),
      tailgateId: 'gumbo',
    )..load();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _meetupSpotController.dispose();
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
        builder: (_) => TailgateDetailScreen(
          initialTab: tabIndex,
          meetupSpotController: _meetupSpotController,
          mapProviderConfig: MapProviderConfig.fromEnvironment(),
          mapBuilder: widget.mapBuilder,
        ),
      ),
    );
  }

  Future<void> _hostTailgate() async {
    final code = 'TG${(_tailgates.length + 1).toString().padLeft(4, '0')}';
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateTailgateScreen(
          inviteCode: code,
          onCreated: (draft) => setState(
            () => _tailgates.add(
              TailgateEntry(
                id: code,
                code: code,
                draft: draft,
                joined: true,
                hosted: true,
              ),
            ),
          ),
        ),
      ),
    );
    if (created == true && mounted) {
      _goToPage(1);
      _viewEntry(_tailgates.last);
    }
  }

  Future<void> _joinTailgate() async {
    final joined = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => JoinTailgateScreen(entries: _tailgates),
      ),
    );
    if (joined is TailgateEntry && mounted) {
      setState(() => joined.joined = true);
      _goToPage(1);
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
            TailgatesScreen(
              entries: _tailgates,
              onJoin: _joinPublic,
              onLeave: _leaveTailgate,
              onHost: _hostTailgate,
              onInvite: _joinTailgate,
              onOpen: _viewEntry,
            ),
            CrewScreen(crewCount: _crewCount),
            MapScreen(
              controller: _meetupSpotController,
              providerConfig: MapProviderConfig.fromEnvironment(),
              mapBuilder: widget.mapBuilder,
            ),
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
            icon: Icon(Icons.celebration_outlined),
            selectedIcon: Icon(Icons.celebration),
            label: 'Tailgates',
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
