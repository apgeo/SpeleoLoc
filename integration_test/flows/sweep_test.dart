import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../catalogue/screens.dart';
import '../support/cell.dart';
import '../support/driver.dart';
import '../support/fixture.dart';
import '../support/flow.dart';
import '../support/probes.dart';
import '../support/recorder.dart';

/// How long one screen may take to open, settle and be photographed before
/// the sweep gives up on it and moves to the next.
const _perScreen = Duration(seconds: 60);

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
          await () async {
            if (page != null) driver.push(page);
            final idle = await driver.settle(
              timeout: const Duration(seconds: 8),
            );
            final thrown = tester.takeException();
            if (thrown != null) {
              status = 'error';
              error = _describe(thrown, lastStack, reported);
            } else if (!idle) {
              // Not a failure: a screen with a spinner or a live reading
              // never goes idle. Worth knowing, because it also means the
              // picture was taken mid-flight.
              status = 'busy';
            }
            findings = [
              ...Probes.truncatedText(tester),
              ...await Probes.accessibility(tester),
            ];
            await driver.shoot(shot);
          }().timeout(_perScreen);
        } on TimeoutException {
          status = 'timeout';
          error = 'did not finish within ${_perScreen.inSeconds}s';
        } catch (e, stack) {
          status = 'error';
          error = _brief(e, stack);
        }

        try {
          lastStack = null;
          reported.clear();
          await driver.backToHome().timeout(const Duration(seconds: 30));
          final leftover = tester.takeException();
          if (leftover != null && status == 'ok') {
            status = 'error';
            error = 'on closing: ${_describe(leftover, lastStack, reported)}';
          }
        } catch (e, stack) {
          status = 'error';
          error ??= 'could not return to the first screen: ${_brief(e, stack)}';
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
        if ((status == 'error' || status == 'timeout') && !shape.bestEffort) {
          broken.add('${entry.id} @ ${shape.name}: $error');
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
    final text = details.toString();
    final marker = text.indexOf('The relevant error-causing widget was:');
    var where = '';
    if (marker >= 0) {
      final after = text.substring(marker).split('\n').skip(1);
      final line = after.firstWhere(
        (l) => l.trim().isNotEmpty,
        orElse: () => '',
      );
      where = line.trim().replaceAll(RegExp(r'file:///[^ ]*?/lib/'), 'lib/');
    }
    final part = _brief(summary, details.stack);
    parts.add(where.isEmpty ? part : '$part | widget: $where');
  }
  final more = reported.length > 3 ? ' (+${reported.length - 3} more)' : '';
  return parts.toSet().join(' || ') + more;
}
