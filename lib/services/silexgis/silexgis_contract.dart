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

  /// The photo and document catalogue and the file-address route.
  static const String featureDocuments = 'documents';

  /// Staged bytes, and the upload's `documents` and `documentLinks` sections.
  static const String featureDocumentUpload = 'documentUpload';

  /// The trips stream, and the upload's `tripRecordings` and `tripPoints`
  /// sections.
  static const String featureTrips = 'trips';

  /// The reviews stream, and the `held` row status for a device that opts in.
  static const String featureReviews = 'reviews';

  /// The rasters stream, and the upload's `rasterMaps` and `rasterPins`
  /// sections.
  static const String featureRasters = 'rasters';

  /// The people directory and the upload's `people` section. An installation
  /// can switch it off, and it is named only to an account that may be told
  /// who people are.
  static const String featurePeople = 'people';

  // ----- client features -----

  /// The device understands the row status `held`: an account whose uploads
  /// wait for a reviewer has its rows kept as proposals rather than written.
  static const String clientFeatureHeld = 'held';

  /// Sent on every upload. A name goes in only from the build that handles
  /// what it unlocks: a build that listed `held` and recorded a held row as
  /// written would believe an unreviewed edit had landed.
  static const List<String> clientFeatures = <String>[clientFeatureHeld];
}
