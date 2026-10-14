import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:speleoloc/main.dart' as app;
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/navigator_key.dart';

import 'cell.dart';
import 'pseudo_locale.dart';
import 'self_seed.dart';
import 'recorder.dart';

/// Shared plumbing for the end-to-end tests.
///
/// Keeps what every such test needs out of the tests themselves: starting
/// the real `main()` and waiting out its asynchronous startup, sizing the
/// surface, and capturing a screen in whichever way the platform allows.
///
/// The same tests run on an Android device and on the Linux desktop build.
/// The desktop run has no phone hardware behind it, but it boots in
/// seconds and can change its own shape, so it is where the breadth is
/// covered; a device is where the platform is.
class AppDriver {
  AppDriver(this.binding, this.tester, this.cell);

  final IntegrationTestWidgetsFlutterBinding binding;
  final WidgetTester tester;
  final MatrixCell cell;

  static IntegrationTestWidgetsFlutterBinding ensureInitialized() =>
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// True where the test shares a process and a disk with the tooling that
  /// started it, rather than running on a device behind a driver.
  static bool get onDesktop =>
      Platform.isLinux || Platform.isMacOS || Platform.isWindows;

  static bool _fontsLoaded = false;

  /// Makes the desktop build draw and measure the way a phone does.
  ///
  /// Two things differ by default and both move layout: desktop Material
  /// uses a denser, scrollbar-bearing variant of every widget, and Linux
  /// has no Roboto, so text falls back to a font with other widths. The
  /// platform override must be undone before the test body returns — the
  /// framework checks — which is what [restore] is for.
  Future<void> prepare() async {
    if (!onDesktop) return;
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final dir = cell.fontsDir;
    if (_fontsLoaded || dir == null) return;
    final loader = FontLoader('Roboto');
    for (final name in const [
      'Roboto-Regular.ttf',
      'Roboto-Medium.ttf',
      'Roboto-Bold.ttf',
      'Roboto-Italic.ttf',
      'Roboto-Light.ttf',
    ]) {
      final file = File('$dir/$name');
      if (!file.existsSync()) continue;
      loader.addFont(file.readAsBytes().then((b) => ByteData.sublistView(b)));
    }
    await loader.load();
    _fontsLoaded = true;
  }

  /// Undoes [prepare] and any shape override. Call from a `finally`.
  Future<void> restore() async {
    if (!onDesktop) return;
    debugDefaultTargetPlatformOverride = null;
    tester.platformDispatcher.clearAllTestValues();
    tester.view.reset();
  }

