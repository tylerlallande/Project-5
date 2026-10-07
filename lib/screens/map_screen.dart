import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('map-screen'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      children: [
        const AppHeader(),
        const SizedBox(height: 24),
        Text('The spot', style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 5),
        const Text(
          'Oak Grove · Tent with the gold flag',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 18),
        AspectRatio(
          aspectRatio: .95,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFECE8DE),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                const Positioned(
                  left: -45,
                  top: 62,
                  child: CircleAvatar(
                    radius: 105,
                    backgroundColor: Color(0xFFCFE4C2),
                  ),
                ),
                const Positioned(
                  right: -50,
                  bottom: -40,
                  child: CircleAvatar(
                    radius: 100,
                    backgroundColor: Color(0xFFDDD0EE),
                  ),
                ),
                Positioned(
                  left: MediaQuery.sizeOf(context).width * .42,
                  top: 0,
                  bottom: 0,
                  child: Container(width: 13, color: Colors.white),
                ),
                Positioned(
                  left: -20,
                  right: -20,
                  top: 145,
                  child: Transform.rotate(
                    angle: .10,
                    child: Container(height: 12, color: Colors.white),
                  ),
                ),
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_pin,
                        size: 62,
                        color: Color(0xFFE8306C),
                      ),
                      Card(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 9,
                          ),
                          child: Text(
                            'Oak Grove · gold flag',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Row(
          children: [
            Expanded(
              child: _MapStat(label: 'GET THERE', value: '11:00 AM'),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MapStat(label: 'WALK TO STADIUM', value: '6 min'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: null,
          icon: Icon(Icons.directions_rounded),
          label: Text('Get directions'),
        ),
        const SizedBox(height: 10),
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.edit_location_alt_outlined),
          label: const Text('Suggest a different spot'),
        ),
      ],
    );
  }
}

class _MapStat extends StatelessWidget {
  const _MapStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    ),
  );
}
