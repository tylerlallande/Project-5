import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../map/current_location.dart';
import '../map/map_provider_config.dart';
import '../map/map_defaults.dart';
import '../map/meetup_map.dart';
import '../map/meetup_spot.dart';
import 'tailgate_draft.dart';
import '../game/game_event.dart';
import '../game/game_repository.dart';

class CreateTailgateScreen extends StatefulWidget {
  const CreateTailgateScreen({
    super.key,
    this.onCreated,
    this.inviteCode = 'GEAUX7',
    this.createOnServer,
    this.gameRepository,
    this.mapBuilder,
    this.locationLoader = loadCurrentLocation,
  });
  final ValueChanged<TailgateDraft>? onCreated;
  final String inviteCode;
  final Future<TailgateEntry> Function(TailgateDraft)? createOnServer;
  final GameRepository? gameRepository;
  final MeetupMapBuilder? mapBuilder;
  final LocationLoader locationLoader;

  @override
  State<CreateTailgateScreen> createState() => _CreateTailgateScreenState();
}

class _CreateTailgateScreenState extends State<CreateTailgateScreen> {
  final _gameController = TextEditingController();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _capacityController = TextEditingController();
  int _step = 0;
  DateTime _date = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _kickoff = const TimeOfDay(hour: 18, minute: 30);
  TimeOfDay _meetup = const TimeOfDay(hour: 11, minute: 0);
  String _vibe = 'Food & drinks';
  bool _isPublic = false;
  bool _requiresApproval = false;
  String? _gameError;
  String? _nameError;
  String? _locationError;
  TailgateDraft? _createdTailgate;
  bool _saving = false;
  String? _savedCode;
  String? _gameId;
  bool _loadingGames = false;
  bool _locating = false;
  MapCoordinate? _userLocation;
  MeetupSpot? _selectedSpot = lsuDefaultSpot(tailgateId: 'draft');

