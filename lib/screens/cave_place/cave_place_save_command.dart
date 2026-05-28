import 'package:drift/drift.dart' hide Column;
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_controller.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_utils.dart';
import 'package:speleoloc/services/place_code/place_code_service.dart';

/// Result of executing [CavePlaceSaveCommand].
sealed class SaveOutcome {
  const SaveOutcome();
}

/// The cave place was inserted or updated successfully. [uuid] is the
/// persisted row's UUID.
class SaveOk extends SaveOutcome {
  const SaveOk(this.uuid);
  final Uuid uuid;
}

/// A field-level validation failed before any dialog or DB write happened.
/// The caller should show [messageKey] (a `LocServ` key) as a toast/snack.
class SaveValidationFailed extends SaveOutcome {
  const SaveValidationFailed(this.messageKey);
  final String messageKey;
}

/// The user dismissed one of the confirmation dialogs (or the page was
/// unmounted while a dialog was open). No DB write happened; the caller
/// should silently return null.
class SaveCancelled extends SaveOutcome {
  const SaveCancelled();
}

/// Dialog/prompt boundary for [CavePlaceSaveCommand].
///
/// Implementations of this port talk to `showDialog` / `BuildContext`.
/// The command itself stays platform-agnostic so it can be unit-tested
/// with a fake port. Every method returns `true` iff the user confirmed;
/// returning `false` (including on unmount) aborts the save.
abstract class CavePlaceConfirmationPort {
  /// Depth outside the "common cave" range (-1800..1800 m) but inside the
  /// hard limit (-5000..5000) — ask the user before saving.
  Future<bool> confirmExtremeDepth(String formattedDepth);

  /// Another cave place in the same cave already uses this PCI.
  Future<bool> confirmDuplicatePci({
    required String otherTitle,
    required String qr,
  });

  /// Another cave place anywhere already uses this QCRI.
  Future<bool> confirmDuplicateQcri({
    required String otherTitle,
    required String qcri,
  });

  /// The title equals the configured "entrance" keyword and the place
  /// isn't yet marked as an entrance — offer to flip the flag.
  Future<bool> askIsEntrance(String detectorWord);

  /// The place is being saved as an entrance but no main entrance exists
  /// for this cave yet — offer to also mark it as the main entrance.
  Future<bool> askIsMainEntrance();
}

/// Command that runs the entire "save cave place" workflow:
///
/// 1. Validates the form values (title required, depth parseable + in
///    range).
/// 2. Asks the user to confirm a series of edge cases via the injected
///    [CavePlaceConfirmationPort].
/// 3. Computes the effective QCRI (from the explicit field or via
///    `placeCodeService.computeQcri`).
/// 4. Writes a `CavePlacesCompanion` through the repository.
///
/// The command reads form values through the [CavePlaceFormController]
/// reference but **does not** mutate the form. Decisions taken from
/// confirmation dialogs (e.g. "yes, also mark as entrance") are kept in
/// local variables and applied to the persisted row only.
class CavePlaceSaveCommand {
  CavePlaceSaveCommand({
    required this.caveUuid,
    required this.currentCavePlaceId,
    required this.form,
    required this.repository,
    required this.placeCodeService,
    required this.confirmations,
  });

  final Uuid caveUuid;
  final Uuid? currentCavePlaceId;
  final CavePlaceFormController form;
  final ICavePlaceRepository repository;
  final PlaceCodeService placeCodeService;
  final CavePlaceConfirmationPort confirmations;

