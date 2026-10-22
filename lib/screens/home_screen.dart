import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../features/tailgate_setup/tailgate_draft.dart';
import '../features/alerts/game_day_alert.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onNavigate,
    required this.onOpenTailgate,
    required this.onHostTailgate,
    required this.onJoinTailgate,
    required this.checkedIn,
    required this.onCheckInChanged,
    required this.tailgates,
    required this.onOpenEntry,
    this.alerts = const [],
  });

  final ValueChanged<int> onNavigate;
  final ValueChanged<int> onOpenTailgate;
  final VoidCallback onHostTailgate;
  final VoidCallback onJoinTailgate;
  final bool checkedIn;
  final ValueChanged<bool> onCheckInChanged;
  final List<TailgateEntry> tailgates;
  final ValueChanged<TailgateEntry> onOpenEntry;
  final List<GameDayAlert> alerts;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool get _checkedIn => widget.checkedIn;
  TailgateEntry? get _nextTailgate {
    final upcoming =
        widget.tailgates
            .where(
              (entry) => !entry.draft.date.isBefore(
                DateTime.now().subtract(const Duration(days: 1)),
              ),
            )
            .toList()
          ..sort((a, b) => a.draft.date.compareTo(b.draft.date));
    return upcoming.isEmpty ? null : upcoming.first;
  }

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
                  tooltip: '',
                  onPressed: _showAlerts,
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
              _sectionTitle(
                'My tailgates',
                '${widget.tailgates.length} joined',
              ),
              const SizedBox(height: 12),
              if (widget.tailgates.isEmpty)
                const Text('Join or host a tailgate to get started.'),
              ...widget.tailgates.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _tailgateTile(
                    color: AppColors.gold,
                    icon: Icons.celebration,
                    date:
                        '${entry.draft.date.month}/${entry.draft.date.day}/${entry.draft.date.year}',
                    title: entry.draft.name,
                    detail:
                        '${entry.draft.location} · ${entry.hosted ? 'Hosting' : 'Joined'}',
                    people: '${entry.memberCount} going',
                    onTap: () => widget.onOpenEntry(entry),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: widget.onJoinTailgate,
                icon: const Icon(Icons.key_rounded),
                label: const Text('Join with an invite code'),
              ),
              const SizedBox(height: 10),
              FilledButton.icon(
                onPressed: widget.onHostTailgate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Host a tailgate'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showAlerts() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Game-day alerts',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              if (widget.alerts.isEmpty)
                const Text('You’re all caught up.')
              else
                ...widget.alerts.map(
                  (alert) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(child: Icon(alert.icon)),
                    title: Text(alert.title),
                    subtitle: Text(alert.message),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard() {
    final entry = _nextTailgate;
    if (entry == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.sports_football_outlined,
                color: AppColors.purple,
                size: 36,
              ),
              const SizedBox(height: 14),
              Text(
                'No upcoming tailgate',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              const Text(
                'Host a tailgate or join a public crew to put your game-day plan here.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: widget.onHostTailgate,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Host a tailgate'),
              ),
            ],
          ),
        ),
      );
    }
    final now = DateTime.now();
    final eventDay = DateTime(
      entry.draft.date.year,
      entry.draft.date.month,
      entry.draft.date.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final days = eventDay.difference(today).inDays;
    final countdown = days == 0
        ? 'TODAY'
        : days == 1
        ? 'TOMORROW'
        : 'IN $days DAYS';
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
                Text(
                  'YOUR NEXT TAILGATE · $countdown',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  entry.draft.game,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_formatDate(entry.draft.date)} · ${entry.draft.kickoff} kickoff · ${entry.draft.name}',
                  style: const TextStyle(
                    color: Color(0xFFD9CFE8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Divider(color: Color(0x55FFFFFF), height: 1),
                ),
                Row(
                  children: [
                    Expanded(
                      child: _EventStat(
                        label: 'CREW',
                        value: '${entry.memberCount} going',
                      ),
                    ),
                    Expanded(
                      child: _EventStat(
                        label: 'MEETUP',
                        value: entry.draft.meetupTime,
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
                        onPressed: () => widget.onCheckInChanged(!_checkedIn),
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
                      tooltip: '',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .13),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => widget.onOpenTailgate(1),
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
    final entry = _nextTailgate;
    if (entry == null) {
      return const Text(
        'Quick actions appear after you host or join a tailgate.',
        style: TextStyle(color: AppColors.muted),
      );
    }
    final actions = [
      (
        icon: Icons.checklist_rounded,
        title: 'Bring list',
        detail: 'Manage supplies',
        onTap: () => widget.onOpenTailgate(0),
      ),
      (
        icon: Icons.groups_rounded,
        title: 'Crew',
        detail: '${entry.memberCount} going',
        onTap: () => widget.onNavigate(1),
      ),
      (
        icon: Icons.location_on_rounded,
        title: 'The spot',
        detail: entry.draft.location,
        onTap: () => widget.onOpenTailgate(1),
      ),
      (
        icon: Icons.campaign_rounded,
        title: 'Updates',
        detail: 'View crew posts',
        onTap: () => widget.onOpenTailgate(2),
      ),
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
            onTap: action.onTap,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: const Color(0xFFEFE8F7),
                    foregroundColor: AppColors.purple,
                    child: Icon(action.icon, size: 21),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          action.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          action.detail,
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

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}';
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
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap ?? () => widget.onOpenTailgate(0),
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
