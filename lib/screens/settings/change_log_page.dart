import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show OrderingTerm, OrderingMode;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/change_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

/// Read-only page listing recent change-log entries for debugging and
/// auditing. Each row shows the entity, operation, timestamp and user;
/// expanding it reveals the list of fields changed (with old values when
/// available and non-truncated).
class ChangeLogPage extends ConsumerStatefulWidget {
  const ChangeLogPage({super.key, this.embedded = false});

  /// When `true`, renders only the body (no `Scaffold`/`AppBar`/end drawer)
  /// so the page can be embedded as a tab inside another page.
  final bool embedded;

  @override
  ConsumerState<ChangeLogPage> createState() => _ChangeLogPageState();
}

class _ChangeLogPageState extends ConsumerState<ChangeLogPage>
    with AppBarMenuMixin<ChangeLogPage> {
  static const int _pageSize = 200;

  Future<List<_ChangeRow>> _loadRows() async {
    final db = ref.read(appDatabaseProvider);
    final headers = await (db.select(db.changeLog)
          ..orderBy([(c) => OrderingTerm(
                expression: c.changedAt,
                mode: OrderingMode.desc,
              )])
          ..limit(_pageSize))
        .get();

    final users = {
      for (final u in await db.select(db.users).get()) u.uuid: u,
    };

    final fieldsByChange = <Uuid, List<ChangeLogFieldData>>{};
    if (headers.isNotEmpty) {
      final ids = headers.map((h) => h.uuid).toList();
      final allFields = await (db.select(db.changeLogField)
            ..where((f) => f.changeUuid.isInValues(ids)))
          .get();
      for (final f in allFields) {
        fieldsByChange.putIfAbsent(f.changeUuid, () => []).add(f);
      }
    }

    // Group entity uuids by table so we can title-lookup with one query each.
    final byTable = <String, Set<Uuid>>{};
    for (final h in headers) {
      byTable.putIfAbsent(h.entityTable, () => {}).add(h.entityUuid);
    }
    final titles = <String, Map<Uuid, String>>{};
    for (final entry in byTable.entries) {
      titles[entry.key] =
          await _loadTitlesForTable(db, entry.key, entry.value);
    }
    // For deletes, recover the title from change_log_field old values
    // (the entity row no longer exists by definition).
    String? titleFromDeleteFields(List<ChangeLogFieldData> fields) {
      for (final f in fields) {
        if (f.fieldName == 'title' && f.oldValueTruncated == 0) {
          final v = f.oldValueShort;
          if (v == null || v.isEmpty) return null;
          try {
            return utf8.decode(v, allowMalformed: false);
          } catch (_) {
            return null;
          }
        }
      }
      return null;
    }

    return headers.map((h) {
      final fields = fieldsByChange[h.uuid] ?? const <ChangeLogFieldData>[];
      String? title = titles[h.entityTable]?[h.entityUuid];
      title ??= titleFromDeleteFields(fields);
      return _ChangeRow(
        header: h,
        user: h.changedByUserUuid != null ? users[h.changedByUserUuid] : null,
        fields: fields,
        entityTitle: title,
      );
    }).toList();
  }

  /// Returns a `uuid -> title` map by selecting from the table named [table]
  /// (snake_case). Returns an empty map for tables without a `title` column
  /// or unknown tables. Users are special-cased to use their username.
  Future<Map<Uuid, String>> _loadTitlesForTable(
    AppDatabase db,
    String table,
    Set<Uuid> uuids,
  ) async {
    if (uuids.isEmpty) return const {};
    final ids = uuids.toList();
    switch (table) {
      case 'caves':
        final rows = await (db.select(db.caves)
              ..where((c) => c.uuid.isInValues(ids)))
            .get();
        return {for (final r in rows) r.uuid: r.title};
      case 'cave_areas':
        final rows = await (db.select(db.caveAreas)
              ..where((c) => c.uuid.isInValues(ids)))
            .get();
        return {for (final r in rows) r.uuid: r.title};
      case 'surface_areas':
        final rows = await (db.select(db.surfaceAreas)
              ..where((c) => c.uuid.isInValues(ids)))
            .get();
        return {for (final r in rows) r.uuid: r.title};
      case 'surface_places':
        final rows = await (db.select(db.surfacePlaces)
              ..where((c) => c.uuid.isInValues(ids)))
            .get();
        return {for (final r in rows) r.uuid: r.title};
      case 'cave_entrances':
        final rows = await (db.select(db.caveEntrances)
              ..where((c) => c.uuid.isInValues(ids)))
            .get();
        return {
          for (final r in rows)
            if (r.title != null) r.uuid: r.title!,
        };
      case 'cave_places':
        final rows = await (db.select(db.cavePlaces)
              ..where((c) => c.uuid.isInValues(ids)))
            .get();
        return {for (final r in rows) r.uuid: r.title};
      case 'raster_maps':
        final rows = await (db.select(db.rasterMaps)
              ..where((c) => c.uuid.isInValues(ids)))
            .get();
        return {for (final r in rows) r.uuid: r.title};
      case 'documentation_files':
        final rows = await (db.select(db.documentationFiles)
              ..where((c) => c.uuid.isInValues(ids)))
            .get();
        return {for (final r in rows) r.uuid: r.title};
      case 'cave_trips':
        final rows = await (db.select(db.caveTrips)
              ..where((c) => c.uuid.isInValues(ids)))
            .get();
        return {for (final r in rows) r.uuid: r.title};
      case 'trip_report_templates':
        final rows = await (db.select(db.tripReportTemplates)
              ..where((c) => c.uuid.isInValues(ids)))
            .get();
        return {for (final r in rows) r.uuid: r.title};
      case 'users':
        final rows = await (db.select(db.users)
              ..where((c) => c.uuid.isInValues(ids)))
            .get();
        return {for (final r in rows) r.uuid: r.username};
      default:
        return const {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = FutureBuilder<List<_ChangeRow>>(
      future: _loadRows(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        final rows = snap.data ?? const [];
        if (rows.isEmpty) {
          return Center(child: Text(LocServ.inst.t('no_change_log')));
        }
        return RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _ChangeTile(row: rows[i]),
          ),
        );
      },
    );
    if (widget.embedded) return body;
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('change_log')),
        actions: [buildAppBarMenuButton()],
      ),
      body: body,
    );
  }
}

