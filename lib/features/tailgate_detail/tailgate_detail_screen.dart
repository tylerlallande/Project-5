import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../bring_list/bring_list_section.dart';

class TailgateDetailScreen extends StatelessWidget {
  const TailgateDetailScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: initialTab.clamp(0, 2),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gumbo & Geaux'),
          actions: [
            IconButton(
              tooltip: 'Tailgate options',
              onPressed: () {},
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
        body: Column(
          children: [
            const _TailgateSummary(),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: _TailgateTabBar(),
            ),
            const Expanded(
              child: TabBarView(
                key: Key('tailgate-tab-view'),
                children: [_BringTab(), _SpotTab(), _UpdatesTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TailgateSummary extends StatelessWidget {
  const _TailgateSummary();

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
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LSU VS. ALABAMA',
            style: TextStyle(
              color: AppColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Saturday · 6:30 PM kickoff',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 9),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                color: Color(0xFFD9CFE8),
                size: 17,
              ),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Oak Grove · Meet at 11:00 AM',
                  style: TextStyle(
                    color: Color(0xFFD9CFE8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.groups_rounded, color: Color(0xFFD9CFE8), size: 17),
              SizedBox(width: 5),
              Text(
                '8 going',
                style: TextStyle(
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
  const _BringTab();

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(
      key: Key('tailgate-bring-content'),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: BringListSection(),
    );
  }
}

class _SpotTab extends StatelessWidget {
  const _SpotTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('tailgate-spot-content'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      children: [
        Text('Meetup spot', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 5),
        const Text(
          'Find the tent with the gold flag in Oak Grove.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 14),
        const _MapPreview(),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _SpotStat(label: 'MEET THERE', value: '11:00 AM'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _SpotStat(label: 'TO STADIUM', value: '6 min walk'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: null,
          icon: Icon(Icons.directions_rounded),
          label: Text('Get directions'),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit_location_alt_outlined),
          label: const Text('Move the meetup pin'),
        ),
      ],
    );
  }
}

class _MapPreview extends StatelessWidget {
  const _MapPreview();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.45,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: const Color(0xFFECE8DE),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          children: [
            const Positioned(
              left: -30,
              top: -30,
              child: CircleAvatar(
                radius: 95,
                backgroundColor: Color(0xFFCFE4C2),
              ),
            ),
            const Positioned(
              right: -35,
              bottom: -50,
              child: CircleAvatar(
                radius: 90,
                backgroundColor: Color(0xFFDDD0EE),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 85,
              child: Container(height: 11, color: Colors.white),
            ),
            Positioned(
              left: 165,
              top: 0,
              bottom: 0,
              child: Container(width: 11, color: Colors.white),
            ),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_pin, size: 54, color: Color(0xFFE8306C)),
                  Card(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      child: Text(
                        'Oak Grove · gold flag',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
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
                tooltip: 'Post update',
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
