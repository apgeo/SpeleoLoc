import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/screens/cave_model/cave_model_viewer_page.dart';
import 'package:speleoloc/utils/file_utils.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Opens the cave's survey model in 3D: for [cavePlaceUuid], the model that
/// maps the place (or the cave's first, to map it there); for
/// [replayTripUuid], with that trip replayed. Says so when the cave has none.
Future<void> openCaveModel(
  BuildContext context,
  WidgetRef ref, {
  required Uuid caveUuid,
  Uuid? cavePlaceUuid,
  Uuid? replayTripUuid,
}) async {
  final choice = await ref
      .read(caveModelLocatorProvider)
      .modelToOpen(caveUuid, cavePlaceUuid: cavePlaceUuid);
  if (choice == null) {
    SnackBarService.showWarning(LocServ.inst.t('model_none_for_cave'));
    return;
  }
  final file = await getDocumentsFile(choice.model.fileName);
  if (file == null) {
    SnackBarService.showWarning(LocServ.inst.t('image_not_found'));
    return;
  }
  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CaveModelViewerPage(
        file: file,
        title: choice.model.title,
        model: choice.model,
        caveUuid: caveUuid,
        focusPlaceUuid: cavePlaceUuid,
        replayTripUuid: replayTripUuid,
      ),
    ),
  );
}
