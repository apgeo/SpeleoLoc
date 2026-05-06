import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:file_picker/file_picker.dart';
import 'package:speleoloc/utils/database_restore_helper.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/screens/dialogs/confirm_dialog.dart';
import 'package:speleoloc/screens/settings/sql_command_runner.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Database management settings: reinitialize, export.
class SettingsDatabasePage extends StatefulWidget {
  const SettingsDatabasePage({super.key});

  @override
  State<SettingsDatabasePage> createState() => _SettingsDatabasePageState();
}

class _SettingsDatabasePageState extends State<SettingsDatabasePage>
    with AppBarMenuMixin<SettingsDatabasePage>, ProductTourMixin<SettingsDatabasePage> {
  @override
  String get tourId => 'settings_db';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'list', titleLocKey: 'tour_settings_db_list_title', bodyLocKey: 'tour_settings_db_list_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_settings_db_menu_title', bodyLocKey: 'tour_settings_db_menu_body'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('settings_database')),
        actions: [KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton())],
      ),
      body: ListView(
        key: tourKeys['list'],
        padding: const EdgeInsets.all(16),
        children: [
          ElevatedButton.icon(
            onPressed: () =>
                _reinitializeDatabase(context, populateTestData: true),
            icon: const Icon(Icons.refresh),
            label: Text(LocServ.inst.t('reinitialize_db_with_test_data')),
          ),
          const SizedBox(height: 8),
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
              if (!debugMode) return const SizedBox.shrink();
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

  void _reinitializeDatabase(BuildContext context,
      {bool populateTestData = true}) async {
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

    if (!mounted) return;
    final confirmed2 = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(text: LocServ.inst.t(reconfirmKey)),
    );

    if (confirmed == true && confirmed2 == true) {
      try {
        if (context.mounted) {
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(populateTestData
                      ? LocServ.inst.t('reinitialize_db_with_test_data')
                      : LocServ.inst.t('reinitialize_db')),
                ],
              ),
            ),
          );
        }

        await DatabaseRestoreHelper.reinitializeDatabase(
          populateTestData: populateTestData,
        );

        if (context.mounted) {
          Navigator.pop(context);
          SnackBarService.showSuccess(populateTestData
                    ? LocServ.inst.t('database_reinitialized')
                    : LocServ.inst.t('database_reinitialized_empty'));
        }

        await DatabaseRestoreHelper.restartApplication();
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          SnackBarService.showError('${LocServ.inst.t('error_reinitializing_database')}: $e');
        }
      }
    }
  }

  Future<void> _restoreDatabaseFromExternalFile(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDialog(
        text: LocServ.inst.t('confirm_restore_database_from_file'),
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: const ['sqlite', 'db'],
      );
      if (result == null || result.files.single.path == null) return;

      if (context.mounted) {
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
        );
      }

      await appDatabase.close();
      final directory = await getApplicationDocumentsDirectory();
      final targetPath = '${directory.path}/speleo_loc.sqlite';
      final pickedPath = result.files.single.path!;

      final targetFile = File(targetPath);
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
      await File(pickedPath).copy(targetPath);

      appDatabase = AppDatabase();
      DatabaseRestoreHelper.logMigrationIfAny(source: 'external-database-restore');

      if (context.mounted) {
        Navigator.pop(context);
        SnackBarService.showSuccess(LocServ.inst.t('database_restored'));
      }

      await DatabaseRestoreHelper.restartApplication();
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        SnackBarService.showError('${LocServ.inst.t('database_restore_failed')}: $e');
      }
    }
  }

  void _exportDatabase(BuildContext context) async {
    final directory = await getApplicationDocumentsDirectory();
    final sourceFile = File('${directory.path}/speleo_loc.sqlite');
    if (!await sourceFile.exists()) {
      if (context.mounted) {
        SnackBarService.showWarning(LocServ.inst.t('database_file_not_found'));
      }
      return;
    }

    String? outputFile;
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final dir = await FilePicker.platform.getDirectoryPath(
            dialogTitle: LocServ.inst.t('select_folder_save_database'));
        if (dir == null) return;
        outputFile = '$dir/speleo_loc_export.sqlite';
      } else {
        outputFile = await FilePicker.platform.saveFile(
          dialogTitle: LocServ.inst.t('save_database_file'),
          fileName: 'speleo_loc_export.sqlite',
        );
      }

      if (outputFile != null) {
        await sourceFile.copy(outputFile);
        if (context.mounted) {
          SnackBarService.showSuccess('${LocServ.inst.t('database_export_success')}: $outputFile');
        }
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarService.showError('${LocServ.inst.t('database_export_failed')}: $e');
      }
    }
  }
}

