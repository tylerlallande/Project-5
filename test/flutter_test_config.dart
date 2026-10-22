import 'dart:async';

import 'support/memory_tailgate_repository.dart';

import 'package:tailgating/features/tailgate_setup/tailgate_repository.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TailgateRepository.create = () => MemoryTailgateRepository();
  await testMain();
}
