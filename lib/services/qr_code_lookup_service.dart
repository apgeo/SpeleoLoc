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

  /// Parses [rawCode] as an integer QR identifier and returns matching cave places.
  ///
  /// Returns an empty list if [rawCode] is not a valid integer.
  Future<List<QrLookupResult>> lookup(String rawCode, {int? currentCaveId}) async {
    final qrCode = int.tryParse(rawCode);
    if (qrCode == null) return [];

    List<CavePlace> places;
    if (currentCaveId != null) {
      places = await (_db.select(_db.cavePlaces)
            ..where((cp) =>
                cp.placeQrCodeIdentifier.equals(qrCode) &
                cp.caveId.equals(currentCaveId)))
          .get();
    } else {
      places = await (_db.select(_db.cavePlaces)
            ..where((cp) => cp.placeQrCodeIdentifier.equals(qrCode)))
          .get();
    }

    if (places.isEmpty) return [];

    // Fetch cave titles for all matching places
    final caveIds = places.map((p) => p.caveId).toSet();
    final caves = await (_db.select(_db.caves)
          ..where((c) => c.id.isIn(caveIds)))
        .get();
    final caveTitles = {for (final c in caves) c.id: c.title};

    return places
        .map((p) => QrLookupResult(
              cavePlace: p,
              caveTitle: caveTitles[p.caveId] ?? '',
            ))
        .toList();
  }
}
