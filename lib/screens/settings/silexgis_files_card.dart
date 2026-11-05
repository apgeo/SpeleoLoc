import 'package:flutter/material.dart';
import 'package:speleoloc/screens/settings/silexgis_after_sync_hint.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/utils/localization.dart';

/// Whether a profile sends photos and documents, and over which networks.
class SilexgisFilesCard extends StatelessWidget {
  const SilexgisFilesCard({
    required this.profile,
    required this.onChanged,
    super.key,
  });

  final SilexgisProfile profile;

  /// The profile with one setting changed, to be saved. Null while the
  /// settings cannot be changed, which greys every switch out.
  final ValueChanged<SilexgisProfile>? onChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: <Widget>[
        SwitchListTile(
          secondary: const Icon(Icons.photo_library_outlined),
          value: profile.sendsFiles,
          onChanged: onChanged == null
              ? null
              : (v) => onChanged!(profile.copyWith(sendsFiles: v)),
          title: Text(LocServ.inst.t('silexgis_files_send')),
          subtitle: Text(LocServ.inst.t('silexgis_files_send_desc')),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.wifi),
          value: profile.filesOnlyOverWifi,
          onChanged: onChanged != null && profile.sendsFiles
              ? (v) => onChanged!(profile.copyWith(filesOnlyOverWifi: v))
              : null,
          title: Text(LocServ.inst.t('silexgis_files_wifi_only')),
          subtitle: Text(LocServ.inst.t('silexgis_files_wifi_only_desc')),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.help_outline),
          value: profile.asksBeforeMobileData,
          onChanged:
              onChanged != null &&
                  profile.sendsFiles &&
                  profile.filesOnlyOverWifi
              ? (v) => onChanged!(profile.copyWith(asksBeforeMobileData: v))
              : null,
          title: Text(LocServ.inst.t('silexgis_files_ask')),
          subtitle: Text(LocServ.inst.t('silexgis_files_ask_desc')),
        ),
        if (onChanged == null) const SilexgisAfterSyncHint(),
      ],
    ),
  );
}
