import 'package:geolocator/geolocator.dart';

class MapCoordinate {
  const MapCoordinate({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationUnavailable implements Exception {
  const LocationUnavailable(this.message);

  final String message;
}

typedef LocationLoader = Future<MapCoordinate> Function();

Future<MapCoordinate> loadCurrentLocation() async {
  if (!await Geolocator.isLocationServiceEnabled()) {
    throw const LocationUnavailable(
      'Turn on location services to show your position on the map.',
    );
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied) {
    throw const LocationUnavailable(
      'Location permission was not granted. You can still use the tailgate pin.',
    );
  }
  if (permission == LocationPermission.deniedForever) {
    throw const LocationUnavailable(
      'Location access is disabled in system settings.',
    );
  }

  final position = await Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 12),
    ),
  );
  return MapCoordinate(
    latitude: position.latitude,
    longitude: position.longitude,
  );
}
