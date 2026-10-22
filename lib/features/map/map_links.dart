import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'meetup_spot.dart';

typedef DirectionsLauncher = Future<bool> Function(MeetupSpot spot);

Uri googleMapsDirectionsUri(MeetupSpot spot) =>
    Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '${spot.latitude},${spot.longitude}',
      'travelmode': 'walking',
    });

/// Opens the Google Maps app on supported mobile devices and otherwise opens
/// Google Maps in the user's primary browser.
Future<bool> openDirections(MeetupSpot spot) => launchUrl(
  googleMapsDirectionsUri(spot),
  mode: LaunchMode.externalApplication,
);

String get directionsDestinationLabel {
  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS)) {
    return 'Google Maps app or browser';
  }
  return 'your primary browser';
}

Future<bool> confirmAndOpenDirections(
  BuildContext context,
  MeetupSpot spot,
  DirectionsLauncher launcher,
) async {
  final approved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Open Google Maps?'),
      content: Text(
        'Tgate will open walking directions to ${spot.name} in '
        '$directionsDestinationLabel.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          key: const Key('confirm-directions'),
          onPressed: () => Navigator.pop(dialogContext, true),
          icon: const Icon(Icons.open_in_new_rounded),
          label: const Text('Open directions'),
        ),
      ],
    ),
  );
  if (approved != true || !context.mounted) return false;

  final opened = await launcher(spot);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Google Maps could not be opened.')),
    );
  }
  return opened;
}
