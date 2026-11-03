import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/services/sync/ftp/sftp_host_key.dart';
import 'package:speleoloc/utils/localization.dart';

/// Shows the host key an SFTP profile trusts, with the action that forgets
/// it. [hostKey] null means nothing is recorded yet; [unreadable] means the
/// record exists but could not be read, which also blocks connecting until
/// it is forgotten.
class SftpHostKeyTile extends StatelessWidget {
  final SftpHostKey? hostKey;
  final bool unreadable;
  final VoidCallback? onForget;

  const SftpHostKeyTile({
    super.key,
    required this.hostKey,
    this.unreadable = false,
    this.onForget,
  });

  static final _dateTimeFmt = DateFormat('yyyy/MM/dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final key = hostKey;
    final textTheme = Theme.of(context).textTheme;
    final canForget = key != null || unreadable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.t('ftp_host_key_title'), style: textTheme.titleSmall),
        const SizedBox(height: 4),
        if (key != null) ...[
          SelectableText(
            key.display,
            style: const TextStyle(fontFamily: 'monospace'),
          ),
          const SizedBox(height: 2),
          Text(
            loc.t('ftp_host_key_recorded_for', {
              'endpoint': key.endpoint,
              'date': _dateTimeFmt.format(key.recordedAt.toLocal()),
            }),
            style: textTheme.bodySmall,
          ),
        ] else
          Text(
            loc.t(unreadable ? 'ftp_host_key_unreadable' : 'ftp_host_key_none'),
            style: textTheme.bodySmall,
          ),
        if (canForget)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              icon: const Icon(Icons.key_off_outlined),
              label: Text(loc.t('ftp_host_key_forget')),
              onPressed: onForget,
            ),
          ),
      ],
    );
  }
}
