import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with AutomaticKeepAliveClientMixin {
  String _name = 'Alex Tiger';
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
                    : 'Choose your preferences. Notification delivery is not connected yet.',
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
    }
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
                'Use Home to create a tailgate or join with an invite code. Open your tailgate to manage supplies, the meetup spot, and updates.\n\nTo report a problem, open an issue in the Project-5 GitHub repository with steps to reproduce it. Feedback submission is not connected in this app yet.',
              ),
            ),
            _SettingsTile(
              icon: Icons.shield_outlined,
              title: 'Privacy',
              onTap: () => _showInfo(
                'Privacy',
                'Sign-in is currently a demo: credentials are not verified or saved. Tailgates and memberships are saved on the server using an anonymous device session stored on this device. Signing out does not erase those memberships; clearing app or browser storage loses access to that device session. Profile settings reset when you sign out or restart the app. Food preferences are not sent to your crew.',
              ),
            ),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About BayouBlitz',
              onTap: () => _showInfo(
                'About BayouBlitz',
                'BayouBlitz · Version 1.0.0\n\nYour game day, together. Plan LSU tailgates, coordinate supplies, and find your crew.\n\nProject 5 · Student project',
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
          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute<void>(builder: (_) => const WelcomeScreen()),
            (_) => false,
          ),
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
