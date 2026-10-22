import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/features/tailgate_setup/tailgate_draft.dart';
import 'package:tailgating/screens/crew_screen.dart';
import 'package:tailgating/widgets/app_header.dart';

void main() {
  testWidgets(
    'home crew hides branding and lists every member including check-in',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CrewScreen(
              members: const [
                CrewMember(
                  id: 'host',
                  displayName: 'Abdul',
                  isHost: true,
                  checkedIn: true,
                ),
                CrewMember(id: 'guest', displayName: 'Taylor'),
              ],
              tailgateName: 'Saturday Crew',
              inviteCode: 'ABC123',
              showBrandHeader: false,
            ),
          ),
        ),
      );
      expect(find.byType(AppHeader), findsNothing);
      expect(
        (tester.getCenter(find.text('Crew HQ')).dy -
                tester.getCenter(find.byKey(const Key('invite-crew'))).dy)
            .abs(),
        lessThan(1),
      );
      await tester.tap(find.byKey(const Key('see-all-crew')));
      await tester.pumpAndSettle();
      expect(find.text('Crew members (2)'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(2));
      expect(find.text('Abdul'), findsOneWidget);
      expect(find.text('Taylor'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Crew HQ'), findsOneWidget);
    },
  );

  testWidgets('crew tab retains branding and starts with only the user', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: CrewScreen(currentUser: 'Abdul')),
      ),
    );
    expect(find.byType(AppHeader), findsOneWidget);
    await tester.tap(find.byKey(const Key('see-all-crew')));
    await tester.pumpAndSettle();
    expect(find.text('Crew members (1)'), findsOneWidget);
    expect(find.text('Abdul'), findsOneWidget);
  });

  testWidgets('invite button exposes the saved tailgate code', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CrewScreen(
            currentUser: 'Abdul',
            tailgateName: 'Saturday Crew',
            inviteCode: 'ABC123',
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('invite-crew')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('crew-invite-code')), findsOneWidget);
    expect(find.text('ABC123'), findsOneWidget);
    expect(find.byKey(const Key('copy-crew-invite')), findsOneWidget);
  });
}
