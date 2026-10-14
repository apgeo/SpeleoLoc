import 'package:flutter/widgets.dart';
import 'package:speleoloc/screens/add_new_cave.dart';
import 'package:speleoloc/screens/beacon_tag_edit_page.dart';
import 'package:speleoloc/screens/beacon_tags_page.dart';
import 'package:speleoloc/screens/cave_beacons_page.dart';
import 'package:speleoloc/screens/cave_document_import_page.dart';
import 'package:speleoloc/screens/cave_map/cave_map_page.dart';
import 'package:speleoloc/screens/cave_place_page.dart';
import 'package:speleoloc/screens/cave_places_list_page.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_points_page.dart';
import 'package:speleoloc/screens/cave_trip_list_page.dart';
import 'package:speleoloc/screens/cave_trip_log_page.dart';
import 'package:speleoloc/screens/cave_trip_page.dart';
import 'package:speleoloc/screens/csv_cave_place_import_page.dart';
import 'package:speleoloc/screens/csv_caves_import_page.dart';
import 'package:speleoloc/screens/documents/editors/camera_capture_page.dart';
import 'package:speleoloc/screens/documents/editors/image_editor_page.dart';
import 'package:speleoloc/screens/documents/editors/rich_text_editor_page.dart';
import 'package:speleoloc/screens/documents/editors/sound_recorder_page.dart';
import 'package:speleoloc/screens/documents/editors/text_document_editor_page.dart';
import 'package:speleoloc/screens/documents/viewers/documentation_file_viewer.dart';
import 'package:speleoloc/screens/documents/viewers/image_gallery_viewer_page.dart';
import 'package:speleoloc/screens/general_data/cave_areas_page.dart';
import 'package:speleoloc/screens/general_data/documentation_files_page.dart';
import 'package:speleoloc/screens/general_data/edit_documentation_file_page.dart';
import 'package:speleoloc/screens/general_data/raster_map_form.dart';
import 'package:speleoloc/screens/general_data/raster_maps_page.dart';
import 'package:speleoloc/screens/general_data/surface_areas_page.dart';
import 'package:speleoloc/screens/generated_qr_code_viewer.dart';
import 'package:speleoloc/screens/geofeature_documents_page.dart';
import 'package:speleoloc/screens/gps_recorder_page.dart';
import 'package:speleoloc/screens/map_viewer_page.dart';
import 'package:speleoloc/screens/raster_map_place_selector.dart';
import 'package:speleoloc/screens/ruuvi_history_page.dart';
import 'package:speleoloc/screens/ruuvi_live_page.dart';
import 'package:speleoloc/screens/scanner_page.dart';
import 'package:speleoloc/screens/settings/beacon_lab_page.dart';
import 'package:speleoloc/screens/settings/change_log_page.dart';
import 'package:speleoloc/screens/settings/data_export_import_page.dart';
import 'package:speleoloc/screens/settings/debug_info_page.dart';
import 'package:speleoloc/screens/settings/ftp_sync_progress_page.dart';
import 'package:speleoloc/screens/settings/ftp_sync_settings_page.dart';
import 'package:speleoloc/screens/settings/settings_beacons_page.dart';
import 'package:speleoloc/screens/settings/settings_database_page.dart';
import 'package:speleoloc/screens/settings/settings_general_page.dart';
import 'package:speleoloc/screens/settings/settings_image_compression_page.dart';
import 'package:speleoloc/screens/settings/settings_main_page.dart';
import 'package:speleoloc/screens/settings/settings_map_page.dart';
import 'package:speleoloc/screens/settings/settings_pdf_output_page.dart';
import 'package:speleoloc/screens/settings/settings_place_codes_page.dart';
import 'package:speleoloc/screens/settings/settings_qr_generation_page.dart';
import 'package:speleoloc/screens/settings/silexgis_sync_settings_page.dart';
import 'package:speleoloc/screens/settings/sql_command_runner.dart';
import 'package:speleoloc/screens/settings/sync_dashboard_page.dart';
import 'package:speleoloc/screens/settings/sync_page.dart';
import 'package:speleoloc/screens/settings/users_page.dart';
import 'package:speleoloc/screens/trip_report_templates_page.dart';
import 'package:speleoloc/services/documents_controller.dart';

import '../support/cell.dart';
import '../support/fixture.dart';

/// One screen of the app and how to open it on whatever data is loaded.
class ScreenEntry {
  const ScreenEntry(
    this.id,
    this.area,
    this.build, {
    this.core = false,
    this.needs = const {},
  });

  /// Stable name; it ends up in screenshot file names and in the report.
  final String id;
  final String area;

