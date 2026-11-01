import 'package:speleoloc/data/source/database/app_database.dart';

/// The cave place this device was last found at — by a scanned QR label or
/// a detected beacon — and when. Kept in memory only: it answers "where am
/// I now", and an old answer is no answer.
class LastLocatedPlace {
  LastLocatedPlace({DateTime Function()? now}) : _now = now ?? DateTime.now;

  final DateTime Function() _now;
  Uuid? _place;
  DateTime? _at;

  /// How long a fix stands for "you are here".
  static const freshFor = Duration(minutes: 30);

  void record(Uuid cavePlaceUuid) {
    _place = cavePlaceUuid;
    _at = _now();
  }

  /// The place, while the fix is fresh.
  Uuid? get current {
    final at = _at;
    if (at == null || _now().difference(at) > freshFor) return null;
    return _place;
  }
}
