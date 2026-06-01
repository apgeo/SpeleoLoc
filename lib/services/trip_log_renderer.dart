import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/trip_log_method.dart';
import 'package:speleoloc/utils/localization.dart';

/// Kind of a single event in the rendered trip log.
enum TripLogEventKind {
  start,
  restart,
  point,
  documentAdded,
  end,
}

/// One event consumed by [TripLogRenderer]. Loaded from structured DB
/// records (cave_trips, cave_trip_points, document links). Plain data
/// class — all fields immutable.
class TripLogEvent {
  TripLogEvent({
    required this.kind,
    required this.at,
    this.title,
    this.label,
    this.notes,
  });

  final TripLogEventKind kind;
  final DateTime at;

  /// Trip title (only set on [TripLogEventKind.start] / restart events).
  final String? title;

  /// Place title (point) or document title (documentAdded).
  final String? label;

  /// Per-point notes (only set on [TripLogEventKind.point]).
  final String? notes;
}

/// Renders the full trip log text from structured records, in one of the
/// four [TripLogMethod] styles. The output of [render] is the only thing
/// written to `cave_trips.log` once the live regeneration in
/// `CaveTripService` is wired up.
class TripLogRenderer {
  TripLogRenderer(this._db);

  /// Singleton backed by the global [appDatabase]. Prefer passing a
  /// [TripLogRenderer] constructed with an injected [AppDatabase] in
  /// contexts where one is available (e.g. [CaveTripService]).
  static TripLogRenderer get instance => TripLogRenderer(appDatabase);

  final AppDatabase _db;

  static final _absFmt = DateFormat('yyyy/MM/dd HH:mm:ss');
  static final _shortTimeFmt = DateFormat('HH:mm');
  static final _dateLongFmt = DateFormat('d MMMM yyyy');

  /// Loads all structured events for [tripUuid] and returns them in
  /// chronological order. The list always begins with a [start] (or a
  /// [restart] preceded by the events from the previous run, see below).
  ///
  /// Restart handling: if any point/pause/document predates
  /// `trip.tripStartedAt`, the renderer emits a synthetic [start] at the
  /// earliest event time, then the events of the previous run, then a
  /// [restart] at `trip.tripStartedAt`, then the rest.
  Future<List<TripLogEvent>> loadEvents(Uuid tripUuid) async {
    final trip = await (_db.select(_db.caveTrips)
          ..where((t) => t.uuid.equalsValue(tripUuid)))
        .getSingleOrNull();
    if (trip == null) return const [];

    final points = await _db.getTripPoints(tripUuid);

    // Document links (created_at + doc title).
    final docRows = await _db.customSelect(
      'SELECT df.title AS title, dl.created_at AS created_at '
      'FROM documentation_files_to_cave_trips dl '
      'JOIN documentation_files df ON df.uuid = dl.documentation_file_uuid '
      'WHERE dl.cave_trip_uuid = ? AND dl.deleted_at IS NULL '
      'ORDER BY dl.created_at',
      variables: [Variable<Uint8List>(tripUuid.bytes)],
    ).get();

    // Place title cache for points.
    final placeUuids = points
        .map((p) => p.cavePlaceUuid)
        .whereType<Uuid>()
        .toSet()
        .toList();
    final placeTitles = <String, String>{};
    if (placeUuids.isNotEmpty) {
      final places = await (_db.select(_db.cavePlaces)
            ..where((c) => c.uuid.isIn(
                placeUuids.map((u) => u.bytes).toList())))
          .get();
      for (final p in places) {
        placeTitles[p.uuid.toString()] = p.title;
      }
    }

    final events = <TripLogEvent>[];

    DateTime ms(int v) => DateTime.fromMillisecondsSinceEpoch(v);

    for (final p in points) {
      final title = p.cavePlaceUuid != null
          ? placeTitles[p.cavePlaceUuid!.toString()]
          : null;
      events.add(TripLogEvent(
        kind: TripLogEventKind.point,
        at: ms(p.scannedAt),
        label: title ?? '?',
        notes: (p.notes != null && p.notes!.trim().isNotEmpty)
            ? p.notes!.trim()
            : null,
      ));
    }
    for (final r in docRows) {
      final createdAt = r.data['created_at'] as int?;
      if (createdAt == null) continue;
      events.add(TripLogEvent(
        kind: TripLogEventKind.documentAdded,
        at: ms(createdAt),
        label: (r.data['title'] as String?) ?? '?',
      ));
    }

    events.sort((a, b) => a.at.compareTo(b.at));

    final tripStart = ms(trip.tripStartedAt);
    final earlierEvents = events.where((e) => e.at.isBefore(tripStart)).toList();
    final result = <TripLogEvent>[];
    if (earlierEvents.isEmpty) {
      result.add(TripLogEvent(
        kind: TripLogEventKind.start,
        at: tripStart,
        title: trip.title,
      ));
      result.addAll(events);
    } else {
      // Restart scenario: events occurred before the current trip_started_at.
      result.add(TripLogEvent(
        kind: TripLogEventKind.start,
        at: earlierEvents.first.at,
        title: trip.title,
      ));
      result.addAll(earlierEvents);
      result.add(TripLogEvent(
        kind: TripLogEventKind.restart,
        at: tripStart,
        title: trip.title,
      ));
      result.addAll(events.where((e) => !e.at.isBefore(tripStart)));
    }
    if (trip.tripEndedAt != null) {
      result.add(TripLogEvent(
        kind: TripLogEventKind.end,
        at: ms(trip.tripEndedAt!),
      ));
    }
    return result;
  }

