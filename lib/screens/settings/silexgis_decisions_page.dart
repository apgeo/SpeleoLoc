import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/silexgis_decision_card.dart';
import 'package:speleoloc/services/silexgis/silexgis_decision.dart';
import 'package:speleoloc/services/silexgis/silexgis_decisions_service.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// What an installation did not write and only the caver can settle, for
/// every section: rows a reviewer turned down or that failed when written,
/// items that met a later version on the server, and pins whose place another
/// pin already marks.
///
/// Nothing is decided for the caver: until they choose, each item stays on
/// the device as they left it and is not sent again.
class SilexgisDecisionsPage extends ConsumerStatefulWidget {
  const SilexgisDecisionsPage({super.key});

  @override
  ConsumerState<SilexgisDecisionsPage> createState() =>
      _SilexgisDecisionsPageState();
}

class _SilexgisDecisionsPageState extends ConsumerState<SilexgisDecisionsPage>
    with AppBarMenuMixin<SilexgisDecisionsPage> {
  SilexgisProfile? _profile;
  List<SilexgisDecision> _decisions = const <SilexgisDecision>[];
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  SilexgisDecisionsService get _service =>
      ref.read(silexgisDecisionsServiceProvider);

  Future<void> _reload() async {
    final profile = await ref
        .read(silexgisProfileRepositoryProvider)
        .getDefaultProfile();
    final decisions = profile == null
        ? const <SilexgisDecision>[]
        : await _service.decisions(profile.profileUuid);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _decisions = decisions;
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

  Future<void> _useServer(SilexgisDecision decision) => _act((p) async {
    final now = await _service.useServerVersion(p, decision);
    return LocServ.inst.t(
      now ? 'silexgis_review_server_now' : 'silexgis_review_server_next_run',
    );
  });

  Future<void> _keepMine(SilexgisDecision decision) => _act((p) async {
    await _service.keepMine(p.profileUuid, decision);
    return LocServ.inst.t('silexgis_review_kept');
  });

  Future<void> _delete(SilexgisDecision decision) async {
    final pin = decision.canRemovePin;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          LocServ.inst.t(
            pin
                ? 'silexgis_decision_remove_pin_title'
                : 'silexgis_review_delete_title',
          ),
        ),
        content: Text(
          LocServ.inst.t(
            pin
                ? 'silexgis_decision_remove_pin_body'
                : 'silexgis_review_delete_body',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              LocServ.inst.t(
                pin ? 'silexgis_decision_remove_pin' : 'silexgis_review_delete',
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _act((p) async {
      await _service.delete(p, decision);
      return null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('silexgis_decisions')),
        actions: [buildAppBarMenuButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _decisions.isEmpty
          ? Center(child: Text(LocServ.inst.t('silexgis_review_none')))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                for (final decision in _decisions)
                  SilexgisDecisionCard(
                    decision: decision,
                    enabled: !_busy,
                    onUseServer: () => _useServer(decision),
                    onKeepMine: () => _keepMine(decision),
                    onDelete: () => _delete(decision),
                  ),
              ],
            ),
    );
  }
}
