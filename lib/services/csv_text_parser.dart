import 'package:csv/csv.dart';

/// Reads the text of a CSV file into rows of cells, every cell kept as
/// text, with Windows and old Mac line endings read as Unix ones.
///
/// The separator is taken from the header row: spreadsheets set up for
/// Romanian, and for most other locales that write the decimal mark as a
/// comma, save CSV with `;`. Whichever of `,` and `;` occurs more often in
/// that row outside double quotes is used; a tie keeps `,`.
List<List<dynamic>> parseCsvText(String content) {
  final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  return CsvToListConverter(
    fieldDelimiter: _headerDelimiter(normalized),
    eol: '\n',
    shouldParseNumbers: false,
  ).convert(normalized);
}

String _headerDelimiter(String text) {
  var commas = 0;
  var semicolons = 0;
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (c == '"') {
      // An escaped quote ("") flips twice and leaves the state as it was.
      quoted = !quoted;
    } else if (quoted) {
      continue;
    } else if (c == '\n') {
      break;
    } else if (c == ',') {
      commas++;
    } else if (c == ';') {
      semicolons++;
    }
  }
  return semicolons > commas ? ';' : ',';
}
