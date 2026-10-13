import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_assignment.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';
import 'package:speleoloc/utils/localization.dart';

/// One row of the trip-media list: a preview, the capture moment, and the
/// cave place the item has been assigned to.
///
/// The row is only selectable once a place is known — a track point without
/// a place is not a thing this screen can create — so the checkbox stays
/// disabled until then.
class TripMediaTile extends StatelessWidget {
  const TripMediaTile({
    super.key,
    required this.item,
    required this.assignment,
    required this.thumbnail,
    required this.localFile,
    required this.onPickPlace,
    required this.onEditTime,
    required this.onToggleSelected,
    required this.onClear,
  });

  final TripMediaItem item;
  final TripMediaAssignment? assignment;

  /// Platform-decoded thumbnail bytes, when the source produced any.
  final Uint8List? thumbnail;

  /// Fallback preview for sources with no thumbnailer (picked stills).
  final File? localFile;

  final VoidCallback onPickPlace;
  final VoidCallback onEditTime;
  final ValueChanged<bool> onToggleSelected;
  final VoidCallback onClear;

  static final _timeFmt = DateFormat('yyyy/MM/dd HH:mm:ss');

  @override
  Widget build(BuildContext context) {
    final a = assignment;
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      leading: _buildPreview(context),
      title: Text(
        a?.place.title ?? LocServ.inst.t('trip_media_no_place'),
        style: TextStyle(
          fontWeight: a != null ? FontWeight.bold : FontWeight.normal,
          color: a != null ? null : scheme.onSurfaceVariant,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.schedule, size: 12, color: scheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                _timeFmt.format(a?.at ?? item.capturedAt),
                style: const TextStyle(fontSize: 11),
              ),
              if (item.capturedAtSource == MediaTimeSource.fileModified) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: LocServ.inst.t('trip_media_time_from_file_hint'),
                  child: const Icon(
                    Icons.help_outline,
                    size: 12,
                    color: Colors.orange,
                  ),
                ),
              ],
            ],
          ),
          if (a?.fromQrCode == true)
            Row(
              children: [
                const Icon(Icons.qr_code_2, size: 12, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  LocServ.inst.t('trip_media_from_qr'),
                  style: const TextStyle(fontSize: 11, color: Colors.green),
                ),
              ],
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.place_outlined, size: 20),
            tooltip: LocServ.inst.t('trip_media_pick_place'),
            visualDensity: VisualDensity.compact,
            onPressed: onPickPlace,
          ),
          if (a != null)
            IconButton(
              icon: const Icon(Icons.schedule, size: 20),
              tooltip: LocServ.inst.t('trip_point_edit_time'),
              visualDensity: VisualDensity.compact,
              onPressed: onEditTime,
            ),
          if (a != null)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              tooltip: LocServ.inst.t('trip_media_clear_place'),
              visualDensity: VisualDensity.compact,
              onPressed: onClear,
            ),
          Checkbox(
            value: a?.selected ?? false,
            onChanged: a == null ? null : (v) => onToggleSelected(v ?? false),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    const size = 48.0;
    final bytes = thumbnail;
    Widget image;
    if (bytes != null) {
      image = Image.memory(bytes, width: size, height: size, fit: BoxFit.cover);
    } else if (localFile != null && item.isPhoto) {
      image = Image.file(
        localFile!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(context, size),
      );
    } else {
      image = _placeholder(context, size);
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(4), child: image),
          if (item.kind == TripMediaKind.video)
            const Align(
              alignment: Alignment.bottomRight,
              child: Icon(
                Icons.videocam,
                size: 14,
                color: Colors.white,
                shadows: [Shadow(blurRadius: 3)],
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context, double size) {
    return Container(
      width: size,
      height: size,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        item.kind == TripMediaKind.video ? Icons.movie : Icons.image,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
