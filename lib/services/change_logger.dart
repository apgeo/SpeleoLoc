import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/current_user_service.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Change types stored in `change_log.change_type`.
class ChangeType {
  ChangeType._();
  static const int insert = 1;
  static const int update = 2;
  static const int delete = 3;
}

/// Audit columns are managed by the repositories themselves; the change
/// logger never logs them as diff fields.
const Set<String> _auditFields = {
  'created_at',
  'updated_at',
  'deleted_at',
  'created_by_user_uuid',
  'last_modified_by_user_uuid',
};

/// Maximum bytes of an old field value persisted in `change_log_field`.
/// Values larger than this are marked truncated and their short copy is
/// dropped (keeps the log compact; current value is always in the entity
/// row itself anyway).
const int kOldValueMaxBytes = 20;

/// Writes structured audit rows to `change_log` / `change_log_field` for
/// every repository write. Synced across peers and auto-purged locally
/// after `configurations.change_log_retention_days`.
///
/// The logger can be globally **suspended** during bulk imports so that
/// restoring an archive doesn't produce a change-log entry per row
/// (the archive already carries the original log).
class ChangeLogger {
  ChangeLogger(this._db, this._currentUser);

  final AppDatabase _db;
  final CurrentUserService _currentUser;
  final _log = AppLogger.of('ChangeLogger');

  int _suspendDepth = 0;
  bool get isSuspended => _suspendDepth > 0;

  /// Runs [body] with logging suspended. Re-entrant; nested calls stack.
  Future<R> runSuspended<R>(Future<R> Function() body) async {
    _suspendDepth++;
    try {
      return await body();
    } finally {
      _suspendDepth--;
    }
  }

  /// Log a fresh insert. No per-field rows are written (full state lives
  /// on the entity row itself).
  Future<void> logInsert(String entityTable, Uuid entityUuid) async {
    if (isSuspended) return;
    await _writeHeader(entityTable, entityUuid, ChangeType.insert);
  }

  /// Log an update. Only fields whose value actually changed are recorded
  /// in `change_log_field`, storing the **old** value (for forensics /
  /// "undo" UI). Audit columns are skipped.
  Future<void> logUpdate(
    String entityTable,
    Uuid entityUuid, {
    required Map<String, Object?> oldValues,
    required Map<String, Object?> newValues,
  }) async {
    if (isSuspended) return;
    final diff = <String, Object?>{};
    for (final entry in newValues.entries) {
      if (_auditFields.contains(entry.key)) continue;
      final oldV = oldValues[entry.key];
      if (!_valuesEqual(oldV, entry.value)) {
        diff[entry.key] = oldV;
      }
    }
    if (diff.isEmpty) return;
    final changeUuid = await _writeHeader(
      entityTable,
      entityUuid,
      ChangeType.update,
    );
    await _writeFields(changeUuid, diff);
  }

  /// Log a soft-delete. All non-audit fields are saved as old values so
  /// the row's last known state is recoverable even after hard purge of
  /// the entity row.
  Future<void> logDelete(
    String entityTable,
    Uuid entityUuid, {
    required Map<String, Object?> oldValues,
  }) async {
    if (isSuspended) return;
    final changeUuid = await _writeHeader(
      entityTable,
      entityUuid,
      ChangeType.delete,
    );
    final filtered = <String, Object?>{
      for (final e in oldValues.entries)
        if (!_auditFields.contains(e.key)) e.key: e.value,
    };
    await _writeFields(changeUuid, filtered);
  }

  Future<Uuid> _writeHeader(
    String entityTable,
    Uuid entityUuid,
    int changeType,
  ) async {
    final changeUuid = Uuid.v7();
    try {
      await _db.into(_db.changeLog).insert(
            ChangeLogCompanion.insert(
              uuid: changeUuid,
              entityTable: entityTable,
              entityUuid: entityUuid,
              changeType: changeType,
              changedAt: DateTime.now().millisecondsSinceEpoch,
              changedByUserUuid: Value(_currentUser.currentUserUuid.value),
              deviceUuid: Value(_currentUser.deviceUuid.value),
            ),
          );
    } catch (e, st) {
      _log.warning('Failed to write change_log header', e, st);
    }
    return changeUuid;
  }

  Future<void> _writeFields(
    Uuid changeUuid,
    Map<String, Object?> oldValues,
  ) async {
    if (oldValues.isEmpty) return;
    try {
      await _db.batch((b) {
        for (final entry in oldValues.entries) {
          final (bytes, truncated) = _encodeOldValue(entry.value);
          b.insert(
            _db.changeLogField,
            ChangeLogFieldCompanion.insert(
              changeUuid: changeUuid,
              fieldName: entry.key,
              oldValueShort: Value(bytes),
              oldValueTruncated: Value(truncated ? 1 : 0),
            ),
          );
        }
      });
    } catch (e, st) {
      _log.warning('Failed to write change_log_field rows', e, st);
    }
  }

  static (Uint8List?, bool) _encodeOldValue(Object? value) {
    if (value == null) return (null, false);
    Uint8List bytes;
    if (value is Uint8List) {
      bytes = value;
    } else if (value is String) {
      bytes = Uint8List.fromList(utf8.encode(value));
    } else if (value is Uuid) {
      bytes = Uint8List.fromList(utf8.encode(value.toString()));
    } else {
      bytes = Uint8List.fromList(utf8.encode(value.toString()));
    }
    if (bytes.length > kOldValueMaxBytes) {
      return (null, true);
    }
    return (bytes, false);
  }

  static bool _valuesEqual(Object? a, Object? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    if (a is Uint8List && b is Uint8List) {
      if (a.length != b.length) return false;
      for (var i = 0; i < a.length; i++) {
        if (a[i] != b[i]) return false;
      }
      return true;
    }
    return a == b;
  }
}
