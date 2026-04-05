import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/map_viewer_page.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:drift/drift.dart' as drift;

/// Handles deep links in the "sp://<dl_input>" format.
///
/// Matches dl_input against place_qr_code_identifier in all caves.
/// If multiple matches, uses the last open cave (stored in settings).
class DeepLinkHandler {
  DeepLinkHandler._();
  static final DeepLinkHandler instance = DeepLinkHandler._();

  GlobalKey<NavigatorState>? _navigatorKey;
  static const _channel = MethodChannel('speleoloc/deep_link');
  StreamSubscription? _linkSub;

  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    // Listen for incoming deep links via platform channel
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeepLink') {
        final String uri = call.arguments as String;
        handleUri(uri);
      }
    });
  }

  void dispose() {
    _linkSub?.cancel();
  }

  /// Process a deep link URI string.
  /// Can be called externally (e.g., from QR scan or manual input).
  Future<void> handleUri(String uri) async {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    String? dlInput;
    if (uri.startsWith(deepLinkPrefix)) {
      dlInput = uri.substring(deepLinkPrefix.length);
    } else if (uri.startsWith('sp://')) {
      dlInput = uri.substring(5);
    } else {
      dlInput = uri;
    }

    if (dlInput.isEmpty) return;

    await _resolveAndNavigate(context, dlInput);
  }

  /// Resolve dl_input against place_qr_code_identifier and navigate.
  Future<void> _resolveAndNavigate(BuildContext context, String dlInput) async {
    final qrCode = int.tryParse(dlInput);
    if (qrCode == null) {
      _showWarning(context, '${LocServ.inst.t('invalid_qr_code')}: "$dlInput"');
      return;
    }

    // Find all cave places matching the QR code identifier across all caves
    final matches = await (appDatabase.select(appDatabase.cavePlaces)
          ..where((cp) => cp.placeQrCodeIdentifier.equals(qrCode)))
        .get();

    if (matches.isEmpty) {
      _showWarning(context,
          '${LocServ.inst.t('cave_place_not_found')}: "$dlInput"');
      return;
    }

    CavePlace target;
    if (matches.length == 1) {
      target = matches.first;
    } else {
      // Multiple matches — prefer the last open cave
      final lastCaveId = await _getLastOpenCaveId();
      final inLastCave =
          matches.where((cp) => cp.caveId == lastCaveId).toList();
      if (inLastCave.isNotEmpty) {
        target = inLastCave.first;
      } else {
        target = matches.first;
      }
    }

    // Navigate to the cave place via MapViewerPage (same behavior as QR scan)
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => MapViewerPage(cavePlaceId: target.id),
        ),
      );
    }
  }

  Future<int?> _getLastOpenCaveId() async {
    final row = await (appDatabase.select(appDatabase.configurations)
          ..where((c) => c.title.equals(lastOpenCaveKey)))
        .getSingleOrNull();
    if (row?.value != null) {
      return int.tryParse(row!.value!);
    }
    return null;
  }

  /// Save the last opened cave ID to configurations.
  static Future<void> saveLastOpenCave(int caveId) async {
    final existing = await (appDatabase.select(appDatabase.configurations)
          ..where((c) => c.title.equals(lastOpenCaveKey)))
        .getSingleOrNull();
    if (existing == null) {
      await appDatabase.into(appDatabase.configurations).insert(
          ConfigurationsCompanion.insert(
              title: lastOpenCaveKey,
              value: drift.Value(caveId.toString())));
    } else {
      await appDatabase.update(appDatabase.configurations).replace(
          Configuration(
              id: existing.id,
              title: lastOpenCaveKey,
              value: caveId.toString()));
    }
  }

  void _showWarning(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 48),
        title: Text(LocServ.inst.t('deep_link_warning')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(LocServ.inst.t('ok')),
          ),
        ],
      ),
    );
  }
}
