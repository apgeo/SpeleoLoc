import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/model_viewer_providers.dart';
import 'package:speleoloc/services/cave_model/current_survey_models.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Lists the cave's survey models a server holds whose file is not on this
/// phone, and fetches one on a tap. Pops with the fetched model's document,
/// or null when nothing was fetched.
Future<Uuid?> showServerModelsSheet(BuildContext context, Uuid caveUuid) =>
    showModalBottomSheet<Uuid>(
      context: context,
      showDragHandle: true,
      builder: (_) => ServerModelsSheet(caveUuid: caveUuid),
    );

class ServerModelsSheet extends ConsumerStatefulWidget {
  const ServerModelsSheet({super.key, required this.caveUuid});

  final Uuid caveUuid;

  @override
  ConsumerState<ServerModelsSheet> createState() => _ServerModelsSheetState();
}

class _ServerModelsSheetState extends ConsumerState<ServerModelsSheet> {
  Uuid? _fetching;

  Future<void> _fetch(ServerSurveyModel model) async {
    setState(() => _fetching = model.modelId);
    final outcome = await ref
        .read(serverSurveyModelFetcherProvider)
        .fetch(model);
    if (!mounted) return;
    setState(() => _fetching = null);
    switch (outcome) {
      case ServerModelFetchOutcome.fetched:
        ref.invalidate(caveModelsProvider(widget.caveUuid));
        ref.invalidate(caveServerModelsProvider(widget.caveUuid));
        Navigator.of(context).pop(model.documentId);
      case ServerModelFetchOutcome.signIn:
        SnackBarService.showWarning(LocServ.inst.t('model_server_sign_in'));
      case ServerModelFetchOutcome.refused:
        SnackBarService.showWarning(LocServ.inst.t('model_server_refused'));
      case ServerModelFetchOutcome.failed:
        SnackBarService.showWarning(LocServ.inst.t('model_server_failed'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final models =
        ref.watch(caveServerModelsProvider(widget.caveUuid)).valueOrNull ??
        const <ServerSurveyModel>[];
    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          ListTile(
            title: Text(LocServ.inst.t('model_server_models')),
            subtitle: Text(LocServ.inst.t('model_server_models_hint')),
          ),
          for (final model in models)
            ListTile(
              leading: const Icon(Icons.cloud_download_outlined),
              title: Text(model.name ?? LocServ.inst.t('model_untitled')),
              subtitle: Text(_details(model)),
              trailing: _fetching == model.modelId
                  ? const SizedBox.square(
                      dimension: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
              enabled: _fetching == null,
              onTap: () => unawaited(_fetch(model)),
            ),
        ],
      ),
    );
  }

  static String _details(ServerSurveyModel model) => <String>[
    '.${model.format}',
    if (model.sizeBytes case final bytes?) _size(bytes),
    if (model.isCurrent) LocServ.inst.t('model_server_current'),
  ].join(' · ');

  static String _size(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
