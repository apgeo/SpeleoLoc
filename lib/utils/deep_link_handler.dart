import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/qr_code_lookup_handler.dart';
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

  /// Resolve dl_input against place_code_identifier / qr_code_resource_identifier
  /// and navigate via the unified [QrCodeLookupHandler].
  ///
  /// Ambiguity policy is read from [deepLinkAmbiguityPolicyKey] settings.
  Future<void> _resolveAndNavigate(BuildContext context, String dlInput) async {
    final code = dlInput.trim();
    if (code.isEmpty) {
      _showWarning(context, '${LocServ.inst.t('invalid_qr_code')}: "$dlInput"');
      return;
    }

    final policy = await loadQrAmbiguityPolicy(QrLookupSource.deepLink);
    if (!context.mounted) return;

    await QrCodeLookupHandler.defaultInstance().handleScannedCode(
      context,
      code,
      ambiguityPolicy: policy,
      // Deep-link prefix has already been stripped in handleUri; skipping
      // the handler's own preprocessing avoids re-parsing the URL.
      preprocessPayload: false,
    );
  }

  /// Save the last opened cave ID to configurations.
  static Future<void> saveLastOpenCave(Uuid caveUuid) async {
    final existing = await (appDatabase.select(appDatabase.configurations)
          ..where((c) => c.title.equals(lastOpenCaveKey)))
        .getSingleOrNull();
    if (existing == null) {
      await appDatabase.into(appDatabase.configurations).insert(
          ConfigurationsCompanion.insert(
              title: lastOpenCaveKey,
              value: drift.Value(caveUuid.toString())));
    } else {
      await appDatabase.update(appDatabase.configurations).replace(
          Configuration(
              id: existing.id,
              title: lastOpenCaveKey,
              value: caveUuid.toString(),
              isSynced: existing.isSynced));
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
