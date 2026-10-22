import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../features/profile/user_session.dart';
import '../features/alerts/notification_service.dart';
import '../features/tailgate_setup/tailgate_repository.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    this.session = const UserSession(
      displayName: 'Tgate member',
      isGuest: false,
    ),
    this.repository,
  });

  final UserSession session;
  final TailgateRepository? repository;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  late String _name;
  late bool _isGuest;
  String _role = 'Game-day coordinator';
  Map<String, bool> _notifications = {
    'Tailgate reminders': true,
    'Crew updates': true,
    'Checklist changes': true,
  };
  Map<String, bool> _food = {
    'Vegetarian': false,
    'Vegan': false,
    'Gluten-free': false,
    'Dairy-free': false,
    'Nut-free': false,
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _name = widget.session.displayName;
    _isGuest = widget.session.isGuest;
  }

  Future<void> _editProfile() async {
    var name = _name;
    var role = _role;
    final form = GlobalKey<FormState>();
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit profile'),
        scrollable: true,
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: name,
                onChanged: (value) => name = value,
                maxLength: 40,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Display name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a display name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: role,
                onChanged: (value) => role = value,
                maxLength: 60,
                decoration: const InputDecoration(labelText: 'Tailgate role'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialogContext, (name.trim(), role.trim()));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _name = result.$1;
        _role = result.$2;
      });
      await UserSession(displayName: _name, isGuest: _isGuest).save();
    }
  }

  Future<void> _editOptions({required bool food}) async {
    final draft = Map<String, bool>.of(food ? _food : _notifications);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, updateDialog) => AlertDialog(
          title: Text(food ? 'Food preferences' : 'Notifications'),
          scrollable: true,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                food
                    ? 'Choose your dietary preferences. These are not shared with your crew yet.'
                    : 'Choose which device alerts Tgate may send.',
              ),
              const SizedBox(height: 12),
              ...draft.entries.map(
                (entry) => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(entry.key),
                  value: entry.value,
                  onChanged: (value) =>
                      updateDialog(() => draft[entry.key] = value),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && mounted) {
      setState(() {
        if (food) {
          _food = draft;
        } else {
          _notifications = draft;
        }
      });
      if (!food && draft.values.any((enabled) => enabled)) {
        await NotificationService.instance.requestPermission();
      }
    }
  }

  Future<void> _upgradeGuest() async {
    var email = '';
    var password = '';
    var confirmPassword = '';
    final form = GlobalKey<FormState>();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keep this profile'),
        scrollable: true,
        content: Form(
          key: form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add an email and password to protect your profile and saved tailgates.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('upgrade-email'),
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                onChanged: (value) => email = value,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) =>
                    value == null || !value.trim().contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('upgrade-password'),
                obscureText: true,
                onChanged: (value) => password = value,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (value) => value == null || value.length < 8
                    ? 'Use at least 8 characters'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('upgrade-confirm-password'),
                obscureText: true,
                onChanged: (value) => confirmPassword = value,
                decoration: const InputDecoration(
                  labelText: 'Confirm password',
                ),
                validator: (_) => confirmPassword != password
                    ? 'Passwords do not match'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('save-guest-account'),
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save profile'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) return;
    try {
      if (widget.repository == null) {
        throw StateError(
          'Connect to the tailgate server to save this profile.',
        );
      }
      await widget.repository!.createAccount(email.trim(), password);
      await UserSession(displayName: _name, isGuest: true).upgrade();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _isGuest = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profile upgraded. Your tailgates and claimed items stay with you.',
        ),
      ),
    );
  }

  void _signOut() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
    unawaited(UserSession.clear());
  }

  void _showInfo(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        scrollable: true,
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final initials = _name
        .split(RegExp(r'\s+'))
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return ListView(
      key: const Key('profile-screen'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        const AppHeader(),
        const SizedBox(height: 28),
        Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.purple,
            child: Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _name,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        Text(
          _role,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 28),
        _SettingsGroup(
          title: 'Your account',
          children: [
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit profile',
              onTap: _editProfile,
            ),
            if (_isGuest)
              _SettingsTile(
                icon: Icons.verified_user_outlined,
                title: 'Keep this profile',
                subtitle: 'Upgrade without losing tailgates or claimed items',
                onTap: _upgradeGuest,
              ),
            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
              onTap: () => _editOptions(food: false),
              subtitle:
                  '${_notifications.values.where((value) => value).length} preferences enabled',
            ),
            _SettingsTile(
              icon: Icons.restaurant_menu_rounded,
              title: 'Food preferences',
              onTap: () => _editOptions(food: true),
              subtitle: _food.entries
                  .where((entry) => entry.value)
                  .map((entry) => entry.key)
                  .join(', '),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _SettingsGroup(
          title: 'App',
          children: [
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              title: 'Help and feedback',
              onTap: () => _showInfo(
                'Help and feedback',
                'Getting started\n'
                    'Host a tailgate from Home, join a public tailgate, or enter a private invite code. Once joined, Crew shows the saved members and bring list, while Map shows the meetup pin and directions.\n\n'
                    'Bring list\n'
                    'Any joined member can add or edit needed supplies. Claim an item when you are bringing it, then mark it packed when it is ready. These changes are saved on the tailgate server for the entire crew.\n\n'
                    'Map and location\n'
                    'The meetup pin belongs to the active tailgate. Location access is optional and is only requested when you choose to show your position or place the pin at your current location.\n\n'
                    'Connection problems\n'
                    'During local development, the Flutter website and tailgate API must both be running and reachable from your device. Use tool/run_mobile_web.sh to start both.\n\n'
                    'Reporting a problem\n'
                    'Open an issue in the Project-5 GitHub repository and include the device, browser, steps to reproduce the problem, and the exact error message.',
              ),
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Privacy',
              onTap: () => _showInfo(
                'Privacy',
                'Guest sessions\n'
                    'A guest receives a private device-session token. The token, not your password, is stored in browser or app storage and connects you to your tailgates, memberships, claimed items, and check-in status. Clearing site or app storage can remove access to that guest session.\n\n'
                    'Saved accounts\n'
                    'Choosing Keep this profile requires an email and password. Email addresses are normalized before storage, and passwords are salted and hashed by the server rather than stored as readable text.\n\n'
                    'Tailgate data\n'
                    'Joined crew members can see names, check-in state, bring-list assignments, meetup details, and shared updates for that tailgate. Public tailgates appear in discovery; private tailgates require their invite code.\n\n'
                    'Location and external maps\n'
                    'Your device location is requested only after you choose a location action. Opening directions sends the selected pin coordinates to the external maps provider after confirmation.\n\n'
                    'Local development\n'
                    'When running from a laptop, app and API traffic stays on the configured network unless an external data provider or directions service is used.',
              ),
            ),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About Tgate',
              onTap: () => _showInfo(
                'About Tgate',
                'Tgate · Version 1.0.0\n\n'
                    'Your game day, together. Tgate helps a crew host or discover a tailgate, coordinate supplies without duplicates, share an invite, track arrivals, and navigate to one meetup point.\n\n'
                    'The map experience uses MapLibre with OpenFreeMap data. Game schedules can be supplied through the configured college-football data service, while weather information supports game-day alerts.\n\n'
                    'Tgate is Project 5, a student-built Flutter application with a Python and SQLite tailgate API.',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Profile preferences are saved for this session.',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          key: const Key('sign-out-button'),
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
          color: AppColors.muted,
        ),
      ),
      const SizedBox(height: 8),
      Card(child: Column(children: children)),
    ],
  );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.purple),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    subtitle: subtitle == null || subtitle!.isEmpty ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