  /// Returns the page, or null when the data has nothing for it to open on.
  /// A null for [home] means the first screen itself.
  final Widget? Function(Fx fx) build;

  /// Part of the short list run on every change. Chosen as the screens a
  /// caver actually spends time on, plus one from each area so a breakage
  /// anywhere shows up early.
  final bool core;

  /// Platform plugins the screen cannot open without.
  final Set<Need> needs;
}

/// Every screen that can be reached in the app.
///
/// **Add an entry here when you add a screen.** The sweep opens each one in
/// every shape and language, which is what catches a layout that only
/// breaks on a narrow phone or with a longer translation; a screen missing
/// from this list is a screen nothing looks at.
final List<ScreenEntry> screenCatalogue = [
  // Home
  ScreenEntry('home', 'home', (fx) => null, core: true),
  ScreenEntry(
    'cave_form_new',
    'home',
    (fx) => const CaveFormPage(),
    core: true,
  ),
  ScreenEntry(
    'cave_form_edit',
    'home',
    (fx) => fx.cave == null ? null : CaveFormPage(cave: fx.cave),
  ),
  ScreenEntry('surface_areas', 'home', (fx) => const SurfaceAreasPage()),
  ScreenEntry('csv_caves_import', 'home', (fx) => const CSVCavesImportPage()),
  ScreenEntry(
    'cave_document_import',
    'home',
    (fx) => CaveDocumentImportPage(caves: fx.caves),
  ),

  // Cave
  ScreenEntry(
    'cave_places_list',
    'cave',
    (fx) =>
        fx.cave == null ? null : CavePlacesListPage(caveUuid: fx.cave!.uuid),
    core: true,
  ),
  ScreenEntry(
    'cave_areas',
    'cave',
    (fx) => fx.cave == null ? null : CaveAreasPage(caveUuid: fx.cave!.uuid),
  ),
  ScreenEntry(
    'cave_beacons',
    'cave',
    (fx) => fx.cave == null ? null : CaveBeaconsPage(caveUuid: fx.cave!.uuid),
    needs: {Need.bluetooth},
  ),
  ScreenEntry(
    'csv_places_import',
    'cave',
    (fx) => fx.cave == null
        ? null
        : CSVCavePlacesImportPage(caveUuid: fx.cave!.uuid),
  ),
  ScreenEntry(
    'generated_qr_codes',
    'cave',
    (fx) =>
        fx.cave == null ? null : GeneratedQRCodeViewer(caveUuid: fx.cave!.uuid),
    core: true,
  ),
  ScreenEntry(
    'cave_documents',
    'cave',
    (fx) => fx.cave == null
        ? null
        : GeofeatureDocumentsPage(
            source: DocumentsSource.cave(
              caveUuid: fx.cave!.uuid,
              caveTitle: fx.cave!.title,
            ),
          ),
    core: true,
  ),
  ScreenEntry(
    'documentation_files',
    'cave',
    (fx) => fx.cave == null
        ? null
        : DocumentationFilesPage(caveUuid: fx.cave!.uuid),
  ),

  // Places
  ScreenEntry(
    'cave_place_new',
    'places',
    (fx) => fx.cave == null ? null : CavePlacePage(caveUuid: fx.cave!.uuid),
  ),
  ScreenEntry(
    'cave_place_edit',
    'places',
    (fx) => fx.place == null
        ? null
        : CavePlacePage(caveUuid: fx.cave!.uuid, cavePlaceUuid: fx.place!.uuid),
    core: true,
  ),
  ScreenEntry(
    'cave_place_entrance',
    'places',
    (fx) => fx.entrance == null
        ? null
        : CavePlacePage(
            caveUuid: fx.cave!.uuid,
            cavePlaceUuid: fx.entrance!.uuid,
          ),
  ),
  ScreenEntry(
    'place_documents',
    'places',
    (fx) => fx.place == null
        ? null
        : GeofeatureDocumentsPage(
            source: DocumentsSource.cavePlace(
              cavePlaceUuid: fx.place!.uuid,
              cavePlaceTitle: fx.place!.title,
              caveTitle: fx.cave!.title,
            ),
          ),
  ),
  ScreenEntry(
    'area_documents',
    'places',
    (fx) => fx.area == null
        ? null
        : GeofeatureDocumentsPage(
            source: DocumentsSource.caveArea(
              caveAreaUuid: fx.area!.uuid,
              caveAreaTitle: fx.area!.title,
              caveTitle: fx.cave!.title,
            ),
          ),
  ),

  // Raster maps
  ScreenEntry(
    'raster_maps',
    'raster_maps',
    (fx) => fx.cave == null ? null : RasterMapsPage(caveUuid: fx.cave!.uuid),
    core: true,
  ),
  ScreenEntry(
    'raster_map_form_new',
    'raster_maps',
    (fx) => fx.cave == null ? null : RasterMapForm(caveUuid: fx.cave!.uuid),
  ),
  ScreenEntry(
    'raster_map_form_edit',
    'raster_maps',
    (fx) => fx.map == null
        ? null
        : RasterMapForm(caveUuid: fx.cave!.uuid, rasterMap: fx.map),
  ),
  ScreenEntry(
    'map_viewer',
    'raster_maps',
    (fx) => fx.place == null
        ? null
        : MapViewerPage(cavePlaceUuid: fx.place!.uuid, caveUuid: fx.cave!.uuid),
    core: true,
  ),
  ScreenEntry(
    'raster_map_place_selector',
    'raster_maps',
    (fx) => fx.map == null || fx.place == null
        ? null
        : RasterMapPlaceSelectorPage(
            rasterMap: fx.map!,
            cavePlaceUuid: fx.place!.uuid,
            cavePlacesWithDefinitions: fx.placesOnMap,
            existingDefinition: fx.definition,
          ),
  ),

  // Surface map
  ScreenEntry(
    'cave_map',
    'surface_map',
    (fx) => const CaveMapPage(),
    core: true,
  ),
  ScreenEntry(
    'cave_map_focused',
    'surface_map',
    (fx) => fx.cave == null
        ? null
        : CaveMapPage(focusCaveUuids: {fx.cave!.uuid}, highlightFocus: true),
  ),

  // Trips
  ScreenEntry(
    'cave_trip_list',
    'trip',
    (fx) => fx.cave == null ? null : CaveTripListPage(caveUuid: fx.cave!.uuid),
    core: true,
  ),
  ScreenEntry(
    'cave_trip_ended',
    'trip',
    (fx) => fx.endedTrip == null
        ? null
        : CaveTripPage(tripUuid: fx.endedTrip!.uuid),
    core: true,
  ),
  ScreenEntry(
    'cave_trip_open',
    'trip',
    (fx) =>
        fx.openTrip == null ? null : CaveTripPage(tripUuid: fx.openTrip!.uuid),
  ),
  ScreenEntry(
    'cave_trip_log',
    'trip',
    (fx) => fx.endedTrip == null
        ? null
        : CaveTripLogPage(tripUuid: fx.endedTrip!.uuid),
    core: true,
  ),
  ScreenEntry(
    'trip_media_points',
    'trip',
    (fx) => fx.endedTrip == null
        ? null
        : TripMediaPointsPage(tripUuid: fx.endedTrip!.uuid),
    needs: {Need.media},
  ),
  ScreenEntry(
    'trip_report_templates',
    'trip',
    (fx) => const TripReportTemplatesPage(),
  ),

  // QR
  ScreenEntry(
    'scanner',
    'qr',
    (fx) => ScannerPage(onScan: (_) {}),
    needs: {Need.camera},
  ),

  // Documents
  ScreenEntry(
    'text_document_editor',
    'documents',
    (fx) => fx.cave == null
        ? null
        : TextDocumentEditorPage(caveUuid: fx.cave!.uuid),
  ),
  ScreenEntry(
    'rich_text_editor',
    'documents',
    (fx) =>
        fx.cave == null ? null : RichTextEditorPage(caveUuid: fx.cave!.uuid),
  ),
  ScreenEntry(
    'sound_recorder',
    'documents',
    (fx) => fx.cave == null ? null : SoundRecorderPage(caveUuid: fx.cave!.uuid),
    needs: {Need.microphone},
  ),
  ScreenEntry(
    'camera_capture',
    'documents',
    (fx) => fx.cave == null ? null : CameraCapturePage(caveUuid: fx.cave!.uuid),
    needs: {Need.camera},
  ),
  ScreenEntry(
    'image_editor',
    'documents',
    (fx) => fx.photo == null
        ? null
        : ImageEditorPage(
            caveUuid: fx.cave!.uuid,
            initialFile: fx.fileOf(fx.photo!),
          ),
  ),
  ScreenEntry(
    'document_viewer_photo',
    'documents',
    (fx) => fx.photo == null
        ? null
        : DocumentationFileViewer(file: fx.fileOf(fx.photo!), doc: fx.photo!),
  ),
  ScreenEntry(
    'document_viewer_text',
    'documents',
    (fx) => fx.textDoc == null
        ? null
        : DocumentationFileViewer(
            file: fx.fileOf(fx.textDoc!),
            doc: fx.textDoc!,
          ),
  ),
  ScreenEntry(
    'image_gallery',
    'documents',
    (fx) => fx.photo == null
        ? null
        : ImageGalleryViewerPage(
            images: [fx.photo!],
            initialIndex: 0,
            docsDir: '${fx.docsDir}/documentation_files',
          ),
  ),
  ScreenEntry(
    'edit_documentation_file_new',
    'documents',
    (fx) => fx.cave == null
        ? null
        : EditDocumentationFilePage(caveUuid: fx.cave!.uuid),
  ),
  ScreenEntry(
    'edit_documentation_file',
    'documents',
    (fx) => fx.textDoc == null
        ? null
        : EditDocumentationFilePage(
            documentationFile: fx.textDoc,
            caveUuid: fx.cave!.uuid,
          ),
  ),

  // Beacons
  ScreenEntry(
    'beacon_tags',
    'beacons',
    (fx) => const BeaconTagsPage(),
    core: true,
    needs: {Need.bluetooth},
  ),
  ScreenEntry(
    'beacon_tag_edit',
    'beacons',
    (fx) => fx.beacon == null ? null : BeaconTagEditPage(item: fx.beacon!),
    needs: {Need.bluetooth},
  ),
  ScreenEntry(
    'beacon_lab',
    'beacons',
    (fx) => const BeaconLabPage(),
    needs: {Need.bluetooth},
  ),
  ScreenEntry(
    'ruuvi_live',
    'beacons',
    (fx) => fx.ruuvi == null
        ? null
        : RuuviLivePage(
            macAddress: fx.ruuvi!.macAddress!,
            title: fx.ruuvi!.title,
          ),
    needs: {Need.bluetooth},
  ),
  ScreenEntry(
    'ruuvi_history',
    'beacons',
    (fx) => fx.ruuvi == null
        ? null
        : RuuviHistoryPage(
            macAddress: fx.ruuvi!.macAddress!,
            title: fx.ruuvi!.title,
          ),
    needs: {Need.bluetooth},
  ),

  // GPS
  ScreenEntry(
    'gps_recorder',
    'gps',
    (fx) => const GpsRecorderPage(),
    needs: {Need.location},
  ),

  // Sync
  ScreenEntry('sync_page', 'sync', (fx) => const SyncPage()),
  ScreenEntry('sync_dashboard', 'sync', (fx) => const SyncDashboardPage()),
  ScreenEntry('ftp_sync_settings', 'sync', (fx) => const FtpSyncSettingsPage()),
  ScreenEntry('ftp_sync_progress', 'sync', (fx) => const FtpSyncProgressPage()),
  ScreenEntry(
    'silexgis_sync_settings',
    'sync',
    (fx) => const SilexgisSyncSettingsPage(),
  ),
  ScreenEntry(
    'data_export_import',
    'sync',
    (fx) => const DataExportImportPage(),
  ),

  // Settings
  ScreenEntry(
    'settings_main',
    'settings',
    (fx) => const SettingsMainPage(),
    core: true,
  ),
  ScreenEntry(
    'settings_general',
    'settings',
    (fx) => const SettingsGeneralPage(),
    core: true,
  ),
  ScreenEntry(
    'settings_database',
    'settings',
    (fx) => const SettingsDatabasePage(),
  ),
  ScreenEntry(
    'settings_image_compression',
    'settings',
    (fx) => const SettingsImageCompressionPage(),
  ),
  ScreenEntry('settings_map', 'settings', (fx) => const SettingsMapPage()),
  ScreenEntry(
    'settings_pdf_output',
    'settings',
    (fx) => const SettingsPdfOutputPage(),
  ),
  ScreenEntry(
    'settings_place_codes',
    'settings',
    (fx) => const SettingsPlaceCodesPage(),
  ),
  ScreenEntry(
    'settings_qr_generation',
    'settings',
    (fx) => const SettingsQrGenerationPage(),
  ),
  ScreenEntry(
    'settings_beacons',
    'settings',
    (fx) => const SettingsBeaconsPage(),
    needs: {Need.bluetooth},
  ),
  ScreenEntry('users', 'settings', (fx) => const UsersPage()),
  ScreenEntry('change_log', 'settings', (fx) => const ChangeLogPage()),
  ScreenEntry('debug_info', 'settings', (fx) => const DebugInfoPage()),
  ScreenEntry(
    'sql_command_runner',
    'settings',
    (fx) => const SQLCommandRunner(),
  ),
];
