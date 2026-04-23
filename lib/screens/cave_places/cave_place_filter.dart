import 'package:speleoloc/data/source/database/app_database.dart';

/// Pure, stateless filter for cave places used by [CavePlacesListPage].
///
/// Matches the query string (case-insensitive, trimmed) against:
///   * the place title
///   * the place QR-code identifier (as string)
///   * the title of the cave-area the place belongs to (via [areaTitles])
///
/// An empty query returns a copy of the input list.
List<CavePlace> filterCavePlaces(
  List<CavePlace> places,
  String query,
  Map<Uuid, String> areaTitles,
) {
  final q = query.trim();
  if (q.isEmpty) return List.of(places);

  final qLower = q.toLowerCase();
  return places.where((cp) {
    final titleMatch = cp.title.toLowerCase().contains(qLower);
    final qrMatch =
        cp.placeQrCodeIdentifier?.toString().contains(qLower) ?? false;
    final areaTitle = (cp.caveAreaUuid != null)
        ? (areaTitles[cp.caveAreaUuid] ?? '')
        : '';
    final areaMatch = areaTitle.toLowerCase().contains(qLower);
    return titleMatch || qrMatch || areaMatch;
  }).toList();
}
