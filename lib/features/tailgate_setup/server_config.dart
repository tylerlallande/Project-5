import 'package:flutter/foundation.dart';

String tailgateApiUrl() {
  const configured = String.fromEnvironment('TAILGATE_API_URL');
  if (configured.isNotEmpty) return configured;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://127.0.0.1:8080';
}
