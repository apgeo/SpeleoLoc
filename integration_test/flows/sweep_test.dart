import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../catalogue/screens.dart';
import '../support/cell.dart';
import '../support/driver.dart';
import '../support/fixture.dart';
import '../support/flow.dart';
import '../support/probes.dart';
import '../support/recorder.dart';

/// Opens every screen in the catalogue, in every shape the cell asks for.
///
/// Deliberately shallow and deliberately blind to content: it asserts that
/// a screen builds and lays out, records what it had to cut off, and
/// photographs it. It carries on past a screen that fails, because the
/// useful answer is the full list of what is broken in this shape, not the
/// first item on it.
void main() {
  for (final scope in const ['core', 'all']) {
    flow(
      'sweep_$scope',
      (driver) => _sweep(driver, coreOnly: scope == 'core'),
      timeout: const Duration(minutes: 45),
    );
  }
}

Future<void> _sweep(AppDriver driver, {required bool coreOnly}) async {
  final tester = driver.tester;
  final cell = driver.cell;
  await driver.launch();
  final fx = await Fx.load();
  // An empty device makes every screen with an object to open skip, and a
  // sweep that skips everything passes. When the fixture was expected, that
  // is a setup failure, not a pass.
  if (cell.isInvented && fx.cave == null) {
    fail('the invented fixture is not on the device: no cave to open');
  }
  final entries = screenCatalogue.where((e) => !coreOnly || e.core).toList();
  final broken = <String>[];

  // The framework hands the test only the exception; where it came from is
  // in the details it was reported with. Listening in keeps the stack, so
  // a failure names a file and a line rather than just a message. The
  // handler has to be put back before the test ends — the framework checks.
  final reportError = FlutterError.onError;
  StackTrace? lastStack;
  final reported = <FlutterErrorDetails>[];
  FlutterError.onError = (details) {
    lastStack = details.stack;
    reported.add(details);
    // Described now, while the widget at fault is still in the tree: the
    // description walks up from it, and once the screen has moved on that
    // walk reports an error of its own — the sweep's doing, not the
    // screen's.
    _rendered[details] = details.toString();
    reportError?.call(details);
  };

  try {
    for (final shape in cell.shapes) {
      await driver.applyShape(shape);
      for (final entry in entries) {
        final watch = Stopwatch()..start();
        final shot = '${entry.id}__${shape.name}';

        final missing = entry.needs.difference(cell.capabilities);
        if (missing.isNotEmpty) {
          _record(
            entry,
            shape,
            'skipped',
            watch,
            error: 'needs ${missing.map((n) => n.name).join(', ')}',
          );
          continue;
        }

        String status = 'ok';
        String? error;
        var findings = const <Map<String, Object?>>[];
        lastStack = null;
        reported.clear();
        try {
          final Widget? page = entry.build(fx);
          if (page == null && entry.id != 'home') {
            _record(
              entry,
              shape,
              'skipped',
              watch,
              error: 'nothing in the data to open it on',
            );
            continue;
          }
          // Every step below is bounded on its own. Wrapping them in one
          // overall timeout looked tidier and was wrong: a timed-out future
          // keeps running, and its frames then collided with the next
          // screen's ("Guarded function conflict").
          await () async {
            if (page != null) driver.push(page);
            final idle = await driver.settle(
              timeout: const Duration(seconds: 8),
            );
            final thrown = tester.takeException();
            if (thrown != null) {
              error = _describe(thrown, lastStack, reported);
              // A map tile that could not be fetched is the normal state of
              // a phone underground, not a broken screen.
              status = _networkOnly(reported, error!) ? 'network' : 'error';
            } else if (!idle) {
              // Not a failure: a screen with a spinner or a live reading
              // never goes idle. Worth knowing, because it also means the
              // picture was taken mid-flight.
              status = 'busy';
            }
            findings = [
              ...Probes.truncatedText(tester),
              ...await Probes.accessibility(
                tester,
                contrast: AppDriver.onDesktop,
              ),
            ];
            await driver.shoot(shot);
          }();
        } catch (e, stack) {
          status = 'error';
          error = _brief(e, stack);
        }

        // What the framework reported is kept from the moment the screen
        // opened, not cleared here: errors that arrive after the check
        // above — a map tile failing seconds later — are folded by the
        // framework into one "Multiple exceptions (30)" that says nothing
        // on its own. The details are what name them.
        try {
          await driver.backToHome();
          final leftover = tester.takeException();
          if (leftover != null && status == 'ok') {
            error = 'on closing: ${_describe(leftover, lastStack, reported)}';
            status = _networkOnly(reported, error!) ? 'network' : 'error';
          }
        } catch (e, stack) {
          status = 'error';
          error ??= 'could not return to the first screen: ${_brief(e, stack)}';
        }

        final failed = status == 'error' || status == 'timeout';
        final known = failed
            ? _known(cell, entry.id, shape.name, error ?? '', reported)
            : null;
        if (known != null) {
          status = 'known';
          error = '$error | known: ${known.reason}';
        }
        _record(
          entry,
          shape,
          status,
          watch,
          shot: shot,
          error: error,
          findings: findings,
        );
        if (failed && known == null && !shape.bestEffort) {
          broken.add('${entry.id} @ ${shape.name}: $error');
        }
        if (failed) {
          await driver.relaunch();
          reported.clear();
        }
      }
    }
  } finally {
    FlutterError.onError = reportError;
  }

  expect(
    broken,
    isEmpty,
    reason:
        '${broken.length} screen(s) failed to open or lay out:\n'
        '${broken.join('\n')}',
  );
}

