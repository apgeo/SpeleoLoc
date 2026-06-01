import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/archive/archive_models.dart';

void main() {
  group('ExportSettings', () {
    test('defaults match documented behaviour', () {
      const s = ExportSettings();
      expect(s.includeDocumentationFiles, isTrue);
      expect(s.includeRasterMaps, isTrue);
      expect(s.diffOnly, isFalse);
      expect(s.caveIds, isNull);
      expect(s.includeFtpPasswords, isFalse);
    });

    test('explicit overrides are preserved', () {
      const s = ExportSettings(
        includeDocumentationFiles: false,
        includeRasterMaps: false,
        diffOnly: true,
        caveIds: [1, 2, 3],
        includeFtpPasswords: true,
      );
      expect(s.includeDocumentationFiles, isFalse);
      expect(s.includeRasterMaps, isFalse);
      expect(s.diffOnly, isTrue);
      expect(s.caveIds, [1, 2, 3]);
      expect(s.includeFtpPasswords, isTrue);
    });
  });

  group('ImportResult', () {
    test('defaults are zero / empty', () {
      const r = ImportResult();
      expect(r.tablesProcessed, 0);
      expect(r.recordsImported, 0);
      expect(r.recordsSkipped, 0);
      expect(r.recordsOverwritten, 0);
      expect(r.filesCopied, 0);
      expect(r.warnings, isEmpty);
    });

    test('preserves all explicit counters and warnings list', () {
      const r = ImportResult(
        tablesProcessed: 4,
        recordsImported: 10,
        recordsSkipped: 2,
        recordsOverwritten: 1,
        filesCopied: 7,
        warnings: ['w1', 'w2'],
      );
      expect(r.tablesProcessed, 4);
      expect(r.recordsImported, 10);
      expect(r.recordsSkipped, 2);
      expect(r.recordsOverwritten, 1);
      expect(r.filesCopied, 7);
      expect(r.warnings, ['w1', 'w2']);
    });
  });

  group('ImportConflict', () {
    test('exposes all required fields verbatim', () {
      const c = ImportConflict(
        tableName: 'caves',
        humanTableName: 'Caves',
        existingRecord: {'id': 1, 'name': 'A'},
        importedRecord: {'id': 1, 'name': 'B'},
        conflictingColumns: ['name'],
      );
      expect(c.tableName, 'caves');
      expect(c.humanTableName, 'Caves');
      expect(c.existingRecord['name'], 'A');
      expect(c.importedRecord['name'], 'B');
      expect(c.conflictingColumns, ['name']);
    });
  });

  group('enum stability', () {
    // The persisted/contract surface of ConflictAction and ImportMode is
    // small but consumed by UI and tests; pin both the value set and order.
    test('ConflictAction values are exactly {skip, overwrite}', () {
      expect(ConflictAction.values,
          orderedEquals(const [ConflictAction.skip, ConflictAction.overwrite]));
    });

    test('ImportMode values are exactly {replace, merge}', () {
      expect(ImportMode.values,
          orderedEquals(const [ImportMode.replace, ImportMode.merge]));
    });
  });
}
