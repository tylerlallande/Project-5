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

  factory GameEvent.fromJson(Map<String, dynamic> data) {
    String teamName(Object? value, String fallback) {
      if (value is Map<String, dynamic>) {
        return value['name'] as String? ?? fallback;
      }
      return value as String? ?? fallback;
    }

    int? points(Object? team, Object? direct) {
      final value = team is Map<String, dynamic> ? team['points'] : direct;
      return value is num ? value.toInt() : null;
    }

    final home = data['homeTeam'] ?? data['home_team'];
    final away = data['awayTeam'] ?? data['away_team'];
    final completed = data['completed'] == true;
    return GameEvent(
      id: '${data['id']}',
      homeTeam: teamName(home, 'Home team'),
      awayTeam: teamName(away, 'Away team'),
      startTime:
          DateTime.tryParse(
            (data['startDate'] ?? data['start_date']) as String? ?? '',
          ) ??
          DateTime.now(),
      status:
          data['status'] as String? ?? (completed ? 'completed' : 'scheduled'),
      homePoints: points(home, data['homePoints'] ?? data['home_points']),
      awayPoints: points(away, data['awayPoints'] ?? data['away_points']),
      venue: data['venue'] is Map<String, dynamic>
          ? (data['venue'] as Map<String, dynamic>)['name'] as String?
          : data['venue'] as String?,
    );
  }
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
      '${temperature.round()}°F · $precipitationProbability% rain · ${windSpeed.round()} mph wind';
}
