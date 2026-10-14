import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';

/// What a platform can do for a flow. A flow names what it needs and is
/// skipped — visibly, with the reason — where that is missing, rather than
/// failing for a reason that has nothing to do with the app.
enum Need { media, camera, bluetooth, location, microphone, network }

/// One cell of the test matrix, as seen from inside the app under test.
///
/// The runner that seeded the data writes `matrix_cell.json` beside it; the
/// test reads it once. That is what lets a single built binary serve every
/// cell: which flows run, in which shapes, and where output goes are
/// decided at run time rather than compiled in.
///
/// With no file present — a plain `flutter drive` by hand — every flow is
/// selected, in the device's own shape.
class MatrixCell {
  MatrixCell._({
    required this.flows,
    required this.shapes,
    required this.language,
    required this.settings,
    required this.theme,
    required this.device,
    required this.dataOrigin,
    required this.outDir,
    required this.fontsDir,
    required this.knownIssues,
  });

  /// Flow names to run; empty means all of them.
  final Set<String> flows;

  /// Shapes to render each screen at. A device has exactly one, applied to
  /// it from outside before the app starts. The desktop build can resize
  /// its own surface, so there the sweep walks through all of them in one
  /// process.
  final List<DeviceShape> shapes;

  final String language;
  final String settings;
  final String theme;
  final String device;

  /// `invented`, `anonymized` or `unmarked`, as declared by the archive the
  /// device was seeded from.
  final String dataOrigin;

  /// Where screenshots and results go when the test process can write to
  /// the host's disk, which only the desktop build can.
  final String? outDir;

  /// A directory holding Roboto, for the desktop build: Android ships the
  /// font and Linux does not, and text measured in another font overflows
  /// in different places.
  final String? fontsDir;

  /// Screen errors already known and waiting on a decision; see
  /// tool/matrix/known_issues.json. Reported, never failing.
  final List<KnownIssue> knownIssues;

  /// The known issue [error] on [screen] in [shape] is, if any.
  KnownIssue? known(String screen, String shape, String error) {
    for (final issue in knownIssues) {
      if (issue.screen == screen &&
          (issue.shape == '*' || issue.shape == shape) &&
          error.contains(issue.contains)) {
        return issue;
      }
    }
    return null;
  }

  bool selects(String flow) => flows.isEmpty || flows.contains(flow);
  bool get isInvented => dataOrigin == 'invented';

  static MatrixCell? _cached;

  static Future<MatrixCell> load() async => _cached ??= await _read();

  static Future<MatrixCell> _read() async {
    Map<String, dynamic> json = const {};
    try {
      final docs = await getApplicationDocumentsDirectory();
      final file = File('${docs.path}/matrix_cell.json');
      if (file.existsSync()) {
        json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      }
    } catch (e) {
      stdout.writeln('matrix cell not readable ($e); running every flow');
    }
    List<String> strings(String key) =>
        ((json[key] as List?) ?? const []).map((e) => '$e').toList();
    final shapes = ((json['shapes'] as List?) ?? const [])
        .map((e) => DeviceShape.fromJson(e as Map<String, dynamic>))
        .toList();
    // A build that runs where no cell file can be pushed — a cloud device
    // lab — can carry its flow list in instead.
    const builtIn = String.fromEnvironment('SPELEO_FLOWS');
    final flows = strings('flows').toSet();
    if (flows.isEmpty && builtIn.isNotEmpty) {
      flows.addAll(builtIn.split(',').where((f) => f.isNotEmpty));
    }
    return MatrixCell._(
      flows: flows,
      shapes: shapes.isEmpty ? const [DeviceShape.native] : shapes,
      language: '${json['language'] ?? ''}',
      settings: '${json['settings'] ?? 'default'}',
      theme: '${json['theme'] ?? 'light'}',
      device: '${json['device'] ?? Platform.operatingSystem}',
      dataOrigin:
          '${json['data_origin'] ?? (const bool.fromEnvironment('SPELEO_FIXTURE_INVENTED') ? 'invented' : 'unmarked')}',
      outDir: json['out_dir'] as String?,
      fontsDir: json['fonts_dir'] as String?,
      knownIssues: ((json['known_issues'] as List?) ?? const [])
          .map((e) => KnownIssue.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// What this platform has plugins for. The desktop build has none of
  /// the phone's hardware plugins. An emulator has them all but no usable
  /// radio behind the Bluetooth one — which is the point of opening those
  /// screens there: they have to cope with a phone that cannot scan.
  Set<Need> get capabilities {
    if (Platform.isAndroid || Platform.isIOS) return Need.values.toSet();
    return {Need.network};
  }
}

/// A screen shape: logical size, pixel density and system font scale.
class DeviceShape {
  const DeviceShape(
    this.name, {
    this.size,
    this.pixelRatio = 2.0,
    this.textScale = 1.0,
    this.bestEffort = false,
  });

  /// Whatever the device is; nothing is overridden.
  static const native = DeviceShape('native');

  factory DeviceShape.fromJson(Map<String, dynamic> json) => DeviceShape(
    '${json['name']}',
    size: json['width'] == null
        ? null
        : Size(
            (json['width'] as num).toDouble(),
            (json['height'] as num).toDouble(),
          ),
    pixelRatio: (json['pixel_ratio'] as num?)?.toDouble() ?? 2.0,
    textScale: (json['text_scale'] as num?)?.toDouble() ?? 1.0,
    bestEffort: json['best_effort'] == true,
  );

  final String name;

  /// Logical size; null leaves the surface as it is.
  final Size? size;
  final double pixelRatio;
  final double textScale;

  /// A shape whose findings are reported but never fail a run — the
  /// largest accessibility font sizes, where some overflow is expected.
  final bool bestEffort;

  @override
  String toString() => name;
}

/// A screen error that is known and accepted for now.
class KnownIssue {
  const KnownIssue(this.screen, this.shape, this.contains, this.reason);

  factory KnownIssue.fromJson(Map<String, dynamic> json) => KnownIssue(
    '${json['screen']}',
    '${json['shape'] ?? '*'}',
    '${json['contains'] ?? ''}',
    '${json['reason'] ?? ''}',
  );

  final String screen;
  final String shape;
  final String contains;
  final String reason;
}
