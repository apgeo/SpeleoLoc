import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_documents_service.dart';
import 'package:speleoloc/widgets/silexgis_server_documents_section.dart';

import '../support/layout_harness.dart';

/// "On the server" on a documents list: absent with no server, and with one,
/// what each entry says about itself.
void main() {
  useLayoutHarness();

  final featureId = Uuid.v7();

  SilexgisServerDocument document(
    String title, {
    String reach = 'original',
    String renditions = '2400,1200,480,160',
    bool usual = false,
    int? size,
  }) {
    final id = Uuid.v7();
    return SilexgisServerDocument(
      entry: SilexgisCatalogueEntry(
        link: SilexgisDocumentLinkData(
          profileUuid: 'p-1',
          linkId: 'link-$title',
          documentId: id,
          targetKind: 'feature',
          targetId: featureId,
          sortOrder: 0,
          isPrimary: false,
          inDefaultSet: usual,
        ),
        document: SilexgisDocumentData(
          profileUuid: 'p-1',
          documentId: id,
          title: title,
          fileKind: 'photo',
          reach: reach,
          renditions: renditions,
          sizeBytes: size,
        ),
      ),
    );
  }

  Future<void> pump(WidgetTester tester, SilexgisServerDocuments? server) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [
            silexgisServerDocumentsProvider.overrideWith(
              (ref, id) async => server,
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CustomScrollView(
                slivers: <Widget>[
                  SilexgisServerDocumentsSection(
                    featureId: featureId,
                    onDownloaded: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  testWidgets('with no server, nothing new appears', (tester) async {
    await pump(tester, null);
    await tester.pumpAndSettle();

    expect(find.text('On the server'), findsNothing);
    expect(find.byType(CheckboxListTile), findsNothing);
  });

  testWidgets('each entry says what it is and whether it can be fetched', (
    tester,
  ) async {
    await pump(
      tester,
      SilexgisServerDocuments(
        installation: 'Clubul Speo Example',
        documents: <SilexgisServerDocument>[
          document('entrance.jpg', size: 2 * 1024 * 1024, usual: true),
          document('shared.jpg', reach: 'locationFree'),
          document('clip.mp4', reach: 'none', renditions: ''),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('On the server'), findsOneWidget);
    expect(find.text('Clubul Speo Example'), findsOneWidget);
    expect(find.text('Download the usual files'), findsOneWidget);
    expect(find.text('Photo · 2.0 MB'), findsOneWidget);
    expect(find.text('without location'), findsOneWidget);
    expect(find.text('Photo · Not available to you'), findsOneWidget);

    // Picking one offers the download.
    await tester.tap(find.text('entrance.jpg'));
    await tester.pumpAndSettle();
    expect(find.text('Download (1)'), findsOneWidget);

    // An entry that cannot be fetched cannot be picked.
    await tester.tap(find.text('clip.mp4'));
    await tester.pumpAndSettle();
    expect(find.text('Download (1)'), findsOneWidget);
  });
}
