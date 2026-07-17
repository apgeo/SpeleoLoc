import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_controller.dart';
import 'package:speleoloc/screens/cave_place/cave_place_save_command.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';
import 'package:speleoloc/services/repository_interfaces.dart';

// ---------------------------------------------------------------------------
// Fakes
// ---------------------------------------------------------------------------

class _FakeRepo extends Fake implements ICavePlaceRepository {
  List<CavePlace> pciDuplicates = const [];
  List<CavePlace> qcriDuplicates = const [];
  List<CavePlace> mainEntrances = const [];

  bool qcriLookupCalled = false;
  bool entrancesLookupCalled = false;
  CavePlacesCompanion? inserted;
  Uuid? updatedUuid;
  CavePlacesCompanion? updatedPatch;

  @override
  Future<List<CavePlace>> findByPlaceCodeIdentifier(
    String code, {
    Uuid? caveUuid,
    Uuid? excludeUuid,
  }) async => pciDuplicates;

  @override
  Future<List<CavePlace>> findByQrCodeResourceIdentifier(
    String code, {
    Uuid? excludeUuid,
  }) async {
    qcriLookupCalled = true;
    return qcriDuplicates;
  }

  @override
  Future<List<CavePlace>> findEntrances(
    Uuid caveUuid, {
    bool mainOnly = false,
    Uuid? excludeUuid,
  }) async {
    entrancesLookupCalled = true;
    return mainEntrances;
  }

  @override
  Future<Uuid> addCavePlaceFromCompanion(CavePlacesCompanion companion) async {
    inserted = companion;
    return companion.uuid.value;
  }

  @override
  Future<void> updateCavePlace(Uuid uuid, CavePlacesCompanion patch) async {
    updatedUuid = uuid;
    updatedPatch = patch;
  }
}

class _FakePlaceCodeService extends Fake implements PlaceCodeService {
  String? computedForPci;

  @override
  Future<String> computeQcri(
    String pci, {
    required Uuid cavePlaceUuid,
    bool? isEntrance,
  }) async {
    computedForPci = pci;
    return 'QCRI-$pci';
  }
}

class _FakePort implements CavePlaceConfirmationPort {
  bool extremeDepthAnswer = true;
  bool duplicatePciAnswer = true;
  bool duplicateQcriAnswer = true;
  bool isEntranceAnswer = false;
  bool isMainEntranceAnswer = false;
  final List<String> calls = [];

  @override
  Future<bool> confirmExtremeDepth(String formattedDepth) async {
    calls.add('extremeDepth:$formattedDepth');
    return extremeDepthAnswer;
  }

  @override
  Future<bool> confirmDuplicatePci({
    required String otherTitle,
    required String qr,
  }) async {
    calls.add('duplicatePci:$otherTitle');
    return duplicatePciAnswer;
  }

  @override
  Future<bool> confirmDuplicateQcri({
    required String otherTitle,
    required String qcri,
  }) async {
    calls.add('duplicateQcri:$otherTitle');
    return duplicateQcriAnswer;
  }

  @override
  Future<bool> askIsEntrance(String detectorWord) async {
    calls.add('askIsEntrance');
    return isEntranceAnswer;
  }

