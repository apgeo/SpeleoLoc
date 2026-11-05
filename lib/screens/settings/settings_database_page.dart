import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speleoloc/services/database_restore_helper.dart';
import 'package:speleoloc/services/storage/database_file_export_service.dart';
import 'package:speleoloc/utils/build_config.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/screens/dialogs/confirm_dialog.dart';
import 'package:speleoloc/screens/settings/database_file_error_text.dart';
import 'package:speleoloc/screens/settings/sql_command_runner.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';
import 'package:speleoloc/providers/database_swap_providers.dart';
import 'package:speleoloc/providers/providers.dart';

/// Database management settings: reinitialize, export.
class SettingsDatabasePage extends ConsumerStatefulWidget {
  const SettingsDatabasePage({super.key});

  @override
  ConsumerState<SettingsDatabasePage> createState() =>
      _SettingsDatabasePageState();
}

class _SettingsDatabasePageState extends ConsumerState<SettingsDatabasePage>
    with
        AppBarMenuMixin<SettingsDatabasePage>,
        ProductTourMixin<SettingsDatabasePage> {
  @override
  String get tourId => 'settings_db';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(
      keyId: 'list',
      titleLocKey: 'tour_settings_db_list_title',
      bodyLocKey: 'tour_settings_db_list_body',
    ),
    TourStepDef(
      keyId: 'menu',
      titleLocKey: 'tour_settings_db_menu_title',
      bodyLocKey: 'tour_settings_db_menu_body',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('settings_database')),
        actions: [
          KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton()),
        ],
      ),
      body: ListView(
        key: tourKeys['list'],
        padding: const EdgeInsets.all(16),
        children: [
          // Dev tooling: the loader reads test_data/* assets that store
          // builds do not bundle, so the button is compiled out with the
          // dev-tools switch.
          if (BuildConfig.devToolsEnabled) ...[
            ElevatedButton.icon(
              onPressed: () =>
                  _reinitializeDatabase(context, populateTestData: true),
              icon: const Icon(Icons.refresh),
              label: Text(LocServ.inst.t('reinitialize_db_with_test_data')),
            ),
            const SizedBox(height: 8),
          ],
          ElevatedButton.icon(
            onPressed: () =>
                _reinitializeDatabase(context, populateTestData: false),
            icon: const Icon(Icons.refresh_outlined),
            label: Text(LocServ.inst.t('reinitialize_db')),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _restoreDatabaseFromExternalFile(context),
            icon: const Icon(Icons.restore_page),
            label: Text(LocServ.inst.t('restore_db_from_file')),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () => _exportDatabase(context),
            icon: const Icon(Icons.upload_file),
            label: Text(LocServ.inst.t('export_db')),
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: debugModeNotifier,
            builder: (context, debugMode, _) {
              // Raw SQL against the live DB is a dev tool: store builds
              // compile it out entirely; dev builds still require the
              // 9-tap runtime debug unlock.
              if (!debugMode || !BuildConfig.devToolsEnabled) {
                return const SizedBox.shrink();
              }
              return ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SQLCommandRunner()),
                  );
                },
                icon: const Icon(Icons.code),
                label: Text(LocServ.inst.t('open_sql_command_runner')),
              );
            },
          ),
        ],
      ),
    );
  }

  void _reinitializeDatabase(
    BuildContext context, {
    bool populateTestData = true,
  }) async {
    if (_refuseWhileSyncRuns()) return;
    final confirmKey = populateTestData
        ? 'confirm_reinitialize_database'
        : 'confirm_reinitialize_database_empty';
    final reconfirmKey = populateTestData
        ? 'reconfirm_reinitialize_database'
        : 'reconfirm_reinitialize_database_empty';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(text: LocServ.inst.t(confirmKey)),
    );

    if (confirmed != true) return;

    if (!context.mounted) return;
    final confirmed2 = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(text: LocServ.inst.t(reconfirmKey)),
    );

    if (confirmed == true && confirmed2 == true) {
      var progressShown = false;
      try {
        if (context.mounted) {
          progressShown = true;
          unawaited(
            showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      populateTestData
                          ? LocServ.inst.t('reinitialize_db_with_test_data')
                          : LocServ.inst.t('reinitialize_db'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        await DatabaseRestoreHelper.reinitializeDatabase(
          populateTestData: populateTestData,
          swap: ref.read(liveDatabaseSwapProvider),
        );

        if (context.mounted) {
          Navigator.pop(context);
          SnackBarService.showSuccess(
            populateTestData
                ? LocServ.inst.t('database_reinitialized')
                : LocServ.inst.t('database_reinitialized_empty'),
          );
        }

        await DatabaseRestoreHelper.restartApplication();
      } catch (e) {
        if (context.mounted) {
          if (progressShown) Navigator.pop(context);
          SnackBarService.showError(
            '${LocServ.inst.t('error_reinitializing_database')}: '
            '${databaseFileErrorText(e)}',
          );
        }
      }
    }
  }

  Future<void> _restoreDatabaseFromExternalFile(BuildContext context) async {
    if (_refuseWhileSyncRuns()) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        text: LocServ.inst.t('confirm_restore_database_from_file'),
      ),
    );
    if (confirmed != true) return;

    var progressShown = false;
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['sqlite', 'db'],
      );
      if (result == null || result.files.single.path == null) return;

      if (context.mounted) {
        progressShown = true;
        unawaited(
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(LocServ.inst.t('restoring_database_from_file')),
                ],
              ),
            ),
          ),
        );
      }

      await ref
          .read(databaseFileRestoreProvider)
          .restoreFrom(File(result.files.single.path!));

      if (context.mounted) {
        Navigator.pop(context);
        SnackBarService.showSuccess(LocServ.inst.t('database_restored'));
      }

      await DatabaseRestoreHelper.restartApplication();
    } catch (e) {
      if (context.mounted) {
        // The picker can throw before the progress dialog is up, and a pop
        // then would close this page instead.
        if (progressShown) Navigator.pop(context);
        SnackBarService.showError(
          '${LocServ.inst.t('database_restore_failed')}: '
          '${databaseFileErrorText(e)}',
        );
      }
    }
  }

  /// Shows why the database cannot be replaced now and returns true while a
  /// sync run is writing to it.
  bool _refuseWhileSyncRuns() {
    if (!ref.read(liveDatabaseSwapProvider).isSyncRunning) return false;
    SnackBarService.showWarning(LocServ.inst.t('database_swap_sync_running'));
    return true;
  }

  void _exportDatabase(BuildContext context) async {
    try {
      final saved = await const DatabaseFileExportService().exportSnapshot(
        ref.read(appDatabaseProvider),
        folderDialogTitle: LocServ.inst.t('select_folder_save_database'),
        saveDialogTitle: LocServ.inst.t('save_database_file'),
      );
      if (saved != null && context.mounted) {
        SnackBarService.showSuccess(
          '${LocServ.inst.t('database_export_success')}: $saved',
        );
      }
    } on DatabaseFileMissingException {
      if (context.mounted) {
        SnackBarService.showWarning(LocServ.inst.t('database_file_not_found'));
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarService.showError(
          '${LocServ.inst.t('database_export_failed')}: $e',
        );
      }
    }
  }
}
