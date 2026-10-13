import 'package:speleoloc/data/source/database/app_database.dart';

/// What has been decided about one offered photo or video: the place it was
/// taken at and the moment to record, plus whether it takes part in the
/// import.
///
/// Absent from the map entirely until something decides a place for the
/// item, so "undecided" needs no flag of its own.
class TripMediaAssignment {
  const TripMediaAssignment({
    required this.place,
    required this.at,
    this.fromQrCode = false,
    this.selected = true,
  });

  final CavePlace place;

  /// The time to record, which starts as the item's capture time and can be
  /// corrected by hand.
  final DateTime at;

  /// True when the place was read off a QR label in the picture rather than
  /// chosen by hand. Shown so the user can tell an automatic guess from
  /// their own decision before committing it.
  final bool fromQrCode;

  final bool selected;

  TripMediaAssignment copyWith({
    CavePlace? place,
    DateTime? at,
    bool? fromQrCode,
    bool? selected,
  }) {
    return TripMediaAssignment(
      place: place ?? this.place,
      at: at ?? this.at,
      fromQrCode: fromQrCode ?? this.fromQrCode,
      selected: selected ?? this.selected,
    );
  }
}
