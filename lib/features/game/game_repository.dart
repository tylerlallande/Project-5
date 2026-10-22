import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'game_event.dart';
import '../tailgate_setup/server_config.dart';

class GameRepository {
  GameRepository({String? baseUrl}) : baseUrl = baseUrl ?? tailgateApiUrl();

  final String baseUrl;
  String? scheduleNotice;

  Future<List<GameEvent>> schedule({String team = 'LSU', int? year}) async {
    final season = year ?? DateTime.now().year;
    final uri = Uri.parse('$baseUrl/games')
        .replace(queryParameters: {'team': team, 'year': '$season'});
    final preferences = await SharedPreferences.getInstance();
    final cacheKey = 'bayou.games.$team.$season';
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 400) throw const FormatException();
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['configured'] != true) {
        scheduleNotice =
            'Live schedules require CFBD_API_KEY on the tailgate server.';
        return _cachedSchedule(preferences, cacheKey);
      }
      scheduleNotice = null;
      final schedule = data['games'] as List? ?? const [];
      var combined = schedule
          .map((item) => GameEvent.fromJson(item as Map<String, dynamic>))
          .toList();
      try {
        final scoreboardUri = Uri.parse('$baseUrl/scoreboard')
            .replace(queryParameters: {'team': team, 'classification': 'fbs'});
        final scoreboardResponse = await http
            .get(scoreboardUri)
            .timeout(const Duration(seconds: 10));
        if (scoreboardResponse.statusCode < 400) {
          final scoreboardData =
              jsonDecode(scoreboardResponse.body) as Map<String, dynamic>;
          final liveGames = (scoreboardData['games'] as List? ?? const []).map(
            (item) => GameEvent.fromJson(item as Map<String, dynamic>),
          );
          final byId = {for (final game in combined) game.id: game};
          for (final game in liveGames) {
            byId[game.id] = game;
          }
          combined = byId.values.toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
        }
      } catch (_) {
        // A scoreboard outage should not hide the season schedule.
      }
      await preferences.setString(
        cacheKey,
        jsonEncode(combined.map(_gameToJson).toList()),
      );
      return combined;
    } catch (_) {
      scheduleNotice = 'The live schedule could not be reached. Showing saved games when available.';
      return _cachedSchedule(preferences, cacheKey);
    }
  }

  Future<TailgateWeather?> weather({
    required double latitude,
    required double longitude,
    required DateTime eventTime,
  }) async {
    final uri = Uri.parse('$baseUrl/weather').replace(
      queryParameters: {'latitude': '$latitude', 'longitude': '$longitude'},
    );
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode >= 400) return null;
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final hourly = data['hourly'] as Map<String, dynamic>?;
      if (hourly == null) return null;
      final times = (hourly['time'] as List?)?.cast<String>() ?? const [];
      if (times.isEmpty) return null;
      var bestIndex = 0;
      var bestDistance = const Duration(days: 365);
      for (var index = 0; index < times.length; index++) {
        final value = times[index];
        final time = DateTime.tryParse(
          value.endsWith('Z') ? value : '${value}Z',
        );
        if (time == null) continue;
        final distance = time.difference(eventTime.toUtc()).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          bestIndex = index;
        }
      }
      if (bestDistance > const Duration(minutes: 90)) return null;
      return TailgateWeather(
        temperature: ((hourly['temperature_2m'] as List)[bestIndex] as num)
            .toDouble(),
        precipitationProbability:
            (hourly['precipitation_probability'] as List)[bestIndex] as int,
        windSpeed: ((hourly['wind_speed_10m'] as List)[bestIndex] as num)
            .toDouble(),
        weatherCode: (hourly['weather_code'] as List)[bestIndex] as int,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _gameToJson(GameEvent game) => {
    'id': game.id,
    'homeTeam': game.homeTeam,
    'awayTeam': game.awayTeam,
    'startDate': game.startTime.toUtc().toIso8601String(),
    'status': game.status,
    'homePoints': game.homePoints,
    'awayPoints': game.awayPoints,
    'venue': game.venue,
  };

  static List<GameEvent> _cachedSchedule(
    SharedPreferences preferences,
    String cacheKey,
  ) {
    final cached = preferences.getString(cacheKey);
    if (cached == null) return const [];
    return (jsonDecode(cached) as List)
        .map((item) => GameEvent.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
