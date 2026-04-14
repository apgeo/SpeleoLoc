import 'dart:io';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

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

  /// Deletes a template file from the templates directory.
  Future<void> deleteTemplateFile(String fileName) async {
    final dir = await getTemplatesDir();
    final file = File(p.join(dir, fileName));
    if (file.existsSync()) {
      await file.delete();
    }
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
    final dir = await getTemplatesDir();
    final templateFile = File(p.join(dir, templateFileName));
    if (!templateFile.existsSync()) {
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
    final paragraphs = text.split('\n').map((line) {
      final escaped = _escapeXml(line);
      return '<text:p text:style-name="Standard">$escaped</text:p>';
    }).join('\n');

    // Insert before closing </office:text>
    const closingTag = '</office:text>';
    final idx = xml.lastIndexOf(closingTag);
    if (idx == -1) {
      debugPrint('Warning: <office:text> closing tag not found in ODT content.xml');
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

  /// Inserts `<w:p>` paragraphs before the closing `</w:body>` tag.
  String _insertDocxParagraph(String xml, String text) {
    final paragraphs = text.split('\n').map((line) {
      final escaped = _escapeXml(line);
      return '<w:p><w:r><w:t>$escaped</w:t></w:r></w:p>';
    }).join('\n');

    const closingTag = '</w:body>';
    final idx = xml.lastIndexOf(closingTag);
    if (idx == -1) {
      debugPrint('Warning: <w:body> closing tag not found in DOCX document.xml');
      return xml;
    }
    return '${xml.substring(0, idx)}$paragraphs\n$closingTag${xml.substring(idx + closingTag.length)}';
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Opens a file with the system's default handler.
  Future<void> openWithSystem(String filePath) async {
    if (Platform.isAndroid) {
      // On Android, use an intent via process; typically handled by
      // a plugin. We use a simple approach via `am start`.
      // For better Android support, consider adding open_filex package.
      await Process.run('am', [
        'start',
        '-a', 'android.intent.action.VIEW',
        '-d', Uri.file(filePath).toString(),
        '-t', _mimeTypeForPath(filePath),
      ]);
    } else if (Platform.isIOS || Platform.isMacOS) {
      await Process.run('open', [filePath]);
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', filePath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [filePath]);
    }
  }

  String _mimeTypeForPath(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.odt':
        return 'application/vnd.oasis.opendocument.text';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }
}
