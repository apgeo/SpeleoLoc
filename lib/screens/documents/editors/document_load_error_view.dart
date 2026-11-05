import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// Shown in place of an editor whose stored document could not be read.
///
/// The editor offers no Save while this is shown: an empty editor saved
/// over the stored file would replace content that may only be missing on
/// this phone, and the sync would hand the empty version to everyone.
class DocumentLoadErrorView extends StatelessWidget {
  const DocumentLoadErrorView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 12),
            Text(
              LocServ.inst.t('document_load_failed_title'),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              LocServ.inst.t('document_load_failed_body'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
