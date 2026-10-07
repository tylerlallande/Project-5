import 'package:flutter/material.dart';

import 'app_shell.dart';
import 'theme/app_theme.dart';

class BayouBlitzApp extends StatelessWidget {
  const BayouBlitzApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BayouBlitz',
      theme: AppTheme.light,
      home: const AppShell(),
    );
  }
}
