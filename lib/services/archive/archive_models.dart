/// Shared data classes for [DataArchiveService] (export / import).
///
/// Extracted during Phase 2.4 of the refactoring to isolate plain data
/// structures from the service orchestration logic. Re-exported by
/// `data_archive_service.dart` so existing imports continue to compile
/// unchanged.
library;

/// Parametrises what is included in an export archive.
class ExportSettings {
  final bool includeDocumentationFiles;
  final bool includeRasterMaps;
  final bool diffOnly;
  final List<int>? caveIds; // null = all caves (future use)
  final bool includeFtpPasswords;

  const ExportSettings({
    this.includeDocumentationFiles = true,
    this.includeRasterMaps = true,
    this.diffOnly = false,
    this.caveIds,
    this.includeFtpPasswords = false,
  });
}

/// What to do when an imported row conflicts with an existing one.
enum ConflictAction { skip, overwrite }

/// Describes a single unique-constraint collision detected during merge.
class ImportConflict {
  final String tableName;
  final String humanTableName;
  final Map<String, dynamic> existingRecord;
  final Map<String, dynamic> importedRecord;
  final List<String> conflictingColumns;

  const ImportConflict({
    required this.tableName,
    required this.humanTableName,
    required this.existingRecord,
    required this.importedRecord,
    required this.conflictingColumns,
  });
}

/// Replace vs Merge when importing into an existing database.
enum ImportMode { replace, merge }

/// Summary returned after a merge-import completes.
class ImportResult {
  final int tablesProcessed;
  final int recordsImported;
  final int recordsSkipped;
  final int recordsOverwritten;
  final int filesCopied;
  final List<String> warnings;

  const ImportResult({
    this.tablesProcessed = 0,
    this.recordsImported = 0,
    this.recordsSkipped = 0,
    this.recordsOverwritten = 0,
    this.filesCopied = 0,
    this.warnings = const [],
  });
}

/// Callback the sync engine invokes per conflict.
/// Return [ConflictAction] to continue, or `null` to cancel import.
typedef ConflictResolver = Future<ConflictAction?> Function(
    ImportConflict conflict);

/// Optional progress reporting.
typedef ProgressCallback = void Function(String message);
