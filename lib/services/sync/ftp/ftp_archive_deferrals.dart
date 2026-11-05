/// Why an archive on the server is, for now, not downloaded again.
enum FtpDeferralReason {
  /// Damaged, or not an archive at all: retried only once its size changes.
  unreadable,

  /// Made by a newer app: retried once this app changes.
  tooNew,

  /// Its import failed: retried once this app changes or a few runs pass.
  importFailed,
}

/// What is remembered about one archive that is not downloaded again.
class FtpArchiveDeferral {
  const FtpArchiveDeferral({
    required this.size,
    required this.reason,
    this.appVersion = '',
    this.runsLeft = 0,
    this.detail = '',
  });

  /// Size of the file when it was deferred; any change means a new file.
  final int size;
  final FtpDeferralReason reason;

  /// The app that could not import it, as [FtpArchiveDeferrals.holding]
  /// compares it.
  final String appVersion;

  /// Runs that still skip a failed import before it is tried again.
  final int runsLeft;

  /// Short reason for the log, e.g. the version an archive needs.
  final String detail;
}

/// The archives on the server that a sync does not download again for now,
/// since doing so on every run costs a full download — every photo and map
/// of that device — each time.
///
/// Stored one per line as `name<TAB>size`, the format of a damaged archive
/// since before the other reasons existed, followed for those reasons by
/// `<TAB>reason<TAB>appVersion<TAB>runsLeft<TAB>detail`. An older app reads
/// a longer line as an entry for no file on the server and drops it.
class FtpArchiveDeferrals {
  FtpArchiveDeferrals._(this._entries);

  factory FtpArchiveDeferrals.parse(String? raw) {
    final entries = <String, FtpArchiveDeferral>{};
    for (final line in (raw ?? '').split('\n')) {
      final f = line.split('\t');
      if (f.length < 2 || f[0].isEmpty) continue;
      final size = int.tryParse(f[1]);
      if (size == null) continue;
      if (f.length == 2) {
        entries[f[0]] = FtpArchiveDeferral(
          size: size,
          reason: FtpDeferralReason.unreadable,
        );
        continue;
      }
      if (f.length < 6) continue;
      final reason = FtpDeferralReason.values.asNameMap()[f[2]];
      if (reason == null) continue;
      entries[f[0]] = FtpArchiveDeferral(
        size: size,
        reason: reason,
        appVersion: f[3],
        runsLeft: int.tryParse(f[4]) ?? 0,
        detail: f[5],
      );
    }
    return FtpArchiveDeferrals._(entries);
  }

  /// Runs that skip an archive whose import failed, before it is downloaded
  /// and tried again. Such failures come from the data, and another run
  /// rarely changes it; the archive's own device re-uploading does.
  static const int failedImportSkippedRuns = 4;

  static const int _maxDetailLength = 160;

  final Map<String, FtpArchiveDeferral> _entries;

  String serialize() => _entries.entries
      .map((e) {
        final d = e.value;
        if (d.reason == FtpDeferralReason.unreadable) {
          return '${e.key}\t${d.size}';
        }
        return [
          e.key,
          d.size,
          d.reason.name,
          _clean(d.appVersion),
          d.runsLeft,
          _clean(d.detail),
        ].join('\t');
      })
      .join('\n');

  /// Forgets archives that are no longer on the server.
  void retainOnly(Set<String> remoteNames) =>
      _entries.removeWhere((name, _) => !remoteNames.contains(name));

  /// The deferral that still keeps [name] from being downloaded, or null.
  /// [appVersion] identifies the running app.
  FtpArchiveDeferral? holding(String name, int size, String appVersion) {
    final d = _entries[name];
    if (d == null || d.size != size) return null;
    return switch (d.reason) {
      FtpDeferralReason.unreadable => d,
      FtpDeferralReason.tooNew => d.appVersion == appVersion ? d : null,
      FtpDeferralReason.importFailed =>
        d.appVersion == appVersion && d.runsLeft > 0 ? d : null,
    };
  }

  /// Counts one run that skipped [name] because its import failed, and
  /// returns the runs that will still skip it.
  int countSkippedRun(String name) {
    final d = _entries[name];
    if (d == null) return 0;
    final left = d.runsLeft > 0 ? d.runsLeft - 1 : 0;
    _entries[name] = FtpArchiveDeferral(
      size: d.size,
      reason: d.reason,
      appVersion: d.appVersion,
      runsLeft: left,
      detail: d.detail,
    );
    return left;
  }

  void markUnreadable(String name, int size) => _entries[name] =
      FtpArchiveDeferral(size: size, reason: FtpDeferralReason.unreadable);

  void markTooNew(
    String name,
    int size, {
    required String appVersion,
    required String detail,
  }) => _entries[name] = FtpArchiveDeferral(
    size: size,
    reason: FtpDeferralReason.tooNew,
    appVersion: appVersion,
    detail: detail,
  );

  void markImportFailed(
    String name,
    int size, {
    required String appVersion,
    required String detail,
  }) => _entries[name] = FtpArchiveDeferral(
    size: size,
    reason: FtpDeferralReason.importFailed,
    appVersion: appVersion,
    runsLeft: failedImportSkippedRuns,
    detail: detail,
  );

  void clear(String name) => _entries.remove(name);

  static String _clean(String s) {
    final flat = s.replaceAll(RegExp(r'[\t\r\n]+'), ' ');
    return flat.length <= _maxDetailLength
        ? flat
        : '${flat.substring(0, _maxDetailLength)}…';
  }
}
