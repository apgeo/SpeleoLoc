import 'package:flutter/widgets.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_utils.dart';

/// Owns all editable form state for [CavePlacePage].
///
/// Encapsulates:
/// - the 8 [TextEditingController]s for the text fields,
/// - the per-field "modified" flags (dirty markers) and the aggregate
///   `hasUnsavedChanges`,
/// - the 3 non-text toggle/selection states (cave area, isEntrance,
///   isMainEntrance).
///
/// The originally-loaded [CavePlace] (if any) is held as `original` and is
/// the baseline against which dirty flags are computed.
///
/// Lifecycle:
/// 1. Page creates a controller in `initState`, attaches listeners via
///    [attachTextListeners], and calls [loadFrom] after the page's
///    `_loadData()` finishes.
/// 2. UI consumes `xxx` for the [TextEditingController] and `xxxModified`
///    for the per-field bool. UI fields with their own state (area
///    dropdown, entrance toggles) call [setArea] / [setEntrance] /
///    [setMainEntrance].
/// 3. After a successful save the page calls [markClean] (typically via
///    `_refreshCavePlaceState`).
/// 4. `dispose()` releases the text controllers.
///
/// The controller is intentionally NOT a `ChangeNotifier`: the page wires
/// rebuilds through `setState` (existing pattern) by passing an
/// `onChanged` callback to [attachTextListeners]. Switching to listenable
/// rebuilds is a follow-up.
class CavePlaceFormController {
  CavePlaceFormController();

  // --- Text controllers (public — bound directly by the page's TextFields).
  final TextEditingController title = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController depth = TextEditingController();
  final TextEditingController qr = TextEditingController();
  final TextEditingController qcri = TextEditingController();
  final TextEditingController lat = TextEditingController();
  final TextEditingController long = TextEditingController();
  final TextEditingController alt = TextEditingController();

  // --- Non-text state.
  Uuid? selectedCaveAreaId;
  bool isEntrance = false;
  bool isMainEntrance = false;

  // --- Dirty flags.
  bool _titleModified = false;
  bool _descriptionModified = false;
  bool _depthModified = false;
  bool _qrModified = false;
  bool _qcriModified = false;
  bool _latModified = false;
  bool _longModified = false;
  bool _altModified = false;
  bool _areaModified = false;
  bool _entranceModified = false;
  bool _mainEntranceModified = false;

  bool get titleModified => _titleModified;
  bool get descriptionModified => _descriptionModified;
  bool get depthModified => _depthModified;
  bool get qrModified => _qrModified;
  bool get qcriModified => _qcriModified;
  bool get latModified => _latModified;
  bool get longModified => _longModified;
  bool get altModified => _altModified;
  bool get areaModified => _areaModified;
  bool get entranceModified => _entranceModified;
  bool get mainEntranceModified => _mainEntranceModified;

  /// The DB-loaded baseline. `null` means "new cave place — every non-empty
  /// field counts as modified".
  CavePlace? original;

  bool get hasUnsavedChanges =>
      _titleModified ||
      _descriptionModified ||
      _depthModified ||
      _qrModified ||
      _qcriModified ||
      _latModified ||
      _longModified ||
      _altModified ||
      _areaModified ||
      _entranceModified ||
      _mainEntranceModified;

  /// Attach `onChanged` to every text controller. Returns the list of
  /// listener callbacks so they can be removed in [dispose] if needed.
  /// The simplest pattern (and the one [CavePlacePage] uses) is to never
  /// remove them — the controllers are disposed alongside the state.
  void attachTextListeners(VoidCallback onChanged) {
    title.addListener(() {
      _recomputeText(_FormField.title);
      onChanged();
    });
    description.addListener(() {
      _recomputeText(_FormField.description);
      onChanged();
    });
    depth.addListener(() {
      _recomputeText(_FormField.depth);
      onChanged();
    });
    qr.addListener(() {
      _recomputeText(_FormField.qr);
      onChanged();
    });
    qcri.addListener(() {
      _recomputeText(_FormField.qcri);
      onChanged();
    });
    lat.addListener(() {
      _recomputeText(_FormField.lat);
      onChanged();
    });
    long.addListener(() {
      _recomputeText(_FormField.long);
      onChanged();
    });
    alt.addListener(() {
      _recomputeText(_FormField.alt);
      onChanged();
    });
  }

