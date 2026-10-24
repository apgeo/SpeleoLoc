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

/// Replace vs Merge when importing into an existing database.
enum ImportMode { replace, merge }

/// Optional progress reporting.
typedef ProgressCallback = void Function(String message);
