import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class CrewScreen extends StatefulWidget {
  const CrewScreen({super.key});

  @override
  State<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends State<CrewScreen> {
  final Set<int> _claimed = {0, 2};

  static const _items = [
    (Icons.soup_kitchen_rounded, 'The gumbo', 'Jordan', 'Grill master'),
    (Icons.icecream_rounded, 'Ice & coolers', null, 'Still up for grabs'),
    (Icons.music_note_rounded, 'Game-day playlist', 'Alex', 'Music lead'),
    (Icons.sports_rounded, 'Cornhole', null, 'Still up for grabs'),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('crew-screen'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        AppHeader(
          action: IconButton.filledTonal(
            onPressed: () {},
            icon: const Icon(Icons.person_add_alt_1_rounded),
            tooltip: 'Invite crew',
          ),
        ),
        const SizedBox(height: 24),
        Text('Crew HQ', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 5),
        const Text(
          'People, supplies, and updates for Gumbo & Geaux.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        _buildCrewCard(),
        const SizedBox(height: 22),
        _sectionHeader(
          'Who’s bringing what?',
          '${_claimed.length} of ${_items.length} covered',
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final claimed = _claimed.contains(index);
              return Column(
                children: [
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFF1EBF8),
                      foregroundColor: AppColors.purple,
                      child: Icon(item.$1),
                    ),
                    title: Text(
                      item.$2,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      claimed ? '${item.$3} · ${item.$4}' : item.$4,
                    ),
                    trailing: claimed
                        ? IconButton(
                            onPressed: () =>
                                setState(() => _claimed.remove(index)),
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                            ),
                            tooltip: 'Unclaim item',
                          )
                        : OutlinedButton(
                            onPressed: () =>
                                setState(() => _claimed.add(index)),
                            child: const Text('I’ll bring it'),
                          ),
                  ),
                  if (index != _items.length - 1)
                    const Divider(height: 1, indent: 68, endIndent: 14),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 22),
        _sectionHeader('Game-day updates', '2 new'),
        const SizedBox(height: 12),
        const _UpdateCard(
          initials: 'J',
          name: 'Jordan · Grill master',
          message: 'Tent’s up by the gold flag 💜',
          time: '11:05 AM',
          color: AppColors.purple,
        ),
        const SizedBox(height: 9),
        const _UpdateCard(
          initials: 'M',
          name: 'Marcus · Drinks',
          message: 'Ice is here. Who has the speaker?',
          time: '11:40 AM',
          color: Color(0xFFC53A36),
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            hintText: 'Post an update…',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            suffixIcon: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.arrow_upward_rounded),
              tooltip: 'Post update',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCrewCard() {
    const members = [
      ('J', 'Jordan', 'Grill', AppColors.purple),
      ('M', 'Marcus', 'Drinks', Color(0xFFC53A36)),
      ('A', 'Alex', 'Chairs', AppColors.success),
      ('T', 'Taylor', 'Music', Color(0xFFE48725)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Expanded(
                  child: Text(
                    'The crew',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '8 GOING',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: members
                  .map(
                    (member) => Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: member.$4,
                          child: Text(
                            member.$1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          member.$2,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          member.$3,
                          style: const TextStyle(
                            fontSize: 9,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String detail) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
      Text(
        detail.toUpperCase(),
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: .8,
          color: AppColors.muted,
        ),
      ),
    ],
  );
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.initials,
    required this.name,
    required this.message,
    required this.time,
    required this.color,
  });
  final String initials;
  final String name;
  final String message;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(height: 3),
                Text(message),
                const SizedBox(height: 5),
                Text(
                  time,
                  style: const TextStyle(fontSize: 10, color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
