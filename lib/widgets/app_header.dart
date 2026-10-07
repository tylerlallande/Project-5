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
                'BAYOU',
                style: TextStyle(
                  fontSize: 23,
                  height: .9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  color: AppColors.deepPurple,
                ),
              ),
              Text(
                'BLITZ',
                style: TextStyle(
                  fontSize: 23,
                  height: 1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                  color: AppColors.gold,
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
