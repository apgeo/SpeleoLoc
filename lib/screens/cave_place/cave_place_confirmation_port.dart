import 'package:flutter/material.dart';
import 'package:speleoloc/screens/cave_place/cave_place_save_command.dart';
import 'package:speleoloc/utils/localization.dart';

/// Bridges [CavePlaceSaveCommand]'s confirmation prompts to
/// [showDialog] / [LocServ] calls on a hosting [State].
///
/// The hosting page (or any [State]) is held by reference so the port
/// can read [State.mounted] and [State.context] for each prompt — no
/// state mutation happens here. Implementing this class instead of
/// passing it [BuildContext] keeps `mounted` checks centralised.
class PageCavePlaceConfirmationPort implements CavePlaceConfirmationPort {
  PageCavePlaceConfirmationPort(this._state);
  final State<StatefulWidget> _state;

  Future<bool> _ask({
    required String title,
    required String content,
    String yesKey = 'yes',
    String noKey = 'cancel',
  }) async {
    if (!_state.mounted) return false;
    final result = await showDialog<bool>(
      context: _state.context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t(noKey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t(yesKey)),
          ),
        ],
      ),
    );
    return result == true;
  }

  @override
  Future<bool> confirmExtremeDepth(String formattedDepth) {
    return _ask(
      title: LocServ.inst.t('confirm'),
      content: LocServ.inst
          .t('depth_outlier_confirm')
          .replaceAll('{depth}', formattedDepth),
    );
  }

  @override
  Future<bool> confirmDuplicatePci({
    required String otherTitle,
    required String qr,
  }) {
    return _ask(
      title: LocServ.inst.t('duplicate_qr_warning'),
      content: LocServ.inst
          .t('duplicate_qr_message')
          .replaceAll('{title}', otherTitle)
          .replaceAll('{qr}', qr),
    );
  }

  @override
  Future<bool> confirmDuplicateQcri({
    required String otherTitle,
    required String qcri,
  }) {
    return _ask(
      title: LocServ.inst.t('duplicate_qr_warning'),
      content: LocServ.inst
          .t('duplicate_qr_message')
          .replaceAll('{title}', otherTitle)
          .replaceAll('{qr}', qcri),
    );
  }

  @override
  Future<bool> askIsEntrance(String title) async {
    final detectorWord = LocServ.inst.t('entrance_detector_text');
    if (title.toLowerCase().trim() != detectorWord.toLowerCase()) {
      return false;
    }
    return _ask(
      title: LocServ.inst.t('is_cave_entrance'),
      content: LocServ.inst
          .t('entrance_detected_in_title')
          .replaceAll('{word}', detectorWord),
      yesKey: 'yes',
      noKey: 'no',
    );
  }

  @override
  Future<bool> askIsMainEntrance() {
    return _ask(
      title: LocServ.inst.t('is_main_cave_entrance'),
      content: LocServ.inst.t('confirm_mark_as_main_entrance'),
      yesKey: 'yes',
      noKey: 'no',
    );
  }
}
