import 'package:flutter/material.dart';
import 'package:speleoloc/services/startup/startup_failure.dart';
import 'package:speleoloc/services/startup/startup_recovery.dart';
import 'package:speleoloc/services/storage/database_file_export_service.dart';
import 'package:speleoloc/utils/localization.dart';

enum _ResetChoice { exportFirst, delete }

/// Shown in place of the app when it could not start, so the caver is never
/// left on the splash screen: says what went wrong, and offers to save the
/// database, try again, or, when the database is what does not open, start
/// over.
class StartupFailurePage extends StatefulWidget {
  const StartupFailurePage({
    super.key,
    required this.error,
    required this.onRetry,
    required this.recovery,
  });

  final Object error;

  /// Runs the start-up again; replaces this page with the app when it
  /// succeeds, and throws what failed when it does not.
  final Future<void> Function() onRetry;

  final StartupRecovery recovery;

  @override
  State<StartupFailurePage> createState() => _StartupFailurePageState();
}

class _StartupFailurePageState extends State<StartupFailurePage> {
  late Object _error = widget.error;
  bool _busy = false;

  StartupFailureKind get _kind => classifyStartupFailure(_error);

  String get _message => LocServ.inst.t(switch (_kind) {
    StartupFailureKind.databaseTooNew => 'startup_failed_database_too_new',
    StartupFailureKind.databaseUnreadable =>
      'startup_failed_database_unreadable',
    StartupFailureKind.storage => 'startup_failed_storage',
    StartupFailureKind.unknown => 'startup_failed_unknown',
  });

  void _show(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final saved = await widget.recovery.exportDatabase();
      if (!mounted) return;
      if (saved != null) {
        _show('${LocServ.inst.t('database_export_success')}: $saved');
      }
    } on DatabaseFileMissingException {
      if (mounted) _show(LocServ.inst.t('database_file_not_found'));
    } catch (e) {
      if (mounted) _show('${LocServ.inst.t('database_export_failed')}: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _retry() => _run(widget.onRetry);

  Future<void> _reset() async {
    final choice = await showDialog<_ResetChoice>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocServ.inst.t('startup_reset_app_data')),
        content: Text(LocServ.inst.t('startup_reset_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _ResetChoice.exportFirst),
            child: Text(LocServ.inst.t('startup_reset_export_first')),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, _ResetChoice.delete),
            child: Text(LocServ.inst.t('startup_reset_delete')),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case _ResetChoice.exportFirst:
        await _export();
        // Back to the question once the export is done or cancelled.
        if (mounted) await _reset();
        return;
      case _ResetChoice.delete:
        await _run(() async {
          await widget.recovery.resetAppData();
          await widget.onRetry();
        });
        return;
      case null:
        return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(LocServ.inst.t('startup_failed_title'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Icon(Icons.error_outline, size: 48, color: colors.error),
            const SizedBox(height: 16),
            Text(_message, style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(LocServ.inst.t('startup_failed_details')),
              children: [SelectableText('$_error')],
            ),
            const SizedBox(height: 16),
            if (_busy) ...[
              const LinearProgressIndicator(),
              const SizedBox(height: 16),
            ],
            FilledButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.save_alt),
              label: Text(LocServ.inst.t('startup_export_database')),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _busy ? null : _retry,
              icon: const Icon(Icons.refresh),
              label: Text(LocServ.inst.t('startup_retry')),
            ),
            // Starting over is offered only when the database itself does
            // not open: a full disk or another failure would delete the
            // caver's data and still not start, and data from a newer app
            // opens as it is once the app is updated.
            if (_kind == StartupFailureKind.databaseUnreadable) ...[
              const SizedBox(height: 8),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: colors.error),
                onPressed: _busy ? null : _reset,
                icon: const Icon(Icons.delete_forever),
                label: Text(LocServ.inst.t('startup_reset_app_data')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
