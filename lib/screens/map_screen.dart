import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/map/current_location.dart';
import '../features/map/map_links.dart';
import '../features/map/map_provider_config.dart';
import '../features/map/meetup_map.dart';
import '../features/map/meetup_spot.dart';
import '../features/map/meetup_spot_controller.dart';
import '../theme/app_theme.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({
    super.key,
    required this.controller,
    required this.providerConfig,
    this.mapBuilder,
    this.directionsLauncher = openDirections,
    this.locationLoader = loadCurrentLocation,
    this.onLocationFound,
  });

  final MeetupSpotController controller;
  final MapProviderConfig providerConfig;
  final MeetupMapBuilder? mapBuilder;
  final DirectionsLauncher directionsLauncher;
  final LocationLoader locationLoader;
  final ValueChanged<MapCoordinate>? onLocationFound;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapCoordinate? _userLocation;
  bool _isLocating = false;
  int _placementRequest = 0;

  void _requestPinPlacement() {
    setState(() => _placementRequest++);
  }

  Future<void> _removePin(MeetupSpot spot) async {
    await widget.controller.remove();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tailgate pin removed.'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () => widget.controller.save(spot),
        ),
      ),
    );
  }

  Future<void> _showCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final location = await widget.locationLoader();
      if (!mounted) return;
      setState(() => _userLocation = location);
      widget.onLocationFound?.call(location);
      final accuracy = location.accuracyMeters;
      final accuracyText = accuracy > 0
          ? ' (about ±${accuracy.toStringAsFixed(0)} m accuracy)'
          : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Your location is shown in blue$accuracyText.')),
      );
    } on LocationUnavailable catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.message),
            duration: const Duration(seconds: 12),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your location could not be found.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _createPinAtCurrentLocation() async {
    if (_isLocating) return;
    setState(() => _isLocating = true);
    try {
      final location = await widget.locationLoader();
      await widget.controller.save(
        MeetupSpot(
          tailgateId: widget.controller.tailgateId,
          name: 'Tailgate spot',
          instructions: 'Meet the crew at the pinned location.',
          latitude: location.latitude,
          longitude: location.longitude,
          meetupTime: 'See tailgate plan',
          walkToStadiumMinutes: 0,
        ),
      );
      widget.onLocationFound?.call(location);
      if (mounted) setState(() => _userLocation = location);
    } on LocationUnavailable catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        if (widget.controller.isLoading && widget.controller.spot == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (widget.controller.error != null && widget.controller.spot == null) {
          return _MapError(onRetry: widget.controller.load);
        }
        final spot = widget.controller.spot;
        if (spot == null && widget.controller.hasLoaded) {
          return _NoMeetupSpot(
            isLocating: _isLocating,
            onCreateAtCurrentLocation: _createPinAtCurrentLocation,
          );
        }
        if (spot == null) return const SizedBox.shrink();
        return _MapContent(
          spot: spot,
          controller: widget.controller,
          providerConfig: widget.providerConfig,
          mapBuilder: widget.mapBuilder,
          directionsLauncher: widget.directionsLauncher,
          userLocation: _userLocation,
          isLocating: _isLocating,
          onShowCurrentLocation: _showCurrentLocation,
          placementRequest: _placementRequest,
          onEditPin: _requestPinPlacement,
          onRemovePin: () => _removePin(spot),
        );
      },
    );
  }
}

class _MapContent extends StatelessWidget {
  const _MapContent({
    required this.spot,
    required this.controller,
    required this.providerConfig,
    required this.mapBuilder,
    required this.directionsLauncher,
    required this.userLocation,
    required this.isLocating,
    required this.onShowCurrentLocation,
    required this.placementRequest,
    required this.onEditPin,
    required this.onRemovePin,
  });

  final MeetupSpot spot;
  final MeetupSpotController controller;
  final MapProviderConfig providerConfig;
  final MeetupMapBuilder? mapBuilder;
  final DirectionsLauncher directionsLauncher;
  final MapCoordinate? userLocation;
  final bool isLocating;
  final VoidCallback onShowCurrentLocation;
  final int placementRequest;
  final VoidCallback onEditPin;
  final VoidCallback onRemovePin;

  Future<void> _openDirections(BuildContext context) async {
    await confirmAndOpenDirections(context, spot, directionsLauncher);
  }

