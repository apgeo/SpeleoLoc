import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_assignment.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_entrance_dialog.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_tile.dart';
import 'package:speleoloc/services/qr_code_lookup_service.dart';
import 'package:speleoloc/services/qr_scan_service.dart';
import 'package:speleoloc/services/trip_media/media_qr_detector.dart';
import 'package:speleoloc/services/trip_media/trip_media_access.dart';
import 'package:speleoloc/services/trip_media/trip_media_entrance_plan.dart';
import 'package:speleoloc/services/trip_media/trip_media_import_service.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/cave_place_picker_dialog.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';
import 'package:speleoloc/widgets/trip_point_time_dialog.dart';

/// Builds a trip's track points out of the capture times of the caver's own
/// photos and videos.
///
/// The screen is a worksheet: every offered item can be given a cave place
/// (read off a QR label in the picture, or chosen by hand) and a moment,
/// and only the ticked ones are committed. Nothing is written until Apply,
/// so a 200-item camera roll can be worked through and corrected first.
class TripMediaPointsPage extends ConsumerStatefulWidget {
  const TripMediaPointsPage({super.key, required this.tripUuid});

  final Uuid tripUuid;

  @override
  ConsumerState<TripMediaPointsPage> createState() =>
      _TripMediaPointsPageState();
}

class _TripMediaPointsPageState extends ConsumerState<TripMediaPointsPage> {
  static final _dayFmt = DateFormat('yyyy/MM/dd');

  CaveTrip? _trip;
  Cave? _cave;

  /// Entrance-flagged places of the cave, which is what makes an assignment
  /// an enter/exit marker.
  Set<Uuid> _entrancePlaceUuids = {};
  Map<Uuid, String> _placeTitles = {};

  TripMediaResolution? _resolution;
  List<TripMediaItem> _items = [];
  final Map<String, TripMediaAssignment> _assignments = {};
  final Map<String, Uint8List?> _thumbnails = {};
  final Map<String, File?> _files = {};

  DateTimeRange? _range;
  bool _importFiles = true;
  bool _loading = true;

  /// Bumped by every reload. The background work a load starts — the
  /// thumbnails and the QR sweep — checks it on each item and stops once a
  /// newer list has replaced the one it was started for, so a change of
  /// date range mid-sweep restarts the sweep instead of being ignored.
  int _listGeneration = 0;

  MediaQrDetector? _detector;
  bool _qrRunning = false;

  /// Set by the Stop button. Distinct from [_disposed]: stopping the QR
  /// sweep must not also abandon thumbnail loading.
  bool _qrCancelled = false;

  /// Set in [dispose], so both background sweeps stop touching state.
  bool _disposed = false;
  int _qrDone = 0;
  int _qrTotal = 0;
  int _qrFound = 0;

  /// Set when the platform turns out to have no image analyzer, so the
  /// screen says that rather than leaving every picture looking code-free.
  bool _qrUnsupported = false;

  bool _applying = false;
  int _applyDone = 0;
  int _applyTotal = 0;

  static const _access = TripMediaAccessResolver();

  /// True when the user chose the picker although the library could be
  /// read; with no library access the picker is not a choice.
  bool _pickerChosen = false;

