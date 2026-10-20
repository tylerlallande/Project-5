import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/features/map/current_location.dart';
import 'package:tailgating/features/map/map_links.dart';
import 'package:tailgating/features/map/map_repository.dart';
import 'package:tailgating/features/map/map_provider_config.dart';
import 'package:tailgating/features/map/meetup_spot.dart';
import 'package:tailgating/features/map/meetup_spot_controller.dart';
import 'package:tailgating/screens/map_screen.dart';

import 'test_map_builder.dart';

const testSpot = MeetupSpot(
  tailgateId: 'test-event',
  name: 'Parade Ground',
  instructions: 'Meet beside the purple banner.',
  latitude: 30.4142,
  longitude: -91.1785,
  meetupTime: '12:15 PM',
  walkToStadiumMinutes: 9,
);

void main() {
  test('meetup spot serializes for the future server API', () {
    expect(MeetupSpot.fromJson(testSpot.toJson()).toJson(), testSpot.toJson());
  });

  testWidgets('map screen renders repository data instead of fixed labels', (
    tester,
  ) async {
    MeetupSpot? directionsSpot;
    final controller = MeetupSpotController(
      InMemoryMapRepository(const [testSpot]),
      tailgateId: testSpot.tailgateId,
    )..load();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapScreen(
            controller: controller,
            providerConfig: MapProviderConfig.fromEnvironment(),
            mapBuilder: buildTestMap,
            directionsLauncher: (spot) async {
              directionsSpot = spot;
              return true;
            },
            locationLoader: () async =>
                const MapCoordinate(latitude: 30.413, longitude: -91.177),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Parade Ground'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('12:15 PM'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('12:15 PM'), findsOneWidget);
    expect(find.text('9 min'), findsOneWidget);
    final coordinates = find.textContaining('30.41420, -91.17850');
    await tester.scrollUntilVisible(
      coordinates,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(coordinates, findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('get-directions')));
    await tester.tap(find.byKey(const Key('get-directions')));
    await tester.pumpAndSettle();
    expect(find.text('Open Google Maps?'), findsOneWidget);
    await tester.tap(find.byKey(const Key('confirm-directions')));
    await tester.pumpAndSettle();
    expect(directionsSpot, same(testSpot));

    await tester.tap(find.byKey(const Key('show-current-location')));
    await tester.pumpAndSettle();
    expect(find.text('Refresh my location'), findsOneWidget);
  });

  test('Google Maps link uses the pin and requests walking directions', () {
    final uri = googleMapsDirectionsUri(testSpot);

    expect(uri.host, 'www.google.com');
    expect(uri.path, '/maps/dir/');
    expect(uri.queryParameters['destination'], '30.4142,-91.1785');
    expect(uri.queryParameters['travelmode'], 'walking');
  });
}
