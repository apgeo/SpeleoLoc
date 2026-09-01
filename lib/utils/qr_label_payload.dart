import 'package:speleoloc/utils/constants.dart';

/// Composes what a printed QR square actually encodes, and says when a label
/// would not resolve.
///
/// Two prefixes are possible and they reach different worlds. `sp://<code>` is
/// resolved by this application's own scanner and by nothing else: no camera
/// app and no browser opens it. `https://<installation>/q/<code>` is opened by
/// a stranger's phone **and** still resolves in this application, because the
/// scanner strips a URL down to the text after its last delimiter. A label
/// printed in the URL form works in both worlds; one printed in the `sp://`
/// form works in only one.
class QrLabelPayload {
  const QrLabelPayload._();

  /// The delimiters the scanner splits a URL on, and therefore the characters
  /// a code may not contain. Kept beside the payload rules rather than in the
  /// scanner because this is where a label is composed and where the problem
  /// can still be prevented.
  static const List<String> stripDelimiters = <String>['/', '='];

  /// What to encode in the square.
  ///
  /// [urlPrefix] wins when it is set; it is expected to end in `/`, and one is
  /// added if it does not, because the scanner takes the text after the last
  /// delimiter and a prefix without one would swallow the code.
  static String compose(
    String code, {
    String? urlPrefix,
    bool includeDeepLinkPrefix = true,
  }) {
    if (code.isEmpty) return code;
    final prefix = urlPrefix?.trim();
    if (prefix != null && prefix.isNotEmpty) {
      return prefix.endsWith('/') ? '$prefix$code' : '$prefix/$code';
    }
    return includeDeepLinkPrefix ? '$deepLinkPrefix$code' : code;
  }

  /// Whether a code survives being printed inside a URL and scanned back.
  ///
  /// A `/` or an `=` inside the code silently truncates it: the scanner splits
  /// on the rightmost delimiter, so everything before it is thrown away and
  /// the lookup fails. A hashed QR reference cannot contain either — its
  /// alphabet is `[0-9a-z]` — but a mirror-mode code is the place code
  /// verbatim, assembled from segments joined by a separator a caver types
  /// themselves.
  ///
  /// **Nothing else enforces this.** Not the scanner, which cannot know what
  /// was lost, and not the server, which resolves whatever it is given.
  static bool isScannable(String code) =>
      code.isNotEmpty && !stripDelimiters.any(code.contains);

  /// Whether a place-code segment separator is safe to print.
  ///
  /// The same rule as [isScannable], asked of the one field that lets a caver
  /// break every label at once: the separator joins every segment of every
  /// mirror-mode code allocated afterwards.
  static bool isSeparatorScannable(String separator) =>
      !stripDelimiters.any(separator.contains);
}
