import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/app_shell.dart';
import 'package:tailgating/features/tailgate_setup/create_tailgate_screen.dart';
import 'package:tailgating/features/tailgate_setup/tailgate_draft.dart';
import 'package:tailgating/screens/tailgates_screen.dart';

void main() {
  testWidgets('leaving can be cancelled and public tailgates can be rejoined', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AppShell()));
    await tester.tap(find.text('Tailgates'));
    await tester.pumpAndSettle();
    final leave = find.byKey(const Key('leave-tailgate-purple'));
    await tester.scrollUntilVisible(
      leave,
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('tailgates-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(leave), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(leave);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(leave, findsOneWidget);
    await tester.tap(leave);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm-leave-tailgate')));
    await tester.pumpAndSettle();
    expect(leave, findsNothing);
    final rejoin = find.byKey(const Key('join-public-purple'));
    await tester.scrollUntilVisible(
      rejoin,
      150,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('tailgates-screen')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await Scrollable.ensureVisible(tester.element(rejoin), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(rejoin);
    await tester.pumpAndSettle();
    expect(rejoin, findsNothing);
  });

  testWidgets(
    'public join adds membership exactly once and preserves event details',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: AppShell()));
      await tester.tap(find.text('Tailgates'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byKey(const Key('join-public-tigers')),
        200,
        scrollable: find
            .descendant(
              of: find.byKey(const Key('tailgates-screen')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await Scrollable.ensureVisible(
        tester.element(find.byKey(const Key('join-public-tigers'))),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('join-public-tigers')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('join-public-tigers')), findsNothing);
      expect(find.text('Tigers Together'), findsOneWidget);
      final view = find.descendant(
        of: find.ancestor(
          of: find.text('Tigers Together'),
          matching: find.byType(Card),
        ),
        matching: find.byType(OutlinedButton),
      );
      await Scrollable.ensureVisible(tester.element(view), alignment: .5);
      await tester.pumpAndSettle();
      await tester.tap(view);
      await tester.pumpAndSettle();
      expect(find.text('Public tailgate'), findsOneWidget);
      expect(find.text('LSU game day'), findsOneWidget);
      expect(find.text('Gumbo & Geaux'), findsNothing);
    },
  );

  testWidgets(
    'private events stay out of discovery and joined events stay in My tailgates',
    (tester) async {
      TailgateEntry entry(
        String id, {
        bool public = false,
        bool joined = false,
      }) => TailgateEntry(
        id: id,
        code: 'ABC123',
        joined: joined,
        draft: TailgateDraft(
          game: 'LSU game day',
          name: id,
          date: DateTime(2026, 10, 24),
          kickoff: '6:30 PM',
          meetupTime: 'Noon',
          location: 'Oak Grove',
          vibe: 'Food',
          isPublic: public,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TailgatesScreen(
              entries: [
                entry('hidden-private'),
                entry('joined-private', joined: true),
                entry('open-public', public: true),
              ],
              onJoin: (_) {},
              onLeave: (_) {},
              onOpen: (_) {},
              onHost: () {},
              onInvite: () {},
            ),
          ),
        ),
      );
      expect(find.text('hidden-private'), findsNothing);
      expect(find.text('joined-private'), findsOneWidget);
      expect(find.text('open-public'), findsOneWidget);
    },
  );

  testWidgets(
    'host public toggle is off by default and passes visibility to created event',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      TailgateDraft? created;
      await tester.pumpWidget(
        MaterialApp(
          home: CreateTailgateScreen(onCreated: (draft) => created = draft),
        ),
      );
      expect(
        tester
            .widget<SwitchListTile>(
              find.byKey(const Key('public-tailgate-toggle')),
            )
            .value,
        isFalse,
      );
      await tester.tap(find.byKey(const Key('public-tailgate-toggle')));
      await tester.enterText(
        find.byKey(const Key('create-game-field')),
        'LSU vs. Florida',
      );
      await tester.enterText(
        find.byKey(const Key('create-name-field')),
        'Public Saturday',
      );
      await tester.tap(find.byKey(const Key('create-tailgate-next')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('create-tailgate-next')));
      await tester.pumpAndSettle();
      expect(find.text('Public · anyone can join'), findsOneWidget);
      await tester.tap(find.byKey(const Key('create-tailgate-submit')));
      await tester.pumpAndSettle();
      expect(created?.isPublic, isTrue);
      expect(created?.name, 'Public Saturday');
    },
  );
}
