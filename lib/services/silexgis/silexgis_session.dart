import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';

/// Builds the per-installation pieces a conversation with the server needs.
///
/// Injected so a test can drive a whole run against a scripted server without
/// a socket, and so nothing that uses a session learns how a sign-in works.
typedef SilexgisSessionBuilder =
    SilexgisSession Function(SilexgisProfile profile);

/// One installation's client, assembled.
class SilexgisSession {
  const SilexgisSession({required this.auth, required this.api});

  /// A session signed in with the refresh token kept in [tokens].
  factory SilexgisSession.signedIn(
    SilexgisProfile profile,
    SilexgisRefreshTokenStore tokens,
  ) {
    final auth = SilexgisAuthService(
      baseUri: profile.baseUri,
      profileUuid: profile.profileUuid,
      store: tokens,
    );
    return SilexgisSession(
      auth: auth,
      api: SilexgisSyncApi(
        SilexgisHttp(baseUri: profile.baseUri, tokens: auth),
      ),
    );
  }

  final SilexgisAuthService auth;
  final SilexgisSyncApi api;
}
