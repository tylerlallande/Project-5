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
    this.capacity,
    this.requiresApproval = false,
    this.gameId,
    this.latitude,
    this.longitude,
  });

  final String game;
  final String name;
  final DateTime date;
  final String kickoff;
  final String meetupTime;
  final String location;
  final String vibe;
  final bool isPublic;
  final int? capacity;
  final bool requiresApproval;
  final String? gameId;
  final double? latitude;
  final double? longitude;

  Map<String, dynamic> toJson() => {
    'game': game,
    'name': name,
    'date': date.toIso8601String(),
    'kickoff': kickoff,
    'meetupTime': meetupTime,
    'location': location,
    'vibe': vibe,
    'isPublic': isPublic,
    'capacity': capacity,
    'requiresApproval': requiresApproval,
    'gameId': gameId,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory TailgateDraft.fromJson(Map<String, dynamic> data) => TailgateDraft(
    game: data['game'] as String,
    name: data['name'] as String,
    date: DateTime.parse(data['date'] as String),
    kickoff: data['kickoff'] as String,
    meetupTime: data['meetupTime'] as String,
    location: data['location'] as String,
    vibe: data['vibe'] as String,
    isPublic: data['isPublic'] as bool? ?? false,
    capacity: data['capacity'] as int?,
    requiresApproval: data['requiresApproval'] as bool? ?? false,
    gameId: data['gameId'] as String?,
    latitude: (data['latitude'] as num?)?.toDouble(),
    longitude: (data['longitude'] as num?)?.toDouble(),
  );
}

enum TailgateStatus { upcoming, active, completed, archived }

enum MembershipStatus { none, pending, joined, waitlisted }

class TailgateEntry {
  TailgateEntry({
    required this.id,
    required this.draft,
    required this.code,
    this.joined = false,
    this.hosted = false,
    this.memberCount = 0,
    this.status = TailgateStatus.upcoming,
    this.membershipStatus = MembershipStatus.none,
    this.pendingCount = 0,
    this.waitlistCount = 0,
    this.pendingMemberIds = const [],
  });
  final String id;
  final TailgateDraft draft;
  final String code;
  bool joined;
  final bool hosted;
  final int memberCount;
  final TailgateStatus status;
  final MembershipStatus membershipStatus;
  final int pendingCount;
  final int waitlistCount;
  final List<String> pendingMemberIds;

  bool get isPast =>
      draft.date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  factory TailgateEntry.fromJson(Map<String, dynamic> data) => TailgateEntry(
    id: data['id'] as String,
    code: data['code'] as String,
    draft: TailgateDraft.fromJson(data['draft'] as Map<String, dynamic>),
    joined: data['joined'] as bool? ?? false,
    hosted: data['hosted'] as bool? ?? false,
    memberCount: data['memberCount'] as int? ?? 0,
    status: TailgateStatus.values.byName(
      data['status'] as String? ?? TailgateStatus.upcoming.name,
    ),
    membershipStatus: MembershipStatus.values.byName(
      data['membershipStatus'] as String? ??
          ((data['joined'] as bool? ?? false) ? 'joined' : 'none'),
    ),
    pendingCount: data['pendingCount'] as int? ?? 0,
    waitlistCount: data['waitlistCount'] as int? ?? 0,
    pendingMemberIds:
        (data['pendingMembers'] as List?)?.cast<String>() ?? const [],
  );
}
