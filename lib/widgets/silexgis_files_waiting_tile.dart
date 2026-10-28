import 'package:flutter/material.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_run.dart';
import 'package:speleoloc/utils/localization.dart';

/// The photos and documents a run did not send, and why — so a caver whose
/// files wait for room on the server, or for Wi-Fi, is told rather than left
/// to wonder. The rows without files went regardless.
class SilexgisFilesWaitingTile extends StatelessWidget {
  const SilexgisFilesWaitingTile({required this.files, super.key});

  final SilexgisFilesReport files;

  @override
  Widget build(BuildContext context) {
    String line(String key, int count) =>
        LocServ.inst.t(key, <String, String>{'count': '$count'});
    final reasons = <String>[
      if (files.waitingForNetwork > 0)
        line('silexgis_files_wifi', files.waitingForNetwork),
      if (files.quotaExceeded > 0)
        line('silexgis_files_quota', files.quotaExceeded),
      if (files.tooLarge > 0) line('silexgis_files_too_large', files.tooLarge),
      if (files.typeRefused > 0) line('silexgis_files_type', files.typeRefused),
      if (files.missing > 0) line('silexgis_files_missing', files.missing),
      if (files.failed > 0) line('silexgis_files_failed', files.failed),
    ];
    return ListTile(
      leading: const Icon(Icons.cloud_upload_outlined),
      title: Text(line('silexgis_files_waiting', files.held)),
      subtitle: Text(reasons.join('\n')),
      isThreeLine: reasons.length > 1,
    );
  }
}