  /// Renders [events] in the [method] style. Pure function — safe to test.
  String render(List<TripLogEvent> events, TripLogMethod method) {
    if (events.isEmpty) return '';
    switch (method) {
      case TripLogMethod.raw:
        return _renderRaw(events);
      case TripLogMethod.classic:
        return _renderClassic(events);
      case TripLogMethod.journal:
        return _renderJournal(events);
      case TripLogMethod.narrative:
        return _renderNarrative(events);
    }
  }

  /// Returns the rendered text for the **last** event in [events] in
  /// O(1) string work (raw/classic) or O(N) bounded counting work
  /// (journal), so appending the N-th event costs O(N) instead of
  /// O(N²) (full re-render of N-1 events twice).
  ///
  /// Returns null when incremental rendering is unsupported for
  /// [method] — currently only narrative, whose paragraph grouping
  /// can't be done from the tail alone. Caller should fall back to
  /// full `render`.
  ///
  /// For a single-event list returns the same text as
  /// `render(events, method)` (no leading separator).
  String? renderTailDelta(List<TripLogEvent> events, TripLogMethod method) {
    if (events.isEmpty) return '';
    switch (method) {
      case TripLogMethod.raw:
        return _renderRawLine(events.last);
      case TripLogMethod.classic:
        return _renderClassicLine(events.last);
      case TripLogMethod.journal:
        final tripStart = events.first.at;
        int pointCount = 0;
        for (int i = 0; i < events.length - 1; i++) {
          final e = events[i];
          if (e.kind == TripLogEventKind.restart) {
            pointCount = 0;
          } else if (e.kind == TripLogEventKind.point) {
            pointCount++;
          }
        }
        return _renderJournalLine(events.last, tripStart, pointCount);
      case TripLogMethod.narrative:
        return null;
    }
  }

  // ---------------------------------------------------------------------------
  // raw — verbatim terse lines, identical to the legacy format.
  // ---------------------------------------------------------------------------
  String _renderRaw(List<TripLogEvent> events) =>
      events.map(_renderRawLine).join('\n');

  String _renderRawLine(TripLogEvent e) {
    final ts = '[${_absFmt.format(e.at)}]';
    switch (e.kind) {
      case TripLogEventKind.start:
        return '$ts ${LocServ.inst.t('trip_log_started', {'title': e.title ?? ''})}';
      case TripLogEventKind.restart:
        return '$ts ${LocServ.inst.t('trip_log_restarted')}';
      case TripLogEventKind.end:
        return '$ts ${LocServ.inst.t('trip_log_ended')}';
      case TripLogEventKind.point:
        return '$ts ${LocServ.inst.t('trip_log_qr_scanned', {'label': '"${e.label}"'})}';
      case TripLogEventKind.documentAdded:
        return '$ts ${LocServ.inst.t('trip_log_document_added', {'label': '"${e.label}"'})}';
    }
  }

