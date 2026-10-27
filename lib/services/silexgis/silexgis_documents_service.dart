import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/repository_interfaces.dart';
import 'package:speleoloc/services/silexgis/model/sync_documents.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_catalogue_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_downloader.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_session.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';

/// Builds the downloader for one installation, talking through [api].
typedef SilexgisDocumentDownloaderBuilder =
    SilexgisDocumentDownloader Function(
      SilexgisProfile profile,
      SilexgisSyncApi api,
    );

/// One catalogue entry not held on this device, as a documents list shows it.
class SilexgisServerDocument {
  const SilexgisServerDocument({
    required this.entry,
    this.sameBytesHeld = false,
  });

  final SilexgisCatalogueEntry entry;

  /// This device holds a file with the same bytes under another document —
  /// the caver's own photo, say, which the server holds too. Not fetched.
  final bool sameBytesHeld;

  Uuid get documentId => entry.documentId;
  String get title => entry.document.title;
  String get fileKind => entry.document.fileKind;

  /// The stored file's size, when fetching it hands over exactly that.
  int? get sizeBytes => entry.sizeOf(SyncRendition.original);

  /// Handed over without the place it was taken.
  bool get withoutLocation => entry.reach == SyncDocumentReach.locationFree;

  bool get inDefaultSet => entry.link.inDefaultSet;
  List<SyncRendition> get offered => entry.offered;
  bool get canDownload => !sameBytesHeld && offered.isNotEmpty;

  /// The form to fetch when the caver asked for [wanted] across several
  /// files: [wanted] when offered, else the nearest picture size, else the
  /// file itself. Null when nothing is offered.
  SyncRendition? formFor(SyncRendition wanted) {
    if (offered.contains(wanted)) return wanted;
    final pictures = offered.where((r) => !r.isOriginal).toList();
    if (pictures.isEmpty) return offered.isEmpty ? null : offered.first;
    if (wanted.isOriginal) return pictures.first;
    pictures.sort(
      (a, b) => (a.size! - wanted.size!).abs().compareTo(
        (b.size! - wanted.size!).abs(),
      ),
    );
    return pictures.first;
  }
}

/// The catalogue entries one feature has on the active installation.
class SilexgisServerDocuments {
  const SilexgisServerDocuments({
    required this.installation,
    required this.documents,
  });

  /// The installation's name, as the caver configured it.
  final String installation;
  final List<SilexgisServerDocument> documents;

  /// The files somebody curating the feature marked as worth carrying.
  List<SilexgisServerDocument> get usual =>
      documents.where((d) => d.inDefaultSet && d.canDownload).toList();
}

/// What fetching [documents] at one size would cost, as far as is known.
class SilexgisDownloadEstimate {
  const SilexgisDownloadEstimate({
    required this.files,
    required this.knownBytes,
    required this.unknown,
  });

  final int files;
  final int knownBytes;

  /// Files whose size is not known until they arrive: pictures the server
  /// draws, and copies without location, are made on request.
  final int unknown;

  static SilexgisDownloadEstimate of(
    Iterable<SilexgisServerDocument> documents,
    SyncRendition wanted,
  ) {
    var files = 0;
    var bytes = 0;
    var unknown = 0;
    for (final document in documents) {
      final form = document.formFor(wanted);
      if (form == null) continue;
      files++;
      final size = document.entry.sizeOf(form);
      if (size == null) {
        unknown++;
      } else {
        bytes += size;
      }
    }
    return SilexgisDownloadEstimate(
      files: files,
      knownBytes: bytes,
      unknown: unknown,
    );
  }
}

/// How a caver's download went, by outcome.
class SilexgisDownloadSummary {
  const SilexgisDownloadSummary(this.results);

  final List<SilexgisDownloadResult> results;

  int count(SilexgisDownloadOutcome outcome) =>
      results.where((r) => r.outcome == outcome).length;
}

/// Why fetching from the server could not start.
enum SilexgisDocumentsBlock {
  /// No server profile, or none whose catalogue lists anything.
  noProfile,

  /// The stored sign-in has lapsed.
  signIn,

