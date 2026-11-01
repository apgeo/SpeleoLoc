import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/screens/cave_model/cave_model_navigation.dart';
import 'package:speleoloc/utils/build_config.dart';
import 'package:speleoloc/utils/localization.dart';

/// An app-bar button that opens the cave's survey model in 3D — for a place,
/// or replaying a trip — shown only when the cave has a model and the build
/// offers the viewer.
class ViewInModelButton extends ConsumerWidget {
  const ViewInModelButton({
    super.key,
    required this.caveUuid,
    this.cavePlaceUuid,
    this.replayTripUuid,
  });

  final Uuid caveUuid;
  final Uuid? cavePlaceUuid;
  final Uuid? replayTripUuid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!BuildConfig.model3dEnabled) return const SizedBox.shrink();
    final models = ref.watch(caveModelsProvider(caveUuid)).valueOrNull;
    if (models == null || models.isEmpty) return const SizedBox.shrink();
    final tooltip = replayTripUuid != null
        ? 'model_replay_trip'
        : cavePlaceUuid != null
        ? 'model_view_place_in_3d'
        : 'model_open_cave_model';
    return IconButton(
      icon: Icon(replayTripUuid != null ? Icons.replay : Icons.view_in_ar),
      tooltip: LocServ.inst.t(tooltip),
      onPressed: () => unawaited(
        openCaveModel(
          context,
          ref,
          caveUuid: caveUuid,
          cavePlaceUuid: cavePlaceUuid,
          replayTripUuid: replayTripUuid,
        ),
      ),
    );
  }
}
