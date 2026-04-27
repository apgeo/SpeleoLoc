import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

// Re-export moved ValueNotifiers so existing import of `constants.dart`
// keeps resolving `debugModeNotifier` / `homePageRefreshNotifier`.
export 'package:speleoloc/state/app_notifiers.dart';

final dateFormat = DateFormat('yyyy/MM/dd');

// App-wide constants
const String appName = 'Speleo Loc';

// Colors
const Color primaryColor = Colors.blue;
const Color secondaryColor = Colors.green;

// Sizes
const double defaultPadding = 16.0;
const double iconSize = 24.0;

// Strings
const String deleteConfirm = 'Are you sure you want to delete this item?';
const String addSuccess = 'Item added successfully';
const String deleteSuccess = 'Item deleted successfully';

// Routes
const String homeRoute = '/';
const String caveRoute = '/cave';
const String cavePlaceRoute = '/cave_place';
const String cavePlaceViewRoute = '/cave_place_view';
const String rasterMapsRoute = '/raster_maps';
const String settingsRoute = '/settings';
const double zoomTextThreshold = 2.0;

// Feature flags
const bool showCaveDeleteButtons = false;

/// When true, the data export page shows an option to include FTP account
/// passwords in the archive. Disable in production builds.
const bool exportFtpPasswordsEnabled = true;

/// When true, holding the QR scan button for 2.5 s on the home screen opens
/// a manual QR-code input dialog (for testing without a physical scanner).
const bool enableQrManualInput = true;

// Configuration keys
const String qrGenerationConfigKey = 'qr_code_generation';
const String pdfOutputConfigKey = 'pdf_output_config';
const String lastOpenCaveKey = 'last_open_cave';

// Default QR label template
const String defaultLabelTemplate = '@place_title, @depth';

// Deep link scheme
const String deepLinkPrefix = 'sp://';

// Data export/import
const String lastExportTimestampKey = 'last_export_timestamp';

// Saved app language for localization
const String appLanguageKey = 'app_language';

// Home page UI
const String showHomeToolbarKey = 'show_home_toolbar';

// Image compression settings
const String imageCompressionConfigKey = 'image_compression';

// Compact nav bar state
const String compactNavBarKey = 'compact_nav_bar';

// QR code viewer: auto-refresh after returning from settings
const bool autoRefreshQrAfterSettings = true;

// Cave trip routes
const String caveTripRoute = '/cave_trip';
const String caveTripListRoute = '/cave_trip_list';
const String caveTripLogRoute = '/cave_trip_log';
const String tripReportTemplatesRoute = '/trip_report_templates';

// Cave trip config key
const String activeTripConfigKey = 'active_trip_id';

// Auto-add entrance cave place when creating a new cave
const String autoAddEntrancePlaceKey = 'auto_add_entrance_place';
