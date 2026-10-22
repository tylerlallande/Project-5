import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../bring_list/bring_list_section.dart';
import '../map/map_links.dart';
import '../map/map_provider_config.dart';
import '../map/meetup_map.dart';
import '../map/meetup_spot.dart';
import '../map/meetup_spot_controller.dart';
import '../tailgate_setup/tailgate_draft.dart';
import '../tailgate_setup/tailgate_repository.dart';

class TailgateDetailScreen extends StatelessWidget {
  const TailgateDetailScreen({
    super.key,
    this.initialTab = 0,
    required this.meetupSpotController,
    required this.mapProviderConfig,
    this.mapBuilder,
    this.directionsLauncher = openDirections,
    this.entry,
    this.currentUser = 'Crew member',
    this.repository,
  });

  final int initialTab;
  final MeetupSpotController meetupSpotController;
  final MapProviderConfig mapProviderConfig;
  final MeetupMapBuilder? mapBuilder;
  final DirectionsLauncher directionsLauncher;
  final TailgateEntry? entry;
  final String currentUser;
  final TailgateRepository? repository;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        appBar: AppBar(
          title: Text(entry?.draft.name ?? 'Tailgate'),
          actions: [
            IconButton(
              tooltip: '',
              onPressed: () {},
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            _TailgateSummary(controller: meetupSpotController, entry: entry),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: _TailgateTabBar(),
            ),
            Expanded(
              child: TabBarView(
                key: Key('tailgate-tab-view'),
                children: [
                  _BringTab(
                    currentUser: currentUser,
                    entry: entry,
                    repository: repository,
                  ),
                  _SpotTab(
                    controller: meetupSpotController,
                    providerConfig: mapProviderConfig,
                    mapBuilder: mapBuilder,
                    directionsLauncher: directionsLauncher,
                  ),
                  const _UpdatesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TailgateSummary extends StatelessWidget {
  const _TailgateSummary({required this.controller, this.entry});

  final MeetupSpotController controller;
  final TailgateEntry? entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.purple, AppColors.deepPurple],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            (entry?.draft.game ?? 'TAILGATE').toUpperCase(),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            entry == null
                ? 'Game details unavailable'
                : '${entry!.draft.date.month}/${entry!.draft.date.day}/${entry!.draft.date.year} · ${entry!.draft.kickoff} kickoff',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                color: Color(0xFFD9CFE8),
                size: 17,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: AnimatedBuilder(
                  animation: controller,
                  builder: (context, _) => Text(
                    controller.spot == null
                        ? 'Loading meetup spot…'
                        : '${controller.spot!.name} · Meet at ${controller.spot!.meetupTime}',
                    style: const TextStyle(
                      color: Color(0xFFD9CFE8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const Icon(
                Icons.groups_rounded,
                color: Color(0xFFD9CFE8),
                size: 17,
              ),
              const SizedBox(width: 5),
              Text(
                '${entry?.memberCount ?? 0} going',
                style: const TextStyle(
                  color: Color(0xFFD9CFE8),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TailgateTabBar extends StatelessWidget {
  const _TailgateTabBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.purple,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.muted,
        labelStyle: const TextStyle(fontWeight: FontWeight.w800),
        tabs: const [
          Tab(key: Key('tailgate-bring-tab'), text: 'Bring'),
          Tab(key: Key('tailgate-spot-tab'), text: 'Spot'),
          Tab(key: Key('tailgate-updates-tab'), text: 'Updates'),
        ],
      ),
    );
  }
}

class _BringTab extends StatelessWidget {
  const _BringTab({
    required this.currentUser,
    required this.entry,
    required this.repository,
  });

  final String currentUser;
  final TailgateEntry? entry;
  final TailgateRepository? repository;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('tailgate-bring-content'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: BringListSection(
        currentUser: currentUser,
        entry: entry,
        repository: repository,
      ),
    );
  }
}

class _SpotTab extends StatelessWidget {
  const _SpotTab({
    required this.controller,
    required this.providerConfig,
    required this.mapBuilder,
    required this.directionsLauncher,
  });

  final MeetupSpotController controller;
  final MapProviderConfig providerConfig;
  final MeetupMapBuilder? mapBuilder;
  final DirectionsLauncher directionsLauncher;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final spot = controller.spot;
        if (spot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _SpotContent(
          spot: spot,
          controller: controller,
          providerConfig: providerConfig,
          mapBuilder: mapBuilder,
          directionsLauncher: directionsLauncher,
        );
      },
    );
  }
}

class _SpotContent extends StatelessWidget {
  const _SpotContent({
    required this.spot,
    required this.controller,
    required this.providerConfig,
    required this.mapBuilder,
    required this.directionsLauncher,
  });

  final MeetupSpot spot;
  final MeetupSpotController controller;
  final MapProviderConfig providerConfig;
  final MeetupMapBuilder? mapBuilder;
  final DirectionsLauncher directionsLauncher;

  Future<void> _openDirections(BuildContext context) async {
    await confirmAndOpenDirections(context, spot, directionsLauncher);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('tailgate-spot-content'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Text('Meetup spot', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 5),
        Text(
          '${spot.instructions} ${spot.name}.',
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        AspectRatio(
          aspectRatio: 1.45,
          child: MeetupMap(
            spot: spot,
            providerConfig: providerConfig,
            compact: true,
            mapBuilder: mapBuilder,
            onSpotMoved: controller.save,
            onPinTapped: () => _openDirections(context),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SpotStat(label: 'MEET THERE', value: spot.meetupTime),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SpotStat(
                label: 'TO STADIUM',
                value: '${spot.walkToStadiumMinutes} min walk',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => _openDirections(context),
          icon: const Icon(Icons.directions_rounded),
          label: const Text('Get directions'),
        ),
      ],
    );
  }
}

class _SpotStat extends StatelessWidget {
  const _SpotStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: .8,
                color: AppColors.muted,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpdatesTab extends StatefulWidget {
  const _UpdatesTab();

  @override
  State<_UpdatesTab> createState() => _UpdatesTabState();
}

class _UpdatesTabState extends State<_UpdatesTab> {
  final List<
    ({String author, String role, String message, String time, Color color})
  >
  _updates = [
    (
      author: 'Jordan',
      role: 'Grill master',
      message: 'Tent’s up by the gold flag 💜',
      time: '11:05 AM',
      color: AppColors.purple,
    ),
    (
      author: 'Marcus',
      role: 'Drinks',
      message: 'Ice is here. Who has the speaker?',
      time: '11:40 AM',
      color: Color(0xFFC53A36),
    ),
  ];
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const Key('tailgate-updates-content'),
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            itemCount: _updates.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) =>
                _UpdateCard(update: _updates[index]),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: TextField(
            key: const Key('tailgate-update-field'),
            controller: _controller,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: 'Post a game-day update…',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              suffixIcon: IconButton(
                key: const Key('post-tailgate-update'),
                tooltip: '',
                onPressed: _postUpdate,
                icon: const Icon(Icons.arrow_upward_rounded),
              ),
            ),
            onSubmitted: (_) => _postUpdate(),
          ),
        ),
      ],
    );
  }

  void _postUpdate() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _updates.add((
        author: 'Alex',
        role: 'Coordinator',
        message: message,
        time: 'Now',
        color: AppColors.success,
      ));
      _controller.clear();
    });
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({required this.update});

  final ({String author, String role, String message, String time, Color color})
  update;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: update.color,
              child: Text(
                update.author.characters.first,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${update.author} · ${update.role}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.purple,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(update.message),
                  const SizedBox(height: 6),
                  Text(
                    update.time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
