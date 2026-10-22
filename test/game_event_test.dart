import 'package:flutter_test/flutter_test.dart';
import 'package:tailgating/features/game/game_event.dart';

void main() {
  test('parses the normalized CFBD schedule contract', () {
    final game = GameEvent.fromJson({
      'id': '401',
      'homeTeam': 'LSU',
      'awayTeam': 'Florida',
      'startDate': '2026-10-24T23:30:00Z',
      'status': 'completed',
      'homePoints': 31,
      'awayPoints': 17,
      'venue': 'Tiger Stadium',
    });

    expect(game.matchup, 'Florida at LSU');
    expect(game.isFinal, isTrue);
    expect(game.homePoints, 31);
    expect(game.startTime.isUtc, isTrue);
  });

  test('also tolerates nested scoreboard teams and the legacy contract', () {
    final live = GameEvent.fromJson({
      'id': 402,
      'homeTeam': {'name': 'LSU', 'points': 14},
      'awayTeam': {'name': 'Alabama', 'points': 10},
      'startDate': '2026-11-07T23:00:00Z',
      'status': 'in_progress',
      'venue': {'name': 'Tiger Stadium'},
    });
    final legacy = GameEvent.fromJson({
      'id': 403,
      'home_team': 'LSU',
      'away_team': 'Tulane',
      'start_date': '2026-09-12T18:00:00Z',
      'completed': true,
    });

    expect(live.isLive, isTrue);
    expect(live.awayPoints, 10);
    expect(live.venue, 'Tiger Stadium');
    expect(legacy.isFinal, isTrue);
  });

  test('weather summary states the units supplied by the server', () {
    const weather = TailgateWeather(
      temperature: 82.4,
      precipitationProbability: 60,
      windSpeed: 26.2,
      weatherCode: 95,
    );

    expect(weather.needsAlert, isTrue);
    expect(weather.summary, '82°F · 60% rain · 26 mph wind');
  });
}
