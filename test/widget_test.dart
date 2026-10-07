import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/main.dart';

void main() {
  testWidgets('home surfaces event details and allows check-in', (
    tester,
  ) async {
    await tester.pumpWidget(const TailgateApp());

    expect(find.text('LSU vs. Alabama'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Count me in'), findsOneWidget);

    await tester.tap(find.byKey(const Key('check-in-button')));
    await tester.pump();

    expect(find.text('Checked in'), findsOneWidget);
  });

  testWidgets('bottom navigation and swipes change pages', (tester) async {
    await tester.pumpWidget(const TailgateApp());

    await tester.tap(find.text('Crew').last);
    await tester.pumpAndSettle();
    expect(find.text('Crew HQ'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('main-page-view')),
      const Offset(-500, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('The spot'), findsOneWidget);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Alex Tiger'), findsOneWidget);
  });
}
