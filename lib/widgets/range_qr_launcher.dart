import 'package:flutter/material.dart';
import 'package:speleoloc/screens/generated_qr_code_viewer.dart';
import 'package:speleoloc/services/range_code_generator.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Presents a [RangeCodeResult]: shows an explanatory toast for the
/// empty / error statuses, or opens [GeneratedQRCodeViewer] for the
/// generated codes. When some indices were skipped (already recorded), a
/// brief info toast reports the count first.
///
/// The caller must confirm its [context] is still mounted before invoking.
Future<void> presentRangeCodeResult(
  BuildContext context,
  RangeCodeResult result,
) async {
  switch (result.status) {
    case RangeCodeStatus.unsupportedStrategy:
      SnackBarService.showWarning(
        LocServ.inst.t('qr_range_unsupported_strategy'),
      );
    case RangeCodeStatus.missingDatasetConfig:
      SnackBarService.showWarning(LocServ.inst.t('qr_range_missing_dataset'));
    case RangeCodeStatus.missingCaveIndex:
      SnackBarService.showWarning(
        LocServ.inst.t('qr_range_missing_cave_index'),
      );
    case RangeCodeStatus.empty:
      SnackBarService.showInfo(LocServ.inst.t('qr_range_none'));
    case RangeCodeStatus.ok:
      if (result.skipped > 0) {
        SnackBarService.showInfo(
          '${result.skipped} ${LocServ.inst.t('qr_range_skipped')}',
        );
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GeneratedQRCodeViewer(cavePlaces: result.places),
        ),
      );
  }
}
