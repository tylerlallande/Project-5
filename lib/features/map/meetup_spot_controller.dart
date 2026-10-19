import 'package:flutter/foundation.dart';

import 'map_repository.dart';
import 'meetup_spot.dart';

class MeetupSpotController extends ChangeNotifier {
  MeetupSpotController(this._repository, {required this.tailgateId});

  final MapRepository _repository;
  final String tailgateId;

  MeetupSpot? _spot;
  Object? _error;
  bool _isLoading = false;

  MeetupSpot? get spot => _spot;
  Object? get error => _error;
  bool get isLoading => _isLoading;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      _spot = await _repository.fetchMeetupSpot(tailgateId);
    } catch (error) {
      _error = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save(MeetupSpot spot) async {
    _spot = await _repository.saveMeetupSpot(spot);
    notifyListeners();
  }
}
