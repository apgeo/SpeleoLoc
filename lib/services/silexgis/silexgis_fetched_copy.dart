import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_fetcher.dart';

/// What a file fetched from an address is, and whether it is what was
/// described.
abstract final class SilexgisFetchedCopy {
  /// What the fetched bytes are. Numbers on the address mark the rewritten
  /// copy whatever the catalogue said: the reach is decided again on every
  /// request. [document] is the catalogue's description, when there is one.
  static SilexgisHeldAs heldAs(
    SilexgisDocumentData? document,
    SyncFileLink link,
  ) {
    if (!link.rendition.isOriginal) return SilexgisHeldAs.rendition;
    if (link.sha256 != null || link.sizeBytes != null) {
      return SilexgisHeldAs.locationFree;
    }
    return SyncDocumentReach.parse(document?.reach) ==
            SyncDocumentReach.locationFree
        ? SilexgisHeldAs.locationFree
        : SilexgisHeldAs.original;
  }

  /// Why what arrived is not what was described, or null when it is.
  static String? mismatch(
    SilexgisDocumentData? document,
    SyncFileLink link,
    SilexgisHeldAs heldAs,
    SilexgisFetchedFile fetched,
  ) {
    String? sha;
    int? size;
    switch (heldAs) {
      case SilexgisHeldAs.original:
        sha = document?.sha256;
        size = document?.sizeBytes;
      case SilexgisHeldAs.locationFree:
        sha = link.sha256;
        size = link.sizeBytes;
      case SilexgisHeldAs.rendition:
      case SilexgisHeldAs.own:
        break;
    }
    // With no numbers to go by, the response's own length is all there is.
    size ??= sha == null ? fetched.announcedLength : null;
    if (sha != null && sha.toLowerCase() != fetched.sha256) {
      return 'the file does not match its fingerprint';
    }
    if (size != null && size != fetched.length) {
      return 'the file is ${fetched.length} bytes, not $size';
    }
    return null;
  }
}
