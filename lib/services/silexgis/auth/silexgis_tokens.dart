/// What a token exchange or a refresh handed back.
class SilexgisTokens {
  const SilexgisTokens({
    required this.accessToken,
    required this.expiresAt,
    required this.refreshToken,
    required this.grantedScopes,
  });

  /// A signed document, checked against its signature rather than looked up.
  /// One already issued keeps working until it expires — revoking a session
  /// stops the *next* one, not this one.
  final String accessToken;

  final DateTime expiresAt;

  /// Null when `offline_access` was not granted. The exchange still succeeds
  /// and looks entirely healthy without one, which is why [hasOfflineAccess]
  /// exists: a device that never noticed would send the caver back to a
  /// password prompt every fifteen minutes.
  final String? refreshToken;

  /// The server's statement of what was actually granted, which is not
  /// necessarily what was asked for.
  final List<String> grantedScopes;

  bool get hasOfflineAccess => refreshToken != null;

  /// True with a margin, so a token that would lapse mid-request is renewed
  /// before it is used rather than after it fails.
  bool isExpired(
    DateTime now, {
    Duration margin = const Duration(minutes: 1),
  }) => !now.add(margin).isBefore(expiresAt);

  /// Null when [json] is not a token answer at all — something in front of
  /// the server can answer `200` with a page of its own, and that says
  /// nothing about the token that was presented.
  static SilexgisTokens? tryParse(Map<String, Object?> json, DateTime now) {
    final access = json['access_token'];
    final refresh = json['refresh_token'];
    final expiresIn = json['expires_in'];
    final scope = json['scope'];
    if (access is! String || access.isEmpty) return null;
    if (refresh != null && refresh is! String) return null;
    if (expiresIn != null && expiresIn is! num) return null;
    if (scope != null && scope is! String) return null;
    return fromJson(json, now);
  }

  static SilexgisTokens fromJson(Map<String, Object?> json, DateTime now) {
    final expiresIn = (json['expires_in'] as num?)?.toInt() ?? 0;
    return SilexgisTokens(
      accessToken: json['access_token']! as String,
      expiresAt: now.add(Duration(seconds: expiresIn)),
      refreshToken: json['refresh_token'] as String?,
      grantedScopes: (json['scope'] as String? ?? '')
          .split(' ')
          .where((s) => s.isNotEmpty)
          .toList(growable: false),
    );
  }
}

/// What a `401 auth.mfa_required` says about how this account can finish
/// signing in.
class TwoFactorChallenge {
  const TwoFactorChallenge({
    required this.methods,
    required this.preferredMethod,
    required this.recoveryAccepted,
    required this.cookie,
  });

  /// What this account can currently use — `authenticator`, `email`, `sms`.
  final List<String> methods;

  /// The one to offer first.
  final String? preferredMethod;

  /// **Always true**, and offering only [methods] can strand somebody with no
  /// way in: every method can be taken away by a person other than the one
  /// signing in. Recovery codes are what stops that from being a lockout.
  final bool recoveryAccepted;

  /// The half-finished sign-in's cookie. Asking for a code that has to be
  /// *sent* needs it, and names no account in the body — naming one would let
  /// the call be used to discover addresses or to send mail to somebody else's.
  final String cookie;

  /// A code read from the caver's own application needs nothing sent; asking
  /// for one is answered `auth.mfa_method_not_delivered`.
  static const String authenticator = 'authenticator';

  /// A recovery code travels in the same field as an ordinary one, prefixed.
  static String asRecoveryCode(String code) => 'recovery:$code';
}