  Future<void> _copyLocation(BuildContext context) async {
    await Clipboard.setData(
      ClipboardData(text: '${spot.latitude},${spot.longitude}'),
    );
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tailgate coordinates copied.')),
      );
    }
  }

  Future<void> _saveSpot(BuildContext context, MeetupSpot updatedSpot) async {
    await controller.save(updatedSpot);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tailgate pin updated for the crew.')),
      );
    }
  }

  void _showPinDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(spot.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(spot.instructions),
              const SizedBox(height: 6),
              Text(
                'Meet at ${spot.meetupTime} · '
                '${spot.walkToStadiumMinutes} min walk to the stadium',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.tonalIcon(
                      key: const Key('edit-tailgate-pin'),
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        onEditPin();
                      },
                      icon: const Icon(Icons.edit_location_alt_rounded),
                      label: const Text('Move pin'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    key: const Key('remove-tailgate-pin'),
                    tooltip: '',
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Remove tailgate pin?'),
                          content: const Text(
                            'The meetup location will no longer be visible to '
                            'the crew.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(dialogContext, false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              key: const Key('confirm-remove-tailgate-pin'),
                              onPressed: () =>
                                  Navigator.pop(dialogContext, true),
                              child: const Text('Remove'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) onRemovePin();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  key: const Key('pin-directions'),
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    _openDirections(context);
                  },
                  icon: const Icon(Icons.directions_walk_rounded),
                  label: const Text('Walking directions'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mapHeight = (constraints.maxHeight - 390).clamp(230.0, 410.0);
        return ListView(
          key: const Key('map-screen'),
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          children: [
            Text('The spot', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 5),
            Text(
              '${spot.name} · ${spot.instructions}',
              style: const TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 8),
            const _MapHelpCard(),
            const SizedBox(height: 10),
            SizedBox(
              height: mapHeight,
              child: MeetupMap(
                spot: spot,
                providerConfig: providerConfig,
                mapBuilder: mapBuilder,
                onSpotMoved: (updatedSpot) => _saveSpot(context, updatedSpot),
                onPinTapped: () => _showPinDetails(context),
                userLocation: userLocation,
                placementRequest: placementRequest,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              key: const Key('show-current-location'),
              onPressed: isLocating ? null : onShowCurrentLocation,
              icon: isLocating
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      userLocation == null
                          ? Icons.my_location_rounded
                          : Icons.location_on_rounded,
                    ),
              label: Text(
                userLocation == null
                    ? 'Show my location'
                    : 'Refresh my location',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _MapStat(label: 'GET THERE', value: spot.meetupTime),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MapStat(
                    label: 'WALK TO STADIUM',
                    value: '${spot.walkToStadiumMinutes} min',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('get-directions'),
                    onPressed: () => _openDirections(context),
                    icon: const Icon(Icons.directions_walk_rounded),
                    label: const Text('Directions'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('copy-map-location'),
                    onPressed: () => _copyLocation(context),
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('Copy location'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${spot.latitude.toStringAsFixed(5)}, '
              '${spot.longitude.toStringAsFixed(5)} · ${providerConfig.attribution}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        );
      },
    );
  }
}

class _MapHelpCard extends StatelessWidget {
  const _MapHelpCard();

  @override
  Widget build(BuildContext context) => Card(
    color: AppColors.purple.withValues(alpha: .07),
    child: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.touch_app_rounded, color: AppColors.purple),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Use +/− or double-click to zoom. Shift+double-click zooms out. '
              'Tap the football to move or remove the pin.',
            ),
          ),
        ],
      ),
    ),
  );
}

class _NoMeetupSpot extends StatelessWidget {
  const _NoMeetupSpot({
    required this.isLocating,
    required this.onCreateAtCurrentLocation,
  });

  final bool isLocating;
  final VoidCallback onCreateAtCurrentLocation;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.add_location_alt_outlined,
            size: 52,
            color: AppColors.muted,
          ),
          const SizedBox(height: 12),
          const Text(
            'No tailgate pin is set',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          const Text(
            'Start at your current location, then move the pin to the exact meetup spot.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: isLocating ? null : onCreateAtCurrentLocation,
            icon: const Icon(Icons.my_location_rounded),
            label: Text(isLocating ? 'Finding location…' : 'Create pin here'),
          ),
        ],
      ),
    ),
  );
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
