import 'package:flutter/material.dart';

/// Keeps app content out from under the system navigation bar.
///
/// Android 15+ forces edge-to-edge for apps targeting SDK 35+, so the
/// 3-button navigation bar is drawn over the app. Scaffold only insets its
/// own `bottomNavigationBar`/FAB; buttons placed at the bottom of a body
/// (Positioned overlays, bottom rows in Columns) end up unclickable under
/// the bar. Applying the inset once here covers every route, dialog and
/// sheet, and descendants see zero bottom padding so nothing double-pads.
///
/// The top edge is left to AppBars, which already extend behind the status
/// bar. The inset is zero where the system reserves no space (older Android,
/// or while the keyboard is up, since `padding` excludes `viewInsets`).
class SystemBarsInsetGuard extends StatelessWidget {
  const SystemBarsInsetGuard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Painted behind the translucent nav bar so the strip matches the app
    // instead of showing the window background.
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(top: false, child: child),
    );
  }
}
