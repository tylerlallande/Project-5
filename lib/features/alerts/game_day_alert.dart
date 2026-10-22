import 'package:flutter/material.dart';

enum GameDayAlertKind { reminder, kickoff, weather, membership, liveScore }

class GameDayAlert {
  const GameDayAlert({
    required this.id,
    required this.kind,
    required this.title,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final GameDayAlertKind kind;
  final String title;
  final String message;
  final DateTime createdAt;

  IconData get icon => switch (kind) {
    GameDayAlertKind.reminder => Icons.alarm_rounded,
    GameDayAlertKind.kickoff => Icons.schedule_rounded,
    GameDayAlertKind.weather => Icons.thunderstorm_outlined,
    GameDayAlertKind.membership => Icons.groups_2_outlined,
    GameDayAlertKind.liveScore => Icons.sports_score_rounded,
  };
}
