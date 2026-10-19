import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../features/map/map_provider_config.dart';
import '../features/map/meetup_spot.dart';
import '../features/map/meetup_spot_controller.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({
    super.key,
    required this.controller,
    required this.providerConfig,
  });

  final MeetupSpotController controller;
  final MapProviderConfig providerConfig;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.isLoading && controller.spot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.error != null && controller.spot == null) {
          return _MapError(onRetry: controller.load);
        }
        final spot = controller.spot;
        if (spot == null) return const SizedBox.shrink();
        return _MapContent(spot: spot, providerConfig: providerConfig);
      },
    );
  }
}

class _MapContent extends StatelessWidget {
  const _MapContent({required this.spot, required this.providerConfig});

  final MeetupSpot spot;
  final MapProviderConfig providerConfig;

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
        Text(
          '${spot.name} · ${spot.instructions}',
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
                Center(
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
                            spot.name,
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
        Row(
          children: [
            Expanded(
              child: _MapStat(label: 'GET THERE', value: spot.meetupTime),
            ),
            SizedBox(width: 10),
            Expanded(
              child: _MapStat(
                label: 'WALK TO STADIUM',
                value: '${spot.walkToStadiumMinutes} min',
              ),
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
        Text(
          '${spot.latitude.toStringAsFixed(4)}, '
          '${spot.longitude.toStringAsFixed(4)} · ${providerConfig.attribution}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _MapError extends StatelessWidget {
  const _MapError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('The meetup spot could not be loaded.'),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
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
