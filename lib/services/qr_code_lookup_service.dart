import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';

/// Result of a QR code lookup: the matching cave place and its parent cave title.
class QrLookupResult {
  final CavePlace cavePlace;
  final String caveTitle;

  const QrLookupResult({required this.cavePlace, required this.caveTitle});
}

/// Searches all cave places by QR code identifier.
///
/// When [currentCaveId] is provided, restricts the search to that cave.
/// Otherwise searches across all caves in the database.
class QrCodeLookupService {
  final AppDatabase _db;

  QrCodeLookupService(this._db);

  /// Looks up cave places whose PCI or QCRI equals [rawCode].
  ///
  /// Returns an empty list when [rawCode] is empty after trimming.
  Future<List<QrLookupResult>> lookup(String rawCode, {Uuid? currentCaveId}) async {
    final code = rawCode.trim();
    if (code.isEmpty) return [];

    List<CavePlace> places;
    if (currentCaveId != null) {
      places = await (_db.select(_db.cavePlaces)
            ..where((cp) =>
                (cp.placeCodeIdentifier.equals(code) |
                        cp.qrCodeResourceIdentifier.equals(code)) &
                cp.caveUuid.equalsValue(currentCaveId)))
          .get();
    } else {
      places = await (_db.select(_db.cavePlaces)
            ..where((cp) =>
                cp.placeCodeIdentifier.equals(code) |
                cp.qrCodeResourceIdentifier.equals(code)))
          .get();
    }

    if (places.isEmpty) return [];

    // Fetch cave titles for all matching places
    final caveIds = places.map((p) => p.caveUuid).toSet();
    final caves = await (_db.select(_db.caves)
          ..where((c) => c.uuid.isInValues(caveIds)))
        .get();
    final caveTitles = {for (final c in caves) c.uuid: c.title};

    return places
        .map((p) => QrLookupResult(
              cavePlace: p,
              caveTitle: caveTitles[p.caveUuid] ?? '',
            ))
        .toList();
  }
}
