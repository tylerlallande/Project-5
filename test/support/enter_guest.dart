import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> enterAsGuest(
  WidgetTester tester, {
  String name = 'Test Guest',
}) async {
  await tester.ensureVisible(find.byKey(const Key('continue-as-guest')));
  await tester.tap(find.byKey(const Key('continue-as-guest')));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('guest-name-field')), name);
  await tester.tap(find.byKey(const Key('guest-name-continue')));
  await tester.pumpAndSettle();
}
