import 'package:flutter/material.dart';
import 'package:speleoloc/utils/app_exceptions.dart';

/// Centralised snackbar presentation for user-facing feedback.
///
/// Screens can call [SnackBarService.showError] with either an
/// [AppException] or a plain [String] and get consistent styling and
/// duration across the app.
class SnackBarService {
  const SnackBarService._();

  /// Duration used for error snackbars.
  static const Duration _errorDuration = Duration(seconds: 4);

  /// Duration used for informational snackbars.
  static const Duration _infoDuration = Duration(seconds: 2);

  /// Show an error message for [error]. When [error] is an [AppException],
  /// its [AppException.message] is used; otherwise `error.toString()`.
  static void showError(BuildContext context, Object error) {
    final msg = error is AppException ? error.message : error.toString();
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        duration: _errorDuration,
      ),
    );
  }

  /// Show a short informational message.
  static void showInfo(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: _infoDuration),
    );
  }
}
