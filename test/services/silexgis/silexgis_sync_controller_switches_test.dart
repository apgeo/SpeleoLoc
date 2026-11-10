import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/utils/clock.dart';

import '../../support/fake_silexgis_server.dart';
import '../../support/silexgis_test_device.dart';

/// A run does what the profile's switches say, and a refusal it does not
/// expect fails the run rather than passing for something else.
void main() {
  final clock = FakeClock(DateTime.utc(2026, 11, 4, 9));
  final uploadPath = SilexgisContract.uploadPath('set-1');

  late FakeSilexgisServer server;
  final devices = <SilexgisTestDevice>[];

  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);
  setUp(() {
    clock.set(DateTime.utc(2026, 11, 4, 9));
    server = FakeSilexgisServer(clock: clock);
  });
  tearDown(() async {
    expect(server.faults, isEmpty);
    for (final device in devices) {
      await device.dispose();
    }
    devices.clear();
  });

  Future<SilexgisTestDevice> device({
    bool uploadsNewRoots = true,
    bool sendsFiles = true,
  }) async {
    final created = await SilexgisTestDevice.create(
      server,
      clock: clock,
      uploadsNewRoots: uploadsNewRoots,
      sendsFiles: sendsFiles,
    );
    devices.add(created);
    return created;
  }

  Iterable<FakeSilexgisRequest> uploads() =>
      server.requests.where((r) => r.path == uploadPath);

  group('files', () {
    /// A cave the installation holds, with an invented photo hung on it.
    Future<void> photoOnASyncedCave(SilexgisTestDevice phone) async {
      final cave = await phone.caves.addCave('Invented cave');
      await phone.sync();
      expect(server.feature(cave.toString()), isNotNull);

      final bytes = utf8.encode('invented picture');
      const relPath = 'documentation_files/doc_1761000000000_photo.jpg';
      final file = File('${phone.documentsDir.path}/$relPath');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
      clock.advance(const Duration(minutes: 1));
      final now = clock.nowMs();
      final doc = Uuid.v7();
      await phone.db
          .into(phone.db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: doc,
              title: 'photo',
              fileName: relPath,
              fileSize: bytes.length,
              fileType: 'photo',
            ).copyWith(
              fileHash: Value(sha256.convert(bytes).toString()),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
      await phone.db
          .into(phone.db.documentationFilesToGeofeatures)
          .insert(
            DocumentationFilesToGeofeaturesCompanion.insert(
              uuid: Uuid.v7(),
              geofeatureType: 'cave',
              documentationFileUuid: doc,
              geofeatureUuid: Value(cave),
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );
    }

    bool sentADocument() =>
        server.requests.any((r) => r.path.startsWith('/api/v1/files/')) ||
        uploads().any((r) => r.jsonBody.containsKey('documents'));

    setUp(() {
      server.features = <String>[
        SilexgisContract.featureDownload,
        SilexgisContract.featureUpload,
        SilexgisContract.featureDocumentUpload,
      ];
    });

    test('go up from a profile that sends them', () async {
      // The control for the case below: this photo is one a run sends.
      final phone = await device();
      await photoOnASyncedCave(phone);

      await phone.sync();

      expect(phone.controller.progress.phase, SilexgisSyncPhase.completed);
      expect(sentADocument(), isTrue);
    });

    test(
      'stay here, unread, when the profile has files switched off',
      () async {
        final phone = await device(sendsFiles: false);
        await photoOnASyncedCave(phone);

        await phone.sync();

        expect(phone.controller.progress.phase, SilexgisSyncPhase.completed);
        expect(sentADocument(), isFalse);
      },
    );
  });

  group('new roots', () {
    test('a new surface area stays here while the profile keeps them '
        'here', () async {
      final phone = await device(uploadsNewRoots: false);
      final area = await phone.caves.addSurfaceArea(title: 'Invented massif');

      await phone.sync();

      expect(phone.controller.progress.phase, SilexgisSyncPhase.completed);
      expect(server.feature(area.toString()), isNull);
      expect(
        uploads().expand((r) => r.jsonBody['rows'] as List? ?? const []),
        isEmpty,
      );
    });

    test('a new surface area goes up once the profile sends them', () async {
      final phone = await device();
      final area = await phone.caves.addSurfaceArea(title: 'Invented massif');

      await phone.sync();

      expect(phone.controller.progress.phase, SilexgisSyncPhase.completed);
      expect(server.feature(area.toString())?['name'], 'Invented massif');
    });
  });

  group('a refusal of the whole request', () {
    test('of the upload, other than asking for an update, fails the run with '
        'its own code', () async {
      final phone = await device();
      await phone.caves.addCave('Invented cave');
      server.refuseNext(
        uploadPath,
        status: 403,
        code: SilexgisCodes.accessForbidden,
        detail: 'Invented refusal.',
      );

      await phone.sync();

      final progress = phone.controller.progress;
      expect(progress.phase, SilexgisSyncPhase.failed);
      expect(progress.code, SilexgisCodes.accessForbidden);
      expect(progress.message, isNot(contains('Update the app')));
      // Nothing is read after a write that did not go.
      expect(
        server.requests.where((r) => r.path.endsWith('/download')),
        isEmpty,
      );
    });

    test('of a read, other than switching it off, fails the run', () async {
      final phone = await device();
      server.refuseNext(
        SilexgisContract.downloadPath('set-1'),
        status: 403,
        code: SilexgisCodes.accessForbidden,
      );

      await phone.sync();

      final progress = phone.controller.progress;
      expect(progress.phase, SilexgisSyncPhase.failed);
      expect(progress.code, SilexgisCodes.accessForbidden);
      expect(progress.unavailable, isEmpty);
    });
  });

  test('a run whose controller a database swap disposed mid-read finishes '
      'without a word to it', () async {
    final phone = await device();
    final cave = await phone.caves.addCave('Invented cave');
    var heard = 0;
    int? heardAtDispose;
    phone.controller.addListener(() => heard++);
    server.onRequest = (request) {
      if (request.path.endsWith('/download')) {
        heardAtDispose = heard;
        phone.disposeController();
      }
    };

    await phone.sync();

    expect(heardAtDispose, isNotNull);
    expect(heard, heardAtDispose);
    expect(phone.controller.progress.phase, SilexgisSyncPhase.completed);
    expect(server.feature(cave.toString()), isNotNull);
  });
}
