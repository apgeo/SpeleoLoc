import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/state/model_viewer_settings_notifier.dart';
import 'package:speleoloc/utils/build_config.dart';
import 'package:speleoloc/utils/localization.dart';

/// This device's settings for 3D survey models.
class SettingsModelViewerPage extends ConsumerWidget {
  const SettingsModelViewerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = watchModelViewerSettings(ref);
    final notifier = ref.read(modelViewerSettingsProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: Text(LocServ.inst.t('settings_model_viewer'))),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(LocServ.inst.t('model_setting_mapping')),
            subtitle: Text(LocServ.inst.t('model_setting_mapping_desc')),
            value: settings.stationMapping,
            onChanged: (v) =>
                unawaited(notifier.set(settings.copyWith(stationMapping: v))),
          ),
          SwitchListTile(
            title: Text(LocServ.inst.t('model_setting_colour_by_area')),
            subtitle: Text(LocServ.inst.t('model_setting_colour_by_area_desc')),
            value: settings.markColourByArea,
            onChanged: settings.stationMapping
                ? (v) => unawaited(
                    notifier.set(settings.copyWith(markColourByArea: v)),
                  )
                : null,
          ),
          if (BuildConfig.silexgisEnabled)
            SwitchListTile(
              title: Text(LocServ.inst.t('model_setting_auto_download')),
              subtitle: Text(
                LocServ.inst.t('model_setting_auto_download_desc'),
              ),
              value: settings.autoDownloadModels,
              onChanged: (v) => unawaited(
                notifier.set(settings.copyWith(autoDownloadModels: v)),
              ),
            ),
        ],
      ),
    );
  }
}
