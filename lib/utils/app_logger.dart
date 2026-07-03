import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:speleoloc/utils/constants.dart';

/// Centralized logging facade.
///
/// Wraps `package:logging` so the whole app has a single configuration point.
/// Call [AppLogger.init] once during app startup. Obtain tagged loggers via
/// `AppLogger.of('MyTag')` or the [AppLoggerX] extension.
class AppLogger {
  AppLogger._();

  static bool _initialized = false;

  /// Initialize the root logger. Idempotent.
  static void init() {
    if (_initialized) return;
    _initialized = true;

    hierarchicalLoggingEnabled = true;
    Logger.root.level = (kDebugMode || debugModeNotifier.value)
        ? Level.ALL
        : Level.INFO;

    Logger.root.onRecord.listen((record) {
      // Route through debugPrint so output is chunked on Android and so
      // release builds (where print is stripped) still surface warnings.
      final tag = record.loggerName.isEmpty ? '' : '[${record.loggerName}] ';
      final buf = StringBuffer()
        ..write(record.level.name.padRight(7))
        ..write(' ')
        ..write(tag)
        ..write(record.message);
      if (record.error != null) {
        buf.write(' | error: ${record.error}');
      }
      if (record.stackTrace != null && record.level >= Level.SEVERE) {
        buf.write('\n${record.stackTrace}');
      }
      debugPrint(buf.toString());

      // Forward WARNING+ to Sentry in release builds so production errors are
      // captured without any changes at call sites. The DSN is injected at
      // build time via --dart-define=SENTRY_DSN=... and is empty in debug
      // builds (where Sentry.init is a no-op), so this branch is safe to run
      // unconditionally.
      //
      // The free-form log message is deliberately NOT sent: messages across
      // the app embed user content (cave/place names, file paths), which must
      // not be uploaded to a third party without consent (finding 6.5). We
      // report the structured error object when present, or a content-free
      // placeholder otherwise, and group events by their source (logger +
      // level) rather than by message text.
      if (record.level >= Level.WARNING && !kDebugMode) {
        Sentry.captureException(
          record.error ?? _LoggedWarning(record.loggerName, record.level.name),
          stackTrace: record.stackTrace,
          withScope: (scope) {
            scope.fingerprint = [record.loggerName, record.level.name];
          },
        );
      }
    });

    // React to runtime debug toggle.
    debugModeNotifier.addListener(() {
      Logger.root.level = (kDebugMode || debugModeNotifier.value)
          ? Level.ALL
          : Level.INFO;
    });
  }

  /// Obtain a tagged [Logger]. Prefer [AppLoggerX.log] on objects when
  /// appropriate.
  static Logger of(String tag) => Logger(tag);
}

/// Convenience extension so any object can obtain a tagged logger based on its
/// runtime type name: `log.info('...')`.
extension AppLoggerX on Object {
  Logger get log => Logger(runtimeType.toString());
}

/// Placeholder exception reported to Sentry for a WARNING+ log record that
/// carried no error object. Holds NO message content, so user data from the
/// log line is never uploaded (see [AppLogger.init], finding 6.5).
class _LoggedWarning implements Exception {
  _LoggedWarning(this.loggerName, this.level);
  final String loggerName;
  final String level;
  @override
  String toString() => '$level logged by "$loggerName"';
}
