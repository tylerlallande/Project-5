import 'package:flutter/material.dart';

import '../features/tailgate_setup/tailgate_draft.dart';
import '../features/tailgate_setup/tailgate_repository.dart';
import '../theme/app_theme.dart';

class TailgatesScreen extends StatefulWidget {
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
    this.onComplete,
    this.onArchive,
    this.onDelete,
    this.onReport,
    this.onManageRequests,
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
  final ValueChanged<TailgateEntry>? onComplete;
  final ValueChanged<TailgateEntry>? onArchive;
  final ValueChanged<TailgateEntry>? onDelete;
  final ValueChanged<TailgateEntry>? onReport;
  final ValueChanged<TailgateEntry>? onManageRequests;

  @override
  State<TailgatesScreen> createState() => _TailgatesScreenState();
}

class _TailgatesScreenState extends State<TailgatesScreen> {
  String _query = '';
  List<TailgateEntry> get entries => widget.entries;
  ValueChanged<TailgateEntry> get onJoin => widget.onJoin;
  ValueChanged<TailgateEntry> get onLeave => widget.onLeave;
  ValueChanged<TailgateEntry> get onOpen => widget.onOpen;
  VoidCallback get onHost => widget.onHost;
  VoidCallback get onInvite => widget.onInvite;
  bool get loading => widget.loading;
  bool get busy => widget.busy;
  String? get error => widget.error;
  VoidCallback? get onRefresh => widget.onRefresh;

  @override
  Widget build(BuildContext context) {
    final mine = entries.where((entry) => entry.joined).toList();
    final discover = entries
        .where(
          (entry) =>
              entry.draft.isPublic &&
              !entry.joined &&
              (_query.isEmpty ||
                  entry.draft.name.toLowerCase().contains(_query) ||
                  entry.draft.game.toLowerCase().contains(_query) ||
                  entry.draft.location.toLowerCase().contains(_query)),
        )
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
              tooltip: '',
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
        TextField(
          key: const Key('public-tailgate-search'),
          decoration: const InputDecoration(
            labelText: 'Search public tailgates',
            hintText: 'Game, crew, or location',
            prefixIcon: Icon(Icons.search_rounded),
          ),
          onChanged: (value) =>
              setState(() => _query = value.trim().toLowerCase()),
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
            if (entry.membershipStatus == MembershipStatus.pending)
              const Text(
                'Waiting for host approval',
                style: TextStyle(color: AppColors.purple),
              ),
            if (entry.membershipStatus == MembershipStatus.waitlisted)
              Text(
                'Waitlisted · ${entry.waitlistCount} waiting',
                style: const TextStyle(color: AppColors.purple),
              ),
            if (entry.draft.capacity != null)
              Text(
                '${entry.memberCount} / ${entry.draft.capacity} spots filled',
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
                      if (entry.hosted &&
                          entry.status == TailgateStatus.upcoming)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => widget.onComplete?.call(entry),
                          child: const Text('Mark completed'),
                        ),
                      if (entry.hosted && entry.pendingCount > 0)
                        TextButton.icon(
                          onPressed: busy
                              ? null
                              : () => widget.onManageRequests?.call(entry),
                          icon: const Icon(Icons.how_to_reg_outlined),
                          label: Text('Review ${entry.pendingCount}'),
                        ),
                      if (entry.hosted &&
                          entry.status == TailgateStatus.completed)
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => widget.onArchive?.call(entry),
                          child: const Text('Archive'),
                        ),
                      if (entry.hosted &&
                          (entry.status == TailgateStatus.completed ||
                              entry.status == TailgateStatus.archived))
                        TextButton(
                          onPressed: busy
                              ? null
                              : () => widget.onDelete?.call(entry),
                          child: const Text('Delete'),
                        ),
                    ],
                  )
                : Wrap(
                    spacing: 8,
                    children: [
                      FilledButton(
                        key: Key('join-public-${entry.id}'),
                        onPressed: busy ? null : () => onJoin(entry),
                        child: Text(
                          entry.membershipStatus == MembershipStatus.pending
                              ? 'Approval pending'
                              : entry.membershipStatus ==
                                    MembershipStatus.waitlisted
                              ? 'On waitlist'
                              : 'Join tailgate',
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onReport?.call(entry),
                        child: const Text('Report or block'),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    ),
  );
}

class TailgateOverviewScreen extends StatelessWidget {
  const TailgateOverviewScreen({
    super.key,
    required this.entry,
    this.repository,
  });
  final TailgateEntry entry;
  final TailgateRepository? repository;
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
        if (entry.joined && repository != null)
          FilledButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TailgatePhotoRecapScreen(
                  entry: entry,
                  repository: repository!,
                ),
              ),
            ),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Open photo recap'),
          ),
      ],
    ),
  );
}

class TailgatePhotoRecapScreen extends StatefulWidget {
  const TailgatePhotoRecapScreen({
    super.key,
    required this.entry,
    required this.repository,
  });

  final TailgateEntry entry;
  final TailgateRepository repository;

  @override
  State<TailgatePhotoRecapScreen> createState() =>
      _TailgatePhotoRecapScreenState();
}

class _TailgatePhotoRecapScreenState extends State<TailgatePhotoRecapScreen> {
  List<TailgatePhoto> _photos = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final photos = await widget.repository.listPhotos(widget.entry);
      if (mounted) setState(() => _photos = photos);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _add() async {
    var url = '';
    var caption = '';
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add a recap photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Photo URL'),
              keyboardType: TextInputType.url,
              onChanged: (value) => url = value,
            ),
            const SizedBox(height: 12),
            TextField(
              maxLength: 200,
              decoration: const InputDecoration(labelText: 'Caption'),
              onChanged: (value) => caption = value,
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
            child: const Text('Add photo'),
          ),
        ],
      ),
    );
    if (submitted != true || url.trim().isEmpty) return;
    try {
      final photos = await widget.repository.addPhoto(
        widget.entry,
        url.trim(),
        caption.trim(),
      );
      if (mounted) setState(() => _photos = photos);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text('${widget.entry.draft.name} recap')),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: _add,
      icon: const Icon(Icons.add_photo_alternate_outlined),
      label: const Text('Add photo'),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_error != null)
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                if (_photos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: Center(
                      child: Text('No recap photos yet. Add the first one.'),
                    ),
                  ),
                ..._photos.map(
                  (photo) => Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            photo.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                        ),
                        if (photo.caption.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(photo.caption),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          ),
  );
}
