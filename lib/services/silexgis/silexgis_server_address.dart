import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';

/// Why a typed server address was refused.
enum SilexgisAddressProblem {
  /// Not an absolute address with a host.
  malformed,

  /// Not `https://`. The password, the session cookie and the refresh token
  /// all travel on this connection, and neither Android's cleartext policy nor
  /// iOS's transport security covers the HTTP client this channel uses, so the
  /// application itself is the only thing that can refuse cleartext.
  notHttps,

  /// Carries a user name, password, query or fragment. None of these belongs
  /// in an installation's base address, and a user name and password typed
  /// into it would be stored and shown in plain text.
  extraParts,
}

/// The verdict on a typed server address: the address to store, or why not.
class SilexgisAddressCheck {
  const SilexgisAddressCheck.accepted(String this.address) : problem = null;

  const SilexgisAddressCheck.refused(SilexgisAddressProblem this.problem)
    : address = null;

  /// The normalised address — no trailing slash — when it was accepted.
  final String? address;

  final SilexgisAddressProblem? problem;

  bool get isAccepted => problem == null;
}

/// What counts as a server address, and when two of them name the same server.
///
/// Plain HTTP is allowed in a debug build only, and only to this machine: the
/// development server listens on `http://127.0.0.1`, and nothing that address
/// reaches leaves the device. A release build refuses it like any other.
abstract final class SilexgisServerAddress {
  /// Checks a typed address and normalises the one it accepts.
  static SilexgisAddressCheck check(
    String input, {
    bool allowLoopbackCleartext = kDebugMode,
  }) {
    final text = input.trim();
    // A space survives parsing as a percent-escape inside the host, which
    // then names a host nobody meant.
    if (text.isEmpty || text.contains(RegExp(r'\s'))) {
      return const SilexgisAddressCheck.refused(
        SilexgisAddressProblem.malformed,
      );
    }
    final uri = Uri.tryParse(text);
    if (uri == null || !uri.hasScheme) {
      return const SilexgisAddressCheck.refused(
        SilexgisAddressProblem.notHttps,
      );
    }
    if (!isSecure(uri, allowLoopbackCleartext: allowLoopbackCleartext)) {
      return const SilexgisAddressCheck.refused(
        SilexgisAddressProblem.notHttps,
      );
    }
    if (!uri.hasAuthority || uri.host.isEmpty || uri.host.contains('%')) {
      return const SilexgisAddressCheck.refused(
        SilexgisAddressProblem.malformed,
      );
    }
    if (uri.userInfo.isNotEmpty || uri.hasQuery || uri.hasFragment) {
      return const SilexgisAddressCheck.refused(
        SilexgisAddressProblem.extraParts,
      );
    }
    return SilexgisAddressCheck.accepted(_normalise(uri).toString());
  }

  /// Whether a request to [uri] may carry this channel's credentials.
  static bool isSecure(Uri uri, {bool allowLoopbackCleartext = kDebugMode}) {
    if (uri.scheme == 'https') return true;
    return allowLoopbackCleartext && uri.scheme == 'http' && _isLoopback(uri);
  }

  /// Throws before a request to [uri] can leave the device, unless it may
  /// carry this channel's credentials. Called on every request rather than
  /// once on the base address, so a profile stored before the address was
  /// checked, or an absolute address a server hands back, is held to the same
  /// rule.
  static void requireSecure(Uri uri) {
    if (!isSecure(uri)) throw const SilexgisInsecureAddressException();
  }

  /// Whether two stored addresses name the same server: the same scheme, host,
  /// port and path prefix. Letter case in the scheme and host, an explicit
  /// default port and a trailing slash do not make another server; anything
  /// else does, because an installation behind a reverse proxy is told apart
  /// from its neighbours by its path alone.
  static bool sameServer(String a, String b) {
    final left = Uri.tryParse(a.trim());
    final right = Uri.tryParse(b.trim());
    if (left == null || right == null) return false;
    final l = _normalise(left);
    final r = _normalise(right);
    return l.scheme == r.scheme &&
        l.host == r.host &&
        l.port == r.port &&
        l.path == r.path;
  }

  static Uri _normalise(Uri uri) =>
      uri.replace(path: uri.path.replaceFirst(RegExp(r'/+$'), ''));

  static bool _isLoopback(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'localhost') return true;
    return InternetAddress.tryParse(host)?.isLoopback ?? false;
  }
}
