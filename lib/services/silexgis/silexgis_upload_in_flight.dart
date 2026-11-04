import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_batch.dart';
import 'package:speleoloc/services/silexgis/silexgis_upload_builder.dart';

/// The feature rows of one upload attempt, kept from just before they are sent
/// until their answer is stored.
///
/// An answer lost on the way back is the ordinary case on a mobile
/// connection. The installation keeps the decisions of every batch it applied
/// under its identifier, so the same rows sent again under the same one are
/// answered as the first time and nothing is written twice. Under a new
/// identifier every edit among them would meet the revision it had itself
/// written, and come back to the caver as a conflict with their own work.
///
/// Only the feature rows are kept, because only their answers can be stored
/// from what is kept here. A batch that also carried other sections is sent
/// again with its rows alone: the identifier is looked up before anything in
/// the batch is, so a server that applied the batch answers with its stored
/// decisions whatever is sent, and one that never received it applies the
/// rows as a batch of their own. The other sections go again in the run's own
/// batches, as they would have without this.
class SilexgisUploadInFlight {
  const SilexgisUploadInFlight({
    required this.batchId,
    required this.rows,
    this.clientFeatures = const <String>[],
  });

  final String batchId;

  /// Each row as sent, with the local table and the stamp it was sent at —
  /// what the answer's revision is stored beside.
  final List<PendingUploadRow> rows;

  /// As the first attempt stated them: a server that never received it
  /// answers the rows by what this device said it understands.
  final List<String> clientFeatures;

  /// The batch to send again: the same identifier and the same rows.
  SyncUploadBatch get batch => SyncUploadBatch(
    batchId: batchId,
    clientFeatures: clientFeatures,
    rows: <SyncUploadRow>[for (final row in rows) row.row],
  );

  Map<String, Object?> toJson() => <String, Object?>{
    'batchId': batchId,
    'clientFeatures': clientFeatures,
    'rows': <Map<String, Object?>>[
      for (final row in rows)
        <String, Object?>{
          'entityTable': row.entityTable,
          'entityUuid': row.entityUuid.toString(),
          'localUpdatedAt': row.localUpdatedAt,
          'row': row.row.toJson(),
        },
    ],
  };

  static SilexgisUploadInFlight fromJson(Map<String, Object?> json) =>
      SilexgisUploadInFlight(
        batchId: json['batchId']! as String,
        clientFeatures: <String>[
          for (final name
              in json['clientFeatures'] as List? ?? const <Object?>[])
            name as String,
        ],
        rows: <PendingUploadRow>[
          for (final entry
              in (json['rows'] as List? ?? const <Object?>[])
                  .cast<Map<Object?, Object?>>())
            PendingUploadRow(
              row: SyncUploadRow.fromJson(
                Map<String, Object?>.from(entry['row']! as Map),
              ),
              entityTable: entry['entityTable']! as String,
              entityUuid: Uuid.parse(entry['entityUuid']! as String),
              localUpdatedAt: (entry['localUpdatedAt'] as num?)?.toInt(),
            ),
        ],
      );
}
