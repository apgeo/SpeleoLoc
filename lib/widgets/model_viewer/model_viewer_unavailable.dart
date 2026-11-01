import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// Shown where the platform has no WebView to draw the model in — the Linux
/// desktop build the UI tests run on.
class ModelViewerUnavailable extends StatelessWidget {
  const ModelViewerUnavailable({super.key});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.view_in_ar, size: 48),
          const SizedBox(height: 12),
          Text(
            LocServ.inst.t('model_viewer_unavailable'),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );
}
