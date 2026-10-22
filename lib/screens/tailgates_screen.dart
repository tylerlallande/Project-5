import 'package:flutter/material.dart';

import '../features/tailgate_setup/tailgate_draft.dart';
import '../theme/app_theme.dart';

class TailgatesScreen extends StatelessWidget {
  const TailgatesScreen({
    super.key,
    required this.entries,
    required this.onJoin,
    required this.onLeave,
    required this.onHost,
    required this.onInvite,
    required this.onOpen,
    this.loading = false,
    this.busy = false,
    this.error,
    this.onRefresh,
  });
  final List<TailgateEntry> entries;
  final ValueChanged<TailgateEntry> onJoin;
  final ValueChanged<TailgateEntry> onLeave;
  final ValueChanged<TailgateEntry> onOpen;
  final VoidCallback onHost;
  final VoidCallback onInvite;
  final bool loading;
  final bool busy;
  final String? error;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final mine = entries.where((entry) => entry.joined).toList();
    final discover = entries
        .where((entry) => entry.draft.isPublic && !entry.joined)
        .toList();
    return ListView(
      key: const Key('tailgates-screen'),
      padding: const EdgeInsets.all(20),
      children: [
        Text('Tailgates', style: Theme.of(context).textTheme.headlineLarge),
        if (onRefresh != null)
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: busy || loading ? null : onRefresh,
              tooltip: 'Refresh tailgates',
              icon: const Icon(Icons.refresh),
            ),
          ),
        if (loading || busy) const LinearProgressIndicator(),
        if (error != null)
          Text(
            error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 8),
        const Text(
          'Your crew, your plans, and new people to meet.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: busy || loading ? null : onHost,
              icon: const Icon(Icons.add),
              label: const Text('Host a tailgate'),
            ),
            OutlinedButton.icon(
              onPressed: busy || loading ? null : onInvite,
              icon: const Icon(Icons.key),
              label: const Text('Join with code'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('My tailgates', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        if (!loading && mine.isEmpty)
          const Text('Join or host a tailgate to see it here.'),
        ...mine.map((entry) => _card(context, entry)),
        const SizedBox(height: 24),
        Text(
          'Public tailgates',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        const Text(
          'Anyone can join—no invite code needed.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 12),
        if (!loading && discover.isEmpty)
          const Text('No public tailgates available to join.'),
        ...discover.map((entry) => _card(context, entry)),
        const SizedBox(height: 20),
        const Text(
          'Tailgates and memberships are saved on the server.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _confirmLeave(BuildContext context, TailgateEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Leave ${entry.draft.name}?'),
        content: Text(
          entry.memberCount == 1
              ? 'You’re the last member. If you leave, this tailgate and its invite code will be permanently deleted.'
              : entry.draft.isPublic
              ? 'It will be removed from My tailgates. You can join again from Public tailgates.'
              : 'It will be removed from My tailgates. You’ll need the invite code to rejoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-leave-tailgate'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(entry.memberCount == 1 ? 'Leave and delete' : 'Leave'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) onLeave(entry);
  }

  Widget _card(BuildContext context, TailgateEntry entry) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.draft.name,
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(entry.draft.game),
            Text(
              '${entry.memberCount} ${entry.memberCount == 1 ? 'member' : 'members'}',
            ),
            Text(
              '${entry.draft.location} · ${entry.draft.meetupTime}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            Text(
              '${entry.hosted ? 'Hosting · ' : ''}${entry.draft.isPublic ? 'Public' : 'Private · invite only'}',
              style: const TextStyle(color: AppColors.purple),
            ),
            const SizedBox(height: 12),
            entry.joined
                ? Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () => onOpen(entry),
                        child: const Text('View tailgate'),
                      ),
                      TextButton.icon(
                        key: Key('leave-tailgate-${entry.id}'),
                        onPressed: busy
                            ? null
                            : () => _confirmLeave(context, entry),
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('Leave tailgate'),
                      ),
                    ],
                  )
                : FilledButton(
                    key: Key('join-public-${entry.id}'),
                    onPressed: busy ? null : () => onJoin(entry),
                    child: const Text('Join tailgate'),
                  ),
          ],
        ),
      ),
    ),
  );
}

class TailgateOverviewScreen extends StatelessWidget {
  const TailgateOverviewScreen({super.key, required this.entry});
  final TailgateEntry entry;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(entry.draft.name)),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          entry.draft.game,
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 20),
        ListTile(
          leading: const Icon(Icons.location_on),
          title: Text(entry.draft.location),
        ),
        ListTile(
          leading: const Icon(Icons.calendar_month),
          title: Text(
            '${entry.draft.date.month}/${entry.draft.date.day}/${entry.draft.date.year}',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: Text(
            'Meet ${entry.draft.meetupTime} · Kickoff ${entry.draft.kickoff}',
          ),
        ),
        ListTile(
          leading: const Icon(Icons.celebration),
          title: Text(entry.draft.vibe),
        ),
        ListTile(
          leading: Icon(
            entry.draft.isPublic ? Icons.public : Icons.lock_outline,
          ),
          title: Text(
            entry.draft.isPublic ? 'Public tailgate' : 'Private tailgate',
          ),
        ),
        if (entry.joined)
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Invite code'),
            subtitle: SelectableText(entry.code),
          ),
      ],
    ),
  );
}
