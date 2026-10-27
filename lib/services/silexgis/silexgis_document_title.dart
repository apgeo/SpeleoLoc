/// A server document's title on this device.
///
/// A local documentation file keeps at most [maxLocalLength] characters of
/// title, and a server title may be longer. The full one stays in the
/// catalogue; the local row holds the cut one. A title is sent back up only
/// when the caver changed it: sending the cut one would rename the document
/// on the server for every reader, for nothing more than a phone's limit.
class SilexgisDocumentTitle {
  const SilexgisDocumentTitle._();

  static const int maxLocalLength = 50;

  /// [serverTitle] as a local row holds it.
  static String local(String serverTitle) {
    final runes = serverTitle.runes;
    if (runes.length <= maxLocalLength) return serverTitle;
    return String.fromCharCodes(runes.take(maxLocalLength));
  }

  /// Whether [localTitle] says anything [serverTitle] does not — that is,
  /// whether the caver changed it here.
  static bool changedLocally(String localTitle, String serverTitle) =>
      localTitle != local(serverTitle);
}
