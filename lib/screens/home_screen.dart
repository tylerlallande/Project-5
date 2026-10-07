import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _checkedIn = false;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const Key('home-screen'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          sliver: SliverList.list(
            children: [
              AppHeader(
                action: IconButton.filledTonal(
                  tooltip: 'Notifications',
                  onPressed: () => _showMessage('You’re all caught up.'),
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
              ),
              const SizedBox(height: 24),
              _buildEventCard(),
              const SizedBox(height: 22),
              Text(
                'Quick actions',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _buildQuickActions(),
              const SizedBox(height: 22),
              _sectionTitle('My tailgates', '2 upcoming'),
              const SizedBox(height: 12),
              _tailgateTile(
                color: AppColors.gold,
                icon: Icons.local_fire_department_rounded,
                date: 'SAT · OCT 10',
                title: 'Gumbo & Geaux',
                detail: 'Oak Grove · You’re hosting',
                people: '8 going',
              ),
              const SizedBox(height: 10),
              _tailgateTile(
                color: const Color(0xFFE8DDF6),
                icon: Icons.park_rounded,
                date: 'SAT · OCT 24',
                title: 'The Purple Lot',
                detail: 'Parade Ground · Joined',
                people: '5 going',
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () =>
                    _showMessage('Join-by-code is next on the build list.'),
                icon: const Icon(Icons.key_rounded),
                label: const Text('Join with an invite code'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: () =>
                    _showMessage('Tailgate creation is coming next.'),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Host a tailgate'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEventCard() {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.purple, AppColors.deepPurple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30482080),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -25,
            top: -35,
            child: Icon(
              Icons.sports_football,
              size: 160,
              color: Colors.white.withValues(alpha: .06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR NEXT TAILGATE · 4 DAYS',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'LSU vs. Alabama',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Sat 6:30 PM kickoff · Gumbo & Geaux',
                  style: TextStyle(
                    color: Color(0xFFD9CFE8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Color(0x55FFFFFF), height: 1),
                ),
                const Row(
                  children: [
                    Expanded(
                      child: _EventStat(label: 'CREW', value: '8 Tigers'),
                    ),
                    Expanded(
                      child: _EventStat(
                        label: 'SUPPLIES',
                        value: '6 / 8 ready',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        key: const Key('check-in-button'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _checkedIn
                              ? AppColors.success
                              : AppColors.gold,
                          foregroundColor: AppColors.deepPurple,
                        ),
                        onPressed: () =>
                            setState(() => _checkedIn = !_checkedIn),
                        icon: Icon(
                          _checkedIn
                              ? Icons.check_circle_rounded
                              : Icons.near_me_rounded,
                        ),
                        label: Text(_checkedIn ? 'Checked in' : 'Count me in'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton.filled(
                      tooltip: 'Open map',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .13),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => widget.onNavigate(2),
                      icon: const Icon(Icons.map_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      (Icons.checklist_rounded, 'Bring list', '6 of 8 ready', 1),
      (Icons.groups_rounded, 'Crew', '8 going', 1),
      (Icons.location_on_rounded, 'The spot', 'Oak Grove', 2),
      (Icons.campaign_rounded, 'Updates', '2 new', 1),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisExtent: 84,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Material(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => widget.onNavigate(action.$4),
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEFE8F7),
                    foregroundColor: AppColors.purple,
                    child: Icon(action.$1, size: 21),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.$2,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          action.$3,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title, String trailing) => Row(
    children: [
      Expanded(
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
      Text(
        trailing.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: AppColors.muted,
        ),
      ),
    ],
  );

  Widget _tailgateTile({
    required Color color,
    required IconData icon,
    required String date,
    required String title,
    required String detail,
    required String people,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => widget.onNavigate(1),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 68,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppColors.deepPurple),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: .8,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    people,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.purple,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _EventStat extends StatelessWidget {
  const _EventStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          color: Color(0xFFBFAED5),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 17,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}
