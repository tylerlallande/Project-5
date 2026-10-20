import 'package:flutter/material.dart';
import 'package:tailgating/features/map/map_provider_config.dart';
import 'package:tailgating/features/map/meetup_spot.dart';

Widget buildTestMap(
  BuildContext context,
  MeetupSpot spot,
  MapProviderConfig config,
) => const ColoredBox(key: Key('test-map-surface'), color: Colors.blueGrey);
