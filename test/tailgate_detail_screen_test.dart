import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/features/tailgate_detail/tailgate_detail_screen.dart';
import 'package:tailgating/features/map/map_repository.dart';
import 'package:tailgating/features/map/map_provider_config.dart';
import 'package:tailgating/features/map/map_seed_data.dart';
import 'package:tailgating/features/map/meetup_spot_controller.dart';
import 'package:tailgating/main.dart';

import 'test_map_builder.dart';
import 'support/enter_guest.dart';

MeetupSpotController createSpotController() => MeetupSpotController(
  InMemoryMapRepository(developmentMeetupSpots),
  tailgateId: 'gumbo',
)..load();

TailgateDetailScreen buildDetailScreen(
  MeetupSpotController controller, {
  int initialTab = 0,
}) => TailgateDetailScreen(
  initialTab: initialTab,
  meetupSpotController: controller,
  mapProviderConfig: MapProviderConfig.fromEnvironment(),
  mapBuilder: buildTestMap,
  directionsLauncher: (_) async => true,
);

void main() {
  testWidgets('home bring-list action opens the tailgate detail page', (
    tester,
  ) async {
    await tester.pumpWidget(const TailgateApp(mapBuilder: buildTestMap));
    await enterAsGuest(tester);

    await tester.tap(find.text('Bring list'));
    await tester.pumpAndSettle();

    expect(find.text('Gumbo & Geaux'), findsOneWidget);
    expect(find.text('Who’s bringing what?'), findsOneWidget);
    expect(find.byKey(const Key('tailgate-bring-content')), findsOneWidget);
  });

  testWidgets('tailgate tabs expose spot and updates content', (tester) async {
    final controller = createSpotController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(home: buildDetailScreen(controller)));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('tailgate-spot-tab')));
    await tester.pumpAndSettle();
    expect(find.text('Meetup spot'), findsOneWidget);
    expect(find.text('Oak Grove'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tailgate-updates-tab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('tailgate-updates-content')), findsOneWidget);
    expect(find.text('Tent’s up by the gold flag 💜'), findsOneWidget);
  });

  testWidgets('posts a local game-day update', (tester) async {
    final controller = createSpotController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: buildDetailScreen(controller, initialTab: 2)),
    );

    await tester.enterText(
      find.byKey(const Key('tailgate-update-field')),
      'Parking now, five minutes away!',
    );
    await tester.tap(find.byKey(const Key('post-tailgate-update')));
    await tester.pump();

    expect(find.text('Parking now, five minutes away!'), findsOneWidget);
    expect(find.text('Alex · Coordinator'), findsOneWidget);
  });
}
