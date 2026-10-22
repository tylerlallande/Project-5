import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key, this.action});

  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TGATE',
                style: TextStyle(
                  fontSize: 26,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  color: AppColors.deepPurple,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'YOUR GAME DAY, TOGETHER',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
        action ?? const SizedBox.shrink(),
      ],
    );
  }
}
