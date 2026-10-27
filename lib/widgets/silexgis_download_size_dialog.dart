import 'package:flutter/material.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/utils/localization.dart';

/// The label of one form a server file can be fetched in.
String silexgisRenditionLabel(SyncRendition rendition) => rendition.isOriginal
    ? LocServ.inst.t('silexgis_docs_size_original')
    : LocServ.inst.t('silexgis_docs_size_px', <String, String>{
        'size': '${rendition.size}',
      });

/// Asks at which size to fetch server files. Offers only [choices]; when
/// [summaryFor] is given, each choice shows what it would cost before the
/// caver commits to it.
Future<SyncRendition?> showSilexgisDownloadSizeDialog(
  BuildContext context, {
  required List<SyncRendition> choices,
  String? Function(SyncRendition rendition)? summaryFor,
}) => showDialog<SyncRendition>(
  context: context,
  builder: (context) => SimpleDialog(
    title: Text(LocServ.inst.t('silexgis_docs_choose_size')),
    children: <Widget>[
      for (final choice in choices)
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop(choice),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(silexgisRenditionLabel(choice)),
            subtitle: switch (summaryFor?.call(choice)) {
              final String summary => Text(summary),
              null => null,
            },
          ),
        ),
    ],
  ),
);
