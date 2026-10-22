import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class MapCoordinate {
  const MapCoordinate({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters = 0,
  });

  final double latitude;
  final double longitude;
  final double accuracyMeters;
}

class LocationUnavailable implements Exception {
  const LocationUnavailable(this.message);

  final String message;
}

typedef LocationLoader = Future<MapCoordinate> Function();

Future<MapCoordinate> loadCurrentLocation() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailable(
        'Turn on Location Services in your device settings, then try again.',
      );
    }

    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      throw LocationUnavailable(
        kIsWeb
            ? 'Location is blocked for this website. Allow it in your browser’s site settings, then reload this page.'
            : 'Location access is blocked. Allow it in your device settings, then try again.',
      );
    }

    // Browsers on desktop may not have GPS hardware. Request a location
    // estimate there instead of demanding navigation-grade accuracy; keep
    // the high-accuracy request on mobile devices.
    final position = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: kIsWeb ? LocationAccuracy.medium : LocationAccuracy.best,
        timeLimit: const Duration(seconds: 20),
      ),
    ).timeout(const Duration(seconds: 22));

    return MapCoordinate(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
    );
  } on LocationUnavailable {
    rethrow;
  } on PermissionDeniedException {
    throw LocationUnavailable(
      kIsWeb
          ? 'Allow location for this website in your browser settings, then try again.'
          : 'Allow location access in your device settings, then try again.',
    );
  } on LocationServiceDisabledException {
    throw const LocationUnavailable(
      'Turn on Location Services in your device settings, then try again.',
    );
  } on TimeoutException {
    throw LocationUnavailable(
      kIsWeb
          ? 'The browser could not get a location fix. Use this page over HTTPS or localhost, allow location access, and try again.'
          : 'The device could not get a location fix. Turn on Location Services and try again somewhere with a clearer view of the sky.',
    );
  } on PositionUpdateException catch (error) {
    final detail = error.message?.trim();
    final reason = detail == null || detail.isEmpty
        ? 'The browser reported that the position is unavailable.'
        : 'The browser reported: $detail';
    throw LocationUnavailable(
      kIsWeb
          ? '$reason Check this site’s Location permission and your device’s Location Services. If this page is not on HTTPS or localhost, open its secure address and retry.'
          : '$reason Check Location Services and app permissions, then try again.',
    );
  } catch (_) {
    throw LocationUnavailable(
      kIsWeb
          ? 'The browser could not access your location. Open the app over HTTPS or localhost and allow location access in site settings.'
          : 'Your location could not be found. Check that Location Services and app permissions are enabled, then try again.',
    );
  }
}
