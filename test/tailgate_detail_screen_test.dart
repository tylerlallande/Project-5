import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/features/tailgate_detail/tailgate_detail_screen.dart';
import 'package:tailgating/features/map/map_repository.dart';
import 'package:tailgating/features/map/map_seed_data.dart';
import 'package:tailgating/features/map/meetup_spot_controller.dart';
import 'package:tailgating/main.dart';

MeetupSpotController createSpotController() => MeetupSpotController(
  InMemoryMapRepository(developmentMeetupSpots),
  tailgateId: 'gumbo',
)..load();

void main() {
  testWidgets('home bring-list action opens the tailgate detail page', (
    tester,
  ) async {
    await tester.pumpWidget(const TailgateApp());
    await tester.ensureVisible(find.byKey(const Key('continue-as-guest')));
    await tester.tap(find.byKey(const Key('continue-as-guest')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Bring list'));
    await tester.pumpAndSettle();

    expect(find.text('Gumbo & Geaux'), findsOneWidget);
    expect(find.text('Who’s bringing what?'), findsOneWidget);
    expect(find.byKey(const Key('tailgate-bring-content')), findsOneWidget);
  });

  testWidgets('tailgate tabs expose spot and updates content', (tester) async {
    final controller = createSpotController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(home: TailgateDetailScreen(meetupSpotController: controller)),
    );
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
      MaterialApp(
        home: TailgateDetailScreen(
          initialTab: 2,
          meetupSpotController: controller,
        ),
      ),
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