void _record(
  ScreenEntry entry,
  DeviceShape shape,
  String status,
  Stopwatch watch, {
  String? shot,
  String? error,
  List<Map<String, Object?>> findings = const [],
}) {
  Recorder.instance.screen(
    id: entry.id,
    area: entry.area,
    shape: shape.name,
    status: status,
    ms: watch.elapsedMilliseconds,
    shot: shot,
    error: error,
    bestEffort: shape.bestEffort,
    findings: findings,
  );
}

/// The first lines of an error and the first frames of the app's own code
/// in its stack: enough to say what and where, without the whole
/// widget-tree dump a layout exception carries.
String _brief(Object error, [StackTrace? stack]) {
  final lines = '$error'.split('\n').where((l) => l.trim().isNotEmpty).take(6);
  var text = lines.join(' | ');
  if (text.length > 500) text = '${text.substring(0, 500)}…';
  if (stack == null) return text;
  final frames = '$stack'
      .split('\n')
      .where((l) => l.contains('package:speleoloc/'))
      .map((l) => l.replaceFirst(RegExp(r'^#\d+\s+'), '').trim())
      .take(3);
  return frames.isEmpty ? text : '$text | at ${frames.join(' <- ')}';
}

/// Describes what went wrong on a screen from everything the framework
/// reported while it was open. When several errors came at once the test
/// only gets "Multiple exceptions (4)"; the details say which, and a layout
/// error names the widget — with its file and line — that overflowed.
String _describe(
  Object thrown,
  StackTrace? stack,
  List<FlutterErrorDetails> reported,
) {
  if (reported.isEmpty) return _brief(thrown, stack);
  final parts = <String>[];
  for (final details in reported.take(3)) {
    final summary = details.exceptionAsString().split('\n').first.trim();
    final text = _rendered[details] ?? details.toString();
    final marker = text.indexOf('The relevant error-causing widget was:');
    var where = '';
    if (marker >= 0) {
      // The widget's name, then — on its own line or the same one — where
      // it was created. The location is the useful half.
      final after = text
          .substring(marker)
          .split('\n')
          .skip(1)
          .where((l) => l.trim().isNotEmpty)
          .take(2)
          .toList();
      final line = after.firstWhere(
        (l) => l.contains('file:///'),
        orElse: () => after.isEmpty ? '' : after.first,
      );
      where = line.trim().replaceAll(RegExp(r'\S*file:///\S*?/lib/'), 'lib/');
    }
    final part = _brief(summary, details.stack);
    parts.add(where.isEmpty ? part : '$part | widget: $where');
  }
  final more = reported.length > 3 ? ' (+${reported.length - 3} more)' : '';
  return parts.toSet().join(' || ') + more;
}

/// The known issue that explains a failed screen, if one explains all of
/// it. Matching only the summary would let a known overflow hide a new
/// error that happened to be reported fourth.
KnownIssue? _known(
  MatrixCell cell,
  String screen,
  String shape,
  String error,
  List<FlutterErrorDetails> reported,
) {
  if (reported.isEmpty) return cell.known(screen, shape, error);
  KnownIssue? first;
  for (final details in reported) {
    final text = details.exceptionAsString();
    if (_networkError.hasMatch(text)) continue;
    final issue = cell.known(screen, shape, text);
    if (issue == null) return null;
    first ??= issue;
  }
  return first;
}

/// Each reported error's text, taken when it was reported.
final _rendered = Expando<String>();

/// Whether everything that went wrong on a screen was a failed network
/// request, such as a map tile that could not be fetched.
bool _networkOnly(List<FlutterErrorDetails> reported, String error) {
  if (reported.isEmpty) return _networkError.hasMatch(error);
  return reported.every((d) => _networkError.hasMatch(d.exceptionAsString()));
}

// Not HandshakeException: a TLS failure is not the network being away. It
// is how Android 7 rejects the tile server's certificate chain, and counting
// it as "network" would have hidden that.
final _networkError = RegExp(
  r'SocketException|ClientException|HttpException|'
  r'Failed host lookup|Connection (refused|reset|closed)',
);
