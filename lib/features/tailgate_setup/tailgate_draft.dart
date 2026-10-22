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

  Map<String, dynamic> toJson() => {
    'game': game,
    'name': name,
    'date': date.toIso8601String(),
    'kickoff': kickoff,
    'meetupTime': meetupTime,
    'location': location,
    'vibe': vibe,
    'isPublic': isPublic,
  };

  factory TailgateDraft.fromJson(Map<String, dynamic> data) => TailgateDraft(
    game: data['game'] as String,
    name: data['name'] as String,
    date: DateTime.parse(data['date'] as String),
    kickoff: data['kickoff'] as String,
    meetupTime: data['meetupTime'] as String,
    location: data['location'] as String,
    vibe: data['vibe'] as String,
    isPublic: data['isPublic'] as bool,
  );
}

class TailgateEntry {
  TailgateEntry({
    required this.id,
    required this.draft,
    required this.code,
    this.joined = false,
    this.hosted = false,
    this.memberCount = 8,
  });
  final String id;
  final TailgateDraft draft;
  final String code;
  bool joined;
  final bool hosted;
  final int memberCount;

  factory TailgateEntry.fromJson(Map<String, dynamic> data) => TailgateEntry(
    id: data['id'] as String,
    code: data['code'] as String,
    draft: TailgateDraft.fromJson(data['draft'] as Map<String, dynamic>),
    joined: data['joined'] as bool,
    hosted: data['hosted'] as bool,
    memberCount: data['memberCount'] as int,
  );
}
