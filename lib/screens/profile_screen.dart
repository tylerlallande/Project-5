import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('profile-screen'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        const AppHeader(),
        const SizedBox(height: 28),
        const Center(
          child: CircleAvatar(
            radius: 48,
            backgroundColor: AppColors.purple,
            child: Text(
              'AT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Alex Tiger',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const Text(
          'Game-day coordinator',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 28),
        const _SettingsGroup(
          title: 'Your account',
          children: [
            _SettingsTile(
              icon: Icons.person_outline_rounded,
              title: 'Edit profile',
            ),
            _SettingsTile(
              icon: Icons.notifications_none_rounded,
              title: 'Notifications',
            ),
            _SettingsTile(
              icon: Icons.restaurant_menu_rounded,
              title: 'Food preferences',
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _SettingsGroup(
          title: 'App',
          children: [
            _SettingsTile(
              icon: Icons.help_outline_rounded,
              title: 'Help and feedback',
            ),
            _SettingsTile(icon: Icons.shield_outlined, title: 'Privacy'),
            _SettingsTile(
              icon: Icons.info_outline_rounded,
              title: 'About BayouBlitz',
            ),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () {},
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
  const _SettingsTile({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: AppColors.purple),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () {},
  );
}
