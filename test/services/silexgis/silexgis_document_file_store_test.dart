import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_file_store.dart';

/// The name a fetched file is stored under decides which viewer opens it, so
/// it has to end in the extension of what the file is.
void main() {
  String nameFor(
    String title,
    String? mimeType, {
    SyncRendition rendition = SyncRendition.original,
  }) => SilexgisDocumentFileStore.fileNameFor(
    title: title,
    mimeType: mimeType,
    rendition: rendition,
  );

  group('a title ending in a version or a scale', () {
    test('gets the extension of its type after it', () {
      expect(nameFor('Topo v2.3', 'application/pdf'), 'Topo v2.3.pdf');
      expect(nameFor('Raport 2024.1', 'application/pdf'), 'Raport 2024.1.pdf');
      expect(nameFor('Plan sc.1.500', 'application/pdf'), 'Plan sc.1.500.pdf');
      expect(nameFor('IMG 3.5', 'image/jpeg'), 'IMG 3.5.jpg');
    });

    test('a dotted word that is not its type is kept in the name', () {
      expect(nameFor('Plan.v2', 'application/pdf'), 'Plan.v2.pdf');
      expect(nameFor('notes.txt', 'application/pdf'), 'notes.txt.pdf');
    });
  });

  group('a title that already names its type', () {
    test('is kept as it is', () {
      expect(nameFor('Plan.pdf', 'application/pdf'), 'Plan.pdf');
      expect(nameFor('Entrance.JPG', 'image/jpeg'), 'Entrance.JPG');
      expect(nameFor('Entrance.jpeg', 'image/jpeg'), 'Entrance.jpeg');
    });

    test('of a type not known here, is kept as it is', () {
      expect(nameFor('Survey.tiff', 'image/tiff'), 'Survey.tiff');
      expect(nameFor('Survey', null), 'Survey');
    });
  });

  group('a picture the server drew', () {
    test('is named for its size, with the extension of the picture', () {
      expect(
        nameFor(
          'Plan.pdf',
          'image/jpeg',
          rendition: SyncRendition.picture(480),
        ),
        'Plan_480.jpg',
      );
      expect(
        nameFor('IMG 3.5', 'image/jpeg', rendition: SyncRendition.picture(160)),
        'IMG 3.5_160.jpg',
      );
    });
  });

  test('a title with nothing in it is still a name', () {
    expect(nameFor('  ', 'application/pdf'), 'document.pdf');
  });
}
