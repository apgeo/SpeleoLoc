import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_transfer.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_transfer_api.dart';

import 'contract_fixtures.dart';
import 'scripted_client.dart';
import 'token_source.dart';

/// Replays the recorded resumable-transfer routes through the app's own
/// transfer API: what goes up must match the recorded request, and what the
/// recording answers must read into the app's models.
void main() {
  const transfer = 'transfer-1';
  const stamp = '2026-10-29T08:00:00Z';
  const placeholders = <String, String>{
    '<upload>': transfer,
    '<timestamp>': stamp,
  };
  const recordedHash =
      '2ade24dc7491adbfcb008ebee4cf4487b964b56202294744aa4e22788c00f32c';

  /// The recorded `METHOD path?query` with the placeholder filled in, so it
  /// can be compared with the address that was really called.
  String recordedTarget(ContractExchange exchange) =>
      exchange.requestLine.replaceAll('<upload>', transfer);

  String sentTarget(SentRequest request) =>
      '${request.method} ${request.url.path}'
      '${request.url.hasQuery ? '?${request.url.query}' : ''}';

  Map<String, Object?> answer(ContractExchange exchange) =>
      fillPlaceholders(exchange.responseBody, placeholders)!
          as Map<String, Object?>;

  ({SilexgisTransferApi api, ScriptedClient client}) replay(
    ContractExchange exchange,
  ) {
    final target = recordedTarget(exchange).split(' ');
    final client = ScriptedClient(<ScriptedResponse>[
      ScriptedResponse.json(
        path: Uri.parse(target.last).path,
        method: target.first,
        status: exchange.status,
        json: answer(exchange),
      ),
    ]);
    return (
      api: SilexgisTransferApi(
        SilexgisHttp(
          baseUri: Uri.parse('https://club.example.org'),
          tokens: FixedTokenSource(),
          client: client,
        ),
      ),
      client: client,
    );
  }

  group('26-files-upload-open', () {
    final exchange = ContractExchange('26-files-upload-open');

    test('opens a staged transfer with the recorded body', () async {
      final (:api, :client) = replay(exchange);

      final opened = await api.open(
        fileName: exchange.requestBody['fileName']! as String,
        sizeBytes: exchange.requestBody['sizeBytes']! as int,
      );

      final sent = client.sent.single;
      expect(sentTarget(sent), exchange.requestLine);
      expect(sent.headers['Content-Type'], 'application/json');
      expect(sent.headers['Authorization'], 'Bearer access-1');
      // Exactly the recorded members: a destination beside `stageForSync`
      // would be refused.
      expect(sent.jsonBody, exchange.requestBody);

      expect(exchange.status, 201);
      expect(opened.id, transfer);
      expect(opened.receivedBytes, 0);
      expect(opened.chunkBytes, 8388608);
      expect(opened.expiresAt, stamp);
      expect(opened.stagedForSync, isTrue);
      expect(opened.stagedAt, isNull);
      expect(opened.sha256, isNull);
      expect(opened.isStaged, isFalse);
    });
  });

  group('27-files-upload-piece', () {
    final exchange = ContractExchange('27-files-upload-piece');

    test('sends the piece raw, at the offset in the query', () async {
      final (:api, :client) = replay(exchange);
      final piece = List<int>.generate(460, (i) => i % 251);

      final answered = await api.sendPiece(transfer, offset: 0, bytes: piece);

      final sent = client.sent.single;
      expect(sentTarget(sent), recordedTarget(exchange));
      expect(sent.headers['Content-Type'], 'application/octet-stream');
      expect(sent.headers['Authorization'], 'Bearer access-1');
      expect(sent.bodyBytes, piece);

      expect(answered.id, transfer);
      expect(answered.receivedBytes, 460);
      expect(answered.chunkBytes, 8388608);
      expect(answered.stagedForSync, isTrue);
      expect(answered.isStaged, isFalse);
    });
  });

  group('28-files-upload-complete', () {
    final exchange = ContractExchange('28-files-upload-complete');

    test('completes with no body and reads the staged bytes', () async {
      final (:api, :client) = replay(exchange);

      final staged = await api.complete(transfer);

      final sent = client.sent.single;
      expect(sentTarget(sent), recordedTarget(exchange));
      expect(sent.bodyBytes, isEmpty);

      expect(staged.id, transfer);
      expect(staged.sizeBytes, 920);
      expect(staged.sha256, recordedHash);
      expect(staged.mimeType, 'text/plain');
      expect(staged.expiresAt, stamp);
    });

    test('the hash is read lower-case whatever case it comes in', () {
      final staged = SilexgisStagedBytes.fromJson(<String, Object?>{
        ...answer(exchange),
        'sha256': recordedHash.toUpperCase(),
      });
      expect(staged.sha256, recordedHash);
    });
  });

  group('29-files-upload-status', () {
    final exchange = ContractExchange('29-files-upload-status');

    test('asks how far a transfer got and reads a staged one', () async {
      final (:api, :client) = replay(exchange);

      final status = await api.status(transfer);

      final sent = client.sent.single;
      expect(sentTarget(sent), recordedTarget(exchange));
      expect(sent.bodyBytes, isEmpty);

      expect(status.receivedBytes, 920);
      expect(status.stagedForSync, isTrue);
      expect(status.isStaged, isTrue);
      expect(status.stagedAt, stamp);
      expect(status.expiresAt, stamp);
      expect(status.sha256, recordedHash);
    });
  });

  group('30-files-config', () {
    final exchange = ContractExchange('30-files-config');

    test('reads the limits, and no limit as no number', () async {
      final (:api, :client) = replay(exchange);

      final config = await api.config();

      expect(sentTarget(client.sent.single), exchange.requestLine);
      expect(config.maxUploadBytes, 536870912);
      expect(config.chunkBytes, 8388608);
      // `null` means nothing limits this account, which is not zero room.
      expect(config.remainingBytes, isNull);
    });
  });
}