  /// The installation no longer offers documents to this account. The
  /// catalogue copy is gone with this answer.
  notServed,
}

class SilexgisDocumentsBlocked implements Exception {
  const SilexgisDocumentsBlocked(this.reason);
  final SilexgisDocumentsBlock reason;
}

/// The documents lists' side of the photo and document catalogue: what a
/// feature has on the server that this device does not, and fetching it on
/// the caver's say-so.
///
/// Offered only with an active server profile whose catalogue lists
/// something — a run empties the catalogue whenever the installation does not
/// offer documents. Without a profile nothing here shows or runs.
class SilexgisDocumentsService {
  SilexgisDocumentsService({
    required SilexgisProfileRepository profiles,
    required SilexgisDocumentCatalogueRepository catalogue,
    required IDocumentationRepository documents,
    required SilexgisSessionBuilder sessionBuilder,
    required SilexgisDocumentDownloaderBuilder downloaderBuilder,
  }) : _profiles = profiles,
       _catalogue = catalogue,
       _documents = documents,
       _sessionBuilder = sessionBuilder,
       _downloaderBuilder = downloaderBuilder;

  final SilexgisProfileRepository _profiles;
  final SilexgisDocumentCatalogueRepository _catalogue;
  final IDocumentationRepository _documents;
  final SilexgisSessionBuilder _sessionBuilder;
  final SilexgisDocumentDownloaderBuilder _downloaderBuilder;

  /// What [featureId] has on the server that this device does not hold, or
  /// null when there is nothing to show.
  Future<SilexgisServerDocuments?> forFeature(Uuid featureId) async {
    final profile = await _profiles.getDefaultProfile();
    if (profile == null) return null;
    final entries = await _catalogue.entriesFor(profile.profileUuid, featureId);
    final documents = <SilexgisServerDocument>[];
    for (final entry in entries) {
      // A raster map's picture comes with its map.
      if (entry.link.role == SyncDocumentLink.roleMap2d) continue;
      if (await _documents.findById(entry.documentId) != null) continue;
      documents.add(
        SilexgisServerDocument(
          entry: entry,
          sameBytesHeld: await _sameBytesHeld(entry),
        ),
      );
    }
    if (documents.isEmpty) return null;
    return SilexgisServerDocuments(
      installation: profile.displayName,
      documents: documents,
    );
  }

  Future<bool> _sameBytesHeld(SilexgisCatalogueEntry entry) async {
    final size = entry.document.sizeBytes;
    final sha = entry.document.sha256;
    if (entry.reach != SyncDocumentReach.original ||
        size == null ||
        sha == null) {
      return false;
    }
    return (await _documents.findDuplicates(
      fileSize: size,
      fileHash: sha.toLowerCase(),
    )).isNotEmpty;
  }

  /// Fetches [requests] from the active installation.
  ///
  /// Asks the installation first whether it offers documents now: the answer
  /// is worked out per request, and the catalogue may be hours old.
  Future<SilexgisDownloadSummary> download(
    List<SilexgisDownloadRequest> requests, {
    void Function(int done, int total)? onProgress,
  }) async {
    final profile = await _profiles.getDefaultProfile();
    if (profile == null) {
      throw const SilexgisDocumentsBlocked(SilexgisDocumentsBlock.noProfile);
    }
    final session = _sessionBuilder(profile);
    if (!await session.auth.restore()) {
      throw const SilexgisDocumentsBlocked(SilexgisDocumentsBlock.signIn);
    }
    final capabilities = await session.api.capabilities();
    if (!capabilities.speaksOurContract) {
      throw const SilexgisDocumentsBlocked(SilexgisDocumentsBlock.notServed);
    }
    if (!capabilities.servesDocuments) {
      await _catalogue.clear(profile.profileUuid);
      throw const SilexgisDocumentsBlocked(SilexgisDocumentsBlock.notServed);
    }
    final results = await _downloaderBuilder(
      profile,
      session.api,
    ).download(requests, onProgress: onProgress);
    return SilexgisDownloadSummary(results);
  }
}
