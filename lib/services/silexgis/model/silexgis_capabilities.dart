import 'package:speleoloc/services/silexgis/silexgis_contract.dart';

/// What a server can do, asked once per server and kept.
///
/// It is also the cheapest place to discover that a stored credential has
/// lapsed: it answers `401` like every other route in this slice.
class SilexgisCapabilities {
  const SilexgisCapabilities({
    required this.contractVersion,
    required this.pageSizeMax,
    required this.uploadRowsMax,
    required this.features,
  });

  /// The protocol generation this build of the server speaks. A statement
  /// about its code, not a setting an installation may lower.
  final int contractVersion;

  /// Ceilings this installation is configured to allow. Asking for more is not
  /// an error — the server clamps — but a device that asks blind cannot tell
  /// how much it actually got without counting, so size to these rather than
  /// compiling numbers in.
  final int pageSizeMax;
  final int uploadRowsMax;

  /// The optional halves of the contract this build actually serves. It is how
  /// a device meets a server that has shipped some of the protocol and not the
  /// rest, and takes what is there.
  final List<String> features;

  bool get servesDownload =>
      features.contains(SilexgisContract.featureDownload);
  bool get servesUpload => features.contains(SilexgisContract.featureUpload);

  /// True when this build's pinned version and the server's agree. A mismatch
  /// is refused rather than interpreted generously, so it is worth answering
  /// before an upload is composed rather than after it is refused whole.
  bool get speaksOurContract => contractVersion == SilexgisContract.version;

  static SilexgisCapabilities fromJson(Map<String, Object?> json) =>
      SilexgisCapabilities(
        contractVersion: (json['contractVersion'] as num?)?.toInt() ?? 0,
        pageSizeMax: (json['pageSizeMax'] as num?)?.toInt() ?? 0,
        uploadRowsMax: (json['uploadRowsMax'] as num?)?.toInt() ?? 0,
        features: (json['features'] as List? ?? const <Object?>[])
            .whereType<String>()
            .toList(growable: false),
      );
}
