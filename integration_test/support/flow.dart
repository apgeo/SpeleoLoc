import 'package:flutter_test/flutter_test.dart';

import 'cell.dart';
import 'driver.dart';
import 'recorder.dart';

/// Declares one end-to-end flow.
///
/// A thin layer over `testWidgets` that gives every flow the same four
/// things: it runs only when the matrix cell selects it, it is skipped —
/// with the reason on record — where the platform cannot support it, it is
/// bounded by its own timeout so one hung flow cannot eat a whole run, and
/// its outcome is recorded where the report can find it.
///
/// A flow that asserts on the invented fixture's own names sets
/// [inventedOnly]; it has nothing to say about any other dataset.
void flow(
  String name,
  Future<void> Function(AppDriver driver) body, {
  Set<Need> needs = const {},
  bool inventedOnly = false,
  Duration timeout = const Duration(minutes: 5),
}) {
  final binding = AppDriver.ensureInitialized();
  testWidgets(name, (tester) async {
    final cell = await MatrixCell.load();
    final record = Recorder.instance.startFlow(name);

    String? skip;
    if (!cell.selects(name)) {
      skip = 'not selected in this cell';
    } else if (inventedOnly && !cell.isInvented) {
      skip = 'asserts on the invented fixture; data here is ${cell.dataOrigin}';
    } else {
      final missing = needs.difference(cell.capabilities);
      if (missing.isNotEmpty) {
        skip = 'needs ${missing.map((n) => n.name).join(', ')}';
      }
    }
    if (skip != null) {
      record.skip(skip);
      markTestSkipped(skip);
      return;
    }

    final driver = AppDriver(binding, tester, cell);
    try {
      await driver.prepare();
      await body(driver);
      record.pass();
    } catch (e) {
      // Like a known screen in the sweep: a failure already listed in
      // tool/matrix/known_issues.json is reported, not failed, so the run
      // keeps saying something about everything else.
      final shape = cell.shapes.isEmpty ? '' : cell.shapes.first.name;
      final issue = cell.known(name, shape, '$e');
      if (issue == null) {
        record.fail(e);
        rethrow;
      }
      record.known(e, issue.reason);
    } finally {
      await driver.restore();
    }
  }, timeout: Timeout(timeout));
}
