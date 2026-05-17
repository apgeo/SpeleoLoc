/// Decision for a single overwrite prompt.
enum OverwriteDecision {
  /// Replace the existing value with the newly-computed one.
  replace,

  /// Keep the existing value (skip this field for this place).
  keep,

  /// Replace this and every subsequent non-empty existing value of
  /// the same field type without prompting.
  replaceAll,

  /// Keep this and every subsequent non-empty existing value of the
  /// same field type without prompting.
  keepAll,

  /// Cancel the batch entirely.
  cancelBatch,
}

/// The two field types that can prompt overwrite decisions.
///
/// Decisions are tracked independently — accepting "replace all PCIs"
/// does *not* implicitly accept "replace all QCRIs".
enum OverwriteField { pci, qcri }

/// Outcome of consulting the policy for a single (field, place).
enum OverwriteAction {
  /// Caller should write the new value.
  write,

  /// Caller should keep the existing value and move on.
  skip,

  /// Caller should stop the entire batch.
  cancel,

  /// Caller should display the prompt for this place + field and
  /// re-call [PlaceCodeOverwritePolicy.recordDecision] with the
  /// user's answer.
  prompt,
}

/// State machine implementing the §5.4 overwrite-prompt semantics.
///
/// The policy keeps per-field "blanket" decisions (replaceAll /
/// keepAll) and applies them automatically on subsequent encounters.
/// Empty/null existing values are always written without prompting.
/// New values that equal the existing value are silently skipped.
///
/// This class is intentionally synchronous and pure: it never touches
/// the database or the UI. The batch runner owns the prompting and
/// persistence; the policy only decides "should we prompt?".
class PlaceCodeOverwritePolicy {
  // Field-scoped blanket decisions.
  final Map<OverwriteField, OverwriteDecision> _blanket = {};
  // Latched cancellation.
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  /// Look up what to do for [field] on a place whose existing value
  /// is [existing] and newly-computed value is [computed].
  OverwriteAction decide({
    required OverwriteField field,
    required String? existing,
    required String computed,
  }) {
    if (_cancelled) return OverwriteAction.cancel;
    final hasExisting = existing != null && existing.isNotEmpty;
    if (!hasExisting) return OverwriteAction.write;
    if (existing == computed) return OverwriteAction.skip;
    final blanket = _blanket[field];
    if (blanket == OverwriteDecision.replaceAll) return OverwriteAction.write;
    if (blanket == OverwriteDecision.keepAll) return OverwriteAction.skip;
    return OverwriteAction.prompt;
  }

  /// Record the user's decision for a prompt that was raised for
  /// [field]. Returns the immediate action the caller should take for
  /// the current place.
  OverwriteAction recordDecision({
    required OverwriteField field,
    required OverwriteDecision decision,
  }) {
    switch (decision) {
      case OverwriteDecision.replace:
        return OverwriteAction.write;
      case OverwriteDecision.keep:
        return OverwriteAction.skip;
      case OverwriteDecision.replaceAll:
        _blanket[field] = OverwriteDecision.replaceAll;
        return OverwriteAction.write;
      case OverwriteDecision.keepAll:
        _blanket[field] = OverwriteDecision.keepAll;
        return OverwriteAction.skip;
      case OverwriteDecision.cancelBatch:
        _cancelled = true;
        return OverwriteAction.cancel;
    }
  }
}