  Future<void> _chooseGame() async {
    setState(() => _loadingGames = true);
    final repository = widget.gameRepository ?? GameRepository();
    final games = await repository.schedule();
    if (!mounted) return;
    setState(() => _loadingGames = false);
    if (games.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            repository.scheduleNotice ?? 'No games are available for this season. You can enter the game manually.',
          ),
        ),
      );
      return;
    }
    final selected = await showModalBottomSheet<GameEvent>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text(
              'Choose a game',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            ...games.map(
              (game) => ListTile(
                leading: const Icon(Icons.sports_football_rounded),
                title: Text(game.matchup),
                subtitle: Text(
                  '${game.startTime.month}/${game.startTime.day}/${game.startTime.year}'
                  '${game.venue == null ? '' : ' · ${game.venue}'}',
                ),
                onTap: () => Navigator.pop(context, game),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _gameId = selected.id;
      _gameController.text = selected.matchup;
      _date = selected.startTime;
      _kickoff = TimeOfDay.fromDateTime(selected.startTime);
      if ((selected.venue ?? '').isNotEmpty) {
        _locationController.text = selected.venue!;
      }
      _gameError = null;
    });
  }

  @override
  void dispose() {
    _gameController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_createdTailgate != null) {
      return _InviteCodeResult(
        tailgate: _createdTailgate!,
        code: _savedCode ?? widget.inviteCode,
        onDone: () => Navigator.pop(context, true),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Host a tailgate')),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            _ProgressHeader(step: _step),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  child: switch (_step) {
                    0 => _buildEventStep(),
                    1 => _buildPlanStep(),
                    _ => _buildReviewStep(),
                  },
                ),
              ),
            ),
            _buildBottomActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildEventStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What are we celebrating?',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 7),
        const Text(
          'Start with the game and give your tailgate a name.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 24),
        SwitchListTile(
          key: const Key('public-tailgate-toggle'),
          contentPadding: EdgeInsets.zero,
          title: const Text('Public tailgate'),
          subtitle: Text(
            _isPublic
                ? 'Anyone can discover and join without an invite code.'
                : 'Private: guests need your invite code to join.',
          ),
          value: _isPublic,
          onChanged: (value) => setState(() => _isPublic = value),
        ),
        const SizedBox(height: 18),
        OutlinedButton.icon(
          key: const Key('choose-scheduled-game'),
          onPressed: _loadingGames ? null : _chooseGame,
          icon: const Icon(Icons.event_available_outlined),
          label: Text(
            _loadingGames ? 'Loading schedule…' : 'Choose from live schedule',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('create-game-field'),
          controller: _gameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Game',
            hintText: 'LSU vs. Alabama',
            errorText: _gameError,
            prefixIcon: const Icon(Icons.sports_football_rounded),
          ),
          onChanged: (_) => setState(() => _gameError = null),
        ),
        const SizedBox(height: 18),
        TextField(
          key: const Key('tailgate-capacity-field'),
          controller: _capacityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: 'Guest capacity (optional)',
            hintText: 'Leave blank for no limit',
            prefixIcon: Icon(Icons.groups_2_outlined),
          ),
        ),
        if (_isPublic)
          SwitchListTile(
            key: const Key('join-approval-toggle'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Approve join requests'),
            subtitle: const Text(
              'New guests wait for the host to approve them.',
            ),
            value: _requiresApproval,
            onChanged: (value) => setState(() => _requiresApproval = value),
          ),
        const SizedBox(height: 18),
        TextField(
          key: const Key('create-name-field'),
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Tailgate name',
            hintText: 'Gumbo & Geaux',
            errorText: _nameError,
            prefixIcon: const Icon(Icons.celebration_rounded),
          ),
          onChanged: (_) => setState(() => _nameError = null),
        ),
      ],
    );
  }

  Widget _buildPlanStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Set the game plan',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 7),
        const Text(
          'Your crew will see these details as soon as they join.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.purple,
                ),
                title: const Text('Game day'),
                subtitle: Text(_formatDate(_date)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickDate,
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(
                  Icons.stadium_rounded,
                  color: AppColors.purple,
                ),
                title: const Text('Kickoff'),
                subtitle: Text(_kickoff.format(context)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _pickTime(isKickoff: true),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.purple,
                ),
                title: const Text('Meetup time'),
                subtitle: Text(_meetup.format(context)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _pickTime(isKickoff: false),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          key: const Key('create-location-field'),
          controller: _locationController,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Meetup location',
            errorText: _locationError,
            prefixIcon: const Icon(Icons.location_on_outlined),
          ),
          onChanged: (_) => setState(() => _locationError = null),
        ),
        const SizedBox(height: 18),
        _buildLocationPicker(),
        const SizedBox(height: 20),
        const Text(
          'Vibe',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Food & drinks', 'Family friendly', 'Music', 'Big crew']
              .map(
                (vibe) => ChoiceChip(
                  label: Text(vibe),
                  selected: _vibe == vibe,
                  onSelected: (_) => setState(() => _vibe = vibe),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildLocationPicker() {
    final spot = _selectedSpot;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tailgate pin',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        const Text(
          'The map starts at LSU. Select “Set tailgate pin” and tap the exact meetup spot, or use your current location.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            key: const Key('create-tailgate-map-start'),
            onPressed: _locating ? null : _startLocationPin,
            icon: _locating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location_rounded),
            label: Text(
              _locating ? 'Finding your location…' : 'Use my current location',
            ),
          ),
        ),
        if (spot != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 330,
            child: MeetupMap(
              key: const ValueKey('create-tailgate-meetup-map'),
              spot: spot,
              providerConfig: MapProviderConfig.fromEnvironment(),
              mapBuilder: widget.mapBuilder,
              userLocation: _userLocation,
              onSpotMoved: (updated) => setState(() => _selectedSpot = updated),
              onPinTapped: _showCreationPinActions,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${spot.latitude.toStringAsFixed(5)}, ${spot.longitude.toStringAsFixed(5)}',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ],
    );
  }

  Future<void> _startLocationPin() async {
    setState(() => _locating = true);
    try {
      final location = await widget.locationLoader();
      if (!mounted) return;
      setState(() {
        _userLocation = location;
        _selectedSpot = MeetupSpot(
          tailgateId: 'draft',
          name: _locationController.text.trim().isEmpty
              ? 'Tailgate spot'
              : _locationController.text.trim(),
          instructions: 'Meet the crew at the pinned tailgate location.',
          latitude: location.latitude,
          longitude: location.longitude,
          meetupTime: _meetup.format(context),
          walkToStadiumMinutes: 0,
        );
      });
    } on LocationUnavailable catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your location could not be found.')),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showCreationPinActions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          leading: const Icon(Icons.delete_outline_rounded),
          title: const Text('Remove tailgate pin'),
          subtitle: const Text(
            'The map will return to its LSU starting point.',
          ),
          onTap: () {
            Navigator.pop(sheetContext);
            setState(() {
              _userLocation = null;
              _selectedSpot = lsuDefaultSpot(tailgateId: 'draft');
            });
          },
        ),
      ),
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review your tailgate',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: 7),
        const Text(
          'Make sure everything looks right before inviting the crew.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 22),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _ReviewRow(
                  icon: Icons.sports_football_rounded,
                  label: 'Game',
                  value: _gameController.text.trim(),
                ),
                _ReviewRow(
                  icon: Icons.groups_2_outlined,
                  label: 'Capacity',
                  value: _capacityController.text.trim().isEmpty
                      ? 'No limit'
                      : '${_capacityController.text.trim()} guests',
                ),
                _ReviewRow(
                  icon: Icons.how_to_reg_outlined,
                  label: 'Joining',
                  value: _requiresApproval
                      ? 'Host approval required'
                      : 'Immediate when space is available',
                ),
                _ReviewRow(
                  icon: Icons.celebration_rounded,
                  label: 'Tailgate',
                  value: _nameController.text.trim(),
                ),
                _ReviewRow(
                  icon: Icons.calendar_month_rounded,
                  label: 'Date',
                  value: _formatDate(_date),
                ),
                _ReviewRow(
                  icon: Icons.schedule_rounded,
                  label: 'Times',
                  value:
                      '${_meetup.format(context)} meetup · ${_kickoff.format(context)} kickoff',
                ),
                _ReviewRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value: _locationController.text.trim(),
                ),
                _ReviewRow(
                  icon: Icons.map_outlined,
                  label: 'Map pin',
                  value: _selectedSpot == null
                      ? 'Not set'
                      : '${_selectedSpot!.latitude.toStringAsFixed(5)}, '
                            '${_selectedSpot!.longitude.toStringAsFixed(5)}',
                ),
                _ReviewRow(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Vibe',
                  value: _vibe,
                ),
                _ReviewRow(
                  icon: _isPublic ? Icons.public : Icons.lock_outline,
                  label: 'Visibility',
                  value: _isPublic
                      ? 'Public · anyone can join'
                      : 'Private · invite only',
                  showDivider: false,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0) ...[
            OutlinedButton(
              onPressed: _saving ? null : () => setState(() => _step--),
              child: const Text('Back'),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: FilledButton(
              key: Key(
                _step == 2 ? 'create-tailgate-submit' : 'create-tailgate-next',
              ),
              onPressed: _saving ? null : _continue,
              child: Text(
                _saving
                    ? 'Saving…'
                    : _step == 2
                    ? 'Create tailgate'
                    : 'Continue',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _continue() async {
    if (_step == 0) {
      final gameMissing = _gameController.text.trim().isEmpty;
      final nameMissing = _nameController.text.trim().isEmpty;
      if (gameMissing || nameMissing) {
        setState(() {
          _gameError = gameMissing ? 'Enter the game or event' : null;
          _nameError = nameMissing ? 'Name your tailgate' : null;
        });
        return;
      }
    }
    if (_step == 1 && _locationController.text.trim().isEmpty) {
      setState(() => _locationError = 'Enter a meetup location');
      return;
    }
    if (_step < 2) {
      setState(() => _step++);
      return;
    }

    if (_saving) return;
    final draft = TailgateDraft(
      game: _gameController.text.trim(),
      name: _nameController.text.trim(),
      date: _date,
      kickoff: _kickoff.format(context),
      meetupTime: _meetup.format(context),
      location: _locationController.text.trim(),
      vibe: _vibe,
      isPublic: _isPublic,
      capacity: int.tryParse(_capacityController.text.trim()),
      requiresApproval: _isPublic && _requiresApproval,
      gameId: _gameId,
      latitude: _selectedSpot?.latitude,
      longitude: _selectedSpot?.longitude,
    );
    setState(() => _saving = true);
    try {
      final saved = await widget.createOnServer?.call(draft);
      if (!mounted) return;
      setState(() {
        _createdTailgate = saved?.draft ?? draft;
        _savedCode = saved?.code;
      });
      widget.onCreated?.call(_createdTailgate!);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2026),
      lastDate: DateTime(2030),
    );
    if (value != null && mounted) setState(() => _date = value);
  }

  Future<void> _pickTime({required bool isKickoff}) async {
    final value = await showTimePicker(
      context: context,
      initialTime: isKickoff ? _kickoff : _meetup,
    );
    if (value != null && mounted) {
      setState(() => isKickoff ? _kickoff = value : _meetup = value);
    }
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({required this.step});
  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Event', 'Plan', 'Review'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: Row(
        children: List.generate(labels.length, (index) {
          final active = index <= step;
          return Expanded(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: active
                      ? AppColors.purple
                      : const Color(0xFFE8E0D3),
                  foregroundColor: active ? Colors.white : AppColors.muted,
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  labels[index],
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: active ? AppColors.purple : AppColors.muted,
                  ),
                ),
                if (index != labels.length - 1)
                  const Expanded(child: Divider(indent: 7, endIndent: 7)),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.icon,
    required this.label,
    required this.value,
    this.showDivider = true,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 21, color: AppColors.purple),
            const SizedBox(width: 12),
            SizedBox(
              width: 70,
              child: Text(
                label,
                style: const TextStyle(color: AppColors.muted),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 13),
            child: Divider(height: 1),
          ),
      ],
    );
  }
}

class _InviteCodeResult extends StatelessWidget {
  const _InviteCodeResult({
    required this.tailgate,
    required this.onDone,
    required this.code,
  });
  final String code;
  final TailgateDraft tailgate;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Tailgate created'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 38,
                backgroundColor: Color(0xFFEDE4FA),
                child: Icon(
                  Icons.celebration_rounded,
                  size: 38,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                tailgate.name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 7),
              Text(
                '${tailgate.game} · ${tailgate.location}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 28),
              const Text(
                'YOUR INVITE CODE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: AppColors.muted,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: AppColors.purple,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('copy-invite-code'),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: code));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite code copied')),
                  );
                },
                icon: const Icon(Icons.copy_rounded),
                label: const Text('Copy invite code'),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  child: const Text('Open tailgate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
