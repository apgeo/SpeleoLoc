import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/archive_sync_decision_card.dart';
import 'package:speleoloc/services/sync/archive_sync_decision.dart';
import 'package:speleoloc/services/sync/archive_sync_decision_errors.dart';
import 'package:speleoloc/services/sync/archive_sync_decisions_service.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// The records an archive sync held because a different record here already
/// has their name, waiting for the caver to merge each into theirs, keep
/// both, or discard the incoming one.
///
/// Sync never waits on this page: everything else was merged, and each held
/// record stays held, with what hangs on it, until the caver chooses.
class ArchiveSyncDecisionsPage extends ConsumerStatefulWidget {
  const ArchiveSyncDecisionsPage({super.key});

  @override
  ConsumerState<ArchiveSyncDecisionsPage> createState() =>
      _ArchiveSyncDecisionsPageState();
}

class _ArchiveSyncDecisionsPageState
    extends ConsumerState<ArchiveSyncDecisionsPage>
    with AppBarMenuMixin<ArchiveSyncDecisionsPage> {
  List<ArchiveSyncDecision> _decisions = const <ArchiveSyncDecision>[];
  bool _loading = true;
  bool _busy = false;

  ArchiveSyncDecisionsService get _service =>
      ref.read(archiveSyncDecisionsServiceProvider);

  @override
  void initState() {
    super.initState();
    _open();
  }

  /// A record renamed or removed here since it was held may no longer
  /// clash, so the held rows are merged again before they are shown.
  Future<void> _open() async {
    try {
      await _service.refresh();
    } on Exception catch (e) {
      SnackBarService.showError(e);
    }
    await _reload();
  }

  Future<void> _reload() async {
    final decisions = await _service.decisions();
    if (!mounted) return;
    setState(() {
      _decisions = decisions;
      _loading = false;
    });
  }

  Future<void> _act(Future<void> Function() action, String doneKey) async {
    if (_busy || !mounted) return;
    setState(() => _busy = true);
    try {
      await action();
      SnackBarService.showSuccess(LocServ.inst.t(doneKey));
    } on ArchiveSyncNameTakenException {
      SnackBarService.showError(LocServ.inst.t('archive_decision_name_taken'));
    } on ArchiveSyncMergeBlockedException {
      SnackBarService.showError(
        LocServ.inst.t('archive_decision_merge_blocked'),
      );
    } on Exception catch (e) {
      SnackBarService.showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _reload();
    }
  }

  Future<bool> _confirm(String titleKey, String bodyKey, String actionKey) =>
      showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(LocServ.inst.t(titleKey)),
          content: Text(LocServ.inst.t(bodyKey)),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(LocServ.inst.t('cancel')),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(LocServ.inst.t(actionKey)),
            ),
          ],
        ),
      ).then((confirmed) => confirmed == true);

  Future<void> _merge(ArchiveSyncDecision decision) async {
    if (!await _confirm(
      'archive_decision_merge_title',
      'archive_decision_merge_body',
      'archive_decision_merge',
    )) {
      return;
    }
    await _act(
      () => _service.mergeIntoLocal(decision),
      'archive_decision_merged',
    );
  }

  Future<void> _discard(ArchiveSyncDecision decision) async {
    if (!await _confirm(
      'archive_decision_discard_title',
      decision.isEdit
          ? 'archive_decision_discard_edit_body'
          : 'archive_decision_discard_body',
      'archive_decision_discard',
    )) {
      return;
    }
    await _act(() => _service.discard(decision), 'archive_decision_discarded');
  }

  Future<void> _keepBoth(ArchiveSyncDecision decision) async {
    final controller = TextEditingController(text: '${decision.title} (2)');
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocServ.inst.t('archive_decision_keep_both_title')),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: LocServ.inst.t('archive_decision_new_name'),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(LocServ.inst.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: Text(LocServ.inst.t('archive_decision_keep_both')),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    await _act(
      () => _service.keepBoth(decision, trimmed),
      'archive_decision_kept_both',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('archive_decisions')),
        actions: [buildAppBarMenuButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _decisions.isEmpty
          ? Center(child: Text(LocServ.inst.t('archive_decisions_none')))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                Text(LocServ.inst.t('archive_decisions_intro')),
                const SizedBox(height: 8),
                for (final decision in _decisions)
                  ArchiveSyncDecisionCard(
                    decision: decision,
                    enabled: !_busy,
                    onMerge: () => _merge(decision),
                    onKeepBoth: () => _keepBoth(decision),
                    onDiscard: () => _discard(decision),
                  ),
              ],
            ),
    );
  }
}
