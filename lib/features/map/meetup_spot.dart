class MeetupSpot {
  const MeetupSpot({
    required this.tailgateId,
    required this.name,
    required this.instructions,
    required this.latitude,
    required this.longitude,
    required this.meetupTime,
    required this.walkToStadiumMinutes,
  });

  final String tailgateId;
  final String name;
  final String instructions;
  final double latitude;
  final double longitude;
  final String meetupTime;
  final int walkToStadiumMinutes;

  factory MeetupSpot.fromJson(Map<String, Object?> json) => MeetupSpot(
    tailgateId: json['tailgateId']! as String,
    name: json['name']! as String,
    instructions: json['instructions']! as String,
    latitude: (json['latitude']! as num).toDouble(),
    longitude: (json['longitude']! as num).toDouble(),
    meetupTime: json['meetupTime']! as String,
    walkToStadiumMinutes: json['walkToStadiumMinutes']! as int,
  );

  Map<String, Object> toJson() => {
    'tailgateId': tailgateId,
    'name': name,
    'instructions': instructions,
    'latitude': latitude,
    'longitude': longitude,
    'meetupTime': meetupTime,
    'walkToStadiumMinutes': walkToStadiumMinutes,
  };
}
