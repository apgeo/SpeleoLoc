/// The upload limits an installation applies, and the room this account has
/// left. Read before a transfer opens, so a file that cannot fit is not
/// started.
class SilexgisFilesConfig {
  const SilexgisFilesConfig({
    required this.maxUploadBytes,
    required this.chunkBytes,
    this.remainingBytes,
  });

  /// The largest file the installation accepts.
  final int maxUploadBytes;

  /// The piece size the installation asks for.
  final int chunkBytes;

  /// Room left for this account, or null when nothing limits it. Staged bytes
  /// already count against it, from the moment their transfer opens.
  final int? remainingBytes;

  static SilexgisFilesConfig fromJson(Map<String, Object?> json) =>
      SilexgisFilesConfig(
        maxUploadBytes: (json['maxUploadBytes'] as num?)?.toInt() ?? 0,
        chunkBytes: (json['chunkBytes'] as num?)?.toInt() ?? 0,
        remainingBytes: (json['remainingBytes'] as num?)?.toInt(),
      );
}

/// How far a resumable transfer has got.
class SilexgisTransfer {
  const SilexgisTransfer({
    required this.id,
    required this.receivedBytes,
    required this.chunkBytes,
    this.expiresAt,
    this.stagedForSync = false,
    this.stagedAt,
    this.sha256,
  });

  final String id;

  /// The offset to send from. Read back from the stored bytes on the server,
  /// so it never describes bytes that did not survive.
  final int receivedBytes;
  final int chunkBytes;

  /// While bytes still arrive, when the transfer stops being resumable; once
  /// staged, when the bytes go if no upload has adopted them.
  final String? expiresAt;
  final bool stagedForSync;

  /// Absent while the bytes are still arriving.
  final String? stagedAt;

  /// The server's hash of staged bytes.
  final String? sha256;

  bool get isStaged => stagedAt != null;

  static SilexgisTransfer fromJson(Map<String, Object?> json) =>
      SilexgisTransfer(
        id: json['id']! as String,
        receivedBytes: (json['receivedBytes'] as num?)?.toInt() ?? 0,
        chunkBytes: (json['chunkBytes'] as num?)?.toInt() ?? 0,
        expiresAt: json['expiresAt'] as String?,
        stagedForSync: json['stagedForSync'] as bool? ?? false,
        stagedAt: json['stagedAt'] as String?,
        sha256: json['sha256'] as String?,
      );
}

/// Bytes completed and described, waiting for a document row to adopt them.
///
/// Completing makes no document: the server hashes the bytes and types them
/// by their content, and keeps them under the transfer's id until an upload
/// names it as `stagedUploadId` or the staging retention runs out.
class SilexgisStagedBytes {
  const SilexgisStagedBytes({
    required this.id,
    required this.sizeBytes,
    required this.sha256,
    this.mimeType,
    this.expiresAt,
  });

  final String id;
  final int sizeBytes;

  /// Lower-case hex. The row must state the same hash.
  final String sha256;
  final String? mimeType;
  final String? expiresAt;

  static SilexgisStagedBytes fromJson(Map<String, Object?> json) =>
      SilexgisStagedBytes(
        id: json['id']! as String,
        sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
        sha256: (json['sha256'] as String? ?? '').toLowerCase(),
        mimeType: json['mimeType'] as String?,
        expiresAt: json['expiresAt'] as String?,
      );
}
