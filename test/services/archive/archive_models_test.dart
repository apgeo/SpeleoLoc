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

  group('enum stability', () {
    // ImportMode is small but consumed by the UI; pin the value set and
    // order.
    test('ImportMode values are exactly {replace, merge}', () {
      expect(
        ImportMode.values,
        orderedEquals(const [ImportMode.replace, ImportMode.merge]),
      );
    });
  });
}
