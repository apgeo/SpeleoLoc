import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_held_row_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_part.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';
import 'package:speleoloc/utils/clock.dart';

import '../../support/fake_silexgis_server.dart';
import 'token_source.dart';

/// How the runner drives the sections beside the feature rows: what it tells
/// a part about the rows this run sends, and the one second pass it allows.
void main() {
  const profile = 'p-1';
  const setId = 'set-1';
  const capabilities = SilexgisCapabilities(
    contractVersion: 1,
    pageSizeMax: 500,
    uploadRowsMax: 500,
    features: <String>['download', 'upload'],
  );
  final clock = FakeClock(DateTime.utc(2026, 11, 2, 10));

  late AppDatabase db;
  late SilexgisLocalStateRepository localState;
  late SilexgisHeldRowRepository heldRows;
  late FakeSilexgisServer server;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    localState = SilexgisLocalStateRepository(db, clock: clock);
    heldRows = SilexgisHeldRowRepository(db, clock: clock);
    server = FakeSilexgisServer(clock: clock);
  });
  tearDown(() => db.close());

  Future<SilexgisUploadReport> run(List<SilexgisUploadPart> parts) =>
      SilexgisUploadRunner(
        api: SilexgisSyncApi(
          SilexgisHttp(
            baseUri: Uri.parse('https://club.example.test'),
            tokens: FixedTokenSource(server.issueAccessToken()),
            client: server.client(),
          ),
        ),
        builder: SilexgisUploadBuilder(
          db: db,
          localState: localState,
          heldRows: heldRows,
          profileUuid: profile,
        ),
        localState: localState,
        heldRows: heldRows,
        profileUuid: profile,
        parts: parts,
      ).run(setId, capabilities: capabilities);

  test('an item answered with what to change goes once more, marked as '
      'sent again', () async {
    final part = _Part(resendOnce: true);

    await run(<SilexgisUploadPart>[part]);

    expect(part.applied, <bool>[false, true]);
    final sent = server.requests.where(
      (r) => r.path.endsWith('/upload') && r.jsonBody['people'] != null,
    );
    expect(sent, hasLength(2));
  });

  test('a part is told the rows this run writes, not the ones it '
      'removes', () async {
    final t0 = clock.nowMs();
    final kept = Uuid.v7();
    final removed = Uuid.v7();
    await db
        .into(db.caves)
        .insert(Cave(uuid: kept, title: 'Invented, kept', updatedAt: t0));
    for (final id in <Uuid>[kept, removed]) {
      server.putFeature(<String, Object?>{
        'id': id.toString(),
        'kind': 'cave',
        'name': 'Invented',
        'parents': const <Object?>[],
      });
      await localState.writeRevision(
        profile,
        id,
        entityTable: 'caves',
        wireKind: 'cave',
        revision: server.feature(id.toString())!['updatedAt']! as String,
        localUpdatedAt: t0,
      );
    }
    clock.advance(const Duration(minutes: 1));
    await (db.update(db.caves)..where((t) => t.uuid.equalsValue(kept))).write(
      CavesCompanion(updatedAt: Value(clock.nowMs())),
    );
    final part = _Part();

    await run(<SilexgisUploadPart>[part]);

    // A recording or a document hung on the removed cave must not be sent on
    // the strength of a row that is going away.
    expect(part.rowsSent, <Uuid>{kept});
    expect(server.isDeleted(removed.toString()), isTrue);
  });
}

/// A section that sends one item, and asks for it once more when told to.
class _Part implements SilexgisUploadPart {
  _Part({this.resendOnce = false});

  final bool resendOnce;
  final List<bool> applied = <bool>[];
  Set<Uuid>? rowsSent;

  @override
  SyncUploadSection get section => SyncUploadSection.people;

  @override
  Future<List<SyncUploadItem>> build(SilexgisUploadContext context) async {
    rowsSent = Set<Uuid>.of(context.rowsSent);
    return <SyncUploadItem>[const _Item('person-1')];
  }

  @override
  Future<SilexgisPartAnswers> apply(
    List<SyncUploadItem> sent,
    List<SyncRowResult> answers, {
    required bool resent,
  }) async {
    applied.add(resent);
    return SilexgisPartAnswers(
      resend: resendOnce && !resent ? sent : const <SyncUploadItem>[],
    );
  }
}

class _Item implements SyncUploadItem {
  const _Item(this.id);

  final String id;

  @override
  Map<String, Object?> toJson() => <String, Object?>{'id': id};
}
