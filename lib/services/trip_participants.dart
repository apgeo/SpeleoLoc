/// A trip's participants, stored as the user types them: names separated by
/// commas.
///
/// Kept as one text field rather than a table of people: participants are
/// whoever went that day, often guests with no user account, and a list a
/// caver can type in one go is what the field is for.
class TripParticipants {
  const TripParticipants._();

  /// The names in [raw], trimmed, blanks dropped, and each name kept once —
  /// the first spelling wins when two differ only in case.
  static List<String> parse(String? raw) {
    if (raw == null) return const [];
    final seen = <String>{};
    return [
      for (final part in raw.split(','))
        if (part.trim().isNotEmpty && seen.add(part.trim().toLowerCase()))
          part.trim(),
    ];
  }

  /// [names] as stored: comma-separated, or null when there are none.
  static String? format(Iterable<String> names) {
    final clean = parse(names.join(','));
    return clean.isEmpty ? null : clean.join(', ');
  }

  /// [raw] with [name] appended, unless it is already there.
  static String add(String? raw, String name) =>
      format([...parse(raw), name]) ?? '';
}
