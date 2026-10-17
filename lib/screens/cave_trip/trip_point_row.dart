import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';

/// One recorded point on the trip screen: its order, place, time and
/// depth, the pictures bound to it, and the edits it offers.
///
/// Extracted from the trip screen so the row can be laid out and tested on
/// its own: it is where a narrow phone is most likely to run out of width,
/// with a picture count, a depth and a menu all beside the place's name.
class TripPointRow extends StatelessWidget {
  const TripPointRow({
    super.key,
    required this.ordinal,
    required this.point,
    required this.place,
    required this.timeLabel,
    required this.pictureCount,
    required this.onOpenPlace,
    required this.onShowPictures,
    required this.onEditTime,
    required this.onDelete,
  });

  /// Position on the trip, from 1.
  final int ordinal;
  final CaveTripPoint point;

  /// Null when the place was deleted after the point was recorded.
  final CavePlace? place;
  final String timeLabel;

  /// Documents bound to this point, usually the pictures it was added from.
  final int pictureCount;

  /// Null when there is no place left to open.
  final VoidCallback? onOpenPlace;
  final VoidCallback onShowPictures;
  final VoidCallback onEditTime;
  final VoidCallback onDelete;

  String get title => place?.title ?? '#${point.cavePlaceUuid}';

  @override
  Widget build(BuildContext context) {
    final depth = place?.depthInCave;
    // Dense, but not squeezed below it: the tightest density capped the row
    // at 32 dp, and with it every control in it — under Android's 48 dp
    // minimum for something a gloved finger has to hit.
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: CircleAvatar(
        radius: 14,
        child: Text('$ordinal', style: const TextStyle(fontSize: 12)),
      ),
      title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Text(timeLabel, style: const TextStyle(fontSize: 11)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pictureCount > 0)
            IconButton(
              tooltip: LocServ.inst.t('trip_point_pictures', {
                'n': '$pictureCount',
              }),
              onPressed: onShowPictures,
              icon: Badge(
                label: Text('$pictureCount'),
                // Not the photo-library icon: the trip screen's toolbar
                // uses that for adding points from pictures, and one icon
                // for two different actions on one screen reads as one.
                child: const Icon(Icons.image_outlined, size: 20),
              ),
            ),
          if (depth != null)
            Text(
              '${depth > 0 ? '+' : ''}${depth}m',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 20),
            tooltip: LocServ.inst.t('trip_point_actions'),
            onSelected: (value) {
              if (value == 'edit_time') {
                onEditTime();
              } else if (value == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'edit_time',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.schedule),
                  title: Text(LocServ.inst.t('trip_point_edit_time')),
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.delete_outline),
                  title: Text(LocServ.inst.t('trip_point_delete')),
                ),
              ),
            ],
          ),
        ],
      ),
      onTap: onOpenPlace,
    );
  }
}
