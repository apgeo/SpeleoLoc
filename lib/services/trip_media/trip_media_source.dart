import 'dart:io';
import 'dart:typed_data';

import 'package:speleoloc/services/trip_media/trip_media_item.dart';

/// Where the trip-media import gets its candidate photos and videos.
///
/// Two implementations exist because the device may not grant the same
/// thing twice: the whole library can be enumerated and date-filtered when
/// the user allows it, and the system picker is what remains usable when
/// they do not. The screen is written against this interface so the
/// difference stays out of it.
abstract class TripMediaSource {
  /// Stable identifier for logs and for telling the user which path they
  /// are on.
  String get id;

  /// Whether the items are ones the user picks in a system picker and adds
  /// to with [chooseMore], rather than whatever the library holds.
  bool get choosesItems;

  /// Asks the user to pick more items, keeping those picked before, and
  /// returns how many were added. A cancelled picker adds nothing and loses
  /// nothing. Returns 0 at once for a source that does not choose.
  ///
  /// Separate from [list] so that reloading — after a change of date range,
  /// say — never re-opens a picker, and never empties the list because the
  /// user dismissed one.
  Future<int> chooseMore();

  /// The candidate items in the order they were taken, restricted to
  /// [from]..[to] by capture time when this source [supportsDateRange].
  ///
  /// Oldest first because the list is a trip being reconstructed: the
  /// caver reads down it in the order they moved through the cave.
  ///
  /// Never prompts: a source that [choosesItems] returns what has been
  /// picked so far, filtered the same way.
  Future<List<TripMediaItem>> list({DateTime? from, DateTime? to});

  /// Encoded bytes for a grid thumbnail of [item], or null when none can be
  /// produced. [edge] is the requested square edge in pixels.
  Future<Uint8List?> thumbnail(TripMediaItem item, {int edge = 200});

  /// The item's bytes on disk, which may be a temporary copy the platform
  /// made. Null when the file cannot be materialised.
  ///
  /// Only for what is actually being kept: on Android 10 and on iOS every
  /// call copies the original into the plugin's cache.
  Future<File?> file(TripMediaItem item);

  /// Runs [use] on a still good enough to look for a QR label in and
  /// returns its result — null for a video, or an item that cannot be read.
  ///
  /// The library hands over a reduced copy, not the original, deleted as
  /// soon as [use] returns. A sweep over a camera roll would otherwise
  /// duplicate the roll in the cache on the platforms where an original is
  /// itself a copy, and decode full-size frames to find a label that a
  /// fraction of the pixels show just as well.
  Future<R?> withScanImage<R>(
    TripMediaItem item,
    Future<R?> Function(File file) use,
  );

  /// A key for this one version of this picture, stable across visits to
  /// the screen, under which what reading it found is remembered. Null when
  /// the source cannot tell one picture from another.
  ///
  /// Not a hash of the file: hashing means reading every picture in full,
  /// and on Android 10 and iOS the plugin first copies each original to do
  /// so — the cost the reduced scan images exist to avoid.
  Future<String?> scanKey(TripMediaItem item);

  /// Frees whatever this source materialised. Call when the screen that
  /// owns it goes away, after any import has finished.
  Future<void> release();
}
