/// Whether an offered item is a still or a moving picture. Only stills can
/// be scanned for a QR label — pulling a frame out of a video would need a
/// decoder this app does not ship.
enum TripMediaKind { photo, video }

/// Where a [TripMediaItem.capturedAt] value came from.
///
/// Surfaced in the UI because the three are not equally trustworthy: the
/// library's own date is the capture moment, EXIF is the camera's own record
/// of it, and a filesystem timestamp is frequently the moment the file was
/// copied rather than taken.
enum MediaTimeSource { library, exif, fileModified }

/// One photo or video offered to the trip-media import, independent of which
/// [TripMediaSource] produced it.
class TripMediaItem {
  const TripMediaItem({
    required this.id,
    required this.kind,
    required this.capturedAt,
    required this.capturedAtSource,
    this.displayName,
  });

  /// Opaque, source-specific handle: a MediaStore / PHAsset id for the
  /// device library, an absolute path for picked files.
  final String id;

  final TripMediaKind kind;
  final DateTime capturedAt;
  final MediaTimeSource capturedAtSource;

  /// File name or album title, when the source knows one.
  final String? displayName;

  bool get isPhoto => kind == TripMediaKind.photo;
}
