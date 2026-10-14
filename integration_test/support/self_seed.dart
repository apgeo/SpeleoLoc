import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Set in builds meant for a device nobody can reach from outside — a
/// cloud device lab — where the data has to be put in place by the test
/// itself rather than by tool/android/seed_app_data.sh.
const _seedFromBundle = bool.fromEnvironment('SPELEO_SEED_FROM_BUNDLE');

/// The invented fixture, as bundled with the build.
const _bundledFixture = 'assets/test_archive/automation_fixture.zip';

/// Unpacks the bundled invented fixture into the app's documents
/// directory, once, before the app first starts — what the seeding script
/// does from outside on a local emulator.
///
/// Does nothing unless the build asked for it, and nothing when a database
/// is already there, so it can never replace data a person put on a
/// device.
Future<void> seedFromBundleIfAsked() async {
  if (!_seedFromBundle) return;
  final docs = await getApplicationDocumentsDirectory();
  if (File('${docs.path}/speleo_loc.sqlite').existsSync()) return;
  final bytes = await rootBundle.load(_bundledFixture);
  final archive = ZipDecoder().decodeBytes(bytes.buffer.asUint8List());
  for (final file in archive.files) {
    if (!file.isFile) continue;
    if (file.name == 'manifest.json' || file.name == 'ftp_credentials.json') {
      continue;
    }
    final out = File('${docs.path}/${file.name}');
    await out.parent.create(recursive: true);
    await out.writeAsBytes(file.content as List<int>);
  }
}
