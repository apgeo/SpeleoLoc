/// Builds the pseudo-locale the UI tests run in: English, made longer and
/// stranger in the ways real translations are.
///
/// Each string grows by about 40% — German and Romanian run that much past
/// English in UI text — gains accented capitals and descenders that test
/// line height and glyph coverage, and is wrapped in brackets, so a
/// string cut off by its container is visibly missing its closing one.
/// Placeholders such as `{name}` are left untouched, or the app's own
/// substitution would break.
Map<String, String> pseudoLocalize(Map<String, String> english) => {
  for (final entry in english.entries) entry.key: pseudoString(entry.value),
};

const _accents = {
  'a': 'á',
  'e': 'ë',
  'i': 'ï',
  'o': 'ö',
  'u': 'ü',
  'c': 'ç',
  'n': 'ñ',
  's': 'ș',
  't': 'ț',
  'y': 'ÿ',
  'A': 'Â',
  'E': 'É',
  'I': 'Î',
  'O': 'Ö',
  'U': 'Ü',
  'C': 'Ç',
  'S': 'Ș',
  'T': 'Ț',
};

String pseudoString(String text) {
  if (text.trim().isEmpty) return text;
  final out = StringBuffer('[');
  var letters = 0;
  var inPlaceholder = false;
  for (final rune in text.runes) {
    final char = String.fromCharCode(rune);
    if (char == '{') inPlaceholder = true;
    if (inPlaceholder) {
      out.write(char);
      if (char == '}') inPlaceholder = false;
      continue;
    }
    out.write(_accents[char] ?? char);
    if (RegExp(r'[A-Za-z]').hasMatch(char)) letters++;
  }
  // The padding goes at the end, where it lengthens a line without
  // splitting a word a reader would recognise.
  final extra = (letters * 0.4).ceil();
  if (extra > 0) out.write(' ${'ŷ' * extra}');
  out.write(']');
  return out.toString();
}
