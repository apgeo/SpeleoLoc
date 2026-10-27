import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_capabilities.dart';

/// The capabilities answer, read from invented bodies with and without each
/// optional part.
void main() {
  Map<String, Object?> answer(List<String> features, {int version = 1}) =>
      <String, Object?>{
        'contractVersion': version,
        'pageSizeMax': 500,
        'uploadRowsMax': 500,
        'features': features,
      };

  const everything = <String>[
    'download',
    'upload',
    'documents',
    'documentUpload',
    'trips',
    'reviews',
    'rasters',
    'people',
  ];

  bool Function(SilexgisCapabilities) getterFor(String name) => switch (name) {
    'download' => (c) => c.servesDownload,
    'upload' => (c) => c.servesUpload,
    'documents' => (c) => c.servesDocuments,
    'documentUpload' => (c) => c.servesDocumentUpload,
    'trips' => (c) => c.servesTrips,
    'reviews' => (c) => c.servesReviews,
    'rasters' => (c) => c.servesRasters,
    'people' => (c) => c.servesPeople,
    _ => throw ArgumentError(name),
  };

  test('a server that serves every part says so for each', () {
    final capabilities = SilexgisCapabilities.fromJson(answer(everything));
    for (final name in everything) {
      expect(getterFor(name)(capabilities), isTrue, reason: name);
    }
  });

  test('each part is read on its own name and no other', () {
    for (final missing in everything) {
      final capabilities = SilexgisCapabilities.fromJson(
        answer(everything.where((n) => n != missing).toList()),
      );
      for (final name in everything) {
        expect(
          getterFor(name)(capabilities),
          name != missing,
          reason: 'without `$missing`, `$name`',
        );
      }
    }
  });

  test('a phase-1 server serves none of the later parts', () {
    final capabilities = SilexgisCapabilities.fromJson(
      answer(const <String>['download', 'upload']),
    );
    expect(capabilities.servesDownload, isTrue);
    expect(capabilities.servesUpload, isTrue);
    expect(capabilities.servesDocuments, isFalse);
    expect(capabilities.servesDocumentUpload, isFalse);
    expect(capabilities.servesTrips, isFalse);
    expect(capabilities.servesReviews, isFalse);
    expect(capabilities.servesRasters, isFalse);
    expect(capabilities.servesPeople, isFalse);
  });

  test('a name this build does not know is ignored', () {
    final capabilities = SilexgisCapabilities.fromJson(
      answer(const <String>['download', 'invented-later']),
    );
    expect(capabilities.servesDownload, isTrue);
    expect(capabilities.servesUpload, isFalse);
  });

  test('the version is compared for equality, whatever is served', () {
    expect(
      SilexgisCapabilities.fromJson(answer(everything)).speaksOurContract,
      isTrue,
    );
    // A newer server is refused rather than interpreted generously, even when
    // it names every part this build knows.
    expect(
      SilexgisCapabilities.fromJson(
        answer(everything, version: 2),
      ).speaksOurContract,
      isFalse,
    );
    expect(
      SilexgisCapabilities.fromJson(
        answer(everything, version: 0),
      ).speaksOurContract,
      isFalse,
    );
  });
}
