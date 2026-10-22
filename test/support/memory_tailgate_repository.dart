import 'package:tailgating/features/tailgate_setup/tailgate_draft.dart';
import 'package:tailgating/features/tailgate_setup/tailgate_repository.dart';

class MemoryTailgateRepository extends TailgateRepository {
  final entries = <TailgateEntry>[
    for (final data in [
      ('gumbo', 'Gumbo & Geaux', 'GEAUX7', false, true),
      ('purple', 'The Purple Lot', 'PURPLE', true, true),
      ('tigers', 'Tigers Together', 'TIGERS', true, false),
    ])
      TailgateEntry(
        id: data.$1,
        code: data.$3,
        joined: data.$5,
        memberCount: 8,
        draft: TailgateDraft(
          game: data.$1 == 'gumbo' ? 'LSU vs. Alabama' : 'LSU game day',
          name: data.$2,
          date: DateTime(2026, 10, 24),
          kickoff: '6:30 PM',
          meetupTime: 'Noon',
          location: 'Oak Grove',
          vibe: 'Food',
          isPublic: data.$4,
        ),
      ),
  ];
  @override
  Future<List<TailgateEntry>> list() async =>
      entries.where((entry) => entry.joined || entry.draft.isPublic).toList();
  @override
  Future<TailgateEntry> createTailgate(TailgateDraft draft) async {
    final entry = TailgateEntry(
      id: 'new${entries.length}',
      code: 'ABC123',
      draft: draft,
      joined: true,
      hosted: true,
      memberCount: 1,
    );
    entries.add(entry);
    return entry;
  }

  @override
  Future<TailgateEntry> lookup(String code) async =>
      entries.firstWhere((entry) => entry.code == code);
  @override
  Future<TailgateEntry> join(TailgateEntry entry) async {
    entry.joined = true;
    return entry;
  }

  @override
  Future<bool> leave(TailgateEntry entry, {bool confirmDelete = false}) async {
    if (entry.memberCount == 1 && !confirmDelete) {
      throw TailgateApiException('Last member', code: 'last_member');
    }
    if (entry.memberCount == 1) {
      entries.remove(entry);
      return true;
    }
    entry.joined = false;
    return false;
  }
}
