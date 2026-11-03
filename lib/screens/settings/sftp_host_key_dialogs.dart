import 'package:flutter/material.dart';
import 'package:speleoloc/services/sync/ftp/sftp_host_key.dart';
import 'package:speleoloc/utils/localization.dart';

/// Asks whether to trust [presented], an SFTP server's host key seen for the
/// first time. [previous] is the key it replaces after the profile's address
/// was edited. Resolves to false when dismissed.
Future<bool> confirmTrustSftpHostKey(
  BuildContext context,
  SftpHostKey presented,
  SftpHostKey? previous,
) async {
  final loc = LocServ.inst;
  final trusted = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text(loc.t('ftp_host_key_first_use_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.t('ftp_host_key_first_use_body', {
                'endpoint': presented.endpoint,
              }),
            ),
            const SizedBox(height: 8),
            SelectableText(
              presented.display,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            if (previous != null) ...[
              const SizedBox(height: 8),
              Text(
                loc.t('ftp_host_key_first_use_replaces', {
                  'endpoint': previous.endpoint,
                }),
              ),
            ],
            const SizedBox(height: 8),
            Text(loc.t('ftp_host_key_first_use_hint')),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(loc.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(loc.t('ftp_host_key_trust')),
        ),
      ],
    ),
  );
  return trusted ?? false;
}

/// Confirms dropping a profile's trusted host key.
Future<bool> confirmForgetSftpHostKey(BuildContext context) async {
  final loc = LocServ.inst;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(loc.t('ftp_host_key_forget')),
      content: Text(loc.t('ftp_host_key_forget_confirm')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(loc.t('cancel')),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(loc.t('ftp_host_key_forget')),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
