/// Decides, once per run, whether file bytes may be sent now.
///
/// Rows that carry no file never ask: only the bytes wait.
abstract interface class SilexgisFileSendingGate {
  /// Whether [files] files totalling [bytes] may go in this run.
  Future<bool> mayFilesGo({required int files, required int bytes});
}

/// Lets every file go. For a run with nothing to decide, and for tests about
/// something else.
class SilexgisFilesAlwaysGo implements SilexgisFileSendingGate {
  const SilexgisFilesAlwaysGo();

  @override
  Future<bool> mayFilesGo({required int files, required int bytes}) async =>
      true;
}
