/// Constants of the SilexGIS device-sync contract.
///
/// The contract is versioned and this build pins a version: a server that has
/// moved on refuses an upload rather than interpreting it generously, so
/// [version] moves only together with a refresh of the recorded traffic under
/// `test_data/silexgis_contract/`. See
/// `docs/integrations/silexgis/00-this-copy.md`.
class SilexgisContract {
  const SilexgisContract._();

  /// Sent on every upload, and compared against the `contractVersion` the
  /// capabilities call answers.
  static const int version = 1;

  /// Registered public client. There is no secret: a secret shipped inside an
  /// installed application is not a secret, and the server requires PKCE S256
  /// instead.
  static const String clientId = 'silexgis-speleoloc';

  /// Asked for on the authorization request. Without `offline_access` the
  /// exchange succeeds, looks healthy, and simply returns no refresh token —
  /// which would send the caver back to a password prompt every 15 minutes.
  static const List<String> scopes = <String>[
    'openid',
    'profile',
    'email',
    'roles',
    'offline_access',
  ];

  // ----- routes -----

  static const String loginPath = '/api/v1/auth/login';
  static const String twoFactorSendPath = '/api/v1/auth/2fa/send';
  static const String authorizePath = '/connect/authorize';
  static const String tokenPath = '/connect/token';
  static const String mePath = '/api/v1/me/';

  static const String capabilitiesPath = '/api/v1/sync/capabilities';
  static const String setsPath = '/api/v1/sync/sets';

  static String setPath(String setId) => '$setsPath/$setId';
  static String downloadPath(String setId) => '${setPath(setId)}/download';
  static String uploadPath(String setId) => '${setPath(setId)}/upload';

  /// The one anonymous route this integration calls. It carries no cave name
  /// and no coordinate — only which installation a scanned code resolves at.
  static String qrLookupPath(String code) => '/api/v1/public/qr/$code';

  // ----- capability names -----

  /// Named in the capabilities answer when this build serves the read half.
  static const String featureDownload = 'download';

  /// Named in the capabilities answer when this build serves the write half.
  static const String featureUpload = 'upload';
}
