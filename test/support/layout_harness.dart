import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

import 'device_profiles.dart';

/// Renders widgets at each [DeviceProfile] and reports what broke.
///
/// Two checks live here rather than one. Overflow checking runs against
/// every profile because a failure needs no reference file to interpret —
/// it names the widget and the pixel count. Golden images run against a
/// couple of profiles only, since each one costs a binary a human has to
/// review on every intentional UI change.
class LayoutHarness {
  const LayoutHarness._();

  /// Loads the real fonts and i18n strings.
  ///
  /// Must run outside a `testWidgets` body — see [useLayoutHarness].
  /// Without the fonts, widget tests draw every glyph as a filled block:
  /// stable enough for a golden, but it hides the thing a human opens a
  /// golden to look at, and it measures text at the wrong width.
  static Future<void> ensureReady() async {
    await LocServ.inst.setLocale('en');
    await LocServ.inst.load();
    final flutterRoot = _flutterRoot();
    await _loadFont('Roboto', [
      'assets/fonts/Roboto-Regular.ttf',
      'assets/fonts/Roboto-Bold.ttf',
      // The bundled faces are subset and miss glyphs the UI does use (the
      // arrow in a before/after line, for one). The SDK ships the full
      // family, so append it as a fallback rather than reshaping UI text
      // around what a test can draw.
      if (flutterRoot != null)
        '$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Regular.ttf',
      if (flutterRoot != null)
        '$flutterRoot/bin/cache/artifacts/material_fonts/Roboto-Medium.ttf',
    ]);
    // Icons are not in the test asset bundle either, and an icon-heavy row
    // reviewed as a grid of empty boxes tells a reviewer nothing. Taken
    // from the SDK's own cache so it tracks the Flutter version in use.
    if (flutterRoot != null) {
      await _loadFont('MaterialIcons', [
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
            'MaterialIcons-Regular.otf',
      ]);
    }
  }

  /// Locates the SDK from the running `dart` executable, so no environment
  /// variable has to be set for the fonts to resolve.
  static String? _flutterRoot() {
    final fromEnv = Platform.environment['FLUTTER_ROOT'];
    if (fromEnv != null && fromEnv.isNotEmpty) return fromEnv;
    // .../flutter/bin/cache/dart-sdk/bin/dart -> .../flutter
    var dir = File(Platform.resolvedExecutable).parent;
    for (var i = 0; i < 6; i++) {
      if (Directory(
        '${dir.path}/bin/cache/artifacts/material_fonts',
      ).existsSync()) {
        return dir.path;
      }
      dir = dir.parent;
    }
    return null;
  }

  static final Set<String> _loadedFonts = {};

  static Future<void> _loadFont(String family, List<String> paths) async {
    if (!_loadedFonts.add(family)) return;
    final loader = FontLoader(family);
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      loader.addFont(file.readAsBytes().then((b) => ByteData.sublistView(b)));
    }
    await loader.load();
  }

  /// Wraps [child] in the app-level scaffolding a screen expects: a
  /// MaterialApp with the project's font family, the profile's text scale,
  /// and the navigator key [SnackBarService] posts through.
  static Widget app(Widget child, DeviceProfile profile) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, fontFamily: 'Roboto'),
      home: child,
      builder: (context, built) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(profile.textScale)),
        child: built ?? const SizedBox.shrink(),
      ),
    );
  }

  /// Sizes the test window to [profile] for the duration of the test.
  static void applyProfile(WidgetTester tester, DeviceProfile profile) {
    tester.view.physicalSize = profile.physicalSize;
    tester.view.devicePixelRatio = profile.devicePixelRatio;
    addTearDown(tester.view.reset);
  }

  /// Pumps [build] at [profile] and returns whatever layout exception it
  /// produced, or null when it laid out cleanly.
  ///
  /// `pump` rather than `pumpAndSettle`: a real screen starts async loads
  /// that may never settle, and overflow is reported on the first frames
  /// anyway.
  static Future<Object?> renderAndCatch(
    WidgetTester tester,
    DeviceProfile profile,
    Widget Function() build, {
    int frames = 3,
  }) async {
    applyProfile(tester, profile);
    await tester.pumpWidget(app(build(), profile));
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return tester.takeException();
  }
}

/// Call once at the top of `main()` in any file using this harness.
///
/// The loading has to happen here rather than inside the tests: a
/// `testWidgets` body runs in a fake-async zone where real asset and file
/// I/O never completes, so awaiting a font load in one hangs the test until
/// the suite times out.
void useLayoutHarness() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(LayoutHarness.ensureReady);
}

/// Asserts [build] lays out without overflow at every profile in
/// [profiles], reporting every failing profile at once rather than
/// stopping at the first.
void testLaysOutEverywhere(
  String description,
  Widget Function() build, {
  List<DeviceProfile> profiles = deviceProfiles,
}) {
  testWidgets('$description lays out on every device profile', (tester) async {
    final failures = <String>[];
    for (final profile in profiles) {
      final error = await LayoutHarness.renderAndCatch(tester, profile, build);
      if (error != null) failures.add('${profile.name}: $error');
    }
    expect(
      failures,
      isEmpty,
      reason:
          'layout failed on ${failures.length} of ${profiles.length} '
          'profiles:\n${failures.join('\n')}',
    );
  });
}

/// Captures a golden image of [build] at every profile in [profiles].
///
/// Goldens are generated and compared on Linux here; glyph rasterisation
/// differs between platforms, so a golden produced on another OS will not
/// match. Regenerate with:
///   flutter test --update-goldens test/widgets/<file>
void testGoldenAcrossDevices(
  String description,
  String goldenName,
  Widget Function() build, {
  List<DeviceProfile> profiles = goldenProfiles,
}) {
  for (final profile in profiles) {
    testWidgets('$description matches its golden on ${profile.name}', (
      tester,
    ) async {
      final error = await LayoutHarness.renderAndCatch(tester, profile, build);
      expect(error, isNull, reason: 'the case must lay out before it is shot');
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${goldenName}_${profile.name}.png'),
      );
    });
  }
}
