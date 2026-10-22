import 'package:flutter/material.dart';

import 'app.dart';

void main() => runApp(const TgateApp());

// Kept as an alias so earlier project tests and references remain compatible.
class TailgateApp extends TgateApp {
  const TailgateApp({super.key, super.mapBuilder});
}
