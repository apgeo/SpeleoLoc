import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_map/cave_map_prompts.dart';
import 'package:speleoloc/services/geo_transfer/geo_waypoint.dart';
import 'package:speleoloc/services/geo_transfer/geo_waypoint_reader.dart';
import 'package:speleoloc/services/geo_transfer/gpx_writer.dart';
import 'package:speleoloc/services/geo_transfer/kml_writer.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Exports located cave places as a GPX or KML file: format prompt →
/// system save dialog. [caveUuids] restricts the export (null/empty =
/// every cave), matching the home screen's selection semantics.
Future<void> exportPlacesFlow(
  BuildContext context,
  WidgetRef ref, {
  Set<Uuid>? caveUuids,
}) async {
  final loc = LocServ.inst;
  final waypoints = await ref
      .read(placeTransferServiceProvider)
      .collectWaypoints(caveUuids: caveUuids);
  if (!context.mounted) return;
  if (waypoints.isEmpty) {
    SnackBarService.showWarning(loc.t('transfer_no_places'));
    return;
  }

  final format = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.route),
            title: const Text('GPX'),
            subtitle: Text(loc.t('transfer_format_gpx_desc')),
            onTap: () => Navigator.pop(ctx, 'gpx'),
          ),
          ListTile(
            leading: const Icon(Icons.public),
            title: const Text('KML'),
            subtitle: Text(loc.t('transfer_format_kml_desc')),
            onTap: () => Navigator.pop(ctx, 'kml'),
          ),
        ],
      ),
    ),
  );
  if (format == null || !context.mounted) return;

  final text = format == 'gpx' ? writeGpx(waypoints) : writeKml(waypoints);
  final bytes = utf8.encode(text);
  try {
    final output = await FilePicker.platform.saveFile(
      dialogTitle: loc.t('save'),
      fileName: 'speleoloc_places.$format',
      bytes: bytes,
    );
    if (output == null || !context.mounted) return;
    // On desktop saveFile only picks the path; mobile writes the bytes.
    if (!Platform.isAndroid && !Platform.isIOS) {
      await File(output).writeAsBytes(bytes);
    }
    if (context.mounted) {
      SnackBarService.showSuccess(
        '${loc.t('files_saved')}: ${waypoints.length}',
      );
    }
  } catch (e) {
    if (context.mounted) {
      SnackBarService.showError('${loc.t('error')}: $e');
    }
  }
}

/// Imports GPX/KML waypoints as places of a chosen cave: file picker →
/// parse → cave chooser → import. Returns true when places were created
/// (so callers can refresh their lists).
Future<bool> importPlacesFlow(BuildContext context, WidgetRef ref) async {
  final loc = LocServ.inst;
  final FilePickerResult? picked;
  try {
    // FileType.any: Android's picker may not know the gpx/kml MIME types.
    picked = await FilePicker.platform.pickFiles(allowMultiple: false);
  } catch (e) {
    SnackBarService.showError('${loc.t('error')}: $e');
    return false;
  }
  final path = picked?.files.single.path;
  if (path == null || !context.mounted) return false;

  final List<GeoWaypoint> waypoints;
  try {
    waypoints = parseWaypoints(await File(path).readAsString());
  } on FormatException {
    if (context.mounted) {
      SnackBarService.showError(loc.t('transfer_import_unreadable'));
    }
    return false;
  }
  if (!context.mounted) return false;
  if (waypoints.isEmpty) {
    SnackBarService.showWarning(loc.t('transfer_import_none'));
    return false;
  }

  final caves = await ref.read(caveRepositoryProvider).getCaves()
    ..sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
  if (!context.mounted) return false;
  if (caves.isEmpty) {
    SnackBarService.showWarning(loc.t('map_no_caves_for_entrance'));
    return false;
  }
  final caveUuid = await showCaveChooser(context, caves);
  if (caveUuid == null || !context.mounted) return false;

  try {
    final result = await ref
        .read(placeTransferServiceProvider)
        .importWaypoints(
          caveUuid,
          waypoints,
          fallbackTitle: loc.t('transfer_waypoint'),
        );
    if (context.mounted) {
      SnackBarService.showSuccess(
        loc
            .t('transfer_import_done')
            .replaceAll('{created}', '${result.created}')
            .replaceAll('{skipped}', '${result.skipped}'),
      );
    }
    return result.created > 0;
  } catch (e) {
    if (context.mounted) {
      SnackBarService.showError('${loc.t('error')}: $e');
    }
    return false;
  }
}