  void _recomputeText(_FormField field) {
    switch (field) {
      case _FormField.title:
        _titleModified = title.text != (original?.title ?? '');
      case _FormField.description:
        _descriptionModified = description.text != (original?.description ?? '');
      case _FormField.depth:
        _depthModified = depth.text != formatDepthValue(original?.depthInCave);
      case _FormField.qr:
        _qrModified = qr.text != (original?.placeCodeIdentifier ?? '');
      case _FormField.qcri:
        _qcriModified =
            qcri.text != (original?.qrCodeResourceIdentifier ?? '');
      case _FormField.lat:
        _latModified = lat.text != (original?.latitude?.toString() ?? '');
      case _FormField.long:
        _longModified = long.text != (original?.longitude?.toString() ?? '');
      case _FormField.alt:
        _altModified = alt.text != (original?.altitude?.toString() ?? '');
    }
  }

  /// Populate text fields and non-text state from `place`, then reset all
  /// dirty flags (this becomes the new baseline).
  ///
  /// Pass `null` for a brand-new cave place — text fields are left as-is
  /// (caller has already cleared them) and flags are reset.
  void loadFrom(CavePlace? place) {
    original = place;
    if (place != null) {
      title.text = place.title;
      description.text = place.description ?? '';
      depth.text = formatDepthValue(place.depthInCave);
      qr.text = place.placeCodeIdentifier ?? '';
      qcri.text = place.qrCodeResourceIdentifier ?? '';
      lat.text = place.latitude?.toString() ?? '';
      long.text = place.longitude?.toString() ?? '';
      alt.text = place.altitude?.toString() ?? '';
      isEntrance = place.isEntrance == 1;
      isMainEntrance = place.isMainEntrance == 1;
    } else {
      isEntrance = false;
      isMainEntrance = false;
    }
    markClean();
  }

  /// Adopt the latest persisted [CavePlace] as the new baseline and clear
  /// every dirty flag. Used after a successful save to silence the
  /// "unsaved changes" prompt without rebuilding the text controllers.
  void adoptAsBaseline(CavePlace refreshed) {
    original = refreshed;
    qcri.text = refreshed.qrCodeResourceIdentifier ?? '';
    selectedCaveAreaId = refreshed.caveAreaUuid;
    isEntrance = refreshed.isEntrance == 1;
    isMainEntrance = refreshed.isMainEntrance == 1;
    markClean();
  }

  /// Reset every dirty flag without touching field values. Used during
  /// initial load.
  void markClean() {
    _titleModified = false;
    _descriptionModified = false;
    _depthModified = false;
    _qrModified = false;
    _qcriModified = false;
    _latModified = false;
    _longModified = false;
    _altModified = false;
    _areaModified = false;
    _entranceModified = false;
    _mainEntranceModified = false;
  }

  /// Mark PCI as explicitly touched (used after QR scan / PCI
  /// auto-generation, where the field was set programmatically but
  /// represents a real user-driven change).
  void markPciTouched() {
    _qrModified = true;
  }

  /// Mark QCRI as explicitly touched.
  void markQcriTouched() {
    _qcriModified = true;
  }

  void setArea(Uuid? value) {
    selectedCaveAreaId = value;
    _areaModified = value != original?.caveAreaUuid;
  }

  void setEntrance(bool value) {
    isEntrance = value;
    _syncEntranceFlags();
  }

  void setMainEntrance(bool value) {
    isMainEntrance = value;
    _syncEntranceFlags();
  }

  void _syncEntranceFlags() {
    final origEntrance = (original?.isEntrance ?? 0) == 1;
    final origMainEntrance = (original?.isMainEntrance ?? 0) == 1;
    _entranceModified = isEntrance != origEntrance;
    _mainEntranceModified = isMainEntrance != origMainEntrance;
  }

  void dispose() {
    title.dispose();
    description.dispose();
    depth.dispose();
    qr.dispose();
    qcri.dispose();
    lat.dispose();
    long.dispose();
    alt.dispose();
  }
}

enum _FormField {
  title,
  description,
  depth,
  qr,
  qcri,
  lat,
  long,
  alt,
}