  @override
  Future<bool> askIsMainEntrance() async {
    calls.add('askIsMainEntrance');
    return isMainEntranceAnswer;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

CavePlace _place(String title) => CavePlace(
  uuid: Uuid.v7(),
  caveUuid: Uuid.zero,
  title: title,
  isEntrance: 0,
  isMainEntrance: 0,
);

CavePlaceFormController _form({
  String title = 'Chamber',
  String description = '',
  String depth = '',
  String qr = '',
  String qcri = '',
}) {
  final f = CavePlaceFormController();
  addTearDown(f.dispose);
  f.title.text = title;
  f.description.text = description;
  f.depth.text = depth;
  f.qr.text = qr;
  f.qcri.text = qcri;
  return f;
}

({
  CavePlaceSaveCommand command,
  _FakeRepo repo,
  _FakePort port,
  _FakePlaceCodeService codes,
}) _setup(CavePlaceFormController form, {Uuid? existingId}) {
  final repo = _FakeRepo();
  final port = _FakePort();
  final codes = _FakePlaceCodeService();
  final command = CavePlaceSaveCommand(
    caveUuid: Uuid.zero,
    currentCavePlaceId: existingId,
    form: form,
    repository: repo,
    placeCodeService: codes,
    confirmations: port,
  );
  return (command: command, repo: repo, port: port, codes: codes);
}

void main() {
  group('validation', () {
    test('empty title fails without touching the repository', () async {
      final s = _setup(_form(title: ''));
      final result = await s.command.execute();
      expect(result, isA<SaveValidationFailed>());
      expect((result as SaveValidationFailed).messageKey, 'title_required');
      expect(s.repo.inserted, isNull);
    });

    test('unparseable depth fails', () async {
      final s = _setup(_form(depth: 'abc'));
      final result = await s.command.execute();
      expect(
        (result as SaveValidationFailed).messageKey,
        'depth_invalid_number',
      );
    });

    test('depth beyond the hard limit fails', () async {
      final s = _setup(_form(depth: '6000'));
      final result = await s.command.execute();
      expect((result as SaveValidationFailed).messageKey, 'depth_out_of_range');
    });
  });

  group('confirmations', () {
    test('extreme depth prompts; declining cancels the save', () async {
      final s = _setup(_form(depth: '2000'));
      s.port.extremeDepthAnswer = false;
      final result = await s.command.execute();
      expect(result, isA<SaveCancelled>());
      expect(s.port.calls, contains('extremeDepth:2000'));
      expect(s.repo.inserted, isNull);
    });

    test('duplicate PCI in cave prompts; declining cancels', () async {
      final s = _setup(_form(qr: 'PN-01'));
      s.repo.pciDuplicates = [_place('Other place')];
      s.port.duplicatePciAnswer = false;
      final result = await s.command.execute();
      expect(result, isA<SaveCancelled>());
      expect(s.port.calls, contains('duplicatePci:Other place'));
    });

    test('QCRI duplicates are only checked when the field was touched', () async {
      final form = _form(qr: 'PN-01', qcri: 'Q-1');
      final s = _setup(form);
      s.repo.qcriDuplicates = [_place('Elsewhere')];
      final result = await s.command.execute();
      // Field not marked touched → no lookup, no prompt, save proceeds.
      expect(s.repo.qcriLookupCalled, isFalse);
      expect(result, isA<SaveOk>());

      final form2 = _form(qr: 'PN-01', qcri: 'Q-1')..markQcriTouched();
      final s2 = _setup(form2);
      s2.repo.qcriDuplicates = [_place('Elsewhere')];
      s2.port.duplicateQcriAnswer = false;
      final result2 = await s2.command.execute();
      expect(s2.repo.qcriLookupCalled, isTrue);
      expect(s2.port.calls, contains('duplicateQcri:Elsewhere'));
      expect(result2, isA<SaveCancelled>());
    });

    test('entrance-detector decision applies to the row, not the form', () async {
      final form = _form();
      final s = _setup(form);
      s.port.isEntranceAnswer = true;
      final result = await s.command.execute();
      expect(result, isA<SaveOk>());
      expect(s.repo.inserted!.isEntrance.value, 1);
      expect(form.isEntrance, isFalse);
    });

    test('main entrance is offered only when the cave has none', () async {
      final form = _form()..setEntrance(true);
      final s = _setup(form);
      s.port.isMainEntranceAnswer = true;
      final result = await s.command.execute();
      expect(result, isA<SaveOk>());
      expect(s.port.calls, contains('askIsMainEntrance'));
      expect(s.repo.inserted!.isMainEntrance.value, 1);

      final form2 = _form()..setEntrance(true);
      final s2 = _setup(form2);
      s2.repo.mainEntrances = [_place('Main entrance')];
      await s2.command.execute();
      expect(s2.port.calls, isNot(contains('askIsMainEntrance')));
      expect(s2.repo.inserted!.isMainEntrance.value, 0);
    });
  });

  group('QCRI derivation', () {
    test('computed from PCI when the QCRI field is empty', () async {
      final s = _setup(_form(qr: 'PN-01'));
      final result = await s.command.execute();
      expect(result, isA<SaveOk>());
      expect(s.codes.computedForPci, 'PN-01');
      expect(s.repo.inserted!.qrCodeResourceIdentifier.value, 'QCRI-PN-01');
    });

    test('explicit QCRI wins; no PCI means null QCRI', () async {
      final s = _setup(_form(qr: 'PN-01', qcri: 'EXPLICIT'));
      await s.command.execute();
      expect(s.codes.computedForPci, isNull);
      expect(s.repo.inserted!.qrCodeResourceIdentifier.value, 'EXPLICIT');

      final s2 = _setup(_form());
      await s2.command.execute();
      expect(s2.repo.inserted!.qrCodeResourceIdentifier.value, isNull);
    });
  });

  group('persistence', () {
    test('insert writes the form values into the companion', () async {
      final s = _setup(_form(description: 'A big chamber', depth: '-120,5'));
      final result = await s.command.execute();
      expect(result, isA<SaveOk>());
      final c = s.repo.inserted!;
      expect(c.title.value, 'Chamber');
      expect(c.description.value, 'A big chamber');
      expect(c.depthInCave.value, -120.5);
      expect(c.uuid.value, (result as SaveOk).uuid);
    });

    test('update targets the existing uuid with the entered values', () async {
      final id = Uuid.v7();
      final s = _setup(_form(description: 'Edited'), existingId: id);
      final result = await s.command.execute();
      expect((result as SaveOk).uuid, id);
      expect(s.repo.updatedUuid, id);
      expect(s.repo.updatedPatch!.description.value, 'Edited');
    });

    test(
      'REGRESSION: clearing the description on update writes null, not absent',
      () async {
        // An absent Value would leave the old description in place (the bug
        // fixed in 8771584) — the patch must carry a present null.
        final s = _setup(_form(description: ''), existingId: Uuid.v7());
        await s.command.execute();
        final desc = s.repo.updatedPatch!.description;
        expect(desc.present, isTrue);
        expect(desc.value, isNull);
      },
    );
  });
}
