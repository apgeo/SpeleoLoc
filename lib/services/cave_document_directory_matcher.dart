import 'package:speleoloc/data/source/database/app_database.dart';

/// How a source directory was resolved to a cave during bulk document import.
enum CaveDirMatchMethod {
  /// Directory name equals the cave title.
  title,

  /// Directory name starts with `<areaCode>-<caveCode>`.
  code,

  /// Assigned by the user in the review screen.
  manual,

  /// No cave could be resolved automatically.
  unmatched,
}

/// A cave together with the two identifiers used for code-based matching.
///
/// Kept free of the drift row type so the matching logic can be unit-tested
/// with plain values.
class CaveMatchCandidate {
  const CaveMatchCandidate({
    required this.caveUuid,
    required this.title,
    this.areaCode,
    this.caveCode,
  });

  final Uuid caveUuid;
  final String title;

  /// `surface_areas.general_area_identifier` of the cave's surface area.
  final String? areaCode;

  /// `caves.cave_local_index`.
  final String? caveCode;
}

/// Result of matching one directory name against a candidate list.
class DirectoryMatch {
  const DirectoryMatch(this.caveUuid, this.method);

  final Uuid? caveUuid;
  final CaveDirMatchMethod method;

  static const DirectoryMatch unmatched = DirectoryMatch(
    null,
    CaveDirMatchMethod.unmatched,
  );
}

/// Pure matcher that resolves a bulk-import subdirectory to a cave.
///
/// Two strategies are tried in order (see the feature spec):
///  a) case-insensitive equality of the directory name and a cave title, then
///  b) a leading `<areaCode>-<caveCode>` token (e.g. `2046-18 P. Fisurii`)
///     equal to a cave's `(surfaceArea.generalAreaIdentifier, caveLocalIndex)`.
///
/// When neither resolves a cave the caller falls back to asking the user.
class CaveDocumentDirectoryMatcher {
  const CaveDocumentDirectoryMatcher._();

  static DirectoryMatch match(
    String directoryName,
    List<CaveMatchCandidate> candidates,
  ) {
    final normalizedDir = directoryName.trim().toLowerCase();

    // a) exact title (normalised). Auto-match only when it is unambiguous —
    // if two in-scope caves share the title (titles are unique only within a
    // surface area, and can both be null-area), leave it for the user rather
    // than silently attaching to an arbitrary one.
    final titleMatches = candidates
        .where((c) => c.title.trim().toLowerCase() == normalizedDir)
        .toList();
    if (titleMatches.length == 1) {
      return DirectoryMatch(
        titleMatches.first.caveUuid,
        CaveDirMatchMethod.title,
      );
    }

    // b) leading area/cave code — likewise only on a unique hit.
    final code = parseLeadingCode(directoryName);
    if (code != null) {
      final area = code.areaCode.toLowerCase();
      final cave = code.caveCode.toLowerCase();
      final codeMatches = candidates.where((c) {
        final ca = c.areaCode?.trim().toLowerCase();
        final cc = c.caveCode?.trim().toLowerCase();
        return ca != null && cc != null && ca == area && cc == cave;
      }).toList();
      if (codeMatches.length == 1) {
        return DirectoryMatch(
          codeMatches.first.caveUuid,
          CaveDirMatchMethod.code,
        );
      }
    }

    return DirectoryMatch.unmatched;
  }

  /// Parses a leading `<areaCode>-<caveCode>` prefix from [directoryName].
  ///
  /// Only the first whitespace-delimited token is considered, so
  /// `2046-18 P. Fisurii` yields `(areaCode: '2046', caveCode: '18')` and the
  /// human-readable name after the space is ignored. The area code is the run
  /// before the first hyphen; the cave code is the remainder of the token.
  /// Returns `null` when there is no hyphen or either side is empty — a wrong
  /// parse simply matches no cave and falls through to the unmatched path.
  static ({String areaCode, String caveCode})? parseLeadingCode(
    String directoryName,
  ) {
    final trimmed = directoryName.trim();
    if (trimmed.isEmpty) return null;
    final head = trimmed.split(RegExp(r'\s')).first;
    final dash = head.indexOf('-');
    if (dash <= 0 || dash >= head.length - 1) return null;
    final areaCode = head.substring(0, dash);
    final caveCode = head.substring(dash + 1);
    if (areaCode.isEmpty || caveCode.isEmpty) return null;
    return (areaCode: areaCode, caveCode: caveCode);
  }
}
