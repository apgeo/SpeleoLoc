/// Unified application exception hierarchy (Phase 4.5).
///
/// Repository and service layers should wrap low-level failures
/// (Drift / Sqlite / dart:io) in one of these typed exceptions so screens
/// can catch a stable, framework-independent type and render the
/// user-facing message via `SnackBarService.showError`.
library;

/// Base class for all application-level exceptions.
///
/// [message] is a short, user-presentable message. [cause] preserves the
/// underlying exception (Drift error, PlatformException, FormatException, …)
/// for logging; it is **not** meant to be shown directly to the user.
abstract class AppException implements Exception {
  /// Short user-presentable description of the failure.
  final String message;

  /// Underlying exception that triggered this failure (if any).
  final Object? cause;

  /// Optional stack trace associated with [cause].
  final StackTrace? stackTrace;

  const AppException(this.message, {this.cause, this.stackTrace});

  @override
  String toString() {
    final causeText = cause != null ? ' (cause: $cause)' : '';
    return '$runtimeType: $message$causeText';
  }
}

/// Raised by repositories when a database operation fails.
class DbException extends AppException {
  const DbException(
    super.message, {
    super.cause,
    super.stackTrace,
  });
}

/// Raised when input data fails a business-level validation rule
/// (e.g. empty required field, malformed QR payload).
class ValidationException extends AppException {
  /// Optional field identifier this violation relates to.
  final String? field;

  const ValidationException(
    super.message, {
    this.field,
    super.cause,
    super.stackTrace,
  });
}

/// Raised by services that interact with the filesystem or platform
/// I/O (image compression, archive read/write, document file lookup).
class IoException extends AppException {
  /// Optional path that triggered the failure.
  final String? path;

  const IoException(
    super.message, {
    this.path,
    super.cause,
    super.stackTrace,
  });
}
