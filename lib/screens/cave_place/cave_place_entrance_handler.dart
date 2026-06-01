import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/utils/localization.dart';

/// Static helpers that drive the "confirm entrance-flag toggle" dialogue flows
/// for [CavePlacePage].
///
/// The page delegates to these methods and applies [CavePlaceFormController]
/// mutations via `setState` only after receiving `true` back.
class CavePlaceEntranceHandler {
  const CavePlaceEntranceHandler._();

  // ── Entrance flag ─────────────────────────────────────────────────────────

  /// Returns `true` when the entrance flag should be **set** (user confirmed
  /// and there were no blocking conditions).
  static Future<bool> confirmEnableEntrance(
    BuildContext context, {
    required ICavePlaceRepository repository,
    required Uuid caveUuid,
    required Uuid? excludeUuid,
  }) async {
    final ok = await _confirm(
      context,
      titleKey: 'confirm',
      bodyKey: 'confirm_mark_as_entrance',
    );
    if (ok != true || !context.mounted) return false;

    final others = await repository.findEntrances(
      caveUuid,
      mainOnly: false,
      excludeUuid: excludeUuid,
    );
    if (others.isNotEmpty && context.mounted) {
      final names = others.map((e) => e.title).join(', ');
      final cont = await _confirm(
        context,
        titleKey: 'other_entrances_defined_title',
        body: LocServ.inst
            .t('other_entrances_defined_body')
            .replaceAll('{names}', names),
      );
      if (cont != true) return false;
    }
    return context.mounted;
  }

  /// Returns `true` when the entrance flag should be **cleared**.
  static Future<bool> confirmDisableEntrance(BuildContext context) async {
    final ok = await _confirm(
      context,
      titleKey: 'confirm',
      bodyKey: 'confirm_unmark_as_entrance',
    );
    return ok == true;
  }

  // ── Main-entrance flag ────────────────────────────────────────────────────

  /// Returns `true` when the main-entrance flag should be **set**.
  ///
  /// Returns `false` when an informational "already defined" alert was shown
  /// (another main entrance exists) or when the user cancelled.
  static Future<bool> confirmEnableMainEntrance(
    BuildContext context, {
    required ICavePlaceRepository repository,
    required Uuid caveUuid,
    required Uuid? excludeUuid,
  }) async {
    final ok = await _confirm(
      context,
      titleKey: 'confirm',
      bodyKey: 'confirm_mark_as_main_entrance',
    );
    if (ok != true || !context.mounted) return false;

    final otherMains = await repository.findEntrances(
      caveUuid,
      mainOnly: true,
      excludeUuid: excludeUuid,
    );
    if (otherMains.isNotEmpty && context.mounted) {
      final names = otherMains.map((e) => e.title).join(', ');
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(LocServ.inst.t('main_entrance_already_defined_title')),
          content: Text(
            LocServ.inst
                .t('main_entrance_already_defined_body')
                .replaceAll('{names}', names),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(LocServ.inst.t('ok')),
            ),
          ],
        ),
      );
      return false; // informational only — do not apply the flag change
    }
    return context.mounted;
  }

  /// Returns `true` when the main-entrance flag should be **cleared**.
  static Future<bool> confirmDisableMainEntrance(BuildContext context) async {
    final ok = await _confirm(
      context,
      titleKey: 'confirm',
      bodyKey: 'confirm_unmark_as_main_entrance',
    );
    return ok == true;
  }

  // ── Private helpers ───────────────────────────────────────────────────────

  static Future<bool?> _confirm(
    BuildContext context, {
    required String titleKey,
    String? bodyKey,
    String? body,
  }) {
    assert(bodyKey != null || body != null, 'Provide bodyKey or body');
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t(titleKey)),
        content: Text(body ?? LocServ.inst.t(bodyKey!)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('yes')),
          ),
        ],
      ),
    );
  }
}
