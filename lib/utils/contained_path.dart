import 'package:path/path.dart' as p;

// File names that arrive from outside this device (archive entries, synced
// rows, names reported by a document provider) are untrusted: joined onto a
// folder as they are, `../x` or `/x` reaches files the app never meant to
// touch, the live database among them. Every such name goes through here
// before it becomes a path.

final RegExp _driveLetter = RegExp('^[A-Za-z]:');

/// The non-empty segments of [name], or null when the name is not a safe
/// relative path. Both separators count, so a name written on Windows reads
/// the same on every platform.
List<String>? _relativeSegments(String name) {
  if (name.isEmpty || name.contains('\u0000')) return null;
  final unified = name.replaceAll(r'\', '/');
  if (unified.startsWith('/') || _driveLetter.hasMatch(unified)) return null;
  final segments = <String>[];
  for (final segment in unified.split('/')) {
    if (segment.isEmpty || segment == '.') continue;
    if (segment == '..') return null;
    segments.add(segment);
  }
  return segments.isEmpty ? null : segments;
}

/// Returns the path [relativeName] names inside [baseDir], or null when it
/// would name anything else: an absolute name, one with a `..` segment or a
/// NUL, or one that resolves to [baseDir] itself.
///
/// Nested names such as `documentation_files/a.jpg` stay valid.
String? containedPath(String baseDir, String relativeName) {
  final segments = _relativeSegments(relativeName);
  if (segments == null) return null;
  final resolved = p.joinAll([baseDir, ...segments]);
  return p.isWithin(baseDir, resolved) ? resolved : null;
}

/// Whether [name] is one plain file name: no separator of either kind, not
/// `.` or `..`, not empty and without a NUL.
bool isPlainFileName(String name) =>
    !name.contains('/') &&
    !name.contains(r'\') &&
    _relativeSegments(name) != null;
