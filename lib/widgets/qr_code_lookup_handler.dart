import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/qr_code_lookup_service.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Handles the full QR code lookup flow: searches for matching cave places,
/// shows a disambiguation dialog if multiple results are found, and navigates
/// to the selected cave place.
class QrCodeLookupHandler {
  final QrCodeLookupService _service;

  QrCodeLookupHandler(this._service);

  /// Looks up [rawCode], shows a disambiguation popup if needed, and navigates
  /// to [MapViewerPage] via the named route.
  ///
  /// [currentCaveId] restricts the search to a single cave when provided.
  /// Returns the [CavePlace] that was opened, or `null` if none was found/selected.
  Future<CavePlace?> handleScannedCode(
    BuildContext context,
    String rawCode, {
    Uuid? currentCaveId,
  }) async {
    final results = await _service.lookup(rawCode, currentCaveId: currentCaveId);

    if (results.isEmpty) {
      SnackBarService.showWarning('${LocServ.inst.t('cave_place_not_found')}: \'$rawCode\'');
      return null;
    }

    QrLookupResult selected;
    if (results.length == 1) {
      selected = results.first;
    } else {
      // Multiple matches — ask user which one to open
      final choice = await _showDisambiguationDialog(context, results);
      if (choice == null) return null;
      selected = choice;
    }

    if (!context.mounted) return null;

    await Navigator.pushNamed(
      context,
      cavePlaceViewRoute,
      arguments: {
        'caveUuid': selected.cavePlace.caveUuid,
        'cavePlaceUuid': selected.cavePlace.uuid,
      },
    );

    return selected.cavePlace;
  }

  Future<QrLookupResult?> _showDisambiguationDialog(
    BuildContext context,
    List<QrLookupResult> results,
  ) {
    return showDialog<QrLookupResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('multiple_qr_matches')),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(LocServ.inst.t('multiple_qr_matches_explanation')),
                const SizedBox(height: 8),
                ...List.generate(results.length, (i) {
                  final r = results[i];
                  final tile = ListTile(
                    title: Text(r.cavePlace.title),
                    subtitle: Text(r.caveTitle),
                    leading: const Icon(Icons.place),
                    onTap: () => Navigator.pop(ctx, r),
                  );
                  return i == 0
                      ? tile
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [const Divider(height: 1), tile],
                        );
                }),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocServ.inst.t('cancel')),
          ),
        ],
      ),
    );
  }
}
