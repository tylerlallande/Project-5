import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/features/tailgate_setup/create_tailgate_screen.dart';
import 'package:tailgating/features/tailgate_setup/join_tailgate_screen.dart';
import 'package:tailgating/main.dart';

import 'test_map_builder.dart';
import 'support/enter_guest.dart';

void main() {
  testWidgets('home opens create and join flows', (tester) async {
    await tester.pumpWidget(const TailgateApp(mapBuilder: buildTestMap));

    await enterAsGuest(tester);
    await tester.drag(
      find.byKey(const Key('home-screen')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Host a tailgate'));
    await tester.pumpAndSettle();
    expect(find.text('What are we celebrating?'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Join with an invite code'));
    await tester.tap(find.text('Join with an invite code'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your invite code'), findsOneWidget);
  });

  testWidgets('creates a tailgate and displays its invite code', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CreateTailgateScreen()));

    await tester.tap(find.byKey(const Key('create-tailgate-next')));
    await tester.pump();
    expect(find.text('Enter the game or event'), findsOneWidget);
    expect(find.text('Name your tailgate'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('create-game-field')),
      'LSU vs. Florida',
    );
    await tester.enterText(
      find.byKey(const Key('create-name-field')),
      'Saturday in Death Valley',
    );
    await tester.tap(find.byKey(const Key('create-tailgate-next')));
    await tester.pumpAndSettle();
    expect(find.text('Set the game plan'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('create-location-field')),
      'Parade Ground',
    );

    await tester.tap(find.byKey(const Key('create-tailgate-next')));
    await tester.pumpAndSettle();
    expect(find.text('Review your tailgate'), findsOneWidget);
    expect(find.text('LSU vs. Florida'), findsOneWidget);

    await tester.tap(find.byKey(const Key('create-tailgate-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Tailgate created'), findsOneWidget);
    expect(find.text('GEAUX7'), findsOneWidget);
  });

  testWidgets('finds a tailgate with a valid invite code', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: JoinTailgateScreen()));

    await tester.enterText(find.byKey(const Key('join-code-field')), 'geaux7');
    await tester.tap(find.byKey(const Key('find-tailgate-button')));
    await tester.pumpAndSettle();

    expect(find.text('Gumbo & Geaux'), findsOneWidget);
    expect(find.text('Hosted by Jordan'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('join-crew-button')), findsOneWidget);
  });
}
