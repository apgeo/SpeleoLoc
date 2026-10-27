import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/silexgis/model/sync_review.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_review_outcomes_service.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Rows a reviewer turned down, or that failed when they were written, with
/// what the caver can do about each.
///
/// Nothing is decided for the caver: until they choose, a turned-down row
/// stays on the device as they left it and is not sent again.
class SilexgisReviewOutcomesPage extends ConsumerStatefulWidget {
  const SilexgisReviewOutcomesPage({super.key});

  @override
  ConsumerState<SilexgisReviewOutcomesPage> createState() =>
      _SilexgisReviewOutcomesPageState();
}

class _SilexgisReviewOutcomesPageState
    extends ConsumerState<SilexgisReviewOutcomesPage>
    with AppBarMenuMixin<SilexgisReviewOutcomesPage> {
  SilexgisProfile? _profile;
  List<SilexgisReviewOutcome> _outcomes = const <SilexgisReviewOutcome>[];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  SilexgisReviewOutcomesService get _service =>
      ref.read(silexgisReviewOutcomesServiceProvider);

  Future<void> _reload() async {
    final profile = await ref
        .read(silexgisProfileRepositoryProvider)
        .getDefaultProfile();
    final outcomes = profile == null
        ? const <SilexgisReviewOutcome>[]
        : await _service.outcomes(profile.profileUuid);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _outcomes = outcomes;
      _loading = false;
    });
  }

  Future<void> _act(Future<String?> Function(SilexgisProfile) action) async {
    final profile = _profile;
    if (profile == null || _busy) return;
    setState(() => _busy = true);
    try {
      final message = await action(profile);
      if (message != null) SnackBarService.showSuccess(message);
    } on Exception catch (e) {
      SnackBarService.showError(e);
    } finally {
      if (mounted) setState(() => _busy = false);
      await _reload();
    }
  }

  Future<void> _useServer(SilexgisReviewOutcome outcome) => _act((p) async {
    final now = await _service.useServerVersion(p, outcome);
    return LocServ.inst.t(
      now ? 'silexgis_review_server_now' : 'silexgis_review_server_next_run',
    );
  });

  Future<void> _keepMine(SilexgisReviewOutcome outcome) => _act((p) async {
    await _service.keepMine(p.profileUuid, outcome);
    return LocServ.inst.t('silexgis_review_kept');
  });

  Future<void> _delete(SilexgisReviewOutcome outcome) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocServ.inst.t('silexgis_review_delete_title')),
        content: Text(LocServ.inst.t('silexgis_review_delete_body')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(LocServ.inst.t('silexgis_review_delete')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _act((p) async {
      await _service.deleteDraft(p.profileUuid, outcome);
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('silexgis_review_outcomes')),
        actions: [buildAppBarMenuButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _outcomes.isEmpty
          ? Center(child: Text(LocServ.inst.t('silexgis_review_none')))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                for (final outcome in _outcomes)
                  _OutcomeCard(
                    outcome: outcome,
                    enabled: !_busy,
                    onUseServer: () => _useServer(outcome),
                    onKeepMine: () => _keepMine(outcome),
                    onDelete: () => _delete(outcome),
                  ),
              ],
            ),
    );
  }
}

class _OutcomeCard extends StatelessWidget {
  const _OutcomeCard({
    required this.outcome,
    required this.enabled,
    required this.onUseServer,
    required this.onKeepMine,
    required this.onDelete,
  });

  final SilexgisReviewOutcome outcome;
  final bool enabled;
  final VoidCallback onUseServer;
  final VoidCallback onKeepMine;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final held = outcome.held;
    final failed = held.outcome == SyncReviewOutcome.failed;
    final title = outcome.title;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title == null || title.isEmpty
                  ? LocServ.inst.t('silexgis_review_untitled')
                  : title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              <String>[
                LocServ.inst.t(
                  failed
                      ? 'silexgis_review_failed'
                      : 'silexgis_review_rejected',
                ),
                if (held.isDelete) LocServ.inst.t('silexgis_review_removal'),
                if (outcome.isNew) LocServ.inst.t('silexgis_review_new_row'),
              ].join(' · '),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            // The reviewer's own words, and the server's code for a failure.
            // Never a reason this application made up.
            if (held.note != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(held.note!),
            ],
            if (held.code != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(held.code!, style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 8),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              children: <Widget>[
                if (outcome.canDelete)
                  TextButton(
                    onPressed: enabled ? onDelete : null,
                    child: Text(LocServ.inst.t('silexgis_review_delete')),
                  ),
                TextButton(
                  onPressed: enabled ? onKeepMine : null,
                  child: Text(LocServ.inst.t('silexgis_review_keep_mine')),
                ),
                if (outcome.canUseServerVersion)
                  FilledButton(
                    onPressed: enabled ? onUseServer : null,
                    child: Text(LocServ.inst.t('silexgis_review_use_server')),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
