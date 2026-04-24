import 'dart:convert';

/// Wire protocol for remote archive exchange.
enum FtpProtocol {
  /// Plain FTP (insecure, port 21 by default).
  ftp,

  /// FTP over TLS implicit (port 990) or explicit (FTPES, port 21).
  /// Implementation uses FTPES by default when [ftps] is selected.
  ftps,

  /// SFTP over SSH (port 22 by default).
  sftp,
}

/// User-configured remote sync endpoint.
///
/// Does **not** carry the password — that lives in a platform keystore via
/// `FtpCredentialStore` and is looked up by [profileUuid]. Keeping credentials
/// out of the main configurations row means a plaintext DB export does not
/// leak passwords.
class FtpProfile {
  /// Stable identifier used as the keystore lookup key. Generated once when
  /// the profile is first created.
  final String profileUuid;

  /// Human-visible name ("Team NAS", "HQ SFTP", …).
  final String displayName;

  final FtpProtocol protocol;
  final String host;

  /// When null, the protocol's default port is used (21/990/22).
  final int? port;

  final String username;

  /// Remote directory where archives are listed/uploaded/downloaded.
  /// Example: `/speleo_loc/sync/` — the filename schema described in the
  /// sync-v2 dev log is applied within this folder.
  final String remoteFolder;

  /// Whether to treat self-signed TLS certs as valid (FTPS only). Keep off by
  /// default; turning on is a per-profile opt-in for lab environments.
  final bool allowInvalidCertificate;

  /// FTP passive mode (data channel initiated by client). Generally required
  /// behind NAT. No effect for SFTP.
  final bool passiveMode;

  const FtpProfile({
    required this.profileUuid,
    required this.displayName,
    required this.protocol,
    required this.host,
    required this.port,
    required this.username,
    required this.remoteFolder,
    this.allowInvalidCertificate = false,
    this.passiveMode = true,
  });

  /// Default port for this profile's protocol.
  int get effectivePort {
    if (port != null) return port!;
    switch (protocol) {
      case FtpProtocol.ftp:
        return 21;
      case FtpProtocol.ftps:
        return 21; // FTPES (explicit TLS) — most compatible default.
      case FtpProtocol.sftp:
        return 22;
    }
  }

  FtpProfile copyWith({
    String? displayName,
    FtpProtocol? protocol,
    String? host,
    int? port,
    bool clearPort = false,
    String? username,
    String? remoteFolder,
    bool? allowInvalidCertificate,
    bool? passiveMode,
  }) {
    return FtpProfile(
      profileUuid: profileUuid,
      displayName: displayName ?? this.displayName,
      protocol: protocol ?? this.protocol,
      host: host ?? this.host,
      port: clearPort ? null : (port ?? this.port),
      username: username ?? this.username,
      remoteFolder: remoteFolder ?? this.remoteFolder,
      allowInvalidCertificate:
          allowInvalidCertificate ?? this.allowInvalidCertificate,
      passiveMode: passiveMode ?? this.passiveMode,
    );
  }

  Map<String, Object?> toJson() => {
        'profileUuid': profileUuid,
        'displayName': displayName,
        'protocol': protocol.name,
        'host': host,
        'port': port,
        'username': username,
        'remoteFolder': remoteFolder,
        'allowInvalidCertificate': allowInvalidCertificate,
        'passiveMode': passiveMode,
      };

  static FtpProfile fromJson(Map<String, Object?> json) {
    final protoName = (json['protocol'] as String?) ?? 'ftp';
    return FtpProfile(
      profileUuid: json['profileUuid'] as String,
      displayName: json['displayName'] as String? ?? '',
      protocol: FtpProtocol.values.firstWhere(
        (p) => p.name == protoName,
        orElse: () => FtpProtocol.ftp,
      ),
      host: json['host'] as String? ?? '',
      port: json['port'] as int?,
      username: json['username'] as String? ?? '',
      remoteFolder: json['remoteFolder'] as String? ?? '/',
      allowInvalidCertificate:
          json['allowInvalidCertificate'] as bool? ?? false,
      passiveMode: json['passiveMode'] as bool? ?? true,
    );
  }

  String encode() => jsonEncode(toJson());

  static FtpProfile decode(String raw) =>
      fromJson(jsonDecode(raw) as Map<String, Object?>);
}
