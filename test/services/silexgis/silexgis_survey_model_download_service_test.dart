import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:speleoloc/data/repositories/configuration_repository.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/cave_model/current_survey_models.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_secure_token_store.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_local_state_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_session.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_download_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_survey_model_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_transfer_api.dart';
import 'package:speleoloc/services/user_repository.dart';

/// Fetching a server model on the caver's request when the phone has no
/// signal: signing in again is the first thing that goes over the network.
void main() {
  const profile = SilexgisProfile(
    profileUuid: 'p-1',
    displayName: 'Clubul Speo Example',
    baseUrl: 'https://club.example.org',
    accountEmail: 'caver@example.org',
    syncSetId: 'set-1',
  );

  late AppDatabase db;
  late Directory base;
  late InMemoryRefreshTokenStore tokens;
  late SilexgisProfileRepository profiles;
  late SilexgisSurveyModelDownloadService service;

  final model = ServerSurveyModel(
    profileUuid: profile.profileUuid,
    modelId: Uuid.v7(),
    documentId: Uuid.v7(),
    name: 'Invented plot',
    format: 'lox',
    sizeBytes: 29,
    isCurrent: true,
  );

  setUp(() async {
    base = await Directory.systemTemp.createTemp('silexgis_model_service_');
    db = AppDatabase.forTesting(NativeDatabase.memory());
    late ChangeLogger loggerRef;
    final currentUser = CurrentUserService(
      db,
      UserRepository(db, () => loggerRef),
      ConfigurationRepository(db),
    );
    await currentUser.initialize();
    loggerRef = ChangeLogger(db, currentUser);
    tokens = InMemoryRefreshTokenStore();
    profiles = SilexgisProfileRepository(
      ConfigurationRepository(db),
      tokens,
      SilexgisLocalStateRepository(db),
    );
    await profiles.save(profile);
    service = SilexgisSurveyModelDownloadService(
      db: db,
      logger: loggerRef,
      profiles: profiles,
      localState: SilexgisLocalStateRepository(db),
      models: SilexgisSurveyModelRepository(db),
      copies: SilexgisFileCopyRepository(db),
      sessionBuilder: (p) {
        final client = _OfflineClient();
        final auth = SilexgisAuthService(
          baseUri: p.baseUri,
          profileUuid: p.profileUuid,
          store: tokens,
          client: client,
          refreshRetryPause: Duration.zero,
        );
        final http = SilexgisHttp(
          baseUri: p.baseUri,
          tokens: auth,
          client: client,
        );
        return SilexgisSession(
          auth: auth,
          api: SilexgisSyncApi(http),
          transfers: SilexgisTransferApi(http),
        );
      },
      baseDir: () async => base,
    );
  });

  tearDown(() async {
    await db.close();
    await base.delete(recursive: true);
  });

  test('with no signal the outcome says offline instead of throwing', () async {
    await tokens.write(profile.profileUuid, 'invented-refresh-token');

    expect(await service.fetch(model), ServerModelFetchOutcome.offline);
  });

  test('without a stored sign-in the caver is asked to sign in', () async {
    expect(await service.fetch(model), ServerModelFetchOutcome.signIn);
  });
}

/// A phone with no signal: every request breaks before an answer.
class _OfflineClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      throw http.ClientException('no route to host');
}
