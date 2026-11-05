import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';

/// Checks the active trip after every FTP or SilexGIS sync run, either of
/// which can delete or end it. Read once at start to keep it listening.
final activeTripSyncReconcilerProvider = Provider<void>((ref) {
  void afterRun(bool? wasRunning, bool running) {
    if (wasRunning == true && !running) {
      unawaited(ref.read(caveTripServiceProvider).reconcileActiveTrip());
    }
  }

  ref.listen<bool>(
    ftpSyncControllerProvider.select((c) => c.isRunning),
    afterRun,
  );
  ref.listen<bool>(
    silexgisSyncControllerProvider.select((c) => c.isRunning),
    afterRun,
  );
});
