import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/screens/profile_screen.dart';

void main() {
  Future<void> openProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProfileScreen())),
    );
  }

  testWidgets('profile validates, saves, and cancels name edits', (
    tester,
  ) async {
    await openProfile(tester);
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a display name'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).first, 'Jordan Tiger');
    await tester.enterText(find.byType(TextFormField).last, 'Grill master');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Jordan Tiger'), findsOneWidget);
    expect(find.text('JT'), findsOneWidget);
    expect(find.text('Grill master'), findsOneWidget);
    await tester.tap(find.text('Edit profile'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Discard this');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Jordan Tiger'), findsOneWidget);
    expect(find.text('Discard this'), findsNothing);
  });

  testWidgets(
    'preference changes save and cancellation preserves saved values',
    (tester) async {
      await openProfile(tester);
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Crew updates'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('2 preferences enabled'), findsOneWidget);
      await tester.tap(find.text('Notifications'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile).at(1)).value,
        isFalse,
      );
      await tester.tap(find.text('Crew updates'));
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('2 preferences enabled'), findsOneWidget);
      await tester.ensureVisible(find.text('Food preferences'));
      await tester.tap(find.text('Food preferences'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vegetarian'));
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Vegetarian'), findsOneWidget);
    },
  );
}
