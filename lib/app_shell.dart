import 'package:flutter/material.dart';

import 'features/tailgate_detail/tailgate_detail_screen.dart';
import 'features/map/map_repository.dart';
import 'features/map/map_defaults.dart';
import 'features/map/map_provider_config.dart';
import 'features/map/meetup_map.dart';
import 'features/map/meetup_spot.dart';
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
import 'features/profile/user_session.dart';
import 'features/alerts/notification_service.dart';
import 'features/map/current_location.dart';

import 'package:geolocator/geolocator.dart';

import 'features/alerts/game_day_alert.dart';
import 'features/game/game_repository.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    this.mapBuilder,
    this.session = const UserSession(
      displayName: 'BayouBlitz member',
      isGuest: false,
    ),
  });

  final MeetupMapBuilder? mapBuilder;
  final UserSession session;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final PageController _pageController;
  late final MeetupSpotController _meetupSpotController;
  late final InMemoryMapRepository _mapRepository;
  int _pageIndex = 0;
  bool _checkedIn = false;
  List<TailgateEntry> _tailgates = [];
  late final TailgateRepository _repository;
  bool _loading = true;
  bool _busy = false;
  String? _serverError;
  final GameRepository _gameRepository = GameRepository();
  List<GameDayAlert> _alerts = const [];
  final Set<String> _notifiedAlertIds = {};

  void _viewEntry(TailgateEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            TailgateOverviewScreen(entry: entry, repository: _repository),
      ),
    );
  }

  Future<void> _reloadTailgates() async {
    try {
      final entries = await _repository.list();
      if (mounted) {
        await _selectMapTailgate(entries);
        if (!mounted) return;
        setState(() {
          _tailgates = entries;
          _serverError = null;
          _loading = false;
        });
        _loadAlerts(entries);
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

  Future<void> _selectMapTailgate(List<TailgateEntry> entries) async {
    final joined = entries.where((entry) => entry.joined).toList()
      ..sort((a, b) => a.draft.date.compareTo(b.draft.date));
    final tailgateId = joined.isEmpty ? 'unselected' : joined.first.id;
    if (joined.isNotEmpty) {
      final draft = joined.first.draft;
      await _mapRepository.saveMeetupSpot(
        draft.latitude != null && draft.longitude != null
            ? MeetupSpot(
                tailgateId: tailgateId,
                name: draft.location,
                instructions: 'Meet the crew at the pinned tailgate location.',
                latitude: draft.latitude!,
                longitude: draft.longitude!,
                meetupTime: draft.meetupTime,
                walkToStadiumMinutes: 0,
              )
            : lsuDefaultSpot(tailgateId: tailgateId),
      );
    } else {
      await _mapRepository.saveMeetupSpot(
        lsuDefaultSpot(tailgateId: tailgateId),
      );
    }
    await _meetupSpotController.selectTailgate(tailgateId);
  }

  void _onMeetupSpotChanged() {
    if (mounted && !_meetupSpotController.isLoading) {
      _loadAlerts(_tailgates);
    }
  }

  Future<void> _loadAlerts(List<TailgateEntry> entries) async {
    final alerts = <GameDayAlert>[];
    final now = DateTime.now();
    final games = await _gameRepository.schedule();
    for (final entry in entries) {
      if (entry.membershipStatus == MembershipStatus.pending) {
        alerts.add(
          GameDayAlert(
            id: '${entry.id}-pending',
            kind: GameDayAlertKind.membership,
            title: 'Join request pending',
            message: '${entry.draft.name} is waiting for host approval.',
            createdAt: now,
          ),
        );
      } else if (entry.membershipStatus == MembershipStatus.waitlisted) {
        alerts.add(
          GameDayAlert(
            id: '${entry.id}-waitlist',
            kind: GameDayAlertKind.membership,
            title: 'You’re on the waitlist',
            message: 'BayouBlitz will keep your place for ${entry.draft.name}.',
            createdAt: now,
          ),
        );
      }
      if (entry.hosted && entry.pendingCount > 0) {
        alerts.add(
          GameDayAlert(
            id: '${entry.id}-requests-${entry.pendingCount}',
            kind: GameDayAlertKind.membership,
            title: 'Join requests waiting',
            message:
                '${entry.pendingCount} ${entry.pendingCount == 1 ? 'person wants' : 'people want'} to join ${entry.draft.name}.',
            createdAt: now,
          ),
        );
      }
      if (!entry.joined) continue;
      final startsIn = entry.draft.date.difference(now);
      if (!startsIn.isNegative && startsIn <= const Duration(hours: 24)) {
        alerts.add(
          GameDayAlert(
            id: '${entry.id}-soon',
            kind: GameDayAlertKind.reminder,
            title: 'Tailgate starting soon',
            message:
                '${entry.draft.name} meets at ${entry.draft.meetupTime} at ${entry.draft.location}.',
            createdAt: now,
          ),
        );
      }
      final matchingGame = games.where(
        (game) =>
            game.id == entry.draft.gameId ||
            game.matchup.toLowerCase() == entry.draft.game.toLowerCase(),
      );
      if (matchingGame.isNotEmpty) {
        final game = matchingGame.first;
        if (game.isLive || game.isFinal) {
          alerts.add(
            GameDayAlert(
              id: '${entry.id}-score-${game.homePoints}-${game.awayPoints}',
              kind: GameDayAlertKind.liveScore,
              title: game.isLive ? 'Game is live' : 'Final score',
              message:
                  '${game.awayTeam} ${game.awayPoints ?? 0} · ${game.homeTeam} ${game.homePoints ?? 0}',
              createdAt: now,
            ),
          );
        }
        final planned = _dateWithTime(entry.draft.date, entry.draft.kickoff);
        if (game.startTime.difference(planned).abs() >=
            const Duration(minutes: 15)) {
          alerts.add(
            GameDayAlert(
              id: '${entry.id}-kickoff-${game.startTime.toIso8601String()}',
              kind: GameDayAlertKind.kickoff,
              title: 'Kickoff time changed',
              message:
                  '${entry.draft.game} is now scheduled for ${_formatTime(game.startTime)}.',
              createdAt: now,
            ),
          );
        }
      }
      final mappedSpot = _meetupSpotController.tailgateId == entry.id
          ? _meetupSpotController.spot
          : null;
      final latitude = entry.draft.latitude ?? mappedSpot?.latitude;
      final longitude = entry.draft.longitude ?? mappedSpot?.longitude;
      if (latitude != null && longitude != null) {
        final weather = await _gameRepository.weather(
          latitude: latitude,
          longitude: longitude,
          eventTime: entry.draft.date,
        );
        if (weather?.needsAlert ?? false) {
          alerts.add(
            GameDayAlert(
              id: '${entry.id}-weather-${weather!.weatherCode}',
              kind: GameDayAlertKind.weather,
              title: 'Weather may affect your tailgate',
              message: weather.summary,
              createdAt: now,
            ),
          );
        }
      }
    }
    if (!mounted) return;
    setState(() => _alerts = alerts);
    for (final alert in alerts.where(
      (item) =>
          item.kind == GameDayAlertKind.kickoff ||
          item.kind == GameDayAlertKind.weather,
    )) {
      if (_notifiedAlertIds.add(alert.id)) {
        await NotificationService.instance.showAlert(
          id: alert.id.hashCode & 0x7fffffff,
          title: alert.title,
          body: alert.message,
        );
      }
    }
  }

  DateTime _dateWithTime(DateTime date, String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return date;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final suffix = match.group(3)!.toUpperCase();
    if (suffix == 'PM' && hour != 12) hour += 12;
    if (suffix == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }

  String _formatTime(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${date.hour >= 12 ? 'PM' : 'AM'}';
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
      final joined = await _repository.join(entry);
      await _reloadTailgates();
      if (joined.joined) {
        await NotificationService.instance.scheduleTailgateReminder(joined);
      }
      if (mounted && !joined.joined) {
        final message = joined.membershipStatus == MembershipStatus.waitlisted
            ? 'This tailgate is full. You were added to the waitlist.'
            : 'Your request was sent to the host for approval.';
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      _showServerError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _completeTailgate(TailgateEntry entry) async {
    await _runTailgateAction(() => _repository.complete(entry));
  }

  Future<void> _archiveTailgate(TailgateEntry entry) async {
    await _runTailgateAction(() => _repository.archive(entry));
  }

  Future<void> _deleteTailgate(TailgateEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete ${entry.draft.name}?'),
        content: const Text(
          'This permanently removes the tailgate, memberships, invite code, and photo recap.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _runTailgateAction(() => _repository.delete(entry));
  }

  Future<void> _reportTailgate(TailgateEntry entry) async {
    var reason = '';
    var block = false;
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, update) => AlertDialog(
          title: Text('Report ${entry.draft.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                maxLength: 500,
                decoration: const InputDecoration(labelText: 'What happened?'),
                onChanged: (value) => reason = value,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: block,
                title: const Text('Also hide this host’s tailgates'),
                onChanged: (value) => update(() => block = value ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Submit report'),
            ),
          ],
        ),
      ),
    );
    if (submitted != true || reason.trim().isEmpty) return;
    await _runTailgateAction(
      () => _repository.report(entry, reason, block: block),
    );
  }

  Future<void> _manageJoinRequests(TailgateEntry entry) async {
    if (entry.pendingMemberIds.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join requests',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              ...entry.pendingMemberIds.map(
                (memberId) => ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline_rounded),
                  ),
                  title: Text('Guest ${memberId.substring(0, 6)}'),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _runTailgateAction(
                            () => _repository.reject(entry, memberId),
                          );
                        },
                        child: const Text('Reject'),
                      ),
                      FilledButton(
                        onPressed: () async {
                          Navigator.pop(sheetContext);
                          await _runTailgateAction(
                            () => _repository.approve(entry, memberId),
                          );
                        },
                        child: const Text('Approve'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runTailgateAction(Future<dynamic> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      await _reloadTailgates();
    } catch (error) {
      _showServerError(error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _autoCheckIn(MapCoordinate location) async {
    final spot = _meetupSpotController.spot;
    final joined = _tailgates.where((item) => item.joined);
    final entry = joined.isEmpty ? null : joined.first;
    if (spot == null || entry == null || _checkedIn) return;
    final distance = Geolocator.distanceBetween(
      location.latitude,
      location.longitude,
      spot.latitude,
      spot.longitude,
    );
    if (distance > 150) return;
    try {
      await _repository.checkIn(entry, true);
      if (!mounted) return;
      setState(() => _checkedIn = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You’re at the spot—checked in!')),
      );
    } catch (error) {
      _showServerError(error);
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
    _mapRepository = InMemoryMapRepository([
      lsuDefaultSpot(tailgateId: 'unselected'),
    ]);
    _meetupSpotController = MeetupSpotController(
      _mapRepository,
      tailgateId: 'unselected',
    );
    _meetupSpotController.addListener(_onMeetupSpotChanged);
    _meetupSpotController.load();
    _reloadTailgates();
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
    final joined = _tailgates.where((entry) => entry.joined).toList()
      ..sort((a, b) => a.draft.date.compareTo(b.draft.date));
    if (joined.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TailgateDetailScreen(
          initialTab: tabIndex,
          meetupSpotController: _meetupSpotController,
          mapProviderConfig: MapProviderConfig.fromEnvironment(),
          mapBuilder: widget.mapBuilder,
          entry: joined.first,
          currentUser: widget.session.displayName,
        ),
      ),
    );
  }

  Future<void> _hostTailgate() async {
    TailgateEntry? hosted;
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateTailgateScreen(
          mapBuilder: widget.mapBuilder,
          createOnServer: (draft) async {
            hosted = await _repository.createTailgate(draft);
            await _reloadTailgates();
            return hosted!;
          },
        ),
      ),
    );
    if (created == true && mounted) {
      if (hosted != null) {
        await NotificationService.instance.scheduleTailgateReminder(hosted!);
      }
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
      if (joined.joined) {
        await NotificationService.instance.scheduleTailgateReminder(joined);
      }
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
              alerts: _alerts,
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
              onComplete: _completeTailgate,
              onArchive: _archiveTailgate,
              onDelete: _deleteTailgate,
              onReport: _reportTailgate,
              onManageRequests: _manageJoinRequests,
            ),
            CrewScreen(crewCount: _crewCount),
            if (_pageIndex == 3)
              MapScreen(
                key: const ValueKey('active-map-screen'),
                controller: _meetupSpotController,
                providerConfig: MapProviderConfig.fromEnvironment(),
                mapBuilder: widget.mapBuilder,
                onLocationFound: _autoCheckIn,
              )
            else
              const SizedBox.expand(key: ValueKey('inactive-map-placeholder')),
            ProfileScreen(session: widget.session),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _pageIndex,
        onDestinationSelected: _goToPage,
        destinations: const [
          NavigationDestination(
            tooltip: '',
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            tooltip: '',
            icon: Icon(Icons.celebration_outlined),
            selectedIcon: Icon(Icons.celebration),
            label: 'Tailgates',
          ),
          NavigationDestination(
            tooltip: '',
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups_rounded),
            label: 'Crew',
          ),
          NavigationDestination(
            tooltip: '',
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded),
            label: 'Map',
          ),
          NavigationDestination(
            tooltip: '',
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
