import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_upload_planner.dart';

/// What became of the files one run meant to send.
class SilexgisFilesReport {
  const SilexgisFilesReport({
    this.staged = 0,
    this.waitingForNetwork = 0,
    this.quotaExceeded = 0,
    this.tooLarge = 0,
    this.typeRefused = 0,
    this.missing = 0,
    this.failed = 0,
  });

  /// Files whose bytes were staged for this run's upload.
  final int staged;

  /// Files kept back because the caver keeps files for another network.
  final int waitingForNetwork;

  /// Files there was no room for on the installation.
  final int quotaExceeded;

  /// Files larger than the installation accepts.
  final int tooLarge;

  /// Files of a type the installation refuses.
  final int typeRefused;

  /// Files whose bytes are no longer on this device.
  final int missing;

  /// Files whose transfer stopped, or whose bytes came out different. The next
  /// run resumes or sends them again.
  final int failed;

  /// Files that wait for something the caver should know about.
  int get held =>
      waitingForNetwork +
      quotaExceeded +
      tooLarge +
      typeRefused +
      missing +
      failed;

  bool get isEmpty => staged == 0 && held == 0;

  SilexgisFilesReport plus(SilexgisFilesReport other) => SilexgisFilesReport(
    staged: staged + other.staged,
    waitingForNetwork: waitingForNetwork + other.waitingForNetwork,
    quotaExceeded: quotaExceeded + other.quotaExceeded,
    tooLarge: tooLarge + other.tooLarge,
    typeRefused: typeRefused + other.typeRefused,
    missing: missing + other.missing,
    failed: failed + other.failed,
  );
}

/// What the two document sections of one run share: the plan, and the
/// documents the `documents` part kept back or is sending again, which the
/// `documentLinks` part leaves out or sends again with them.
class SilexgisDocumentUploadRun {
  SilexgisDocumentPlan plan = const SilexgisDocumentPlan();

  /// Documents not sent in this run; their new links wait with them.
  final Set<Uuid> keptBack = <Uuid>{};

  /// Documents sent once more in this run, after their bytes were staged
  /// again.
  final Set<Uuid> resent = <Uuid>{};

  SilexgisFilesReport files = const SilexgisFilesReport();
}
