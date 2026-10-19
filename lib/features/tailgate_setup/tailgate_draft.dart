class TailgateDraft {
  const TailgateDraft({
    required this.game,
    required this.name,
    required this.date,
    required this.kickoff,
    required this.meetupTime,
    required this.location,
    required this.vibe,
    this.isPublic = false,
  });

  final String game;
  final String name;
  final DateTime date;
  final String kickoff;
  final String meetupTime;
  final String location;
  final String vibe;
  final bool isPublic;
}

class TailgateEntry {
  TailgateEntry({
    required this.id,
    required this.draft,
    required this.code,
    this.joined = false,
    this.hosted = false,
  });
  final String id;
  final TailgateDraft draft;
  final String code;
  bool joined;
  final bool hosted;
}
