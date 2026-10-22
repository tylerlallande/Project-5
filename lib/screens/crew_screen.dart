import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/bring_list/bring_list_section.dart';
import '../features/tailgate_setup/tailgate_draft.dart';
import '../features/tailgate_setup/tailgate_repository.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class CrewScreen extends StatefulWidget {
  const CrewScreen({
    super.key,
    this.members = const [],
    this.currentUser = 'You',
    this.tailgateName,
    this.inviteCode = '',
    this.showBrandHeader = true,
    this.entry,
    this.repository,
  });
  final List<CrewMember> members;
  final String currentUser;
  final String? tailgateName;
  final String inviteCode;
  final bool showBrandHeader;
  final TailgateEntry? entry;
  final TailgateRepository? repository;

  @override
  State<CrewScreen> createState() => _CrewScreenState();
}

class _CrewScreenState extends State<CrewScreen> {
  List<CrewMember> get _members => widget.members.isNotEmpty
      ? widget.members
      : [
          CrewMember(
            id: 'current-user',
            displayName: widget.currentUser,
            isHost: true,
          ),
        ];

  Color _memberColor(int index) => const [
    AppColors.purple,
    Color(0xFFC53A36),
    AppColors.success,
    Color(0xFFE48725),
  ][index % 4];

  String _initial(String name) {
    final clean = name.trim();
    return clean.isEmpty ? '?' : clean[0].toUpperCase();
  }

  Future<void> _showInvite() async {
    if (widget.inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Host or join a tailgate before inviting crew.'),
        ),
      );
      return;
    }
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Invite your crew'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Share this code so another person can join:'),
            const SizedBox(height: 12),
            SelectableText(
              widget.inviteCode,
              key: const Key('crew-invite-code'),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: AppColors.purple,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
          FilledButton.icon(
            key: const Key('copy-crew-invite'),
            onPressed: () async {
              await Clipboard.setData(
                ClipboardData(
                  text:
                      'Join ${widget.tailgateName ?? 'my tailgate'} in Tgate with code ${widget.inviteCode}',
                ),
              );
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy invite'),
          ),
        ],
      ),
    );
  }

  void _showMembers() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Crew members (${_members.length})')),
          body: SafeArea(
            child: ListView(
              key: const Key('crew-members-list'),
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  widget.tailgateName ?? 'Your tailgate crew',
                  style: const TextStyle(color: AppColors.muted),
                ),
                const SizedBox(height: 12),
                ..._members.indexed.map(
                  (item) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _memberColor(item.$1),
                      child: Text(
                        _initial(item.$2.displayName),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(item.$2.displayName),
                    subtitle: Text(item.$2.isHost ? 'Host' : 'Crew member'),
                    trailing: Icon(
                      item.$2.checkedIn
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      color: item.$2.checkedIn
                          ? AppColors.success
                          : AppColors.muted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('crew-screen'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        if (widget.showBrandHeader) ...[
          const AppHeader(),
          const SizedBox(height: 24),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                'Crew HQ',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
            ),
            IconButton.filledTonal(
              key: const Key('invite-crew'),
              onPressed: _showInvite,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              tooltip: '',
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          widget.tailgateName == null
              ? 'Host or join a tailgate to build your crew.'
              : 'People and supplies for ${widget.tailgateName}.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 20),
        _buildCrewCard(),
        const SizedBox(height: 22),
        BringListSection(
          currentUser: widget.currentUser,
          entry: widget.entry,
          repository: widget.repository,
        ),
        const SizedBox(height: 22),
        _sectionHeader('Game-day updates', '0 new'),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'No crew updates yet.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
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
              tooltip: '',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCrewCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'The crew',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                ),
                Text(
                  '${_members.length} GOING',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.spaceAround,
              spacing: 16,
              runSpacing: 12,
              children: _members.indexed
                  .take(4)
                  .map(
                    (item) => Column(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: _memberColor(item.$1),
                          child: Text(
                            _initial(item.$2.displayName),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.$2.displayName,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.$2.isHost
                              ? 'Host'
                              : item.$2.checkedIn
                              ? 'Checked in'
                              : 'Crew',
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
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                key: const Key('see-all-crew'),
                onPressed: _showMembers,
                child: const Text('See all members'),
              ),
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