  /// Set while the user is in the system settings granting library access,
  /// so that coming back re-checks it.
  bool _awaitingSettings = false;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _onResume);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _disposed = true;
    _qrCancelled = true;
    unawaited(_detector?.dispose());
    unawaited(_resolution?.source.release());
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final trip = await ref
        .read(caveTripRepositoryProvider)
        .findById(widget.tripUuid);
    if (trip == null) {
      if (mounted) Navigator.pop(context, false);
      return;
    }
    final cave = await ref.read(caveRepositoryProvider).findById(trip.caveUuid);
    final places = await ref
        .read(cavePlaceRepositoryProvider)
        .getCavePlaces(trip.caveUuid);

    if (!mounted) return;
    setState(() {
      _trip = trip;
      _cave = cave;
      _placeTitles = {for (final p in places) p.uuid: p.title};
      _entrancePlaceUuids = {
        for (final p in places)
          if (p.isEntrance == 1 || p.isMainEntrance == 1) p.uuid,
      };
      // Default to the trip's own window: that is the range the pictures
      // worth importing almost always fall in, and it keeps the first load
      // off the whole camera roll.
      _range = DateTimeRange(
        start: _startOfDay(
          DateTime.fromMillisecondsSinceEpoch(trip.tripStartedAt),
        ),
        end: _endOfDay(
          trip.tripEndedAt != null
              ? DateTime.fromMillisecondsSinceEpoch(trip.tripEndedAt!)
              : DateTime.now(),
        ),
      );
    });

    final resolution = await _access.resolve();
    if (!mounted) return;
    setState(() => _resolution = resolution);
    // With no library to read, the screen opens on the picker.
    if (resolution.source.choosesItems) await resolution.source.chooseMore();
    if (!mounted) return;
    await _loadItems();
  }

  /// Puts [next] in place of the current source. The old one is released
  /// first; the assignments made against it go with its list.
  Future<void> _switchSource(
    TripMediaResolution next, {
    required bool pickerChosen,
  }) async {
    final previous = _resolution;
    setState(() {
      _resolution = next;
      _pickerChosen = pickerChosen;
    });
    unawaited(previous?.source.release());
    if (next.source.choosesItems) await next.source.chooseMore();
    if (!mounted) return;
    await _loadItems();
  }

  Future<void> _usePicker() async {
    final current = _resolution;
    if (current == null) return;
    await _switchSource(_access.picker(current.access), pickerChosen: true);
  }

  Future<void> _useLibrary() async {
    final current = _resolution;
    if (current == null) return;
    await _switchSource(_access.library(current.access), pickerChosen: false);
  }

  Future<void> _addFiles() async {
    final source = _resolution?.source;
    if (source == null) return;
    await source.chooseMore();
    if (!mounted) return;
    await _loadItems();
  }

  Future<void> _chooseMorePhotos() async {
    await _access.chooseMorePhotos();
    if (!mounted) return;
    await _loadItems();
  }

  Future<void> _openAccessSettings() async {
    _awaitingSettings = true;
    await _access.openSystemSettings();
  }

  /// Coming back from the system settings: if library access was granted
  /// there, move from the picker to the library without being asked.
  Future<void> _onResume() async {
    if (!_awaitingSettings || !mounted) return;
    _awaitingSettings = false;
    final checked = await _access.resolve();
    if (!mounted) return;
    if (checked.access == TripMediaAccess.picker) {
      unawaited(checked.source.release());
      return;
    }
    await _switchSource(checked, pickerChosen: false);
  }

  static DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _endOfDay(DateTime d) =>
      DateTime(d.year, d.month, d.day, 23, 59, 59, 999);

  Future<void> _loadItems() async {
    final resolution = _resolution;
    if (resolution == null) return;
    final generation = ++_listGeneration;
    setState(() => _loading = true);
    List<TripMediaItem> items;
    try {
      items = await resolution.source.list(
        from: _range?.start,
        to: _range?.end,
      );
    } catch (e, st) {
      log.warning('media listing failed', e, st);
      items = const [];
      if (mounted) SnackBarService.showError(e);
    }
    // A later load overtook this one; its result is the one to show.
    if (!mounted || generation != _listGeneration) return;
    setState(() {
      _items = items;
      _loading = false;
      _thumbnails.clear();
      _files.clear();
      // Assignments for items no longer listed would be invisible but still
      // committed on Apply, so they go with the list they belonged to.
      final visible = items.map((i) => i.id).toSet();
      _assignments.removeWhere((id, _) => !visible.contains(id));
    });
    unawaited(_loadThumbnails(generation));
    unawaited(_runQrPass(generation));
  }

  bool _isCurrent(int generation) =>
      mounted && !_disposed && generation == _listGeneration;

  Future<void> _loadThumbnails(int generation) async {
    final resolution = _resolution;
    if (resolution == null) return;
    for (final item in List<TripMediaItem>.from(_items)) {
      if (!_isCurrent(generation)) return;
      if (_thumbnails.containsKey(item.id)) continue;
      final bytes = await resolution.source.thumbnail(item);
      File? file;
      if (bytes == null && item.isPhoto) {
        // No platform thumbnailer (the picker path): the tile renders the
        // file itself instead.
        file = await resolution.source.file(item);
      }
      if (!_isCurrent(generation)) return;
      setState(() {
        _thumbnails[item.id] = bytes;
        if (file != null) _files[item.id] = file;
      });
    }
  }

  /// Reads QR labels out of the stills, filling in places as it goes.
  ///
  /// Runs after the list is on screen and one item at a time: each analysis
  /// is a platform call on a file the platform may first have to copy out of
  /// the library, which is far too slow to block the first paint on. Items
  /// the user has already decided are skipped so an automatic guess never
  /// overwrites a deliberate choice.
  Future<void> _runQrPass(int generation) async {
    final trip = _trip;
    final resolution = _resolution;
    if (trip == null || resolution == null) return;

    final photos = _items.where((i) => i.isPhoto).toList();
    if (photos.isEmpty) {
      if (_isCurrent(generation)) setState(() => _qrRunning = false);
      return;
    }

    // Loaded before the null check rather than inside it: two sweeps
    // starting together would otherwise each build a detector, and the
    // first one's scanner would never be released.
    final config = await QrScanConfig.load();
    final detector = _detector ??= MediaQrDetector(
      QrCodeLookupService(ref.read(appDatabaseProvider)),
      config: config,
    );

    if (!_isCurrent(generation)) return;
    setState(() {
      _qrRunning = true;
      _qrCancelled = false;
      _qrDone = 0;
      _qrFound = 0;
      _qrTotal = photos.length;
    });

    for (final item in photos) {
      if (!_isCurrent(generation) || _qrCancelled) break;
      if (_assignments.containsKey(item.id)) {
        if (_isCurrent(generation)) setState(() => _qrDone++);
        continue;
      }
      try {
        final place = await resolution.source.withScanImage(
          item,
          (file) => detector.detectCavePlace(file, caveUuid: trip.caveUuid),
        );
        if (place != null &&
            _isCurrent(generation) &&
            !_assignments.containsKey(item.id)) {
          setState(() {
            _assignments[item.id] = TripMediaAssignment(
              place: place,
              at: item.capturedAt,
              fromQrCode: true,
            );
            _qrFound++;
          });
        }
      } catch (e, st) {
        log.fine('QR pass failed for ${item.id}', e, st);
      }
      if (_isCurrent(generation)) setState(() => _qrDone++);
      if (detector.isUnsupported) break;
    }

    // A sweep that a newer list replaced leaves the progress to that one.
    if (_isCurrent(generation)) {
      setState(() {
        _qrRunning = false;
        _qrUnsupported = detector.isUnsupported;
      });
    }
  }

  Future<void> _pickRange() async {
    final trip = _trip;
    if (trip == null) return;
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: _range,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    setState(
      () => _range = DateTimeRange(
        start: _startOfDay(picked.start),
        end: _endOfDay(picked.end),
      ),
    );
    await _loadItems();
  }

  Future<void> _pickPlace(TripMediaItem item) async {
    final trip = _trip;
    if (trip == null) return;
    final place = await CavePlacePickerDialog.show(context, trip.caveUuid);
    if (place == null || !mounted) return;
    setState(() {
      final existing = _assignments[item.id];
      _assignments[item.id] = TripMediaAssignment(
        place: place,
        at: existing?.at ?? item.capturedAt,
        selected: existing?.selected ?? true,
      );
    });
  }

  Future<void> _editTime(TripMediaItem item) async {
    final trip = _trip;
    final assignment = _assignments[item.id];
    if (trip == null || assignment == null) return;
    final at = await TripPointTimeDialog.show(
      context,
      initial: assignment.at,
      tripStart: DateTime.fromMillisecondsSinceEpoch(trip.tripStartedAt),
      tripEnd: trip.tripEndedAt != null
          ? DateTime.fromMillisecondsSinceEpoch(trip.tripEndedAt!)
          : null,
    );
    if (at == null || !mounted) return;
    setState(() => _assignments[item.id] = assignment.copyWith(at: at));
  }

  List<TripMediaAssignment> get _committed => [
    for (final a in _assignments.values)
      if (a.selected) a,
  ];

  Future<void> _apply() async {
    final trip = _trip;
    if (trip == null) return;
    final selectedIds = [
      for (final e in _assignments.entries)
        if (e.value.selected) e.key,
    ];
    if (selectedIds.isEmpty) {
      SnackBarService.showWarning(LocServ.inst.t('trip_media_nothing_ticked'));
      return;
    }

    // Entrance markers contradict two things that are already recorded, so
    // ask before touching either.
    var deletePointUuids = const <Uuid>[];
    DateTime? newStart;
    DateTime? newEnd;
    final entranceTimes = [
      for (final a in _committed)
        if (_entrancePlaceUuids.contains(a.place.uuid)) a.at,
    ];
    if (entranceTimes.isNotEmpty) {
      final existing = await ref
          .read(caveTripRepositoryProvider)
          .getTripPoints(trip.uuid);
      final plan = planEntranceReconciliation(
        tripStart: DateTime.fromMillisecondsSinceEpoch(trip.tripStartedAt),
        tripEnd: trip.tripEndedAt != null
            ? DateTime.fromMillisecondsSinceEpoch(trip.tripEndedAt!)
            : null,
        newEntranceTimes: entranceTimes,
        existingPoints: existing,
        entrancePlaceUuids: _entrancePlaceUuids,
      );
      if (!plan.isEmpty) {
        if (!mounted) return;
        final decision = await TripMediaEntranceDialog.show(
          context,
          plan: plan,
          tripStart: DateTime.fromMillisecondsSinceEpoch(trip.tripStartedAt),
          tripEnd: trip.tripEndedAt != null
              ? DateTime.fromMillisecondsSinceEpoch(trip.tripEndedAt!)
              : null,
          placeTitles: _placeTitles,
        );
        if (decision == null) return;
        deletePointUuids = decision.deletePointUuids;
        newStart = decision.newTripStart;
        newEnd = decision.newTripEnd;
      }
    }

    final resolution = _resolution;
    if (resolution == null) return;

    final itemsById = {for (final i in _items) i.id: i};
    final commits = <TripMediaCommit>[];
    for (final id in selectedIds) {
      final assignment = _assignments[id];
      final item = itemsById[id];
      // A reload between ticking and applying can drop an item; skipping it
      // is right, throwing on it is not.
      if (assignment == null || item == null) continue;
      commits.add(
        TripMediaCommit(
          item: item,
          cavePlaceUuid: assignment.place.uuid,
          at: assignment.at,
          file: _importFiles
              ? (_files[id] ?? await resolution.source.file(item))
              : null,
        ),
      );
    }
    if (commits.isEmpty) {
      SnackBarService.showWarning(LocServ.inst.t('trip_media_nothing_ticked'));
      return;
    }

    if (!mounted) return;
    setState(() {
      _applying = true;
      _applyDone = 0;
      _applyTotal = commits.length;
    });

    final outcome = await ref
        .read(tripMediaImportServiceProvider)
        .apply(
          tripUuid: trip.uuid,
          commits: commits,
          importFiles: _importFiles,
          // `true` defers to the user's own image-compression settings,
          // which is what every other import path in the app does.
          compressImages: true,
          deletePointUuids: deletePointUuids,
          newTripStart: newStart,
          newTripEnd: newEnd,
          onProgress: (done, total) {
            if (mounted) setState(() => _applyDone = done);
          },
        );

    if (!mounted) return;
    setState(() => _applying = false);
    _reportOutcome(outcome);
    Navigator.pop(context, true);
  }

  void _reportOutcome(TripMediaImportOutcome outcome) {
    final parts = <String>[
      LocServ.inst.t('trip_media_result_points', {
        'n': outcome.pointsAdded.toString(),
      }),
    ];
    if (outcome.pointsDuplicate > 0) {
      parts.add(
        LocServ.inst.t('trip_media_result_duplicates', {
          'n': outcome.pointsDuplicate.toString(),
        }),
      );
    }
    if (outcome.pointsDeleted > 0) {
      parts.add(
        LocServ.inst.t('trip_media_result_deleted', {
          'n': outcome.pointsDeleted.toString(),
        }),
      );
    }
    if (outcome.filesImported > 0 || outcome.filesDuplicate > 0) {
      parts.add(
        LocServ.inst.t('trip_media_result_files', {
          'n': outcome.filesImported.toString(),
        }),
      );
    }
    final message = parts.join(' · ');
    if (outcome.pointsFailed > 0 || outcome.warnings.isNotEmpty) {
      SnackBarService.showWarning(message);
    } else {
      SnackBarService.showSuccess(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    return PopScope(
      canPop: !_applying,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          SnackBarService.showInfo(LocServ.inst.t('trip_media_busy'));
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocServ.inst.t('trip_media_title')),
          bottom: trip == null
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(28),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6, left: 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '${_cave?.title ?? ''} · ${trip.title}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
        ),
        body: trip == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildControls(),
                  if (_qrRunning) _buildQrProgress(),
                  if (_applying) _buildApplyProgress(),
                  Expanded(child: _buildList()),
                ],
              ),
        floatingActionButton: trip == null || _applying
            ? null
            : FloatingActionButton.extended(
                onPressed: _apply,
                icon: const Icon(Icons.check),
                label: Text(
                  LocServ.inst.t('trip_media_apply', {
                    'n': _committed.length.toString(),
                  }),
                ),
              ),
      ),
    );
  }

  Widget _buildControls() {
    final resolution = _resolution;
    final rangeLabel = _range == null
        ? LocServ.inst.t('trip_media_any_date')
        : '${_dayFmt.format(_range!.start)} – ${_dayFmt.format(_range!.end)}';

    // A Material rather than a coloured Container: the switch below is a
    // ListTile, which paints its ink on the nearest Material ancestor, and a
    // plain coloured box in between hides it (and trips a debug assertion).
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: _buildControlsBody(resolution, rangeLabel),
      ),
    );
  }

  Widget _buildControlsBody(
    TripMediaResolution? resolution,
    String rangeLabel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(
                  rangeLabel,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: _pickRange,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: LocServ.inst.t('trip_media_reload'),
              onPressed: _loading ? null : () => unawaited(_loadItems()),
            ),
          ],
        ),
        if (resolution != null) _buildSourceRow(resolution),
        if (_qrUnsupported)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              LocServ.inst.t('trip_media_qr_unsupported'),
              style: const TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          value: _importFiles,
          title: Text(
            LocServ.inst.t('trip_media_import_files'),
            style: const TextStyle(fontSize: 13),
          ),
          subtitle: Text(
            LocServ.inst.t('trip_media_import_files_desc'),
            style: const TextStyle(fontSize: 11),
          ),
          onChanged: (v) => setState(() => _importFiles = v),
        ),
      ],
    );
  }

  /// Says where the pictures come from, with the ways to change it. A
  /// [Wrap] rather than a row so the actions drop to a second line on a
  /// narrow phone instead of overflowing.
  Widget _buildSourceRow(TripMediaResolution resolution) {
    final granted = resolution.access;
    final onPicker = _pickerChosen || granted == TripMediaAccess.picker;
    final String label;
    final bool caution;
    final actions = <Widget>[];

    TextButton action(String key, VoidCallback onPressed) => TextButton(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      onPressed: _loading || _applying ? null : onPressed,
      child: Text(LocServ.inst.t(key), style: const TextStyle(fontSize: 12)),
    );

    if (onPicker) {
      caution = true;
      label = granted == TripMediaAccess.picker
          ? LocServ.inst.t('trip_media_picker_mode')
          : LocServ.inst.t('trip_media_source_picked');
      actions.add(action('trip_media_add_files', () => unawaited(_addFiles())));
      if (granted == TripMediaAccess.picker) {
        actions.add(
          action(
            'trip_media_allow_full_access',
            () => unawaited(_openAccessSettings()),
          ),
        );
      } else {
        actions.add(
          action('trip_media_use_library', () => unawaited(_useLibrary())),
        );
      }
    } else if (granted == TripMediaAccess.limited) {
      caution = true;
      label = LocServ.inst.t('trip_media_limited_mode');
      actions
        ..add(
          action(
            'trip_media_choose_more',
            () => unawaited(_chooseMorePhotos()),
          ),
        )
        ..add(
          action(
            'trip_media_pick_files_instead',
            () => unawaited(_usePicker()),
          ),
        );
    } else {
      caution = false;
      label = LocServ.inst.t('trip_media_source_library');
      actions.add(
        action('trip_media_pick_files_instead', () => unawaited(_usePicker())),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: caution
                  ? Colors.orange
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Wrap(spacing: 4, children: actions),
        ],
      ),
    );
  }

  Widget _buildQrProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  LocServ.inst.t('trip_media_qr_progress', {
                    'done': _qrDone.toString(),
                    'total': _qrTotal.toString(),
                    'found': _qrFound.toString(),
                  }),
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: _qrTotal == 0 ? null : _qrDone / _qrTotal,
                  minHeight: 3,
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _qrCancelled = true),
            child: Text(LocServ.inst.t('trip_media_qr_stop')),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            LocServ.inst.t('trip_media_applying', {
              'done': _applyDone.toString(),
              'total': _applyTotal.toString(),
            }),
            style: const TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 2),
          LinearProgressIndicator(
            value: _applyTotal == 0 ? null : _applyDone / _applyTotal,
            minHeight: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            LocServ.inst.t('trip_media_empty'),
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }
    return ListView.builder(
      itemCount: _items.length,
      padding: const EdgeInsets.only(bottom: 88),
      itemBuilder: (_, i) {
        final item = _items[i];
        return TripMediaTile(
          item: item,
          assignment: _assignments[item.id],
          thumbnail: _thumbnails[item.id],
          localFile: _files[item.id],
          onPickPlace: () => unawaited(_pickPlace(item)),
          onEditTime: () => unawaited(_editTime(item)),
          onToggleSelected: (v) {
            final existing = _assignments[item.id];
            if (existing == null) return;
            setState(
              () => _assignments[item.id] = existing.copyWith(selected: v),
            );
          },
          onClear: () => setState(() => _assignments.remove(item.id)),
        );
      },
    );
  }
}
