import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// Banner over the surface map when its online tiles are not arriving, so a
/// blank map reads as "offline" rather than "broken" and points to the
/// offline map files that work without a connection.
class CaveMapTilesNotice extends StatelessWidget {
  const CaveMapTilesNotice({
    super.key,
    required this.onOpenMapSettings,
    required this.onDismiss,
  });

  final VoidCallback onOpenMapSettings;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      container: true,
      child: Material(
        color: scheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
          child: Row(
            children: [
              Icon(Icons.cloud_off, color: scheme.onSecondaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.t('map_tiles_unavailable'),
                      style: TextStyle(color: scheme.onSecondaryContainer),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onOpenMapSettings,
                        child: Text(loc.t('map_tiles_open_settings')),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: loc.t('close'),
                icon: const Icon(Icons.close),
                color: scheme.onSecondaryContainer,
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
