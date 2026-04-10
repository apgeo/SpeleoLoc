import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/utils/localization.dart';

export 'package:tutorial_coach_mark/tutorial_coach_mark.dart'
  show ContentAlign, ShapeLightFocus;

/// Lazily creates and caches [GlobalKey]s by string identifier.
class TourKeySet {
  final Map<String, GlobalKey> _keys = {};

  TourKeySet([List<String> ids = const []]) {
    for (final id in ids) {
      _keys[id] = GlobalKey();
    }
  }

  GlobalKey operator [](String id) {
    return _keys.putIfAbsent(id, () => GlobalKey());
  }

  List<String> get ids => _keys.keys.toList();
}

/// Immutable descriptor for a single tour step.
class TourStepDef {
  final String keyId;
  final String titleLocKey;
  final String bodyLocKey;
  final ContentAlign align;
  final ShapeLightFocus shape;

  const TourStepDef({
    required this.keyId,
    required this.titleLocKey,
    required this.bodyLocKey,
    this.align = ContentAlign.bottom,
    this.shape = ShapeLightFocus.RRect,
  });
}

/// Config key prefix for tracking whether a screen tour has been seen.
const String _tourSeenPrefix = 'tour_seen_';

/// Resets all tour-seen flags so tours auto-start again.
Future<void> resetAllTours(List<String> tourIds) async {
  for (final id in tourIds) {
    await SettingsHelper.saveStringConfig('$_tourSeenPrefix$id', '');
  }
}

/// All known tour IDs across the app, for reset purposes.
const List<String> allTourIds = [
  'home',
  'cave_places_list',
  'cave_place',
  'cave_trip',
  'cave_trip_list',
  'cave_trip_log',
  'add_new_cave',
  'csv_import',
  'csv_cave_place_import',
  'csv_caves_import',
  'scanner',
  'map_viewer',
  'raster_map_place_selector',
  'generated_qr_code_viewer',
  'geofeature_documents',
  'cave_areas',
  'surface_areas',
  'raster_maps',
  'raster_map_form',
  'documentation_files',
  'edit_documentation_file',
  'camera_capture',
  'image_editor',
  'text_document_editor',
  'rich_text_editor',
  'sound_recorder',
  'documentation_file_viewer',
  'sound_file_viewer',
  'settings_main',
  'settings_general',
  'settings_image_compression',
  'settings_qr_generation',
  'settings_pdf_output',
  'settings_database',
  'sql_command_runner',
  'data_export_import',
];

/// Mixin that adds product tour / feature walkthrough capability to any screen.
///
/// Screens override [tourId], [tourKeys], and [tourSteps] to define their tour.
/// The tour is started via [startScreenTour] (called from Help button or
/// auto-started on first visit).
///
/// Usage:
/// ```dart
/// class _MyPageState extends State<MyPage>
///     with AppBarMenuMixin<MyPage>, ProductTourMixin<MyPage> {
///   @override
///   String get tourId => 'my_page';
///   @override
///   final tourKeys = TourKeySet(['btn_add', 'list_main']);
///   @override
///   List<TourStepDef> get tourSteps => [
///     TourStepDef(keyId: 'btn_add', titleLocKey: 'tour_my_add_title', bodyLocKey: 'tour_my_add_body'),
///   ];
/// }
/// ```
mixin ProductTourMixin<T extends StatefulWidget> on State<T> {
  /// Unique screen identifier for tracking tour completion.
  String get tourId;

  /// Named GlobalKeys for tour target widgets.
  TourKeySet get tourKeys;

  /// Ordered list of tour step definitions.
  List<TourStepDef> get tourSteps;

  bool _tourAutoStartChecked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoStartTour();
    });
  }

  Future<void> _checkAutoStartTour() async {
    if (_tourAutoStartChecked) return;
    _tourAutoStartChecked = true;
    final seen = await SettingsHelper.loadStringConfig('$_tourSeenPrefix$tourId');
    if (seen.isEmpty && mounted) {
      // Small delay to ensure layout is fully complete
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) startScreenTour();
    }
  }

  /// Starts the sequential product tour for this screen.
  void startScreenTour() {
    final targets = <TargetFocus>[];
    for (final step in tourSteps) {
      final key = tourKeys[step.keyId];
      // Only include steps whose target widget is currently mounted
      if (key.currentContext == null) continue;
      targets.add(
        TargetFocus(
          identify: step.keyId,
          keyTarget: key,
          shape: step.shape,
          alignSkip: Alignment.bottomRight,
          enableOverlayTab: true,
          enableTargetTab: true,
          contents: [
            TargetContent(
              align: step.align,
              builder: (context, controller) {
                return _TourStepContent(
                  title: LocServ.inst.t(step.titleLocKey),
                  body: LocServ.inst.t(step.bodyLocKey),
                );
              },
            ),
          ],
        ),
      );
    }
    if (targets.isEmpty) return;
    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.75,
      hideSkip: false,
      textSkip: LocServ.inst.t('skip'),
      onFinish: () => _markTourSeen(),
      onSkip: () {
        _markTourSeen();
        return true;
      },
    ).show(context: context);
  }

  Future<void> _markTourSeen() async {
    await SettingsHelper.saveStringConfig('$_tourSeenPrefix$tourId', 'true');
  }
}

/// Content widget rendered inside each tour step callout.
class _TourStepContent extends StatelessWidget {
  final String title;
  final String body;

  const _TourStepContent({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
