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

  /// True when [list] honours its date range itself. The picker cannot —
  /// the user chooses before any filter is known — so the screen offers its
  /// own filtering instead of pretending the range was applied.
  bool get supportsDateRange;

  /// The candidate items, newest first, restricted to [from]..[to] when
  /// this source [supportsDateRange].
  ///
  /// A source that needs the user to choose (the system picker) prompts on
  /// each call and returns what they selected; one that reads the library
  /// returns everything it can see.
  Future<List<TripMediaItem>> list({DateTime? from, DateTime? to});

  /// Encoded bytes for a grid thumbnail of [item], or null when none can be
  /// produced. [edge] is the requested square edge in pixels.
  Future<Uint8List?> thumbnail(TripMediaItem item, {int edge = 200});

  /// The item's bytes on disk, which may be a temporary copy the platform
  /// made. Null when the file cannot be materialised.
  Future<File?> file(TripMediaItem item);
}
