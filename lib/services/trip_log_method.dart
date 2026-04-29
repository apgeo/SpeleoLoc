/// Selectable trip log generation methods.
///
/// The active method is persisted in `configurations` under the key
/// [ConfigKey.tripLogMethod] (see `current_user_service.dart`). The
/// rendered output for a trip is produced by `TripLogRenderer` and is the
/// only writer of `cave_trips.log` going forward.
enum TripLogMethod {
  /// Verbatim terse lines: `[yyyy/MM/dd HH:mm:ss] <message>` using the
  /// existing `trip_log_*` i18n keys. Retained for back-compat.
  raw('raw', 'trip_log_method_raw'),

  /// Full-sentence phrasing of every event, one entry per line. Same line
  /// timestamp prefix as [raw], but uses new `trip_log_classic_*` keys.
  classic('classic', 'trip_log_method_classic'),

  /// Field-journal style: `[HH:mm · +Δ] sentence` with elapsed time from
  /// trip start and sequence-aware phrasing (first stop vs. next stops).
  journal('journal', 'trip_log_method_journal'),

  /// Narrative paragraphs grouping consecutive movements, summarizing
  /// pauses, and producing prose suitable for ODT/DOCX export.
  narrative('narrative', 'trip_log_method_narrative');

  const TripLogMethod(this.id, this.i18nKey);

  /// Stable string stored in `configurations.value`. Do not change.
  final String id;

  /// i18n key for the user-facing display name of this method.
  final String i18nKey;

  /// Parses a stored id into a [TripLogMethod]. Returns [fallback] (which
  /// itself defaults to [TripLogMethod.classic]) when [id] is null or
  /// unrecognized.
  static TripLogMethod fromId(String? id,
      {TripLogMethod fallback = TripLogMethod.classic}) {
    if (id == null) return fallback;
    for (final m in TripLogMethod.values) {
      if (m.id == id) return m;
    }
    return fallback;
  }
}
