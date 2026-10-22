import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../tailgate_setup/tailgate_draft.dart';

class NotificationService {
  NotificationService._();

  static final instance = NotificationService._();
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _available = true;

  Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (_) {
      // UTC remains a safe fallback on platforms without a timezone bridge.
    }
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('ic_launcher'),
          iOS: IOSInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
    } catch (_) {
      _available = false;
    }
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    if (!_available) return false;
    if (kIsWeb) {
      final implementation = _plugin
          .resolvePlatformSpecificImplementation<
            WebFlutterLocalNotificationsPlugin
          >();
      return await implementation?.requestNotificationsPermission() ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final implementation = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await implementation?.requestNotificationsPermission() ?? true;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final implementation = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await implementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final implementation = _plugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >();
      return await implementation?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }
    return true;
  }

  Future<void> scheduleTailgateReminder(TailgateEntry entry) async {
    await initialize();
    if (!_available) return;
    final meetup = _dateWithTime(entry.draft.date, entry.draft.meetupTime);
    final reminder = meetup.subtract(const Duration(hours: 1));
    if (!reminder.isAfter(DateTime.now())) return;
    await _plugin.zonedSchedule(
      id: entry.id.hashCode & 0x7fffffff,
      title: '${entry.draft.name} starts soon',
      body:
          'Meet at ${entry.draft.meetupTime} at ${entry.draft.location}. Tap to review the plan.',
      scheduledDate: tz.TZDateTime.from(reminder, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'tailgate_reminders',
          'Tailgate reminders',
          channelDescription: 'Upcoming tailgate, kickoff, and weather alerts',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: 'tailgate-reminders'),
        macOS: DarwinNotificationDetails(
          threadIdentifier: 'tailgate-reminders',
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: entry.id,
    );
  }

  Future<void> showAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!_available) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'game_day_alerts',
          'Game-day alerts',
          channelDescription: 'Kickoff changes and severe weather notices',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: 'game-day-alerts'),
        macOS: DarwinNotificationDetails(threadIdentifier: 'game-day-alerts'),
      ),
    );
  }

  DateTime _dateWithTime(DateTime date, String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*([AP]M)$',
      caseSensitive: false,
    ).firstMatch(value.trim());
    if (match == null) return DateTime(date.year, date.month, date.day, 9);
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final suffix = match.group(3)!.toUpperCase();
    if (suffix == 'PM' && hour != 12) hour += 12;
    if (suffix == 'AM' && hour == 12) hour = 0;
    return DateTime(date.year, date.month, date.day, hour, minute);
  }
}
