import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/sync/ftp/ftp_archive_deferrals.dart';

void main() {
  const a = 'speleo_loc_sync_1000_deadbeef.zip';
  const b = 'speleo_loc_sync_2000_cafebabe.zip';

  test('reads the older name-and-size lines as unreadable archives', () {
    final d = FtpArchiveDeferrals.parse('$a\t42');

    expect(d.holding(a, 42, 'any')?.reason, FtpDeferralReason.unreadable);
    expect(d.holding(a, 43, 'any'), isNull, reason: 'the file changed');
    expect(d.serialize(), '$a\t42', reason: 'still readable by older apps');
  });

  test('every reason survives a round trip through storage', () {
    final d = FtpArchiveDeferrals.parse(null)
      ..markTooNew(a, 10, appVersion: '1.0+1/36', detail: 'v2.0')
      ..markImportFailed(
        b,
        20,
        appVersion: '1.0+1/36',
        detail: 'constraint\tfailed\non two lines',
      );

    final back = FtpArchiveDeferrals.parse(d.serialize());

    final tooNew = back.holding(a, 10, '1.0+1/36')!;
    expect(tooNew.reason, FtpDeferralReason.tooNew);
    expect(tooNew.detail, 'v2.0');
    final failed = back.holding(b, 20, '1.0+1/36')!;
    expect(failed.reason, FtpDeferralReason.importFailed);
    expect(failed.runsLeft, FtpArchiveDeferrals.failedImportSkippedRuns);
    expect(failed.detail, 'constraint failed on two lines');
  });

  test('another app version releases what this one could not import', () {
    final d = FtpArchiveDeferrals.parse(null)
      ..markTooNew(a, 10, appVersion: 'old', detail: 'v2.0')
      ..markImportFailed(b, 20, appVersion: 'old', detail: 'x');

    expect(d.holding(a, 10, 'new'), isNull);
    expect(d.holding(b, 20, 'new'), isNull);
  });

  test('a failed import is held for a fixed number of runs', () {
    final d = FtpArchiveDeferrals.parse(null)
      ..markImportFailed(a, 10, appVersion: 'v', detail: 'x');

    for (var i = 0; i < FtpArchiveDeferrals.failedImportSkippedRuns; i++) {
      expect(d.holding(a, 10, 'v'), isNotNull, reason: 'run $i');
      d.countSkippedRun(a);
    }
    expect(d.holding(a, 10, 'v'), isNull);
  });

  test('forgets archives that left the server', () {
    final d = FtpArchiveDeferrals.parse('$a\t1\n$b\t2')..retainOnly({b});

    expect(d.serialize(), '$b\t2');
  });
}
