import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/cave_place_qr_generator.dart';

/// Guards finding 4.2: the PNG image path must render the configured label
/// template (like the PDF path does), not just the place title.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  CavePlace place() => CavePlace(
    uuid: Uuid.v7(),
    title: 'Entrance',
    caveUuid: Uuid.v7(),
    placeCodeIdentifier: 'PCI123',
    depthInCave: -12.5,
    isEntrance: 0,
    isMainEntrance: 0,
  );

  const base = GenerationPreferences(
    asPdf: false,
    includeTitle: true,
    qrSizePx: 120,
    imagePaddingPx: 8,
  );

  test('label template changes the rendered image', () async {
    final p = place();
    final titleOnly = await QrImageRenderer.render(
      p,
      const GenerationPreferences(
        asPdf: false,
        includeTitle: true,
        qrSizePx: 120,
        imagePaddingPx: 8,
        labelTemplate: '@place_title',
      ),
    );
    final withDepth = await QrImageRenderer.render(
      p,
      const GenerationPreferences(
        asPdf: false,
        includeTitle: true,
        qrSizePx: 120,
        imagePaddingPx: 8,
        labelTemplate: '@place_title, @depth',
      ),
    );

    // Same QR payload, different label → different pixels. Pre-fix both
    // ignored the template and drew only the title, producing identical
    // bytes.
    expect(titleOnly, isNotEmpty);
    expect(withDepth, isNotEmpty);
    expect(withDepth, isNot(equals(titleOnly)));
  });

  test('includeTitle=false omits the label', () async {
    final p = place();
    final withLabel = await QrImageRenderer.render(p, base);
    final noLabel = await QrImageRenderer.render(
      p,
      const GenerationPreferences(
        asPdf: false,
        includeTitle: false,
        qrSizePx: 120,
        imagePaddingPx: 8,
      ),
    );
    expect(withLabel, isNot(equals(noLabel)));
  });
}
