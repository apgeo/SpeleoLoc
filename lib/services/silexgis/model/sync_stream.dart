/// The paged streams of a sync set beside the feature download.
///
/// Each is read the way the feature download is read, on a cursor of its own:
/// a position one stream issued is refused `sync.cursor_invalid` by every
/// other, so a device keeps one cursor per stream and drops only the one
/// refused.
enum SyncStream {
  documents('documents'),
  trips('trips'),
  rasters('rasters'),
  reviews('reviews');

  const SyncStream(this.routeName);

  /// The last segment of the stream's route, which is also the key its cursor
  /// is stored under.
  final String routeName;
}

/// What every paged read answers with, whatever else its page carries.
abstract interface class SyncStreamPage {
  /// The set's revision as of this page. A move retires every cursor issued
  /// before it.
  int get setRevision;

  /// The position to resume from, opaque. Present whenever the page carried
  /// anything.
  String? get nextCursor;

  /// False means level with the server as of this read: stop looping now.
  bool get hasMore;
}
