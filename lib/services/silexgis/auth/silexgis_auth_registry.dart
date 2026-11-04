import 'package:http/http.dart' as http;
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_server_address.dart';
import 'package:speleoloc/utils/clock.dart';

/// One sign-in per server profile, shared by everything that talks to it.
///
/// Refresh tokens roll: each refresh spends the token presented, and a spent
/// token presented again revokes the whole chain. A run that kept a sign-in
/// of its own while a model fetch, a document download or a set listing
/// refreshed from another would present a token already spent. So every
/// caller asks here and gets the same service, whose refreshes are
/// serialised and which always holds the latest token.
class SilexgisAuthRegistry {
  SilexgisAuthRegistry({
    required SilexgisRefreshTokenStore store,
    http.Client Function()? newClient,
    Clock clock = const SystemClock(),
  }) : _store = store,
       _newClient = newClient,
       _clock = clock;

  final SilexgisRefreshTokenStore _store;
  final http.Client Function()? _newClient;
  final Clock _clock;
  final Map<String, SilexgisAuthService> _live =
      <String, SilexgisAuthService>{};

  /// The sign-in of [profile]. A profile that now names another server gets
  /// a new one, and the old one is retired so nothing it still has on its
  /// way is stored; the same server written another way keeps its sign-in.
  SilexgisAuthService forProfile(SilexgisProfile profile) {
    final live = _live[profile.profileUuid];
    if (live != null &&
        SilexgisServerAddress.sameServer(
          live.baseUri.toString(),
          profile.baseUrl,
        )) {
      return live;
    }
    live?.retire();
    return _live[profile.profileUuid] = SilexgisAuthService(
      baseUri: profile.baseUri,
      profileUuid: profile.profileUuid,
      store: _store,
      client: _newClient?.call(),
      clock: _clock,
    );
  }

  /// Ends the sign-in of a profile that was forgotten or moved to another
  /// server, so that a refresh still on its way cannot store a token under
  /// it afterwards.
  void retire(String profileUuid) => _live.remove(profileUuid)?.retire();
}
