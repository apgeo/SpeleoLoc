/// The one action a client takes in response to a failure.
///
/// Every failure this surface can answer with names exactly one of these, so
/// the branch lives in one place instead of a case per code.
enum SilexgisAction {
  /// Send the same request again, unchanged, after a backoff.
  retry,

  /// Refresh the credential, or sign in again; then send the request again.
  reAuth,

  /// Take what the answer carries — the server's row, or the thing it names
  /// as missing — change the request accordingly, and send it again.
  applyAndResubmit,

  /// Only a human can move this forward. Say what the server said; do not
  /// invent a diagnosis.
  surfaceToUser,

  /// Nothing the device can do makes *this request, as sent* succeed. It is
  /// not "give up on syncing": the caver's data is still on the device, which
  /// is the source of truth, and a later run may well succeed because the
  /// installation changed.
  stop,

  /// Informational. The request succeeded and this is an annotation on it.
  ignore,
}

/// Stable `code` values this surface answers with.
///
/// Branch on these, never on `detail` and never on `title`: a detail is a
/// sentence for a human reading a log — untranslated, unstable, sometimes
/// absent.
class SilexgisCodes {
  const SilexgisCodes._();

  // Reading.
  static const String setNotFound = 'sync.set_not_found';
  static const String cursorInvalid = 'sync.cursor_invalid';
  static const String cursorStale = 'sync.cursor_stale';

  // Editing a sync set.
  static const String rootNotFound = 'sync.root_not_found';
  static const String cavingGroupNotFound = 'sync.caving_group_not_found';
  static const String cavingGroupForbidden = 'sync.caving_group_forbidden';
  static const String setRevisionRequired = 'sync.set_revision_required';
  static const String setConflict = 'sync.set_conflict';
  static const String validationFailed = 'validation.failed';

  // A whole batch.
  static const String contractUnsupported = 'sync.contract_unsupported';
  static const String batchTooLarge = 'sync.batch_too_large';
  static const String batchConflict = 'sync.batch_conflict';

  // One row inside a 200.
  static const String conflict = 'sync.conflict';
  static const String rowNotFound = 'sync.row_not_found';
  static const String idConflict = 'sync.id_conflict';
  static const String rowDeleted = 'sync.row_deleted';
  static const String rowForbidden = 'sync.row_forbidden';
  static const String rowDeleteForbidden = 'sync.row_delete_forbidden';
  static const String createForbidden = 'access.create_forbidden';
  static const String parentRequired = 'sync.parent_required';
  static const String parentNotFound = 'sync.parent_not_found';
  static const String parentForbidden = 'sync.parent_forbidden';
  static const String locationForbidden = 'sync.location_forbidden';
  static const String geometryInvalid = 'sync.geometry_invalid';
  static const String typeUnknown = 'sync.type_unknown';
  static const String kindUnsupported = 'sync.kind_unsupported';

  // The QR landing route.
  static const String qrNotFound = 'qr.not_found';
}

/// An RFC 9457 problem document, as this surface answers one.
///
/// Two answers are problem documents with **no** `code` and are the exceptions
/// to everything else: a `401`, and the QR route's `429`. Both are produced
/// before the route runs — the first by authentication, the second by the rate
/// limiter — so there is no handler to mint one. That is why [action] branches
/// on [status] first: a client that reaches for `code` before looking at the
/// status finds none on those two and falls through, which for a `401` means
/// never refreshing the credential.
class SilexgisProblem {
  const SilexgisProblem({
    required this.status,
    this.code,
    this.title,
    this.detail,
    this.traceId,
    this.type,
  });

  final int status;
  final String? code;
  final String? title;

  /// A sentence for a human reading a log. Show it verbatim when there is
  /// nothing else to say; never branch on it.
  final String? detail;

  /// The framework's correlation identifier, for reading a server log with.
  /// Nothing on a device branches on it.
  final String? traceId;

  final String? type;

  /// Reads a problem document out of a decoded response body.
  ///
  /// Returns null when [body] is not one — on a `4xx`/`5xx` that is neither a
  /// `401` nor a `429`, a body that does not parse as a problem document came
  /// from a proxy, a captive portal or a load balancer and is a transport
  /// failure rather than a server verdict. The two exceptions are synthesised
  /// from the status instead of being refused, because letting that rule reach
  /// a `401` would retry an expired token for ever instead of refreshing it.
  static SilexgisProblem? tryParse(int status, Object? body) {
    if (body is Map) {
      final map = body.cast<Object?, Object?>();
      final reportedStatus = map['status'];
      final looksLikeProblem =
          map.containsKey('code') ||
          map.containsKey('title') ||
          reportedStatus is int;
      if (looksLikeProblem) {
        return SilexgisProblem(
          status: status,
          code: map['code'] as String?,
          title: map['title'] as String?,
          detail: map['detail'] as String?,
          traceId: map['traceId'] as String?,
          type: map['type'] as String?,
        );
      }
    }
    if (status == 401) {
      return const SilexgisProblem(status: 401, title: 'Unauthorized');
    }
    return null;
  }

  /// The one action to take. See [SilexgisAction].
  SilexgisAction get action {
    // Status first: the two codeless answers are decided here or not at all.
    if (status == 401) return SilexgisAction.reAuth;
    if (status == 429) return SilexgisAction.retry;
    if (status >= 500) return SilexgisAction.retry;

    switch (code) {
      case SilexgisCodes.cursorInvalid:
      case SilexgisCodes.cursorStale:
      case SilexgisCodes.setRevisionRequired:
      case SilexgisCodes.setConflict:
      case SilexgisCodes.batchTooLarge:
        return SilexgisAction.applyAndResubmit;

      case SilexgisCodes.batchConflict:
        return SilexgisAction.retry;

      case SilexgisCodes.contractUnsupported:
      case SilexgisCodes.validationFailed:
        return SilexgisAction.stop;

      case SilexgisCodes.setNotFound:
      case SilexgisCodes.rootNotFound:
      case SilexgisCodes.cavingGroupNotFound:
      case SilexgisCodes.cavingGroupForbidden:
      case SilexgisCodes.qrNotFound:
        return SilexgisAction.surfaceToUser;
    }

    // A `4xx` this build has not heard of. The batch as sent cannot be
    // applied, and looping on it would not change that; a code that has to be
    // handled differently is a contract change, and arrives with one.
    return SilexgisAction.stop;
  }

  @override
  String toString() =>
      'SilexgisProblem($status${code == null ? '' : ' $code'}'
      '${detail == null ? '' : ': $detail'})';
}
