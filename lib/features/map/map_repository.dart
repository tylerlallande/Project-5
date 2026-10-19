import 'meetup_spot.dart';

abstract interface class MapRepository {
  Future<MeetupSpot> fetchMeetupSpot(String tailgateId);

  Future<MeetupSpot> saveMeetupSpot(MeetupSpot spot);
}

/// Temporary local implementation of the same contract the server will use.
class InMemoryMapRepository implements MapRepository {
  InMemoryMapRepository(Iterable<MeetupSpot> spots)
    : _spots = {for (final spot in spots) spot.tailgateId: spot};

  final Map<String, MeetupSpot> _spots;

  @override
  Future<MeetupSpot> fetchMeetupSpot(String tailgateId) async {
    final spot = _spots[tailgateId];
    if (spot == null) {
      throw StateError('No meetup spot found for $tailgateId');
    }
    return spot;
  }

  @override
  Future<MeetupSpot> saveMeetupSpot(MeetupSpot spot) async {
    _spots[spot.tailgateId] = spot;
    return spot;
  }
}
