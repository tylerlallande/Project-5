import 'meetup_spot.dart';

abstract interface class MapRepository {
  Future<MeetupSpot?> fetchMeetupSpot(String tailgateId);

  Future<MeetupSpot> saveMeetupSpot(MeetupSpot spot);

  Future<void> deleteMeetupSpot(String tailgateId);
}

/// Temporary local implementation of the same contract the server will use.
class InMemoryMapRepository implements MapRepository {
  InMemoryMapRepository(Iterable<MeetupSpot> spots)
    : _spots = {for (final spot in spots) spot.tailgateId: spot};

  final Map<String, MeetupSpot> _spots;

  @override
  Future<MeetupSpot?> fetchMeetupSpot(String tailgateId) async =>
      _spots[tailgateId];

  @override
  Future<MeetupSpot> saveMeetupSpot(MeetupSpot spot) async {
    _spots[spot.tailgateId] = spot;
    return spot;
  }

  @override
  Future<void> deleteMeetupSpot(String tailgateId) async {
    _spots.remove(tailgateId);
  }
}
