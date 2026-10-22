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
import 'features/tailgate_setup/tailgate_repository.dart';

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
  List<TailgateEntry> _tailgates = [];
  late final TailgateRepository _repository;
  bool _loading = true;
  bool _busy = false;
  String? _serverError;

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

  Future<void> _reloadTailgates() async {
    try {
      final entries = await _repository.list();
      if (mounted) {
        setState(() {
          _tailgates = entries;
          _serverError = null;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _serverError = error.toString();
          _loading = false;
        });
      }
    }
  }

  void _showServerError(Object error) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Future<void> _joinPublic(TailgateEntry entry) async {
    if (!entry.draft.isPublic || entry.joined) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _repository.join(entry);
      await _reloadTailgates();
    } catch (error) {
      _showServerError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _leaveTailgate(TailgateEntry entry) async {
    if (!entry.joined) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      bool deleted;
      try {
        deleted = await _repository.leave(
          entry,
          confirmDelete: entry.memberCount == 1,
        );
      } on TailgateApiException catch (error) {
        if (error.code != 'last_member' || !mounted) rethrow;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('You’re now the last member'),
            content: const Text(
              'The other members have left. Leaving will permanently delete this tailgate and its invite code. Do you still want to leave?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Leave and delete'),
              ),
            ],
          ),
        );
        if (confirm != true) {
          await _reloadTailgates();
          return;
        }
        deleted = await _repository.leave(entry, confirmDelete: true);
      }
      if (entry.id == 'gumbo') _checkedIn = false;
      await _reloadTailgates();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              deleted
                  ? 'Tailgate deleted because no members remain.'
                  : 'Left ${entry.draft.name}',
            ),
          ),
        );
      }
    } catch (error) {
      _showServerError(error);
      await _reloadTailgates();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
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
    _repository = TailgateRepository.create();
    _reloadTailgates();
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
    if (index == 1) _reloadTailgates();
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
    TailgateEntry? hosted;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateTailgateScreen(
          createOnServer: (draft) async {
            hosted = await _repository.createTailgate(draft);
            await _reloadTailgates();
            return hosted!;
          },
        ),
      ),
    );
    if (created == true && mounted) {
      _goToPage(1);
      if (hosted != null) _viewEntry(hosted!);
    }
  }

  Future<void> _joinTailgate() async {
    final joined = await Navigator.of(context).push<Object>(
      MaterialPageRoute(
        builder: (_) => JoinTailgateScreen(
          entries: _tailgates,
          lookupOnServer: _repository.lookup,
          joinOnServer: _repository.join,
        ),
      ),
    );
    if (joined is TailgateEntry && mounted) {
      await _reloadTailgates();
      if (!mounted) return;
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
              tailgates: _tailgates.where((entry) => entry.joined).toList(),
              onOpenEntry: _viewEntry,
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
              loading: _loading,
              busy: _busy,
              error: _serverError,
              onRefresh: _reloadTailgates,
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
