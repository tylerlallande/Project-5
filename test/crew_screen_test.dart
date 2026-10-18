import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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
        const MaterialApp(
          home: Scaffold(
            body: CrewScreen(crewCount: 9, showBrandHeader: false),
          ),
        ),
      );
      expect(find.byType(AppHeader), findsNothing);
      expect(
        (tester.getCenter(find.text('Crew HQ')).dy -
                tester.getCenter(find.byTooltip('Invite crew')).dy)
            .abs(),
        lessThan(1),
      );
      await tester.tap(find.byKey(const Key('see-all-crew')));
      await tester.pumpAndSettle();
      expect(find.text('Crew members (9)'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(9));
      await tester.scrollUntilVisible(find.text('You'), 200);
      expect(find.text('Checked in'), findsOneWidget);
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Crew HQ'), findsOneWidget);
    },
  );

  testWidgets('crew tab retains branding and starts with eight members', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: CrewScreen())),
    );
    expect(find.byType(AppHeader), findsOneWidget);
    await tester.tap(find.byKey(const Key('see-all-crew')));
    await tester.pumpAndSettle();
    expect(find.text('Crew members (8)'), findsOneWidget);
    expect(find.text('You'), findsNothing);
  });
}
