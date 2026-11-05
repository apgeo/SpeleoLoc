import 'package:speleoloc/services/database_swap/live_database_swap.dart';
import 'package:speleoloc/services/storage/database_file_export_service.dart';
import 'package:speleoloc/utils/localization.dart';

/// The two ways out of a failed start that touch the caver's data.
abstract interface class StartupRecovery {
  /// Saves a copy of the database file where the caver picks. Returns where
  /// it went, or null when the caver cancelled.
  Future<String?> exportDatabase();

  /// Deletes the database so the next start begins empty.
  Future<void> resetAppData();
}

class DatabaseStartupRecovery implements StartupRecovery {
  const DatabaseStartupRecovery(
    this._swap, {
    DatabaseFileExportService exporter = const DatabaseFileExportService(),
  }) : _exporter = exporter;

  final LiveDatabaseSwap _swap;
  final DatabaseFileExportService _exporter;

  @override
  Future<String?> exportDatabase() async => _exporter.export(
    await _swap.liveDatabaseFile(),
    folderDialogTitle: LocServ.inst.t('select_folder_save_database'),
    saveDialogTitle: LocServ.inst.t('save_database_file'),
  );

  @override
  Future<void> resetAppData() => _swap.discardLiveDatabase();
}
