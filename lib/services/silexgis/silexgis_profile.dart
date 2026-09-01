import 'dart:convert';

/// A SilexGIS installation this device is configured to talk to.
///
/// **Its own configuration key, deliberately not a member of the FTP protocol
/// enum.** The FTP-profile *pattern* is the precedent — metadata in the local
/// database, the credential in the platform keystore — but joining the FTP
/// profile list would be a hazard rather than a tidiness: an older build
/// reading a profile whose protocol it does not recognise falls back to plain
/// FTP, and would then try to speak FTP to an HTTPS server, with the caver's
/// stored credential, on whatever host the profile names.
///
/// A server profile is exactly as optional as an FTP profile. Its absence
/// fails soft, and a build with none configured behaves the same as today's in
/// every respect a caver can observe.
class SilexgisProfile {
  const SilexgisProfile({
    required this.profileUuid,
    required this.displayName,
    required this.baseUrl,
    this.accountEmail = '',
    this.syncSetId,
    this.uploadsNewRoots = false,
  });

  /// Stable identifier, generated once when the profile is first created. It
  /// is the keystore lookup key for the refresh token, and the key this
  /// device's cursor and row revisions are stored under.
  final String profileUuid;

  /// Human-visible name — "Clubul Speo Example".
  final String displayName;

  /// The installation's base address. Its path prefix, if it has one, is kept:
  /// an installation may sit behind a reverse proxy under a subdirectory.
  final String baseUrl;

  /// The account last signed in as. Shown when the credential lapses and a
  /// password is needed again; **never a credential itself**.
  final String accountEmail;

  /// The sync set this device carries on that installation, once a caver has
  /// chosen one. Null until then, which is a configured-but-idle profile
  /// rather than an error.
  final String? syncSetId;

  /// Whether a cave this device surveyed somewhere the server knows nothing
  /// about may be sent as well.
  ///
  /// Off by default, and the default is the point: a caver who picked the
  /// club's caves to carry would not expect their own survey of an unrelated
  /// cave to be published because a profile happens to be configured. What
  /// travels by default is what the installation already holds, plus what the
  /// caver has since put inside it.
  ///
  /// Turning it on is what makes a genuinely new cave reachable at all. A sync
  /// set names roots, and a root has to exist on the server before it can be
  /// named — so without this a new cave can never get there, and adding it to
  /// the selection is impossible for the same reason.
  final bool uploadsNewRoots;

  Uri get baseUri => Uri.parse(baseUrl);

  bool get isReadyToSync => syncSetId != null && syncSetId!.isNotEmpty;

  SilexgisProfile copyWith({
    String? displayName,
    String? baseUrl,
    String? accountEmail,
    String? syncSetId,
    bool clearSyncSet = false,
    bool? uploadsNewRoots,
  }) => SilexgisProfile(
    profileUuid: profileUuid,
    displayName: displayName ?? this.displayName,
    baseUrl: baseUrl ?? this.baseUrl,
    accountEmail: accountEmail ?? this.accountEmail,
    syncSetId: clearSyncSet ? null : (syncSetId ?? this.syncSetId),
    uploadsNewRoots: uploadsNewRoots ?? this.uploadsNewRoots,
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'profileUuid': profileUuid,
    'displayName': displayName,
    'baseUrl': baseUrl,
    'accountEmail': accountEmail,
    'syncSetId': syncSetId,
    'uploadsNewRoots': uploadsNewRoots,
  };

  static SilexgisProfile fromJson(Map<String, Object?> json) => SilexgisProfile(
    profileUuid: json['profileUuid']! as String,
    displayName: json['displayName'] as String? ?? '',
    baseUrl: json['baseUrl'] as String? ?? '',
    accountEmail: json['accountEmail'] as String? ?? '',
    syncSetId: json['syncSetId'] as String?,
    uploadsNewRoots: json['uploadsNewRoots'] as bool? ?? false,
  );

  String encode() => jsonEncode(toJson());

  static SilexgisProfile decode(String raw) =>
      fromJson(jsonDecode(raw) as Map<String, Object?>);
}
