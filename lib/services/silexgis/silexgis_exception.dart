import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/utils/app_exceptions.dart';

/// Base of the failures the SilexGIS channel raises.
///
/// Every one names an [action] from the closed set the errors document
/// defines, so a caller branches once on the action rather than once per
/// failure type.
abstract class SilexgisException extends AppException {
  const SilexgisException(super.message, {super.cause, super.stackTrace});

  SilexgisAction get action;
}

/// The server answered, and its answer was a refusal.
class SilexgisProblemException extends SilexgisException {
  SilexgisProblemException(this.problem)
    : super(problem.detail ?? problem.title ?? 'Request refused');

  final SilexgisProblem problem;

  @override
  SilexgisAction get action => problem.action;

  int get status => problem.status;
  String? get code => problem.code;
}

/// The request never reached the application, or what came back was not this
/// API's.
///
/// On a mobile connection these are the common case rather than the exception:
/// a timeout, a dropped connection mid-page, a `502` with an HTML body from
/// something in front of the server, a redirect the API never issues. A
/// download holds no server-side state, so the request is repeatable exactly
/// as sent.
class SilexgisTransportException extends SilexgisException {
  const SilexgisTransportException(
    super.message, {
    this.status,
    super.cause,
    super.stackTrace,
  });

  /// The HTTP status, when there was one.
  final int? status;

  @override
  SilexgisAction get action => SilexgisAction.retry;
}

/// Signing in failed.
///
/// The sign-in routes answer with their own vocabulary — the `auth.*` codes on
/// the login and two-factor calls, and OAuth's `error`/`error_description` on
/// the token endpoint, which is not a problem document at all.
class SilexgisAuthException extends SilexgisException {
  const SilexgisAuthException(
    super.message, {
    this.code,
    this.status,
    this.action = SilexgisAction.surfaceToUser,
    super.cause,
  });

  /// An `auth.*` code, or an OAuth `error` value such as `invalid_grant`.
  final String? code;
  final int? status;

  @override
  final SilexgisAction action;

  /// The account has two-factor sign-in turned on and the password alone is
  /// not enough. Carries what this account can currently use.
  bool get isTwoFactorRequired => code == SilexgisAuthCodes.mfaRequired;
}

/// Codes the sign-in and two-factor calls answer with.
class SilexgisAuthCodes {
  const SilexgisAuthCodes._();

  static const String invalidCredentials = 'auth.invalid_credentials';
  static const String mfaRequired = 'auth.mfa_required';
  static const String mfaInvalid = 'auth.mfa_invalid';
  static const String lockedOut = 'auth.locked_out';
  static const String emailNotConfirmed = 'auth.email_not_confirmed';
  static const String mfaMethodNotDelivered = 'auth.mfa_method_not_delivered';
  static const String mfaMethodUnavailable = 'auth.mfa_method_unavailable';
  static const String mfaResendTooSoon = 'auth.mfa_resend_too_soon';
  static const String mfaSendFailed = 'auth.mfa_send_failed';
}
