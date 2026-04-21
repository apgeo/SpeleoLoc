import 'package:flutter/foundation.dart';

/// Runtime debug mode activated by tapping the home-page title 9 times.
/// Listen via [debugModeNotifier] to react to changes.
final ValueNotifier<bool> debugModeNotifier = ValueNotifier<bool>(false);

/// Increment to request HomePage layout/state refresh from settings screens
/// (used after destructive operations like DB restore that replace the
/// sqlite file and invalidate any in-flight Drift streams).
final ValueNotifier<int> homePageRefreshNotifier = ValueNotifier<int>(0);
