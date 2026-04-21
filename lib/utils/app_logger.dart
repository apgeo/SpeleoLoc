import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
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
      if (record.stackTrace != null &&
          record.level >= Level.SEVERE) {
        buf.write('\n${record.stackTrace}');
      }
      debugPrint(buf.toString());
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
