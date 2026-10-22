import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  const UserSession({required this.displayName, required this.isGuest});

  static const _nameKey = 'bayou.profile.displayName';
  static const _guestKey = 'bayou.profile.isGuest';

  final String displayName;
  final bool isGuest;

  static Future<UserSession?> restore() async {
    final preferences = await SharedPreferences.getInstance();
    final name = preferences.getString(_nameKey)?.trim();
    if (name == null || name.isEmpty) return null;
    return UserSession(
      displayName: name,
      isGuest: preferences.getBool(_guestKey) ?? true,
    );
  }

  Future<void> save() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_nameKey, displayName.trim());
    await preferences.setBool(_guestKey, isGuest);
  }

  Future<UserSession> upgrade() async {
    final upgraded = UserSession(displayName: displayName, isGuest: false);
    await upgraded.save();
    return upgraded;
  }

  static Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_nameKey);
    await preferences.remove(_guestKey);
  }
}
