import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

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
const String rasterMapsRoute = '/raster_maps';
const String settingsRoute = '/settings';
const double zoomTextThreshold = 2.0;

// Feature flags
const bool showCaveDeleteButtons = false;

/// Runtime debug mode activated by tapping the home-page title 9 times.
/// Listen via [debugModeNotifier] to react to changes.
final ValueNotifier<bool> debugModeNotifier = ValueNotifier<bool>(false);

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

// Image compression settings
const String imageCompressionConfigKey = 'image_compression';

// Compact nav bar state
const String compactNavBarKey = 'compact_nav_bar';

// QR code viewer: auto-refresh after returning from settings
const bool autoRefreshQrAfterSettings = true;
