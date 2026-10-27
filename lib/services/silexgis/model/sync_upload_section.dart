/// One array of an upload, named as it travels.
///
/// **Declared in the server's apply order**, which is fixed whatever order the
/// arrays sit in a request: a later section may name what an earlier one
/// created, so this order is also the order items are chunked in, and a
/// dependent item never lands in an earlier batch than the item it depends on.
///
/// Each section is used only while the capabilities answer names the part it
/// belongs to.
enum SyncUploadSection {
  rows('rows'),
  people('people'),
  documents('documents'),
  rasterMaps('rasterMaps'),
  tripRecordings('tripRecordings'),
  tripPoints('tripPoints'),
  documentLinks('documentLinks'),
  rasterPins('rasterPins');

  const SyncUploadSection(this.wireName);
  final String wireName;
}

/// One item of any section, as it goes on the wire.
abstract interface class SyncUploadItem {
  Map<String, Object?> toJson();
}

/// Splits [items] into parts of at most [max] items each, counted across every
/// section together, and taken in [SyncUploadSection] order.
///
/// A part keeps only the sections it carries something for. A [max] of zero
/// or less means no ceiling was announced, and everything goes in one part.
List<Map<SyncUploadSection, List<T>>> chunkUploadSections<T>(
  Map<SyncUploadSection, List<T>> items,
  int max,
) {
  final chunks = <Map<SyncUploadSection, List<T>>>[];
  var current = <SyncUploadSection, List<T>>{};
  var count = 0;
  for (final section in SyncUploadSection.values) {
    for (final item in items[section] ?? List<T>.empty()) {
      if (max > 0 && count == max) {
        chunks.add(current);
        current = <SyncUploadSection, List<T>>{};
        count = 0;
      }
      (current[section] ??= <T>[]).add(item);
      count++;
    }
  }
  if (count > 0) chunks.add(current);
  return chunks;
}
