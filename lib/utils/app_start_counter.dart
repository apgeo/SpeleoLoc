import 'dart:io';
import 'package:path_provider/path_provider.dart';

/// Tracks the number of application starts in a plain-text file.
class AppStartCounter {
  AppStartCounter._();

  static const String _fileName = 'app_start_count.txt';

  static int _cachedCount = 0;

  /// The current start count (available after [increment] has been called).
  static int get count => _cachedCount;

  /// Reads the current count, increments it, writes it back, and returns the
  /// new value.  Call once during app startup (e.g. in `main()`).
  static Future<int> increment() async {
    final file = await _getFile();
    int current = 0;
    if (await file.exists()) {
      try {
        current = int.parse((await file.readAsString()).trim());
      } catch (_) {
        current = 0;
      }
    }
    current++;
    await file.writeAsString(current.toString(), flush: true);
    _cachedCount = current;
    return current;
  }

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }
}