  // ---------------------------------------------------------------------------
  // classic — full sentences, same line format.
  // ---------------------------------------------------------------------------
  String _renderClassic(List<TripLogEvent> events) =>
      events.map(_renderClassicLine).join('\n');

  String _renderClassicLine(TripLogEvent e) {
    final ts = '[${_absFmt.format(e.at)}]';
    switch (e.kind) {
      case TripLogEventKind.start:
        return '$ts ${LocServ.inst.t('trip_log_classic_started', {'title': e.title ?? ''})}';
      case TripLogEventKind.restart:
        return '$ts ${LocServ.inst.t('trip_log_classic_restarted')}';
      case TripLogEventKind.end:
        return '$ts ${LocServ.inst.t('trip_log_classic_ended')}';
      case TripLogEventKind.point:
        var line = LocServ.inst
            .t('trip_log_classic_arrived', {'label': e.label ?? ''});
        if (e.notes != null) line = '$line (${e.notes})';
        return '$ts $line';
      case TripLogEventKind.documentAdded:
        return '$ts ${LocServ.inst.t('trip_log_classic_documented', {'label': e.label ?? ''})}';
    }
  }

  // ---------------------------------------------------------------------------
  // journal — `[HH:mm · +Δ] sentence` with sequence-aware phrasing.
  // ---------------------------------------------------------------------------
  String _renderJournal(List<TripLogEvent> events) {
    final tripStart = events.first.at;
    int pointCount = 0;
    final lines = <String>[];
    for (final e in events) {
      if (e.kind == TripLogEventKind.point) {
        pointCount++;
        lines.add(_renderJournalLine(e, tripStart, pointCount - 1));
      } else if (e.kind == TripLogEventKind.restart) {
        lines.add(_renderJournalLine(e, tripStart, pointCount));
        pointCount = 0;
      } else {
        lines.add(_renderJournalLine(e, tripStart, pointCount));
      }
    }
    return lines.join('\n');
  }

  /// Renders a single journal-method line for [e]. [pointCountBefore]
  /// is the number of point events since the last restart (or since
  /// trip start) that occurred BEFORE [e]; the point line numbering is
  /// `pointCountBefore + 1` for the first stop, etc.
  String _renderJournalLine(
      TripLogEvent e, DateTime tripStart, int pointCountBefore) {
    final clock = _shortTimeFmt.format(e.at);
    final elapsed = _formatElapsed(e.at.difference(tripStart));
    final prefix = e.kind == TripLogEventKind.start
        ? '[$clock]'
        : '[$clock · +$elapsed]';
    switch (e.kind) {
      case TripLogEventKind.start:
        return '$prefix ${LocServ.inst.t('trip_log_journal_started', {'title': e.title ?? ''})}';
      case TripLogEventKind.restart:
        return '$prefix ${LocServ.inst.t('trip_log_journal_restarted')}';
      case TripLogEventKind.end:
        return '$prefix ${LocServ.inst.t('trip_log_journal_ended')}';
      case TripLogEventKind.point:
        final ordinal = pointCountBefore + 1;
        final key = ordinal == 1
            ? 'trip_log_journal_first_stop'
            : 'trip_log_journal_next_stop';
        var line = LocServ.inst.t(key, {'label': e.label ?? ''});
        if (e.notes != null) line = '$line (${e.notes})';
        return '$prefix $line';
      case TripLogEventKind.documentAdded:
        return '$prefix ${LocServ.inst.t('trip_log_journal_documented', {'label': e.label ?? ''})}';
    }
  }

