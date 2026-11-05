import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/contained_path.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;

/// Service responsible for exporting trip reports by cloning a template
/// document (ODF or DOCX) and appending text content at the end.
///
/// The output format matches the template's source format:
///   - `.odt` → ODF (modifies content.xml inside the ZIP)
///   - `.docx` → DOCX (modifies word/document.xml inside the ZIP)
///
/// Future extension points:
///   - Template field substitution (e.g. `{{trip_title}}`, `{{date}}`)
///   - Image insertion
///   - Audio/sound recording embedding
class TripReportExportService {
  TripReportExportService._();
  static final TripReportExportService instance = TripReportExportService._();

  /// Returns the templates directory path, creating it if needed.
  Future<String> getTemplatesDir() async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'templates'));
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Copies a picked template file into the templates directory.
  /// Returns the destination file name (basename).
  Future<String> storeTemplateFile(File sourceFile) async {
    final dir = await getTemplatesDir();
    final baseName = p.basename(sourceFile.path);
    // Ensure uniqueness by prefixing timestamp if file already exists.
    String destName = baseName;
    final destFile = File(p.join(dir, destName));
    if (destFile.existsSync()) {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = p.extension(baseName);
      final nameOnly = p.basenameWithoutExtension(baseName);
      destName = '${nameOnly}_$ts$ext';
    }
    await sourceFile.copy(p.join(dir, destName));
    return destName;
  }

  /// Deletes a template file from the templates directory. A name that is
  /// not a plain file name is left alone: template rows sync from other
  /// devices, and joined as it is such a name can reach any file.
  Future<void> deleteTemplateFile(String fileName) async {
    final file = await _templateFile(fileName);
    if (file == null) {
      log.warning('not deleting a template named outside its folder');
      return;
    }
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// The template called [fileName] inside the templates directory, or null
  /// when the name is not a plain file name.
  Future<File?> _templateFile(String fileName) async {
    if (!isPlainFileName(fileName)) return null;
    return File(p.join(await getTemplatesDir(), fileName));
  }

  /// Detects the format from a file extension.
  /// Returns `'odt'` or `'docx'`, or `null` if unsupported.
  String? detectFormat(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    if (ext == '.odt') return 'odt';
    if (ext == '.docx') return 'docx';
    return null;
  }

  /// Builds the report bytes by cloning the template and appending [text].
  /// Returns the raw bytes of the resulting document.
  Future<List<int>> buildReportBytes({
    required String templateFileName,
    required String text,
  }) async {
    final templateFile = await _templateFile(templateFileName);
    if (templateFile == null || !templateFile.existsSync()) {
      throw StateError('Template file not found: $templateFileName');
    }

    final format = detectFormat(templateFileName);
    if (format == null) {
      throw StateError('Unsupported template format: $templateFileName');
    }

    final bytes = await templateFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final Archive modifiedArchive;
    if (format == 'odt') {
      modifiedArchive = _appendTextToOdt(archive, text);
    } else {
      modifiedArchive = _appendTextToDocx(archive, text);
    }

    final outputBytes = ZipEncoder().encode(modifiedArchive);
    if (outputBytes == null) {
      throw StateError('Failed to encode modified archive');
    }
    return outputBytes;
  }

  /// Exports a trip report document by cloning the template and appending [text].
  ///
  /// [templateFileName] is the basename inside the templates directory.
  /// [text] is the content to append (trip log or custom text).
  /// [outputPath] is the full path where the exported file will be saved.
  ///
  /// Returns the output file path on success.
  Future<String> exportReport({
    required String templateFileName,
    required String text,
    required String outputPath,
  }) async {
    final outputBytes = await buildReportBytes(
      templateFileName: templateFileName,
      text: text,
    );
    final outputFile = File(outputPath);
    await outputFile.writeAsBytes(outputBytes);
    return outputPath;
  }

  /// Appends text as a new paragraph to the ODT content.xml `<office:text>` body.
  Archive _appendTextToOdt(Archive archive, String text) {
    final newFiles = <ArchiveFile>[];
    for (final file in archive) {
      if (file.name == 'content.xml') {
        final content = utf8.decode(file.content as List<int>);
        final modifiedContent = _insertOdtParagraph(content, text);
        final newBytes = utf8.encode(modifiedContent);
        newFiles.add(ArchiveFile(file.name, newBytes.length, newBytes));
      } else {
        newFiles.add(file);
      }
    }
    final result = Archive();
    for (final f in newFiles) {
      result.addFile(f);
    }
    return result;
  }

  /// Inserts a `<text:p>` paragraph before the closing `</office:text>` tag.
  String _insertOdtParagraph(String xml, String text) {
    // Split text by newlines and create separate paragraphs
    final paragraphs = text
        .split('\n')
        .map((line) {
          final escaped = _escapeXml(line);
          return '<text:p text:style-name="Standard">$escaped</text:p>';
        })
        .join('\n');

    // Insert before closing </office:text>
    const closingTag = '</office:text>';
    final idx = xml.lastIndexOf(closingTag);
    if (idx == -1) {
      log.warning('<office:text> closing tag not found in ODT content.xml');
      return xml;
    }
    return '${xml.substring(0, idx)}$paragraphs\n$closingTag${xml.substring(idx + closingTag.length)}';
  }

  /// Appends text as a new paragraph to the DOCX word/document.xml `<w:body>`.
  Archive _appendTextToDocx(Archive archive, String text) {
    final newFiles = <ArchiveFile>[];
    for (final file in archive) {
      if (file.name == 'word/document.xml') {
        final content = utf8.decode(file.content as List<int>);
        final modifiedContent = _insertDocxParagraph(content, text);
        final newBytes = utf8.encode(modifiedContent);
        newFiles.add(ArchiveFile(file.name, newBytes.length, newBytes));
      } else {
        newFiles.add(file);
      }
    }
    final result = Archive();
    for (final f in newFiles) {
      result.addFile(f);
    }
    return result;
  }

  /// Inserts `<w:p>` paragraphs at the end of the body content.
  ///
  /// The schema makes the body's own `<w:sectPr>` its last child, and every
  /// Word-saved document has one; paragraphs placed after it make Word call
  /// the file corrupt. So they go before that element when there is one,
  /// otherwise before `</w:body>`. Leading spaces of a log line are kept
  /// with `xml:space="preserve"`, which `<w:t>` otherwise collapses.
  String _insertDocxParagraph(String xml, String text) {
    final paragraphs = text
        .split('\n')
        .map((line) {
          final escaped = _escapeXml(line);
          return '<w:p><w:r><w:t xml:space="preserve">$escaped</w:t></w:r></w:p>';
        })
        .join('\n');

    const closingTag = '</w:body>';
    final bodyEnd = xml.lastIndexOf(closingTag);
    if (bodyEnd == -1) {
      log.warning('<w:body> closing tag not found in DOCX document.xml');
      return xml;
    }
    final idx = _bodySectionStart(xml, bodyEnd) ?? bodyEnd;
    return '${xml.substring(0, idx)}$paragraphs\n${xml.substring(idx)}';
  }

  static final _sectPrOpen = RegExp(r'<w:sectPr[\s>/]');

  /// Where the body-level `<w:sectPr>` starts, or null when the body has
  /// none. A section break inside a paragraph (`<w:pPr><w:sectPr>`) is not
  /// it: the body's own one has no paragraph closing after it.
  int? _bodySectionStart(String xml, int bodyEnd) {
    final matches = _sectPrOpen.allMatches(xml.substring(0, bodyEnd));
    if (matches.isEmpty) return null;
    final start = matches.last.start;
    return xml.substring(start, bodyEnd).contains('</w:p>') ? null : start;
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Puts [bytes] at the path the save dialog returned, adding the
  /// [format] extension when the name was typed without it, and returns
  /// the path written.
  ///
  /// On a phone the system save dialog has already written the bytes to
  /// what it returned, which may not even be a path this app can write to,
  /// so the file is written only when nothing is there yet. On a desktop
  /// the file is always written: a name typed without its extension points
  /// at a different file than the one the dialog wrote, and an older report
  /// already there under the full name must be replaced, not kept.
  Future<String> savePickedReport({
    required String pickedPath,
    required String format,
    required List<int> bytes,
    bool? desktop,
  }) async {
    final finalPath = pickedPath.toLowerCase().endsWith('.$format')
        ? pickedPath
        : '$pickedPath.$format';
    final file = File(finalPath);
    if ((desktop ?? _isDesktop) || !file.existsSync()) {
      await file.writeAsBytes(bytes, flush: true);
    }
    return finalPath;
  }

  bool get _isDesktop =>
      Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  /// Opens a saved report in the desktop's default application, and says
  /// whether it did.
  ///
  /// Phones are left alone. iOS forbids starting processes, and neither
  /// iOS nor Android lets another app open a `file:` address inside this
  /// one; that needs a file-sharing plugin, which the app does not have.
  /// The report is already where the caver chose in the save dialog.
  Future<bool> openWithSystem(String filePath) async {
    if (!_isDesktop) return false;
    try {
      return await launchUrl(Uri.file(filePath));
    } catch (e, st) {
      log.warning('opening the report failed', e, st);
      return false;
    }
  }
}