class _ChangeRow {
  final ChangeLogData header;
  final User? user;
  final List<ChangeLogFieldData> fields;
  final String? entityTitle;
  _ChangeRow({
    required this.header,
    required this.user,
    required this.fields,
    this.entityTitle,
  });
}

class _ChangeTile extends StatelessWidget {
  final _ChangeRow row;
  const _ChangeTile({required this.row});

  String _opLabel(int t) {
    switch (t) {
      case ChangeType.insert:
        return LocServ.inst.t('change_insert');
      case ChangeType.update:
        return LocServ.inst.t('change_update');
      case ChangeType.delete:
        return LocServ.inst.t('change_delete');
    }
    return '?';
  }

  IconData _opIcon(int t) {
    switch (t) {
      case ChangeType.insert:
        return Icons.add_circle_outline;
      case ChangeType.update:
        return Icons.edit_outlined;
      case ChangeType.delete:
        return Icons.delete_outline;
    }
    return Icons.help_outline;
  }

  Color _opColor(int t) {
    switch (t) {
      case ChangeType.insert:
        return Colors.green;
      case ChangeType.update:
        return Colors.blue;
      case ChangeType.delete:
        return Colors.red;
    }
    return Colors.grey;
  }

  String _formatTs(int ms) {
    final d = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${d.year}-${two(d.month)}-${two(d.day)} '
        '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  }

  String _userLabel() {
    final u = row.user;
    if (u == null) return '—';
    final name = [u.firstName ?? '', u.lastName ?? '']
        .where((s) => s.isNotEmpty)
        .join(' ');
    return name.isEmpty ? u.username : '${u.username} ($name)';
  }

  String _decodeValue(Uint8List? bytes) {
    if (bytes == null || bytes.isEmpty) return '';
    // Try UTF-8 first; fall back to hex for binary blobs.
    try {
      final s = utf8.decode(bytes, allowMalformed: false);
      return s;
    } catch (_) {
      return '0x${bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join()}';
    }
  }

  /// Converts a snake_case table name into a user-friendly label (spaces
  /// instead of underscores). E.g. `cave_places` -> `cave places`.
  String _friendlyTableName(String table) => table.replaceAll('_', ' ');

  @override
  Widget build(BuildContext context) {
    final h = row.header;
    final expandable = row.fields.isNotEmpty;
    final subtitle =
        '${_formatTs(h.changedAt)} · ${LocServ.inst.t('change_by')} ${_userLabel()}';

    final entityLabel = row.entityTitle != null && row.entityTitle!.isNotEmpty
        ? '${_friendlyTableName(h.entityTable)}: ${row.entityTitle}'
        : _friendlyTableName(h.entityTable);

    final header = Row(
      children: [
        Icon(_opIcon(h.changeType), color: _opColor(h.changeType)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_opLabel(h.changeType)} · $entityLabel',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );

    if (!expandable) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: header,
      );
    }

    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 16),
      title: header,
      childrenPadding: const EdgeInsets.fromLTRB(48, 0, 16, 12),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            LocServ.inst.t('change_fields'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
        const SizedBox(height: 4),
        for (final f in row.fields)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 140,
                  child: Text(
                    f.fieldName,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    f.oldValueTruncated != 0
                        ? LocServ.inst.t('change_value_truncated')
                        : _decodeValue(f.oldValueShort),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
