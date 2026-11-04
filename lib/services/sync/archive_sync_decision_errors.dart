/// The name chosen to keep both records is held by another record here as
/// well. Nothing was changed.
class ArchiveSyncNameTakenException implements Exception {
  const ArchiveSyncNameTakenException();

  @override
  String toString() => 'ArchiveSyncNameTakenException';
}

/// Merging would move a row onto the local record that clashes with a row
/// it already holds. Nothing was changed; renaming one of the two lets the
/// merge go through.
class ArchiveSyncMergeBlockedException implements Exception {
  const ArchiveSyncMergeBlockedException();

  @override
  String toString() => 'ArchiveSyncMergeBlockedException';
}
