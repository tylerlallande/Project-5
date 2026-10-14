import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/main.dart';

void main() {
  testWidgets('optional sign in masks the password and accepts demo details', (
    tester,
  ) async {
    await tester.pumpWidget(const TailgateApp());
    await tester.enterText(find.byKey(const Key('login-username')), 'TigerFan');
    await tester.enterText(
      find.byKey(const Key('login-password')),
      'demo-password',
    );
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('login-password')))
          .obscureText,
      isTrue,
    );
    await tester.ensureVisible(find.byTooltip('Show password'));
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(
      tester
          .widget<TextField>(find.byKey(const Key('login-password')))
          .obscureText,
      isFalse,
    );
    await tester.ensureVisible(find.byKey(const Key('sign-in-button')));
    await tester.tap(find.byKey(const Key('sign-in-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('sign in accepts empty fields while accounts are optional', (
    tester,
  ) async {
    await tester.pumpWidget(const TailgateApp());
    await tester.ensureVisible(find.byKey(const Key('sign-in-button')));
    await tester.tap(find.byKey(const Key('sign-in-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('sign out returns to welcome and guest entry starts at home', (
    tester,
  ) async {
    await tester.pumpWidget(const TailgateApp());
    await tester.ensureVisible(find.byKey(const Key('continue-as-guest')));
    await tester.tap(find.byKey(const Key('continue-as-guest')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('sign-out-button')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('profile-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const Key('sign-out-button')));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Bayou Blitz'), findsOneWidget);
    expect(find.byKey(const Key('profile-screen')), findsNothing);
    expect(
      tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
      isFalse,
    );
    await tester.ensureVisible(find.byKey(const Key('continue-as-guest')));
    await tester.tap(find.byKey(const Key('continue-as-guest')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
  });

  testWidgets('welcome fits a small phone and opens home without login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const TailgateApp());
    expect(find.byKey(const Key('home-screen')), findsNothing);
    expect(find.byType(TextField), findsNWidgets(2));
    await tester.ensureVisible(find.byKey(const Key('continue-as-guest')));
    await tester.tap(find.byKey(const Key('continue-as-guest')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-screen')), findsOneWidget);
    expect(find.byKey(const Key('continue-as-guest')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home surfaces event details and allows check-in', (
    tester,
  ) async {
    await tester.pumpWidget(const TailgateApp());
    await tester.ensureVisible(find.byKey(const Key('continue-as-guest')));
    await tester.tap(find.byKey(const Key('continue-as-guest')));
    await tester.pumpAndSettle();

    expect(find.text('LSU vs. Alabama'), findsOneWidget);
    expect(find.text('Quick actions'), findsOneWidget);
    expect(find.text('Count me in'), findsOneWidget);

    await tester.tap(find.byKey(const Key('check-in-button')));
    await tester.pump();

    expect(find.text('Checked in'), findsOneWidget);
  });

  testWidgets('bottom navigation and swipes change pages', (tester) async {
    await tester.pumpWidget(const TailgateApp());
    await tester.ensureVisible(find.byKey(const Key('continue-as-guest')));
    await tester.tap(find.byKey(const Key('continue-as-guest')));
    await tester.pumpAndSettle();

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
