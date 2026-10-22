import 'package:flutter/material.dart';

import 'features/map/meetup_map.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';

class TgateApp extends StatelessWidget {
  const TgateApp({super.key, this.mapBuilder});

  final MeetupMapBuilder? mapBuilder;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tgate',
      theme: AppTheme.light,
      home: WelcomeScreen(mapBuilder: mapBuilder),
    );
  }
}
