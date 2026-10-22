import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/features/bring_list/bring_list_section.dart';
import 'package:tailgating/features/bring_list/bring_item.dart';
import 'package:tailgating/features/tailgate_setup/tailgate_draft.dart';
import 'package:tailgating/features/tailgate_setup/tailgate_repository.dart';

final _entry = TailgateEntry(
  id: 'test-tailgate',
  code: 'TEST12',
  joined: true,
  memberCount: 1,
  draft: TailgateDraft(
    game: 'Test game',
    name: 'Test tailgate',
    date: DateTime(2026, 10, 24),
    kickoff: '6:30 PM',
    meetupTime: 'Noon',
    location: 'Test spot',
    vibe: 'Fun',
  ),
);

class _BringRepository extends TailgateRepository {
  final items = <BringItem>[
    const BringItem(
      id: '1',
      name: 'The gumbo',
      quantity: 1,
      category: BringItemCategory.food,
      claimedBy: 'Jordan',
      isPacked: true,
    ),
    const BringItem(
      id: '2',
      name: 'Ice & coolers',
      quantity: 2,
      category: BringItemCategory.drinks,
    ),
    const BringItem(
      id: '3',
      name: 'Game-day playlist',
      quantity: 1,
      category: BringItemCategory.other,
      claimedBy: 'Alex',
    ),
    const BringItem(
      id: '4',
      name: 'Cornhole',
      quantity: 1,
      category: BringItemCategory.games,
    ),
  ];
  @override
  Future<List<TailgateEntry>> list() async => [_entry];
  @override
  Future<TailgateEntry> createTailgate(TailgateDraft draft) =>
      throw UnimplementedError();
  @override
  Future<TailgateEntry> lookup(String code) => throw UnimplementedError();
  @override
  Future<TailgateEntry> join(TailgateEntry entry) => throw UnimplementedError();
  @override
  Future<bool> leave(TailgateEntry entry, {bool confirmDelete = false}) =>
      throw UnimplementedError();
  @override
  Future<List<BringItem>> listBringItems(TailgateEntry entry) async =>
      List.of(items);
  @override
  Future<BringItem> addBringItem(TailgateEntry entry, BringItem item) async {
    final saved = BringItem(
      id: 'new-${items.length}',
      name: item.name,
      quantity: item.quantity,
      category: item.category,
    );
    items.add(saved);
    return saved;
  }

  @override
  Future<BringItem> updateBringItem(TailgateEntry entry, BringItem item) async {
    items[items.indexWhere((value) => value.id == item.id)] = item;
    return item;
  }

  @override
  Future<void> deleteBringItem(TailgateEntry entry, BringItem item) async =>
      items.remove(item);
}

Widget _testApp(_BringRepository repository) {
  return MaterialApp(
    home: Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: BringListSection(
            currentUser: 'Alex',
            entry: _entry,
            repository: repository,
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('claims an open item and includes it in the Mine filter', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_BringRepository()));
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(_testApp(_BringRepository()));
    await tester.pumpAndSettle();

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
    await tester.pumpWidget(_testApp(_BringRepository()));
    await tester.pumpAndSettle();

    final actions = find.byKey(const Key('bring-item-actions-3'));
    await tester.tap(actions);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark packed'));
    await tester.pumpAndSettle();

    expect(find.text('2 of 4 covered · 2 packed'), findsOneWidget);
  });
}
