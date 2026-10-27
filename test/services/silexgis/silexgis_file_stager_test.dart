import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_stager.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_staged_upload_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_transfer_api.dart';
import 'package:speleoloc/utils/clock.dart';

import 'scripted_client.dart';
import 'token_source.dart';

/// Staging a file's bytes ahead of the upload that names them: in order, a
/// piece at a time, resumed from what the server holds, and never named while
/// the server's hash and the phone's disagree.
void main() {
  const profileUuid = 'p-1';
  const transferId = 'transfer-1';
  final clock = FakeClock(DateTime.utc(2026, 10, 28, 8));
  final documentUuid = Uuid.v7();
  // Twenty invented bytes, sent in pieces of eight.
  final bytes = Uint8List.fromList(List<int>.generate(20, (i) => i * 7));
  final hash = sha256.convert(bytes).toString();

  late Directory dir;
  late File file;
  late AppDatabase db;
  late SilexgisStagedUploadRepository staged;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('silexgis_stager_');
    file = File('${dir.path}/invented.jpg');
    await file.writeAsBytes(bytes);
    db = AppDatabase.forTesting(NativeDatabase.memory());
    staged = SilexgisStagedUploadRepository(db, clock: clock);
  });
  tearDown(() async {
    await db.close();
    await dir.delete(recursive: true);
  });

  final upload = SilexgisContract.fileUploadPath(transferId);
  final complete = SilexgisContract.fileUploadCompletePath(transferId);

  ScriptedResponse config({int? remaining}) => ScriptedResponse.json(
    path: SilexgisContract.filesConfigPath,
    json: <String, Object?>{
      'maxUploadBytes': 1000,
      'remainingBytes': remaining,
      'chunkBytes': 8,
    },
  );

  ScriptedResponse opened() => ScriptedResponse.json(
    path: SilexgisContract.fileUploadsPath,
    status: 201,
    json: <String, Object?>{
      'id': transferId,
      'receivedBytes': 0,
      'declaredSizeBytes': bytes.length,
      'chunkBytes': 8,
      'expiresAt': '2026-10-29T08:00:00Z',
      'stagedForSync': true,
    },
  );

  ScriptedResponse progress(int received, {String method = 'PUT'}) =>
      ScriptedResponse.json(
        path: upload,
        method: method,
        json: <String, Object?>{
          'id': transferId,
          'receivedBytes': received,
          'declaredSizeBytes': bytes.length,
          'chunkBytes': 8,
          'expiresAt': '2026-10-29T08:00:00Z',
          'stagedForSync': true,
        },
      );

  ScriptedResponse stagedStatus({String? sha}) => ScriptedResponse.json(
    path: upload,
    method: 'GET',
    json: <String, Object?>{
      'id': transferId,
      'receivedBytes': bytes.length,
      'declaredSizeBytes': bytes.length,
      'chunkBytes': 8,
      'expiresAt': '2026-11-04T08:00:00Z',
      'stagedForSync': true,
      'stagedAt': '2026-10-28T07:00:00Z',
      'sha256': sha ?? hash,
    },
  );

  ScriptedResponse completed({String? sha}) => ScriptedResponse.json(
    path: complete,
    json: <String, Object?>{
      'id': transferId,
      'fileName': 'invented.jpg',
      'sizeBytes': bytes.length,
      'sha256': sha ?? hash,
      'mimeType': 'image/jpeg',
      'kind': 'image',
      'stagedAt': '2026-10-28T08:00:00Z',
      'expiresAt': '2026-11-04T08:00:00Z',
    },
  );

  ScriptedResponse gone({String method = 'GET'}) => ScriptedResponse.problem(
    path: upload,
    method: method,
    status: 404,
    code: SilexgisCodes.sessionNotFound,
  );

  SilexgisFileStager stager(ScriptedClient client) => SilexgisFileStager(
    api: SilexgisTransferApi(
      SilexgisHttp(
        baseUri: Uri.parse('https://club.example.org'),
        tokens: FixedTokenSource(),
        client: client,
      ),
    ),
    staged: staged,
    profileUuid: profileUuid,
    clock: clock,
  );

  SilexgisStageRequest request() => SilexgisStageRequest(
    documentUuid: documentUuid,
    file: file,
    fileName: 'invented.jpg',
    sha256: hash,
    sizeBytes: bytes.length,
  );

  /// What a transfer left behind in an earlier run.
  Future<void> left(
    SilexgisStagedState state, {
    int received = 0,
    String expiresAt = '2026-10-29T08:00:00Z',
    String? sha,
  }) => staged.write(
    profileUuid,
    SilexgisStagedFile(
      documentUuid: documentUuid,
      sha256: sha ?? hash,
      sizeBytes: bytes.length,
      state: state,
      transferId: transferId,
      receivedBytes: received,
      expiresAt: expiresAt,
    ),
  );

  List<int> sentPieces(ScriptedClient client) => <int>[
    for (final r in client.sent.where((r) => r.method == 'PUT')) ...r.bodyBytes,
  ];

  List<String> offsets(ScriptedClient client) => <String>[
    for (final r in client.sent.where((r) => r.method == 'PUT'))
      r.url.queryParameters['offset']!,
  ];

  test('a new file is opened for staging and sent in order', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      config(),
      opened(),
      progress(8),
      progress(16),
      progress(20),
      completed(),
    ]);

    final result = await stager(client).stage(request());

    expect(result.outcome, SilexgisStageOutcome.staged);
    expect(result.transferId, transferId);
    final open = client.sent.firstWhere(
      (r) => r.url.path == SilexgisContract.fileUploadsPath,
    );
    // No destination of its own: the upload says where it goes.
    expect(open.jsonBody, <String, Object?>{
      'fileName': 'invented.jpg',
      'sizeBytes': 20,
      'stageForSync': true,
    });
    expect(offsets(client), <String>['0', '8', '16']);
    expect(sentPieces(client), bytes);
    expect(
      client.sent.firstWhere((r) => r.method == 'PUT').headers['Content-Type'],
      'application/octet-stream',
    );
    final kept = (await staged.read(profileUuid, documentUuid))!;
    expect(kept.state, SilexgisStagedState.staged);
    expect(kept.expiresAt, '2026-11-04T08:00:00Z');
    expect(client.isExhausted, isTrue);
  });

  test('a dropped run resumes from what the server holds', () async {
    // The device recorded eight bytes; the server got sixteen before the
    // answer was lost.
    await left(SilexgisStagedState.sending, received: 8);
    final client = ScriptedClient(<ScriptedResponse>[
      progress(16, method: 'GET'),
      progress(20),
      completed(),
    ]);

    final result = await stager(client).stage(request());

    expect(result.outcome, SilexgisStageOutcome.staged);
    expect(offsets(client), <String>['16']);
    expect(sentPieces(client), bytes.sublist(16));
    expect(client.isExhausted, isTrue);
  });

  test('a piece out of place resumes from the offset asked for', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      config(),
      opened(),
      progress(8),
      ScriptedResponse.problem(
        path: upload,
        method: 'PUT',
        status: 409,
        code: SilexgisCodes.chunkOutOfOrder,
        detail: 'The next piece starts at 16.',
      ),
      progress(16, method: 'GET'),
      progress(20),
      completed(),
    ]);

    final result = await stager(client).stage(request());

    expect(result.outcome, SilexgisStageOutcome.staged);
    expect(offsets(client), <String>['0', '8', '16']);
    expect(client.isExhausted, isTrue);
  });

  test('bytes still staged are named again, not sent again', () async {
    await left(SilexgisStagedState.staged, received: 20);
    final client = ScriptedClient(<ScriptedResponse>[stagedStatus()]);

    final result = await stager(client).stage(request());

    expect(result.outcome, SilexgisStageOutcome.staged);
    expect(result.transferId, transferId);
    expect(client.sent.where((r) => r.method == 'PUT'), isEmpty);
  });

  test('bytes past their expiry are staged again', () async {
    await left(
      SilexgisStagedState.staged,
      received: 20,
      expiresAt: '2026-10-28T07:59:59Z',
    );
    final client = ScriptedClient(<ScriptedResponse>[
      config(),
      opened(),
      progress(8),
      progress(16),
      progress(20),
      completed(),
    ]);

    final result = await stager(client).stage(request());

    expect(result.outcome, SilexgisStageOutcome.staged);
    // Not even asked about: the server answers an expired one as absent.
    expect(
      client.sent.where((r) => r.method == 'GET' && r.url.path == upload),
      isEmpty,
    );
    expect(sentPieces(client), bytes);
  });

  test('a transfer the server no longer knows is opened anew', () async {
    await left(SilexgisStagedState.staged, received: 20);
    final client = ScriptedClient(<ScriptedResponse>[
      gone(),
      config(),
      opened(),
      progress(8),
      progress(16),
      progress(20),
      completed(),
    ]);

    final result = await stager(client).stage(request());

    expect(result.outcome, SilexgisStageOutcome.staged);
    expect(sentPieces(client), bytes);
  });

  test('a transfer that vanishes part-way is started once more', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      config(),
      opened(),
      progress(8),
      gone(method: 'PUT'),
      opened(),
      progress(8),
      progress(16),
      progress(20),
      completed(),
    ]);

    final result = await stager(client).stage(request());

    expect(result.outcome, SilexgisStageOutcome.staged);
    expect(offsets(client), <String>['0', '8', '0', '8', '16']);
  });

  test('bytes whose hash is not the file\'s are never named', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      config(),
      opened(),
      progress(8),
      progress(16),
      progress(20),
      completed(sha: 'ff' * 32),
      ScriptedResponse(path: upload, method: 'DELETE', status: 204),
      // Sent once more from the start; the same answer stands.
      opened(),
      progress(8),
      progress(16),
      progress(20),
      completed(sha: 'ff' * 32),
      ScriptedResponse(path: upload, method: 'DELETE', status: 204),
    ]);

    final result = await stager(client).stage(request());

    expect(result.outcome, SilexgisStageOutcome.hashMismatch);
    expect(result.transferId, isNull);
    expect(await staged.read(profileUuid, documentUuid), isNull);
    expect(client.isExhausted, isTrue);
  });

  test('a file that changed since it was staged is staged again', () async {
    await left(SilexgisStagedState.staged, received: 20, sha: 'ee' * 32);
    final client = ScriptedClient(<ScriptedResponse>[
      // The old bytes are withdrawn so they stop counting against the room.
      ScriptedResponse(path: upload, method: 'DELETE', status: 204),
      config(),
      opened(),
      progress(8),
      progress(16),
      progress(20),
      completed(),
    ]);

    final result = await stager(client).stage(request());

    expect(result.outcome, SilexgisStageOutcome.staged);
    expect((await staged.read(profileUuid, documentUuid))!.sha256, hash);
  });

  group('the room left', () {
    test('a file that does not fit is not started', () async {
      final client = ScriptedClient(<ScriptedResponse>[config(remaining: 10)]);

      final result = await stager(client).stage(request());

      expect(result.outcome, SilexgisStageOutcome.quotaExceeded);
      expect(
        client.sent.where(
          (r) => r.url.path == SilexgisContract.fileUploadsPath,
        ),
        isEmpty,
      );
    });

    test('after a refusal for room, nothing more opens this run', () async {
      final client = ScriptedClient(<ScriptedResponse>[
        config(),
        ScriptedResponse.problem(
          path: SilexgisContract.fileUploadsPath,
          status: 409,
          code: SilexgisCodes.quotaExceeded,
        ),
      ]);
      final once = stager(client);

      expect(
        (await once.stage(request())).outcome,
        SilexgisStageOutcome.quotaExceeded,
      );
      expect(
        (await once.stage(request())).outcome,
        SilexgisStageOutcome.quotaExceeded,
      );
      expect(client.sent, hasLength(2));
    });
  });

  test('a lost connection leaves the progress to resume from', () async {
    final client = ScriptedClient(<ScriptedResponse>[
      config(),
      opened(),
      progress(8),
      // Nothing scripted for the second piece: the connection is gone.
    ]);

    final result = await stager(client).stage(request());

    expect(result.outcome, SilexgisStageOutcome.interrupted);
    final kept = (await staged.read(profileUuid, documentUuid))!;
    expect(kept.state, SilexgisStagedState.sending);
    expect(kept.receivedBytes, 8);
  });

  test('adopted bytes are not named for a new revision', () async {
    await left(SilexgisStagedState.adopted, received: 20);
    final client = ScriptedClient(<ScriptedResponse>[
      config(),
      opened(),
      progress(8),
      progress(16),
      progress(20),
      completed(),
    ]);

    final result = await stager(client).stage(request());

    expect(result.outcome, SilexgisStageOutcome.staged);
    // Adopted bytes are the document's file now; nothing is withdrawn.
    expect(client.sent.where((r) => r.method == 'DELETE'), isEmpty);
  });
}
