import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// Root of the recorded SilexGIS traffic copied into this repository.
/// See `docs/integrations/silexgis/00-this-copy.md` for its provenance and
/// how it is refreshed.
final Directory contractRoot = Directory(
  p.join(Directory.current.path, 'test_data', 'silexgis_contract', 'v1'),
);

/// One recorded exchange: the request line, the body that went up (writes
/// only), the body that came back, and the status line (refusals only — a
/// successful exchange has no `status.txt` because its status is 200 by
/// construction).
///
/// These bytes are the specification. Where the documents under
/// `docs/integrations/silexgis/` and these files disagree, these files are
/// right — prose drifts from a payload silently and a byte comparison cannot.
class ContractExchange {
  ContractExchange(this.name);

  /// Directory name under the recordings root, e.g. `11-upload-create` or
  /// `16-errors/cursor-stale`.
  final String name;

  Directory get _dir => Directory(p.join(contractRoot.path, name));

  File _file(String leaf) => File(p.join(_dir.path, leaf));

  /// `METHOD /path?query`, exactly as recorded.
  String get requestLine => _file('request.txt').readAsStringSync().trim();

  /// The path-and-query half of [requestLine].
  String get requestTarget => requestLine.split(' ').last;

  /// The request body of a write. Absent for a read.
  Map<String, Object?> get requestBody =>
      jsonDecode(_file('request.json').readAsStringSync())
          as Map<String, Object?>;

  /// The recorded response body.
  Map<String, Object?> get responseBody =>
      jsonDecode(_file('response.json').readAsStringSync())
          as Map<String, Object?>;

  /// The recorded HTTP status, or 200 for an exchange with no `status.txt`.
  int get status {
    final file = _file('status.txt');
    if (!file.existsSync()) return 200;
    return int.parse(file.readAsStringSync().trim().split(' ').first);
  }
}
