import 'current_location.dart';
import 'meetup_spot.dart';

const lsuMapCenter = MapCoordinate(latitude: 30.4120, longitude: -91.1838);

MeetupSpot lsuDefaultSpot({required String tailgateId}) => MeetupSpot(
  tailgateId: tailgateId,
  name: 'LSU campus',
  instructions: 'Set the pin to the exact tailgate meetup location.',
  latitude: lsuMapCenter.latitude,
  longitude: lsuMapCenter.longitude,
  meetupTime: 'See tailgate plan',
  walkToStadiumMinutes: 0,
);
