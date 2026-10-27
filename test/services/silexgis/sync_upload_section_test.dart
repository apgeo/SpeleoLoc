import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';

/// How an upload is split for `uploadRowsMax`, which counts the items of every
/// section together.
void main() {
  test('the sections are declared in the server\'s apply order', () {
    expect(SyncUploadSection.values.map((s) => s.wireName), <String>[
      'rows',
      'people',
      'documents',
      'rasterMaps',
      'tripRecordings',
      'tripPoints',
      'documentLinks',
      'rasterPins',
    ]);
  });

  test('counts items across sections, and keeps the apply order', () {
    // Handed over in an order that is not the apply order: a link to a
    // document and a scan of a recording must never go up before them.
    final chunks = chunkUploadSections<String>(
      <SyncUploadSection, List<String>>{
        SyncUploadSection.documentLinks: <String>['link-1'],
        SyncUploadSection.tripPoints: <String>['scan-1', 'scan-2'],
        SyncUploadSection.rows: <String>['row-1', 'row-2'],
        SyncUploadSection.documents: <String>['doc-1'],
        SyncUploadSection.tripRecordings: <String>['trip-1'],
      },
      3,
    );

    expect(chunks, <Map<SyncUploadSection, List<String>>>[
      <SyncUploadSection, List<String>>{
        SyncUploadSection.rows: <String>['row-1', 'row-2'],
        SyncUploadSection.documents: <String>['doc-1'],
      },
      <SyncUploadSection, List<String>>{
        SyncUploadSection.tripRecordings: <String>['trip-1'],
        SyncUploadSection.tripPoints: <String>['scan-1', 'scan-2'],
      },
      <SyncUploadSection, List<String>>{
        SyncUploadSection.documentLinks: <String>['link-1'],
      },
    ]);
  });

  test('a section is split across parts when it does not fit', () {
    final chunks = chunkUploadSections<int>(<SyncUploadSection, List<int>>{
      SyncUploadSection.rows: List<int>.generate(5, (i) => i),
    }, 2);
    expect(chunks.map((c) => c[SyncUploadSection.rows]), <List<int>>[
      <int>[0, 1],
      <int>[2, 3],
      <int>[4],
    ]);
  });

  test('no announced ceiling sends everything at once', () {
    final chunks = chunkUploadSections<int>(<SyncUploadSection, List<int>>{
      SyncUploadSection.rows: <int>[1, 2],
      SyncUploadSection.people: <int>[3],
    }, 0);
    expect(chunks, hasLength(1));
    expect(chunks.single.keys, <SyncUploadSection>[
      SyncUploadSection.rows,
      SyncUploadSection.people,
    ]);
  });

  test('nothing to send is no part at all', () {
    expect(
      chunkUploadSections<int>(const <SyncUploadSection, List<int>>{}, 10),
      isEmpty,
    );
  });
}
