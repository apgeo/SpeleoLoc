import 'dart:convert';

/// The SSH host key an SFTP profile trusts, recorded on its first connection.
///
/// [host] and [port] say which address presented the key. Identity is the key
/// itself: a later connection is trusted when its [fingerprint] matches,
/// whatever address the profile points at by then.
class SftpHostKey {
  final String host;
  final int port;

  /// Host-key algorithm negotiated for the connection, e.g. `ssh-ed25519` or
  /// `rsa-sha2-512`. Shown to users only: one RSA key can be negotiated under
  /// different algorithm names, so trust compares [fingerprint] alone.
  final String keyType;

  /// OpenSSH-style `SHA256:<base64>` fingerprint, the same text
  /// `ssh-keygen -lf` prints on the server, so users can compare the two.
  final String fingerprint;

  final DateTime recordedAt;

  const SftpHostKey({
    required this.host,
    required this.port,
    required this.keyType,
    required this.fingerprint,
    required this.recordedAt,
  });

  String get endpoint => '$host:$port';

  /// `<type> <fingerprint>`, the form shown to users and written to the log.
  String get display => '$keyType $fingerprint';

  /// The fingerprint hashes the whole public key blob, key type included.
  bool sameKeyAs(SftpHostKey other) => fingerprint == other.fingerprint;

  Map<String, Object?> toJson() => {
    'host': host,
    'port': port,
    'keyType': keyType,
    'fingerprint': fingerprint,
    'recordedAt': recordedAt.toUtc().toIso8601String(),
  };

  static SftpHostKey fromJson(Map<String, Object?> json) => SftpHostKey(
    host: json['host'] as String,
    port: json['port'] as int,
    keyType: json['keyType'] as String,
    fingerprint: json['fingerprint'] as String,
    recordedAt: DateTime.parse(json['recordedAt'] as String),
  );

  String encode() => jsonEncode(toJson());

  static SftpHostKey decode(String raw) =>
      fromJson(jsonDecode(raw) as Map<String, Object?>);
}
