import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'game_event.dart';
import '../tailgate_setup/server_config.dart';

class GameRepository {
  GameRepository({String? baseUrl}) : baseUrl = baseUrl ?? tailgateApiUrl();

  final String baseUrl;

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
      final raw = data['games'] as List? ?? const [];
      await preferences.setString(cacheKey, jsonEncode(raw));
      return raw
          .map((item) => GameEvent.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      final cached = preferences.getString(cacheKey);
      if (cached == null) return const [];
      return (jsonDecode(cached) as List)
          .map((item) => GameEvent.fromJson(item as Map<String, dynamic>))
          .toList();
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
      final times = (hourly['time'] as List).cast<String>();
      var bestIndex = 0;
      var bestDistance = const Duration(days: 365);
      for (var index = 0; index < times.length; index++) {
        final time = DateTime.tryParse(times[index]);
        if (time == null) continue;
        final distance = time.difference(eventTime).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          bestIndex = index;
        }
      }
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
}
