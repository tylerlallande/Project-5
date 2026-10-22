class GameEvent {
  const GameEvent({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    required this.startTime,
    required this.status,
    this.homePoints,
    this.awayPoints,
    this.venue,
  });

  final String id;
  final String homeTeam;
  final String awayTeam;
  final DateTime startTime;
  final String status;
  final int? homePoints;
  final int? awayPoints;
  final String? venue;

  String get matchup => '$awayTeam at $homeTeam';
  bool get isLive => status.toLowerCase() == 'in_progress';
  bool get isFinal => status.toLowerCase() == 'completed';

  factory GameEvent.fromJson(Map<String, dynamic> data) => GameEvent(
    id: '${data['id']}',
    homeTeam: data['home_team'] as String? ?? 'Home team',
    awayTeam: data['away_team'] as String? ?? 'Away team',
    startTime:
        DateTime.tryParse(data['start_date'] as String? ?? '') ??
        DateTime.now(),
    status: data['status'] as String? ?? 'scheduled',
    homePoints: data['home_points'] as int?,
    awayPoints: data['away_points'] as int?,
    venue: data['venue'] as String?,
  );
}

class TailgateWeather {
  const TailgateWeather({
    required this.temperature,
    required this.precipitationProbability,
    required this.windSpeed,
    required this.weatherCode,
  });

  final double temperature;
  final int precipitationProbability;
  final double windSpeed;
  final int weatherCode;

  bool get needsAlert =>
      precipitationProbability >= 50 || windSpeed >= 25 || weatherCode >= 95;

  String get summary =>
      '${temperature.round()}° · $precipitationProbability% rain · ${windSpeed.round()} mph wind';
}
