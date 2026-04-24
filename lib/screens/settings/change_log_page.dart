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
  const ChangeLogPage({super.key});

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

    return headers
        .map((h) => _ChangeRow(
              header: h,
              user: h.changedByUserUuid != null
                  ? users[h.changedByUserUuid]
                  : null,
              fields: fieldsByChange[h.uuid] ?? const [],
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('change_log')),
        actions: [buildAppBarMenuButton()],
      ),
      body: FutureBuilder<List<_ChangeRow>>(
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
      ),
    );
  }
}

class _ChangeRow {
  final ChangeLogData header;
  final User? user;
  final List<ChangeLogFieldData> fields;
  _ChangeRow({required this.header, required this.user, required this.fields});
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

  @override
  Widget build(BuildContext context) {
    final h = row.header;
    final expandable = row.fields.isNotEmpty;
    final subtitle =
        '${_formatTs(h.changedAt)} · ${LocServ.inst.t('change_by')} ${_userLabel()}';

    final header = Row(
      children: [
        Icon(_opIcon(h.changeType), color: _opColor(h.changeType)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_opLabel(h.changeType)} · ${h.entityTable}',
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
