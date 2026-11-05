import 'package:flutter/widgets.dart';
import 'package:speleoloc/screens/startup/startup_failure_app.dart';
import 'package:speleoloc/services/startup/startup_recovery.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';

/// Runs the start-up steps in [start], then shows [app]. When a step throws,
/// shows [StartupFailureApp] instead: no frame drawn would leave the native
/// splash up for good, and with it the caver's only way out a reinstall.
///
/// A retry calls [prepareRetry] before running [start] again, for state a
/// failed attempt leaves unusable.
Future<void> startApp({
  required Future<void> Function() start,
  required Future<void> Function() prepareRetry,
  required Widget Function() app,
  required StartupRecovery recovery,
  void Function(Widget root) run = runApp,
}) async {
  try {
    await start();
  } catch (e, st) {
    AppLogger.of('Startup').severe('The app could not start', e, st);
    if (!LocServ.inst.isLoaded) await LocServ.inst.load();
    run(
      StartupFailureApp(
        error: e,
        recovery: recovery,
        onRetry: () async {
          await prepareRetry();
          await start();
          run(app());
        },
      ),
    );
    return;
  }
  run(app());
}