  /// Boots the real application and waits for its first screen.
  ///
  /// Polling rather than `pumpAndSettle`: startup awaits the database, the
  /// i18n bundle, the current user and the active-trip lookup before
  /// `runApp`, so the first frame can arrive long after the test begins.
  Future<void> launch({Duration timeout = const Duration(seconds: 90)}) async {
    // The pseudo-locale has no asset of its own. Installed before the app
    // starts, it is there when startup reads the language the seeded data
    // asks for and switches to it.
    if (cell.language == 'pseudo') {
      final english =
          jsonDecode(await rootBundle.loadString('assets/i18n/en.json'))
              as Map<String, dynamic>;
      LocServ.inst.installStrings(
        'pseudo',
        pseudoLocalize(english.map((k, v) => MapEntry(k, '$v'))),
      );
    }
    await seedFromBundleIfAsked();
    final started = DateTime.now();
    app.main();
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byType(MaterialApp).evaluate().isNotEmpty) break;
    }
    expect(
      find.byType(MaterialApp),
      findsOneWidget,
      reason: 'the app did not reach its first frame within $timeout',
    );
    // A debug build's start-up is slow in absolute terms; compared run to
    // run on the same device, a jump still means something.
    Recorder.instance.startupMs ??= DateTime.now()
        .difference(started)
        .inMilliseconds;
    await settle();
  }

  /// Renders at [shape] where the surface can be resized from inside the
  /// test. A device is shaped from outside before the app starts, so there
  /// this only reports what it was asked for.
  ///
  /// The view is told it has the shape's size and density outright, rather
  /// than being given a test surface scaled to fit the window: everything
  /// measured afterwards — tap-target sizes, text widths, the screenshot —
  /// is then in the shape's own units. The real window only clips what is
  /// shown on the virtual display, which nobody looks at.
  Future<void> applyShape(DeviceShape shape) async {
    if (!onDesktop || shape.size == null) return;
    tester.view.devicePixelRatio = shape.pixelRatio;
    tester.view.physicalSize = shape.size! * shape.pixelRatio;
    tester.platformDispatcher.textScaleFactorTestValue = shape.textScale;
    await settle(timeout: const Duration(seconds: 5));
  }

  /// Pumps until the UI is idle or [timeout] passes, and says which.
  ///
  /// A real screen can leave something running for ever — the product
  /// tour's timers, a progress indicator, a live sensor reading — so this
  /// never fails for not settling; `pumpAndSettle` would, and take the
  /// whole flow with it.
  Future<bool> settle({Duration timeout = const Duration(seconds: 20)}) async {
    final deadline = DateTime.now().add(timeout);
    do {
      await tester.pump(const Duration(milliseconds: 100));
      if (!tester.binding.hasScheduledFrame) return true;
    } while (DateTime.now().isBefore(deadline));
    return false;
  }

  /// Pumps until [condition] holds, failing with [reason] if it never does.
  ///
  /// For waits on work the frame loop cannot see finishing — a platform
  /// call reading the media library, a QR sweep — where `settle` would
  /// return the moment nothing is animating, long before the result lands.
  Future<void> pumpUntil(
    bool Function() condition, {
    required String reason,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) {
        fail('timed out after $timeout waiting for: $reason');
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
  }

  /// Captures the current screen under [name], with its semantics tree
  /// beside it.
  ///
  /// The tree is what a screenshot cannot show: a control that is visible
  /// but has no label, or one that is in the picture and absent from the
  /// tree, never reached accessibility at all.
  ///
  /// On Android the surface must be converted before it can be read back.
  /// A platform without either way still runs the flow — the screenshot is
  /// the part that is optional, not the assertions.
  Future<void> shoot(String name) async {
    Recorder.instance.semantics(name, _semanticsTree());
    if (onDesktop) {
      final dir = cell.outDir;
      if (dir == null) return;
      final bytes = await _renderSurface();
      if (bytes == null) return;
      final file = File('$dir/$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
      return;
    }
    try {
      await binding.convertFlutterSurfaceToImage();
      await tester.pump();
    } catch (e) {
      stdout.writeln('surface conversion unavailable ($e)');
    }
    await binding.takeScreenshot(name);
  }

  String _semanticsTree() {
    final owner = tester.binding.rootPipelineOwner.semanticsOwner;
    final views = tester.binding.renderViews;
    final node =
        owner?.rootSemanticsNode ??
        (views.isEmpty
            ? null
            : views.first.owner?.semanticsOwner?.rootSemanticsNode);
    return node?.toStringDeep() ?? '(no semantics tree)';
  }

  /// Draws the whole view into a PNG at its physical size, straight from
  /// the layer tree, so it does not matter that the window it is shown in
  /// is smaller.
  Future<Uint8List?> _renderSurface() async {
    final view = tester.binding.renderViews.first;
    final layer = view.debugLayer;
    if (layer is! OffsetLayer) return null;
    final ui.Image image = await layer.toImage(
      Offset.zero & tester.view.physicalSize,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data?.buffer.asUint8List();
  }

  /// Opens [page] on top of whatever is showing, the way the app itself
  /// would, without waiting for the route to be popped.
  void push(Widget page) {
    // Deliberately not awaited: the future completes when the route is
    // popped, which is the caller's next step, not this one's.
    // ignore: unawaited_futures
    navigatorKey.currentState!.push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  /// Closes everything above the first screen, including any dialog or
  /// sheet a screen opened on its own.
  Future<void> backToHome() async {
    navigatorKey.currentState!.popUntil((route) => route.isFirst);
    await settle(timeout: const Duration(seconds: 8));
  }

  /// Taps the first match for [finder] when it is present, returning
  /// whether it was. Lets a flow walk past a screen that may or may not be
  /// showing (a first-run tour, a permission prompt) without branching in
  /// the test body.
  Future<bool> tapIfPresent(Finder finder) async {
    if (finder.evaluate().isEmpty) return false;
    await tester.tap(finder.first);
    await settle();
    return true;
  }
}
