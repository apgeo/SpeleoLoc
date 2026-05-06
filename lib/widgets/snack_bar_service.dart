import 'dart:async';
import 'package:flutter/material.dart';
import 'package:speleoloc/utils/app_exceptions.dart';
import 'package:speleoloc/utils/navigator_key.dart';

// ---------------------------------------------------------------------------
// Public types
// ---------------------------------------------------------------------------

/// Severity level of a toast notification.
enum ToastType { info, success, warning, error }

// ---------------------------------------------------------------------------
// Public API — all methods are context-free; they use [navigatorKey].
// ---------------------------------------------------------------------------

/// Centralised overlay-toast service.
///
/// Multiple toasts stack at the bottom of the screen and auto-dismiss
/// independently, so rapid messages are always visible without queuing.
///
/// Call [showError], [showSuccess], [showWarning], or [showInfo] from
/// anywhere in the app — no [BuildContext] required.
class SnackBarService {
  const SnackBarService._();

  static const _errorDuration   = Duration(seconds: 5);
  static const _warningDuration = Duration(seconds: 4);
  static const _successDuration = Duration(seconds: 3);
  static const _infoDuration    = Duration(seconds: 2);

  /// Show a red error toast. Accepts [AppException] or any [Object].
  static void showError(Object error, {Duration? duration}) {
    final msg = error is AppException ? error.message : error.toString();
    _ToastManager.instance.show(msg, ToastType.error,
        duration: duration ?? _errorDuration);
  }

  /// Show a green success / confirmation toast.
  static void showSuccess(String message, {Duration? duration}) =>
      _ToastManager.instance.show(message, ToastType.success,
          duration: duration ?? _successDuration);

  /// Show an amber warning toast (validation failures, non-critical issues).
  static void showWarning(String message, {Duration? duration}) =>
      _ToastManager.instance.show(message, ToastType.warning,
          duration: duration ?? _warningDuration);

  /// Show a blue informational toast.
  static void showInfo(String message, {Duration? duration}) =>
      _ToastManager.instance.show(message, ToastType.info,
          duration: duration ?? _infoDuration);
}

// ---------------------------------------------------------------------------
// Internal implementation
// ---------------------------------------------------------------------------

class _ToastData {
  final int id;
  final String message;
  final ToastType type;
  final Duration duration;

  const _ToastData(
      {required this.id,
      required this.message,
      required this.type,
      required this.duration});
}

class _ToastManager {
  _ToastManager._();
  static final instance = _ToastManager._();

  final _hostKey = GlobalKey<_ToastHostState>();
  OverlayEntry? _entry;

  void show(String message, ToastType type, {required Duration duration}) {
    final overlay = navigatorKey.currentState?.overlay;
    if (overlay == null) return;

    if (_entry == null) {
      _entry = OverlayEntry(builder: (_) => _ToastHost(hostKey: _hostKey));
      overlay.insert(_entry!);
    }

    final data = _ToastData(
      id: DateTime.now().microsecondsSinceEpoch,
      message: message,
      type: type,
      duration: duration,
    );
    _hostKey.currentState?.addToast(data);
  }
}

// ---------------------------------------------------------------------------
// Toast host widget — lives in the overlay and manages the toast stack.
// ---------------------------------------------------------------------------

class _ToastHost extends StatefulWidget {
  final GlobalKey<_ToastHostState> hostKey;
  const _ToastHost({required this.hostKey}) : super(key: hostKey);

  @override
  State<_ToastHost> createState() => _ToastHostState();
}

class _ToastHostState extends State<_ToastHost> with TickerProviderStateMixin {
  final _toasts = <_LiveToast>[];

  void addToast(_ToastData data) {
    if (!mounted) return;
    final ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    final toast = _LiveToast(data: data, controller: ctrl);
    setState(() => _toasts.insert(0, toast)); // newest at top
    ctrl.forward();
    Future.delayed(data.duration, () => _dismiss(toast));
  }

  Future<void> _dismiss(_LiveToast toast) async {
    if (!mounted || !_toasts.contains(toast)) return;
    await toast.controller.reverse();
    if (!mounted) return;
    setState(() => _toasts.remove(toast));
    toast.controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom + 8.0;
    return Positioned(
      bottom: bottomPad,
      left: 16,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _toasts.reversed.map(_buildToast).toList(),
      ),
    );
  }

  Widget _buildToast(_LiveToast t) {
    return SlideTransition(
      key: ValueKey(t.data.id),
      position: Tween<Offset>(
              begin: const Offset(0, 0.6), end: Offset.zero)
          .animate(
              CurvedAnimation(parent: t.controller, curve: Curves.easeOutCubic)),
      child: FadeTransition(
        opacity:
            CurvedAnimation(parent: t.controller, curve: Curves.easeIn),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: _ToastCard(data: t.data, onDismiss: () => _dismiss(t)),
        ),
      ),
    );
  }
}

class _LiveToast {
  final _ToastData data;
  final AnimationController controller;
  _LiveToast({required this.data, required this.controller});
}

// ---------------------------------------------------------------------------
// Individual toast card
// ---------------------------------------------------------------------------

class _ToastCard extends StatelessWidget {
  final _ToastData data;
  final VoidCallback onDismiss;

  const _ToastCard({required this.data, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (data.type) {
      ToastType.info    => (const Color(0xFF1565C0), Icons.info_outline),
      ToastType.success => (const Color(0xFF2E7D32), Icons.check_circle_outline),
      ToastType.warning => (const Color(0xFFE65100), Icons.warning_amber_rounded),
      ToastType.error   => (const Color(0xFFC62828), Icons.error_outline),
    };

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(8),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onDismiss,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  data.message,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      height: 1.35),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close, color: Colors.white70, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

