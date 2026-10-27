import 'package:speleoloc/services/silexgis/model/sync_upload_result.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_runner.dart';

/// What a part made of its section's answers.
class SilexgisPartAnswers {
  const SilexgisPartAnswers({
    this.refusals = const <SilexgisRefusal>[],
    this.resend = const <SyncUploadItem>[],
    this.held = 0,
  });

  /// Items the caver should be told about.
  final List<SilexgisRefusal> refusals;

  /// Items to send once more in this run, already changed as their answer
  /// asked.
  final List<SyncUploadItem> resend;

  /// Items left waiting for a reviewer.
  final int held;
}

/// One section of an upload beside the feature rows: what goes in it, and what
/// to do with each item's answer.
///
/// A new section is added by writing a part and passing it to the upload
/// runner, which chunks every section together and sends them in one upload.
abstract interface class SilexgisUploadPart {
  SyncUploadSection get section;

  /// The items this run sends in [section].
  Future<List<SyncUploadItem>> build();

  /// Stores the answers to [sent]. [resent] is true for items sent a second
  /// time in this run, which are not sent a third.
  Future<SilexgisPartAnswers> apply(
    List<SyncUploadItem> sent,
    List<SyncRowResult> answers, {
    required bool resent,
  });
}
