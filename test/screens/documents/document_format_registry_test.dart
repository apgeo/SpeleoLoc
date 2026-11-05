import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/documents/document_format_registry.dart';
import 'package:speleoloc/widgets/editable_document_viewer.dart';

/// The audio editor records and splices PCM WAV, so it is offered only for
/// stored `.wav` documents; the other audio containers open in the viewer.
void main() {
  final registry = DocumentFormatRegistry.instance;

  setUpAll(() {
    if (registry.handlerById('audio') == null) registerBuiltInDocumentFormats();
  });

  DocumentationFile audio(String fileName) => DocumentationFile(
    uuid: Uuid.v7(),
    title: 'Invented recording',
    fileName: 'documentation_files/$fileName',
    fileSize: 1,
    fileType: 'audio',
  );

  test('the audio editor is offered for wav documents only', () {
    final handler = registry.handlerById('audio')!;

    expect(handler.canEdit(audio('a.wav')), isTrue);
    expect(handler.canEdit(audio('A.WAV')), isTrue);
    for (final ext in ['mp3', 'ogg', 'm4a', 'flac']) {
      expect(handler.canEdit(audio('a.$ext')), isFalse, reason: ext);
    }
    // New recordings still use the editor.
    expect(handler.hasEditor, isTrue);
  });

  test(
    'a non-wav audio document opens in the viewer without an edit button',
    () {
      final doc = audio('a.m4a');
      final opener = registry.buildBestOpener(
        file: File('a.m4a'),
        doc: doc,
        link: DocumentationGeofeatureLink(
          type: GeofeatureType.cavePlace,
          geofeatureUuid: Uuid.v7(),
        ),
      );

      expect(opener, isNotNull);
      expect(opener, isNot(isA<EditableDocumentViewer>()));
      expect(opener!.runtimeType.toString(), 'SoundFileViewer');
    },
  );

  test('a wav audio document still opens the editor', () {
    final doc = audio('a.wav');
    final opener = registry.buildBestOpener(
      file: File('a.wav'),
      doc: doc,
      link: DocumentationGeofeatureLink(
        type: GeofeatureType.cavePlace,
        geofeatureUuid: Uuid.v7(),
      ),
    );

    expect(opener.runtimeType.toString(), 'SoundRecorderPage');
  });
}
