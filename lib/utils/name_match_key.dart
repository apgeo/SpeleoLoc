/// The form a name is compared in when an import looks for an existing
/// row: lower-cased, and with the Romanian s and t written with a cedilla
/// (ş ţ, U+015F U+0163) read as the comma-below letters (ș ț, U+0219
/// U+021B). Older keyboards and spreadsheets still type the cedilla forms,
/// so the same cave or place arrives spelled both ways. Only for matching;
/// a stored title keeps the letters it was typed with.
String nameMatchKey(String name) => name
    .toLowerCase()
    .replaceAll('\u015F', '\u0219')
    .replaceAll('\u0163', '\u021B');
