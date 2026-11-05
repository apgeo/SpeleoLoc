import 'package:speleoloc/services/sync/sync_merge_state.dart';

/// A record an archive merge holds until a person decides about it, with
/// the incoming rows that wait on it.
class ArchiveSyncDecision {
  const ArchiveSyncDecision({
    required this.root,
    required this.waiting,
    required this.isEdit,
    this.title,
    this.localTitle,
    this.caveTitle,
  });

  /// The incoming record whose unique key a local record already holds.
  final SyncHeldRow root;

  /// The incoming rows that hang on [root] and wait with it.
  final List<SyncHeldRow> waiting;

  /// The record exists here and the incoming row is an edit of it that
  /// would give it the key; otherwise the incoming record is new here.
  final bool isEdit;

  /// The incoming record's title, for a record that has one.
  final String? title;

  /// The title of the local record already holding the key.
  final String? localTitle;

  /// The cave the incoming record belongs to, for a record inside one.
  final String? caveTitle;

  String get table => root.table;

  /// Keeping both works by renaming the incoming record, so only when the
  /// two clash on their title.
  bool get canKeepBoth => title != null && title == localTitle;
}
