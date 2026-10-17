import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_trip/trip_log_stale_banner.dart';
import 'package:speleoloc/services/trip_log_method.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/product_tour.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

class CaveTripLogPage extends ConsumerStatefulWidget {
  const CaveTripLogPage({super.key, required this.tripUuid});
  final Uuid tripUuid;

  @override
  ConsumerState<CaveTripLogPage> createState() => _CaveTripLogPageState();
}

class _CaveTripLogPageState extends ConsumerState<CaveTripLogPage>
    with ProductTourMixin<CaveTripLogPage> {
  @override
  String get tourId => 'cave_trip_log';
  @override
  final tourKeys = TourKeySet(['editor', 'save']);
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(
      keyId: 'editor',
      titleLocKey: 'tour_cave_trip_log_editor_title',
      bodyLocKey: 'tour_cave_trip_log_editor_body',
      align: ContentAlign.top,
    ),
    TourStepDef(
      keyId: 'save',
      titleLocKey: 'tour_cave_trip_log_save_title',
      bodyLocKey: 'tour_cave_trip_log_save_body',
    ),
  ];
  final TextEditingController _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  TripLogMethod _activeMethod = TripLogMethod.classic;

  /// The trip as last read: carries whether its log has fallen behind.
  CaveTrip? _trip;

  /// The user's setting, so the page can say what editing points does here.
  bool _regeneratesOnEdit = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final trip = await ref
        .read(caveTripRepositoryProvider)
        .findById(widget.tripUuid);
    final method = await ref
        .read(currentUserServiceProvider)
        .getTripLogMethod();
    final regenerates = await ref
        .read(caveTripServiceProvider)
        .regeneratesLogOnEdit();
    if (mounted) {
      setState(() {
        _trip = trip;
        _controller.text = trip?.log ?? '';
        _activeMethod = method;
        _regeneratesOnEdit = regenerates;
        _loading = false;
      });
    }
  }

  /// Re-reads the trip and the setting without touching the text, which may
  /// hold edits not saved yet.
  Future<void> _refreshStatus() async {
    final trip = await ref
        .read(caveTripRepositoryProvider)
        .findById(widget.tripUuid);
    final regenerates = await ref
        .read(caveTripServiceProvider)
        .regeneratesLogOnEdit();
    if (mounted) {
      setState(() {
        _trip = trip;
        _regeneratesOnEdit = regenerates;
      });
    }
  }

  Future<void> _openSettings() async {
    await AppRoutes.pushTripLogSettings(context);
    await _refreshStatus();
  }

  /// What editing this trip's points does to this log, and where that is
  /// decided — always in view, since it decides whether typing here lasts.
  Widget _buildModeStrip() {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
      child: Row(
        children: [
          Icon(
            _regeneratesOnEdit ? Icons.sync : Icons.edit_note,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LocServ.inst.t(
                _regeneratesOnEdit
                    ? 'trip_log_mode_regenerates'
                    : 'trip_log_mode_keeps',
              ),
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 20),
            tooltip: LocServ.inst.t('trip_log_settings_link'),
            onPressed: () => unawaited(_openSettings()),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(caveTripRepositoryProvider)
          .updateTripLog(widget.tripUuid, _controller.text);
      if (mounted) {
        SnackBarService.showSuccess(LocServ.inst.t('trip_log_saved'));
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _onMethodSelected(TripLogMethod method) async {
    if (method == _activeMethod) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('trip_log_method_change_confirm_title')),
        content: Text(LocServ.inst.t('trip_log_method_change_confirm_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('trip_log_method_change_confirm_ok')),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(caveTripServiceProvider)
          .regenerateLogWithMethod(widget.tripUuid, method);
      // Reload the trip text from DB after regeneration.
      final trip = await ref
          .read(caveTripRepositoryProvider)
          .findById(widget.tripUuid);
      if (mounted) {
        setState(() {
          _trip = trip;
          _controller.text = trip?.log ?? '';
          _activeMethod = method;
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocServ.inst.t('trip_log_title')),
        actions: [
          PopupMenuButton<TripLogMethod>(
            tooltip: LocServ.inst.t('trip_log_method_picker_tooltip'),
            icon: const Icon(Icons.auto_stories),
            onSelected: _onMethodSelected,
            itemBuilder: (ctx) => [
              for (final m in TripLogMethod.values)
                PopupMenuItem<TripLogMethod>(
                  value: m,
                  child: Row(
                    children: [
                      Icon(
                        m == _activeMethod
                            ? Icons.check
                            : Icons.radio_button_unchecked,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(LocServ.inst.t(m.i18nKey))),
                    ],
                  ),
                ),
            ],
          ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              key: tourKeys['save'],
              icon: const Icon(Icons.save),
              tooltip: LocServ.inst.t('save'),
              onPressed: _save,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildModeStrip(),
                if (_trip?.logStaleSince != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TripLogStaleBanner(
                      trip: _trip!,
                      onRegenerated: () => unawaited(_load()),
                      onKept: () => unawaited(_refreshStatus()),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      key: tourKeys['editor'],
                      controller: _controller,
                      maxLines: null,
                      expands: true,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: LocServ.inst.t('trip_log_title'),
                      ),
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