  Future<SaveOutcome> execute() async {
    final title = form.title.text;
    final description =
        form.description.text.isEmpty ? null : form.description.text;
    final depth = parseDepthValue(form.depth.text);
    final qrText = form.qr.text.trim();
    final qr = qrText.isEmpty ? null : qrText;
    final qcriText = form.qcri.text.trim();
    final lat = double.tryParse(form.lat.text);
    final long = double.tryParse(form.long.text);
    final alt = form.alt.text.trim().isEmpty
        ? null
        : double.tryParse(form.alt.text);

    // --- 1. Validation.
    if (title.isEmpty) {
      return const SaveValidationFailed('title_required');
    }
    if (form.depth.text.trim().isNotEmpty && depth == null) {
      return const SaveValidationFailed('depth_invalid_number');
    }
    if (depth != null && (depth < -5000 || depth > 5000)) {
      return const SaveValidationFailed('depth_out_of_range');
    }

    // --- 2. Extreme-depth confirmation.
    if (depth != null && (depth < -1800 || depth > 1800)) {
      final ok =
          await confirmations.confirmExtremeDepth(formatDepthValue(depth));
      if (!ok) return const SaveCancelled();
    }

    // --- 3. PCI duplicate (in same cave).
    if (qr != null) {
      final duplicates = await repository.findByPlaceCodeIdentifier(
        qr,
        caveUuid: caveUuid,
        excludeUuid: currentCavePlaceId,
      );
      if (duplicates.isNotEmpty) {
        final ok = await confirmations.confirmDuplicatePci(
          otherTitle: duplicates.first.title,
          qr: qr,
        );
        if (!ok) return const SaveCancelled();
      }
    }

    // --- 4. QCRI duplicate (anywhere) — only if user explicitly touched QCRI.
    if (form.qcriModified && qcriText.isNotEmpty) {
      final dupQcri = await repository.findByQrCodeResourceIdentifier(
        qcriText,
        excludeUuid: currentCavePlaceId,
      );
      if (dupQcri.isNotEmpty) {
        final ok = await confirmations.confirmDuplicateQcri(
          otherTitle: dupQcri.first.title,
          qcri: qcriText,
        );
        if (!ok) return const SaveCancelled();
      }
    }

    // --- 5. Entrance-detector + main-entrance prompts. Decisions are
    // applied to the saved row but NOT written back to the form (mirrors
    // the pre-PR-6 behaviour: the toggle row in the UI isn't flipped by
    // these implicit decisions).
    //
    // [askIsEntrance] receives the current title and returns true iff
    // the user agreed to mark the place as an entrance. The port owns
    // the localised detector-word lookup and the title comparison —
    // implementations that don't want to prompt simply return false.
    var effectiveIsEntrance = form.isEntrance;
    var effectiveIsMainEntrance = form.isMainEntrance;

    if (!effectiveIsEntrance) {
      final ok = await confirmations.askIsEntrance(title);
      if (ok) effectiveIsEntrance = true;
    }

    if (effectiveIsEntrance && !effectiveIsMainEntrance) {
      final existingMain = await repository.findEntrances(
        caveUuid,
        mainOnly: true,
        excludeUuid: currentCavePlaceId,
      );
      if (existingMain.isEmpty) {
        final ok = await confirmations.askIsMainEntrance();
        if (ok) effectiveIsMainEntrance = true;
      }
    }

    // --- 6. Persist.
    final uuid = currentCavePlaceId ?? Uuid.v7();
    final qcri = qr == null
        ? null
        : qcriText.isNotEmpty
            ? qcriText
            : await placeCodeService.computeQcri(qr, cavePlaceUuid: uuid);

    if (currentCavePlaceId == null) {
      final companion = CavePlacesCompanion.insert(
        uuid: uuid,
        title: title,
        caveUuid: caveUuid,
        description:
            description == null ? const Value.absent() : Value(description),
        depthInCave: Value(depth),
        placeCodeIdentifier: Value(qr),
        qrCodeResourceIdentifier: Value(qcri),
        latitude: Value(lat),
        longitude: Value(long),
        altitude: Value(alt),
        caveAreaUuid: Value(form.selectedCaveAreaId),
        isEntrance: Value(effectiveIsEntrance ? 1 : 0),
        isMainEntrance:
            Value(effectiveIsEntrance && effectiveIsMainEntrance ? 1 : 0),
      );
      await repository.addCavePlaceFromCompanion(companion);
    } else {
      final companion = CavePlacesCompanion(
        title: Value(title),
        description:
            description == null ? const Value.absent() : Value(description),
        depthInCave: Value(depth),
        placeCodeIdentifier: Value(qr),
        qrCodeResourceIdentifier: Value(qcri),
        latitude: Value(lat),
        longitude: Value(long),
        altitude: Value(alt),
        caveAreaUuid: Value(form.selectedCaveAreaId),
        isEntrance: Value(effectiveIsEntrance ? 1 : 0),
        isMainEntrance:
            Value(effectiveIsEntrance && effectiveIsMainEntrance ? 1 : 0),
      );
      await repository.updateCavePlace(uuid, companion);
    }

    return SaveOk(uuid);
  }
}
