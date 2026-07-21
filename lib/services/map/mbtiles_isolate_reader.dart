import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:speleoloc/services/map/mbtiles_reader.dart';

/// Serves tile reads from one MBTiles file on a dedicated worker isolate,
/// keeping the per-tile SQLite I/O off the UI thread during pan and zoom.
///
/// The worker owns the [MbTilesReader] (open, prepared statement, close);
/// this side only shuttles `(id, z, x, y)` requests and `(id, bytes)`
/// replies, so any number of tile fetches can be in flight at once.
class MbTilesIsolateReader {
  MbTilesIsolateReader._(this.path, this.metadata, this._commands, this._responses);

  final String path;
  final MbTilesMetadata metadata;
  final SendPort _commands;
  final ReceivePort _responses;
  final _pending = <int, Completer<Uint8List?>>{};
  var _nextId = 0;
  var _disposed = false;

  /// Opens [path] on a fresh worker isolate. Throws (like
  /// [MbTilesReader.open]) when the file is not a readable MBTiles
  /// database; the worker exits in that case.
  static Future<MbTilesIsolateReader> open(String path) async {
    final responses = ReceivePort();
    try {
      await Isolate.spawn(
        _worker,
        (responses.sendPort, path),
        debugName: 'mbtiles-reader',
      );
    } catch (_) {
      responses.close();
      rethrow;
    }

    final ready = Completer<(SendPort, MbTilesMetadata)>();
    late final MbTilesIsolateReader reader;
    responses.listen((message) {
      if (!ready.isCompleted) {
        if (message is String) {
          ready.completeError(StateError(message));
        } else {
          ready.complete(message as (SendPort, MbTilesMetadata));
        }
        return;
      }
      final (id, bytes) = message as (int, Uint8List?);
      reader._pending.remove(id)?.complete(bytes);
    });

    try {
      final (commands, metadata) = await ready.future;
      return reader = MbTilesIsolateReader._(
        path,
        metadata,
        commands,
        responses,
      );
    } catch (_) {
      responses.close();
      rethrow;
    }
  }

  /// Returns the raw tile bytes at XYZ coordinates, or null when the file
  /// holds no tile there (or the reader was disposed mid-request).
  Future<Uint8List?> tile(int z, int x, int y) {
    if (_disposed) return Future.value(null);
    final id = _nextId++;
    final completer = Completer<Uint8List?>();
    _pending[id] = completer;
    _commands.send((id, z, x, y));
    return completer.future;
  }

  /// Idempotent. Outstanding [tile] futures resolve to null.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _commands.send(null);
    _responses.close();
    for (final pending in _pending.values) {
      pending.complete(null);
    }
    _pending.clear();
  }

  static Future<void> _worker((SendPort, String) args) async {
    final (responses, path) = args;
    final MbTilesReader reader;
    try {
      reader = MbTilesReader.open(path);
    } catch (e) {
      responses.send(e.toString());
      return;
    }
    final commands = ReceivePort();
    responses.send((commands.sendPort, reader.metadata));
    await for (final message in commands) {
      if (message == null) break;
      final (id, z, x, y) = message as (int, int, int, int);
      Uint8List? bytes;
      try {
        bytes = reader.tile(z, x, y);
      } catch (_) {
        bytes = null;
      }
      responses.send((id, bytes));
    }
    reader.dispose();
    commands.close();
  }
}
