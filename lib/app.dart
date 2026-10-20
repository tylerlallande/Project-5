import 'package:flutter/material.dart';

import 'features/map/meetup_map.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

class BayouBlitzApp extends StatelessWidget {
  const BayouBlitzApp({super.key, this.mapBuilder});

  final MeetupMapBuilder? mapBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BayouBlitz',
      theme: AppTheme.light,
      home: WelcomeScreen(mapBuilder: mapBuilder),
    );
  }
}
