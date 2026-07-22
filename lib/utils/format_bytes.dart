/// Human-readable byte size: `978 KB` below one megabyte, `12.4 MB`
/// from there on.
String formatByteSize(int bytes) {
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(0)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
