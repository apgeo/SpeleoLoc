import 'dart:convert';
import 'dart:io';

/// Collects what a run found, in a form a script can read back.
///
/// A test's pass or fail says one bit. A sweep over fifty screens in six
/// shapes produces far more than that — which screen, in which shape,
/// overflowed by how much; which strings were cut off — and it has to
/// survive the test process to be of any use. On a device it travels back
/// through the test driver; the desktop build writes it straight to disk.
class Recorder {
  Recorder._();
  static final Recorder instance = Recorder._();

  final List<Map<String, Object?>> _flows = [];
  final List<Map<String, Object?>> _screens = [];
  final Map<String, String> _semantics = {};
  Map<String, Object?> cell = {};

  FlowRecord startFlow(String name) {
    final record = FlowRecord._(name);
    _flows.add(record._json);
    return record;
  }

  void screen({
    required String id,
    required String area,
    required String shape,
    required String status,
    required int ms,
    String? shot,
    String? error,
    bool bestEffort = false,
    List<Map<String, Object?>> findings = const [],
  }) {
    _screens.add({
      'id': id,
      'area': area,
      'shape': shape,
      'status': status,
      'ms': ms,
      'shot': ?shot,
      'error': ?error,
      if (bestEffort) 'best_effort': true,
      if (findings.isNotEmpty) 'findings': findings,
    });
  }

  void semantics(String shot, String tree) => _semantics[shot] = tree;

  Map<String, Object?> toJson() => {
    'cell': cell,
    'flows': _flows,
    'screens': _screens,
    'semantics': _semantics,
  };

  /// Writes the result and the semantics dumps under [dir]. Only possible
  /// where the test process shares a disk with whoever reads the result.
  void writeTo(String dir) {
    Directory(dir).createSync(recursive: true);
    for (final entry in _semantics.entries) {
      File('$dir/${entry.key}.semantics.txt').writeAsStringSync(entry.value);
    }
    final json = toJson()..remove('semantics');
    File(
      '$dir/result.json',
    ).writeAsStringSync(const JsonEncoder.withIndent(' ').convert(json));
  }
}

class FlowRecord {
  FlowRecord._(String name) : _started = DateTime.now() {
    _json['name'] = name;
    _json['status'] = 'running';
  }

  final Map<String, Object?> _json = {};
  final DateTime _started;

  void _end(String status, [String? detail]) {
    _json['status'] = status;
    _json['ms'] = DateTime.now().difference(_started).inMilliseconds;
    if (detail != null) _json['detail'] = detail;
  }

  void pass() => _end('passed');
  void skip(String reason) => _end('skipped', reason);
  void fail(Object error) {
    final text = '$error';
    _end('failed', text.length > 1500 ? '${text.substring(0, 1500)}…' : text);
  }
}
