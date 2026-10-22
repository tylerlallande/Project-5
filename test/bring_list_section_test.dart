import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/features/bring_list/bring_list_section.dart';

Widget _testApp() {
  return const MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: BringListSection(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('claims an open item and includes it in the Mine filter', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());

    expect(find.text('2 of 4 covered · 1 packed'), findsOneWidget);
    await tester.tap(find.byKey(const Key('claim-2')));
    await tester.pump();

    expect(find.text('3 of 4 covered · 1 packed'), findsOneWidget);
    expect(find.text('Qty 2 · Claimed by Alex'), findsOneWidget);

    await tester.tap(find.byKey(const Key('bring-filter-mine')));
    await tester.pump();

    expect(find.text('Ice & coolers'), findsOneWidget);
    expect(find.text('Game-day playlist'), findsOneWidget);
    expect(find.text('The gumbo'), findsNothing);
  });

  testWidgets('adds a new item to the list', (tester) async {
    await tester.pumpWidget(_testApp());

    await tester.tap(find.byKey(const Key('add-bring-item')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('new-item-name')),
      'Paper plates',
    );
    await tester.enterText(find.byKey(const Key('new-item-quantity')), '3');
    await tester.tap(find.byKey(const Key('save-bring-item')));
    await tester.pumpAndSettle();

    expect(find.text('Paper plates'), findsOneWidget);
    expect(find.text('Qty 3 · Still up for grabs'), findsOneWidget);
    expect(find.text('2 of 5 covered · 1 packed'), findsOneWidget);
  });

  testWidgets('marks the current user item packed', (tester) async {
    await tester.pumpWidget(_testApp());

    final actions = find.byKey(const Key('bring-item-actions-3'));
    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark packed'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 4 covered · 2 packed'), findsOneWidget);
  });
}