  // ---------------------------------------------------------------------------
  // narrative — paragraphs grouping consecutive points; pause durations
  // summarized; opening/closing prose.
  // ---------------------------------------------------------------------------
  String _renderNarrative(List<TripLogEvent> events) {
    final paragraphs = <String>[];
    final tripStart = events.first.at;

    String label(TripLogEvent p) => p.label ?? '?';
    String quoted(String s) => '"$s"';

    // Opening
    final startEv = events.first;
    if (startEv.kind == TripLogEventKind.start) {
      paragraphs.add(LocServ.inst.t('trip_log_narrative_opening', {
        'title': startEv.title ?? '',
        'date': _dateLongFmt.format(startEv.at),
        'time': _shortTimeFmt.format(startEv.at),
      }));
    }

    // Walk events grouping consecutive points.
    int i = 1;
    DateTime cursor = startEv.at;
    while (i < events.length) {
      final e = events[i];
      if (e.kind == TripLogEventKind.point) {
        final group = <TripLogEvent>[];
        while (i < events.length && events[i].kind == TripLogEventKind.point) {
          group.add(events[i]);
          i++;
        }
        paragraphs.add(_narrativeMovementParagraph(group, cursor));
        // Append per-point note sentences (one per point with a note).
        for (final p in group) {
          if (p.notes != null) {
            paragraphs.add(LocServ.inst.t('trip_log_narrative_point_note', {
              'label': label(p),
              'note': p.notes!,
            }));
          }
        }
        cursor = group.last.at;
        continue;
      }
      switch (e.kind) {
        case TripLogEventKind.documentAdded:
          paragraphs.add(LocServ.inst.t('trip_log_narrative_document', {
            'label': quoted(label(e)),
            'time': _shortTimeFmt.format(e.at),
          }));
          cursor = e.at;
          i++;
          break;
        case TripLogEventKind.restart:
          paragraphs.add(LocServ.inst.t('trip_log_narrative_restart', {
            'time': _shortTimeFmt.format(e.at),
          }));
          cursor = e.at;
          i++;
          break;
        case TripLogEventKind.end:
          final total = e.at.difference(tripStart);
          paragraphs.add(LocServ.inst.t('trip_log_narrative_closing', {
            'time': _shortTimeFmt.format(e.at),
            'duration': _formatHoursMinutes(total),
          }));
          i++;
          break;
        case TripLogEventKind.start:
        case TripLogEventKind.point:
          // start can only appear at index 0; point handled above.
          i++;
          break;
      }
    }
    return paragraphs.join('\n\n');
  }

  String _narrativeMovementParagraph(
      List<TripLogEvent> group, DateTime cursor) {
    final firstDelta = _formatMinutes(
        group.first.at.difference(cursor).inMinutes.clamp(0, 1 << 30));
    if (group.length == 1) {
      return LocServ.inst.t('trip_log_narrative_single_stop', {
        'delta': firstDelta,
        'label': '"${group.first.label}"',
      });
    }
    // First stop sentence + chained "then continued to X (5 min later)".
    final buf = StringBuffer();
    buf.write(LocServ.inst.t('trip_log_narrative_first_in_group', {
      'delta': firstDelta,
      'label': '"${group.first.label}"',
    }));
    for (int j = 1; j < group.length; j++) {
      final delta = _formatMinutes(
          group[j].at.difference(group[j - 1].at).inMinutes.clamp(0, 1 << 30));
      final isLast = j == group.length - 1;
      final key = isLast
          ? 'trip_log_narrative_then_last'
          : 'trip_log_narrative_then_more';
      buf.write(LocServ.inst.t(key, {
        'delta': delta,
        'label': '"${group[j].label}"',
      }));
    }
    return buf.toString();
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------
  String _formatElapsed(Duration d) {
    if (d.isNegative) return '0min';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h > 0) return '${h}h${m.toString().padLeft(2, '0')}min';
    return '${m}min';
  }

  String _formatMinutes(int mins) {
    if (mins < 60) {
      return LocServ.inst.t('trip_log_dur_minutes', {'n': mins.toString()});
    }
    final h = mins ~/ 60;
    final m = mins % 60;
    if (m == 0) {
      return LocServ.inst.t('trip_log_dur_hours', {'n': h.toString()});
    }
    return LocServ.inst.t('trip_log_dur_hours_minutes', {
      'h': h.toString(),
      'm': m.toString(),
    });
  }

  String _formatHoursMinutes(Duration d) =>
      _formatMinutes(d.inMinutes.clamp(0, 1 << 30));
}
