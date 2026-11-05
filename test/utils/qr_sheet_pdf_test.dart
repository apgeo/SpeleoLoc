import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/cave_place_qr_generator.dart';

import '../support/event_loop_stall.dart';

/// A large cave's QR sheet takes seconds to lay out and serialise, so the
/// screen showing its progress must keep serving frames meanwhile.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final caveUuid = Uuid.v7();
  final places = [
    for (var i = 0; i < 400; i++)
      CavePlace(
        uuid: Uuid.v7(),
        title: 'Invented passage ș ț $i',
        caveUuid: caveUuid,
        placeCodeIdentifier: 'PCI${i.toString().padLeft(5, '0')}',
        qrCodeResourceIdentifier: 'q${i.toRadixString(36).padLeft(6, 'x')}',
        depthInCave: -i.toDouble(),
        isEntrance: 0,
        isMainEntrance: 0,
      ),
  ];

  test('builds the sheet on a background isolate', () async {
    late GenerationResult result;
    final stall = await longestEventLoopStall(() async {
      result = await CavePlaceQRCodePDFGenerator().generate(
        places,
        const GenerationPreferences(caveTitle: 'Invented cave'),
      );
    });

    expect(result.files, hasLength(1));
    final pdf = result.files.single;
    expect(pdf.mimeType, 'application/pdf');
    expect(ascii.decode(pdf.bytes.sublist(0, 5)), '%PDF-');
    expect(pdf.bytes.length, greaterThan(10000));
    expect(stall, lessThan(const Duration(milliseconds: 250)));
  });
}
