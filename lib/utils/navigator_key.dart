import 'package:flutter/material.dart';

/// Application-wide [NavigatorState] key.
///
/// Used by [SnackBarService] to insert overlay toasts without requiring a
/// [BuildContext] at call sites.  Also shared with [DeepLinkHandler].
final navigatorKey = GlobalKey<NavigatorState>();
