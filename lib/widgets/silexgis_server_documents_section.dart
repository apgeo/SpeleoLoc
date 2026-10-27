import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/silexgis/model/sync_file_links.dart';
import 'package:speleoloc/services/silexgis/silexgis_document_downloader.dart';
import 'package:speleoloc/services/silexgis/silexgis_documents_service.dart';
import 'package:speleoloc/utils/format_bytes.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/silexgis_download_size_dialog.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// "On the server": the photos and documents a feature has on the club's
/// installation that this device does not hold, to fetch on the caver's
/// say-so. A sliver, for the documents list.
///
/// Shows nothing without an active server profile, or while the installation
/// does not offer documents to this account.
class SilexgisServerDocumentsSection extends ConsumerStatefulWidget {
  const SilexgisServerDocumentsSection({
    required this.featureId,
    required this.onDownloaded,
    super.key,
  });

  final Uuid featureId;

  /// Called after a download stored something, so the list above reloads.
  final VoidCallback onDownloaded;

  @override
  ConsumerState<SilexgisServerDocumentsSection> createState() =>
      _SilexgisServerDocumentsSectionState();
}

class _SilexgisServerDocumentsSectionState
    extends ConsumerState<SilexgisServerDocumentsSection> {
  final Set<Uuid> _selected = <Uuid>{};
  ({int done, int total})? _progress;

  bool get _busy => _progress != null;

  @override
  Widget build(BuildContext context) {
    final server = ref
        .watch(silexgisServerDocumentsProvider(widget.featureId))
        .value;
    if (server == null) return const SliverToBoxAdapter();
    final theme = Theme.of(context);
    final usual = server.usual;
    final selected = server.documents
        .where((d) => _selected.contains(d.documentId))
        .toList();

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: Text(
              LocServ.inst.t('silexgis_docs_on_server'),
              style: theme.textTheme.titleSmall,
            ),
            subtitle: Text(server.installation),
            trailing: usual.isEmpty || _busy
                ? null
                : TextButton(
                    onPressed: () => _downloadUsual(usual),
                    child: Text(LocServ.inst.t('silexgis_docs_download_usual')),
                  ),
          ),
          if (_progress case final progress?)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  LinearProgressIndicator(
                    value: progress.total == 0
                        ? null
                        : progress.done / progress.total,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    LocServ.inst.t(
                      'silexgis_docs_downloading',
                      <String, String>{
                        'done': '${progress.done}',
                        'total': '${progress.total}',
                      },
                    ),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          for (final document in server.documents) _row(document),
          if (selected.isNotEmpty && !_busy)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: FilledButton.icon(
                icon: const Icon(Icons.download),
                label: Text(
                  LocServ.inst.t(
                    'silexgis_docs_download_selected',
                    <String, String>{'count': '${selected.length}'},
                  ),
                ),
                onPressed: () => _downloadSelected(selected),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _row(SilexgisServerDocument document) {
    final size = document.sizeBytes;
    final details = <String>[
      LocServ.inst.t('silexgis_docs_kind_${document.fileKind}'),
      if (size != null) formatByteSize(size),
      if (document.sameBytesHeld)
        LocServ.inst.t('silexgis_docs_you_have_this')
      else if (!document.canDownload)
        LocServ.inst.t('silexgis_docs_not_available'),
    ];
    return CheckboxListTile(
      value: _selected.contains(document.documentId),
      onChanged: document.canDownload && !_busy
          ? (on) => setState(() {
              if (on ?? false) {
                _selected.add(document.documentId);
              } else {
                _selected.remove(document.documentId);
              }
            })
          : null,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      title: Text(document.title, overflow: TextOverflow.ellipsis),
      subtitle: Text(details.join(' · ')),
      secondary: document.withoutLocation
          ? Chip(
              label: Text(LocServ.inst.t('silexgis_docs_without_location')),
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }

  Future<void> _downloadSelected(List<SilexgisServerDocument> selected) async {
    final choices = _choicesOf(selected);
    final rendition = choices.length == 1
        ? choices.single
        : await showSilexgisDownloadSizeDialog(context, choices: choices);
    if (rendition == null || !mounted) return;
    await _download(selected, rendition);
  }

  Future<void> _downloadUsual(List<SilexgisServerDocument> usual) async {
    final rendition = await showSilexgisDownloadSizeDialog(
      context,
      choices: _choicesOf(usual),
      summaryFor: (choice) =>
          _estimateLabel(SilexgisDownloadEstimate.of(usual, choice)),
    );
    if (rendition == null || !mounted) return;
    await _download(usual, rendition);
  }

  /// Every form at least one of [documents] is offered in, largest first.
  static List<SyncRendition> _choicesOf(
    List<SilexgisServerDocument> documents,
  ) => <SyncRendition>[
    SyncRendition.original,
    for (final size in SyncRendition.sizes) SyncRendition.picture(size),
  ].where((r) => documents.any((d) => d.offered.contains(r))).toList();

  static String _estimateLabel(SilexgisDownloadEstimate estimate) {
    final params = <String, String>{
      'files': '${estimate.files}',
      'size': formatByteSize(estimate.knownBytes),
      'unknown': '${estimate.unknown}',
    };
    if (estimate.unknown == 0) {
      return LocServ.inst.t('silexgis_docs_estimate', params);
    }
    if (estimate.unknown == estimate.files) {
      return LocServ.inst.t('silexgis_docs_estimate_none_known', params);
    }
    return LocServ.inst.t('silexgis_docs_estimate_some_unknown', params);
  }

  Future<void> _download(
    List<SilexgisServerDocument> documents,
    SyncRendition wanted,
  ) async {
    final requests = <SilexgisDownloadRequest>[
      for (final document in documents)
        if (document.formFor(wanted) case final form?)
          SilexgisDownloadRequest(
            documentId: document.documentId,
            rendition: form,
          ),
    ];
    setState(() => _progress = (done: 0, total: requests.length));
    try {
      final summary = await ref
          .read(silexgisDocumentsServiceProvider)
          .download(
            requests,
            onProgress: (done, total) {
              if (mounted)
                setState(() => _progress = (done: done, total: total));
            },
          );
      _report(summary);
    } on SilexgisDocumentsBlocked catch (e) {
      SnackBarService.showWarning(
        LocServ.inst.t(switch (e.reason) {
          SilexgisDocumentsBlock.signIn => 'silexgis_action_reauth',
          SilexgisDocumentsBlock.notServed ||
          SilexgisDocumentsBlock.noProfile => 'silexgis_docs_not_served',
        }),
      );
    } on Exception catch (e) {
      SnackBarService.showError(e);
    }
    if (!mounted) return;
    setState(() {
      _progress = null;
      _selected.clear();
    });
    ref.invalidate(silexgisServerDocumentsProvider(widget.featureId));
    widget.onDownloaded();
  }

  void _report(SilexgisDownloadSummary summary) {
    final counts = <String, int>{
      'silexgis_docs_downloaded': summary.count(
        SilexgisDownloadOutcome.downloaded,
      ),
      'silexgis_docs_already_held': summary.count(
        SilexgisDownloadOutcome.alreadyHeld,
      ),
      'silexgis_docs_unavailable': summary.count(
        SilexgisDownloadOutcome.unavailable,
      ),
      'silexgis_docs_withheld':
          summary.count(SilexgisDownloadOutcome.withheld) +
          summary.count(SilexgisDownloadOutcome.notOffered),
      'silexgis_docs_failed': summary.count(SilexgisDownloadOutcome.failed),
    };
    final message = <String>[
      for (final MapEntry(:key, :value) in counts.entries)
        if (value > 0) LocServ.inst.t(key, <String, String>{'count': '$value'}),
    ].join(', ');
    if (message.isEmpty) return;
    if (counts['silexgis_docs_downloaded'] == summary.results.length) {
      SnackBarService.showSuccess(message);
    } else {
      SnackBarService.showWarning(message);
    }
  }
}
