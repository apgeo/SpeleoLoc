import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// Says why the controls above it are greyed out while a sync runs.
///
/// A disabled button alone reads as broken; the caver needs to know the
/// controls come back on their own once the run ends.
class SilexgisAfterSyncHint extends StatelessWidget {
  const SilexgisAfterSyncHint({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: <Widget>[
          Icon(Icons.hourglass_top, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LocServ.inst.t('silexgis_available_after_sync'),
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
