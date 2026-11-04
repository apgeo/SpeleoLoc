import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// Shown in the profile editor for a profile stored with FTPS, which no
/// longer connects: says why and how to move the profile to SFTP.
class FtpsUnsupportedNotice extends StatelessWidget {
  const FtpsUnsupportedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_outlined, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc.t('ftp_ftps_unsupported'),
                  style: textTheme.titleSmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loc.t('ftp_ftps_unsupported_desc'),
                  style: textTheme.bodySmall?.copyWith(
                    color: scheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
