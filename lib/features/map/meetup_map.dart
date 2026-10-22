import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:maplibre/maplibre.dart';

import '../../theme/app_theme.dart';
import 'current_location.dart';
import 'map_provider_config.dart';
import 'meetup_spot.dart';

typedef MeetupMapBuilder = Widget Function(
  BuildContext context,
  MeetupSpot spot,
  MapProviderConfig config,
);

class MeetupMap extends StatefulWidget {
  const MeetupMap({
    super.key,
    required this.spot,
    required this.providerConfig,
    this.compact = false,
    this.onSpotMoved,
    this.onPinTapped,
    this.userLocation,
    this.placementRequest = 0,
    this.mapBuilder,
  });

  final MeetupSpot spot;
  final MapProviderConfig providerConfig;
  final bool compact;
  final ValueChanged<MeetupSpot>? onSpotMoved;
  final VoidCallback? onPinTapped;
  final MapCoordinate? userLocation;
  final int placementRequest;
  final MeetupMapBuilder? mapBuilder;

  @override
  State<MeetupMap> createState() => _MeetupMapState();
}

class _MeetupMapState extends State<MeetupMap> {
  static const double _minimumZoom = 3;
  static const double _maximumZoom = 20;

  bool _isMovingPin = false;
  MapController? _mapController;
  double? _currentZoom;
  DateTime? _lastPointerDown;
  Offset? _lastPointerPosition;

  @override
  void didUpdateWidget(covariant MeetupMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.placementRequest != oldWidget.placementRequest) {
      setState(() => _isMovingPin = true);
    }
  }

  Future<void> _changeZoom(double amount) async {
    final controller = _mapController;
    if (controller == null) return;
    final zoom = ((_currentZoom ?? controller.getCamera().zoom) + amount).clamp(
      _minimumZoom,
      _maximumZoom,
    );
    await controller.animateCamera(
      zoom: zoom,
      nativeDuration: const Duration(milliseconds: 250),
      webMaxDuration: const Duration(milliseconds: 250),
    );
    if (mounted) setState(() => _currentZoom = zoom);
  }

  void _forwardScrollToPage(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (
      resolvedEvent,
    ) {
      if (resolvedEvent is! PointerScrollEvent) return;
      final position = scrollable.position;
      position.jumpTo(
        (position.pixels + resolvedEvent.scrollDelta.dy).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
    });
  }

  void _handlePointerDown(PointerDownEvent event) {
    final now = DateTime.now();
    final previousTime = _lastPointerDown;
    final previousPosition = _lastPointerPosition;
    _lastPointerDown = now;
    _lastPointerPosition = event.localPosition;

    if (previousTime == null || previousPosition == null) return;
    final isDoubleClick =
        now.difference(previousTime) <= const Duration(milliseconds: 350) &&
        (event.localPosition - previousPosition).distance <= 24;
    if (!isDoubleClick) return;

    _lastPointerDown = null;
    _lastPointerPosition = null;
    _changeZoom(HardwareKeyboard.instance.isShiftPressed ? -1 : 1);
  }

  void _handleMapEvent(MapEvent event) {
    if (event case MapEventMoveCamera(:final camera)) {
      _currentZoom = camera.zoom;
    }
    if (!_isMovingPin || widget.onSpotMoved == null) return;
    if (event case MapEventClick(:final point)) {
      widget.onSpotMoved!(
        widget.spot.copyWith(latitude: point.lat, longitude: point.lon),
      );
      setState(() => _isMovingPin = false);
    }
  }

  Widget _buildMap() {
    final customBuilder = widget.mapBuilder;
    if (customBuilder != null) {
      return customBuilder(context, widget.spot, widget.providerConfig);
    }

    final point = Geographic(
      lon: widget.spot.longitude,
      lat: widget.spot.latitude,
    );
    final userLocation = widget.userLocation;
    final initialCenter = userLocation == null
        ? point
        : Geographic(
            lon: userLocation.longitude,
            lat: userLocation.latitude,
          );
    return MapLibreMap(
      key: ValueKey(
        'meetup-map-${widget.spot.latitude}-${widget.spot.longitude}-'
        '${userLocation?.latitude}-${userLocation?.longitude}',
      ),
      options: MapOptions(
        initStyle: widget.providerConfig.styleUrl,
        initCenter: initialCenter,
        initZoom: widget.providerConfig.defaultZoom.toDouble(),
        gestures: const MapGestures.all(),
      ),
      onMapCreated: (controller) {
        _mapController = controller;
        _currentZoom = controller.getCamera().zoom;
        if (mounted) setState(() {});
      },
      onEvent: _handleMapEvent,
      children: [
        WidgetLayer(
          markers: [
            if (userLocation != null)
              Marker(
                point: Geographic(
                  lon: userLocation.longitude,
                  lat: userLocation.latitude,
                ),
                size: const Size.square(30),
                child: Semantics(
                  label: 'Your current location',
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 7),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_pin_circle_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
            Marker(
              point: point,
              size: Size.square(widget.compact ? 34 : 42),
              child: Semantics(
                button: true,
                label: 'Open ${widget.spot.name} meetup spot details',
                child: GestureDetector(
                  key: const Key('meetup-map-pin'),
                  onTap: widget.onPinTapped,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.purple,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.gold, width: 4),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.sports_football_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.compact ? 22 : 24),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(widget.compact ? 22 : 24),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: _handlePointerDown,
              onPointerSignal: _forwardScrollToPage,
              child: _buildMap(),
            ),
            Positioned(
              left: 10,
              bottom: 10,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .94),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Text(
                    widget.spot.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 10,
              bottom: 10,
              child: _MapZoomControls(
                enabled: _mapController != null,
                onZoomIn: () => _changeZoom(1),
                onZoomOut: () => _changeZoom(-1),
              ),
            ),
            if (widget.onSpotMoved != null)
              Positioned(
                top: 10,
                right: 10,
                child: FilledButton.tonalIcon(
                  key: const Key('move-meetup-pin'),
                  onPressed: () => setState(() => _isMovingPin = !_isMovingPin),
                  icon: Icon(
                    _isMovingPin ? Icons.close : Icons.edit_location_alt,
                  ),
                  label: Text(_isMovingPin ? 'Cancel' : 'Set tailgate pin'),
                ),
              ),
            if (_isMovingPin)
              const Positioned(
                top: 62,
                left: 10,
                right: 10,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: Text(
                      'Tap anywhere on the map to place the tailgate pin.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MapZoomControls extends StatelessWidget {
  const _MapZoomControls({
    required this.enabled,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  final bool enabled;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white.withValues(alpha: .96),
    elevation: 3,
    borderRadius: BorderRadius.circular(12),
    clipBehavior: Clip.antiAlias,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          key: const Key('map-zoom-in'),
          tooltip: 'Zoom in',
          onPressed: enabled ? onZoomIn : null,
          icon: const Icon(Icons.add_rounded),
        ),
        const SizedBox(width: 36, child: Divider(height: 1)),
        IconButton(
          key: const Key('map-zoom-out'),
          tooltip: 'Zoom out',
          onPressed: enabled ? onZoomOut : null,
          icon: const Icon(Icons.remove_rounded),
        ),
      ],
    ),
  );
}
