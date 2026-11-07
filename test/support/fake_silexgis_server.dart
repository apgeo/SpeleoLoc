import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';
import 'package:speleoloc/services/silexgis/silexgis_contract.dart';
import 'package:speleoloc/utils/clock.dart';

/// One request the fake installation received, for a test to assert on.
class FakeSilexgisRequest {
  FakeSilexgisRequest(this.method, this.url, this.headers, this.body);

  final String method;
  final Uri url;
  final Map<String, String> headers;
  final String body;

  String get path => url.path;

  Map<String, Object?> get jsonBody => jsonDecode(body) as Map<String, Object?>;

  /// The `application/x-www-form-urlencoded` body, decoded.
  Map<String, String> get formBody => Uri.splitQueryString(body);
}

/// A SilexGIS installation held in memory, for tests that need the server to
/// remember: one device's upload served to another device's download, a
/// revision that moves with every write, a removal that leaves a tombstone.
///
/// It keeps the contract's rules that decide what a device sees, and no more:
///
/// * a refresh token is spent once redeemed; presented again within
///   [graceWindow] it is answered with the same successor, and presented later
///   it revokes its whole chain;
/// * feature rows are arbitrated on `baseRevision`, and a lost race is answered
///   `conflict` with the server's own row;
/// * an upload is applied section by section in the server's order, and each
///   section item by item, so a row naming a parent sent later in the same
///   upload is refused `sync.parent_not_found`;
/// * a place has one live pin on a map and one live station mapping;
/// * a `batchId` sent again is answered with its first answer, writing nothing;
/// * a removal takes its containment subtree with it.
///
/// The read streams other than the feature download are not served. Sections
/// without a rule here (documents, links, trips, people) are stored and
/// answered as written.
class FakeSilexgisServer {
  FakeSilexgisServer({
    required Clock clock,
    this.setId = 'set-1',
    List<String> features = const <String>[
      SilexgisContract.featureDownload,
      SilexgisContract.featureUpload,
    ],
    this.pageSizeMax = 500,
    this.uploadRowsMax = 500,
    this.accessLifetime = const Duration(minutes: 15),
    this.graceWindow = const Duration(seconds: 30),
  }) : _clock = clock,
       features = List<String>.of(features);

  final Clock _clock;
  final String setId;
  final int pageSizeMax;
  final int uploadRowsMax;
  final Duration accessLifetime;
  final Duration graceWindow;

  /// What the capabilities route names. Change it between runs to model an
  /// installation that switches a part on or off.
  List<String> features;

  /// Every request received, in order, including those answered with a
  /// failure.
  final List<FakeSilexgisRequest> requests = <FakeSilexgisRequest>[];

  /// Rows whose every upload is refused with the code given, as a server
  /// answers a row this account may not write.
  final Map<String, String> rejectRows = <String, String>{};

  /// A client for one device. Every device of a test talks to the same state.
  http.Client client() => _FakeSilexgisClient(this);

  // ------------------------------------------------------------------ knobs

  final List<String> _loseNext = <String>[];
  final Map<String, _Refusal> _refuseNext = <String, _Refusal>{};

  /// The next request to [path] is carried out, and its answer is lost on the
  /// way back, as a dropped connection loses it.
  void loseNextAnswer(String path) => _loseNext.add(path);

  /// The next request to [path] is refused whole with [code], before anything
  /// is looked at.
  void refuseNext(
    String path, {
    required int status,
    required String code,
    String? detail,
  }) => _refuseNext[path] = _Refusal(status, code, detail);

  // ----------------------------------------------------------------- tokens

  final Map<String, _RefreshToken> _refreshTokens = <String, _RefreshToken>{};
  final Map<String, DateTime> _accessTokens = <String, DateTime>{};
  final Set<int> _revokedChains = <int>{};
  int _chains = 0;
  int _minted = 0;

  /// A refresh token as a password sign-in leaves on a device, at the start
  /// of a chain of its own.
  String signIn() => _mintRefresh(_chains++);

  /// An access token good for [accessLifetime] from now, for a test that
  /// stands a fixed credential in for the sign-in.
  String issueAccessToken() {
    final access = 'access-${++_minted}';
    _accessTokens[access] = _clock.now().add(accessLifetime);
    return access;
  }

  /// The refresh tokens presented to the token endpoint, in order.
  final List<String> refreshesPresented = <String>[];

  /// Whether the chain [refreshToken] belongs to was revoked by a replay.
  bool isRevoked(String refreshToken) {
    final token = _refreshTokens[refreshToken];
    return token == null || _revokedChains.contains(token.chain);
  }

  String _mintRefresh(int chain) {
    final token = 'refresh-${++_minted}';
    _refreshTokens[token] = _RefreshToken(chain);
    return token;
  }

  _Answer _token(FakeSilexgisRequest request) {
    final form = request.formBody;
    if (form['grant_type'] != 'refresh_token') {
      return _Answer.json(400, <String, Object?>{'error': 'unsupported_grant'});
    }
    final presented = form['refresh_token'] ?? '';
    refreshesPresented.add(presented);
    final token = _refreshTokens[presented];
    if (token == null || _revokedChains.contains(token.chain)) {
      return _invalidGrant('The refresh token is no longer valid.');
    }
    final now = _clock.now();
    final redeemedAt = token.redeemedAt;
    if (redeemedAt != null) {
      if (now.difference(redeemedAt) > graceWindow) {
        // A spent token presented late is read as a stolen one: the chain
        // goes, and every device holding a token of it signs in again.
        _revokedChains.add(token.chain);
        return _invalidGrant('The refresh token was already used.');
      }
    } else {
      token
        ..redeemedAt = now
        ..successor = _mintRefresh(token.chain);
    }
    final access = 'access-${++_minted}';
    _accessTokens[access] = now.add(accessLifetime);
    return _Answer.json(200, <String, Object?>{
      'access_token': access,
      'token_type': 'Bearer',
      'expires_in': accessLifetime.inSeconds,
      'scope': SilexgisContract.scopes.join(' '),
      'refresh_token': token.successor,
    });
  }

  static _Answer _invalidGrant(String description) =>
      _Answer.json(400, <String, Object?>{
        'error': 'invalid_grant',
        'error_description': description,
      });

  bool _authorized(FakeSilexgisRequest request) {
    final header = request.headers['Authorization'] ?? '';
    if (!header.startsWith('Bearer ')) return false;
    final expiresAt = _accessTokens[header.substring('Bearer '.length)];
    return expiresAt != null && _clock.now().isBefore(expiresAt);
  }

  // ------------------------------------------------------------ feature rows

  final Map<String, _Feature> _features = <String, _Feature>{};
  int _seq = 0;
  int _lastRevisionMs = 0;

  /// A revision is the time of the write, each one later than the last, so
  /// two writes in one millisecond are still told apart.
  String _nextRevision() {
    final now = _clock.nowMs();
    _lastRevisionMs = now > _lastRevisionMs ? now : _lastRevisionMs + 1;
    return DateTime.fromMillisecondsSinceEpoch(
      _lastRevisionMs,
      isUtc: true,
    ).toIso8601String();
  }

  /// The live row [id] as the download serves it, or null when there is none.
  Map<String, Object?>? feature(String id) {
    final row = _features[id];
    return row == null || row.deleted ? null : row.json;
  }

  /// Whether [id] was here and was removed.
  bool isDeleted(String id) => _features[id]?.deleted ?? false;

  /// Every live row, in the order last written.
  List<Map<String, Object?>> get liveFeatures => <Map<String, Object?>>[
    for (final row in _byChange())
      if (!row.deleted) row.json,
  ];

  /// Writes [json] as an edit made on the server itself — through its web
  /// pages, by another account — and returns its new revision. Fields left
  /// out keep their value.
  String putFeature(Map<String, Object?> json) {
    final id = json['id']! as String;
    final existing = _features[id];
    final revision = _nextRevision();
    final merged = <String, Object?>{
      ...?existing?.json,
      ...json,
      'createdAt': existing?.json['createdAt'] ?? revision,
      'updatedAt': revision,
    };
    _features[id] = _Feature(merged, ++_seq);
    return revision;
  }

  /// Removes [id] and everything inside it, as a removal on the server does.
  void removeFeature(String id) => _removeSubtree(id);

  List<_Feature> _byChange() =>
      _features.values.toList()..sort((a, b) => a.seq.compareTo(b.seq));

  void _removeSubtree(String id) {
    final row = _features[id];
    if (row == null || row.deleted) return;
    for (final child in _features.values.toList()) {
      if (!child.deleted && child.parentIds.contains(id)) {
        _removeSubtree(child.id);
      }
    }
    row
      ..deleted = true
      ..deletedAt = _nextRevision()
      ..seq = ++_seq;
  }

  _Answer _download(FakeSilexgisRequest request) {
    final cursor = request.url.queryParameters['cursor'];
    final after = cursor == null
        ? 0
        : cursor.startsWith('c')
        ? int.tryParse(cursor.substring(1))
        : null;
    if (after == null) {
      return _Answer.problem(
        400,
        SilexgisCodes.cursorInvalid,
        'The cursor is not one this installation issued.',
      );
    }
    final asked = int.tryParse(request.url.queryParameters['pageSize'] ?? '');
    final size = asked == null || asked > pageSizeMax ? pageSizeMax : asked;
    final due = _byChange().where((r) => r.seq > after).toList();
    final page = due.take(size).toList();
    return _Answer.json(200, <String, Object?>{
      'setRevision': 1,
      'settings': const <String, Object?>{},
      'features': <Object?>[
        for (final row in page)
          if (!row.deleted) row.json,
      ],
      'tombstones': <Object?>[
        for (final row in page)
          if (row.deleted)
            <String, Object?>{'id': row.id, 'deletedAt': row.deletedAt},
      ],
      'nextCursor': 'c${page.isEmpty ? after : page.last.seq}',
      'hasMore': due.length > page.length,
    });
  }

  // ----------------------------------------------------------------- upload

  final Map<String, Map<String, Object?>> _answered =
      <String, Map<String, Object?>>{};
  final Map<SyncUploadSection, Map<String, _Item>> _items =
      <SyncUploadSection, Map<String, _Item>>{};

  /// The live items of [section] that are not feature rows, by identifier.
  Map<String, Map<String, Object?>> items(SyncUploadSection section) =>
      <String, Map<String, Object?>>{
        for (final item in (_items[section] ?? const <String, _Item>{}).values)
          if (!item.deleted) item.id: item.json,
      };

  /// Stores [json] as an item of [section] the installation already holds,
  /// and returns its revision.
  String putItem(SyncUploadSection section, Map<String, Object?> json) {
    final id = json['id']! as String;
    final revision = _nextRevision();
    (_items[section] ??= <String, _Item>{})[id] = _Item(id, json, revision);
    return revision;
  }

  _Answer _upload(FakeSilexgisRequest request) {
    final batch = request.jsonBody;
    final batchId = batch['batchId']! as String;
    final earlier = _answered[batchId];
    if (earlier != null) {
      return _Answer.json(200, <String, Object?>{...earlier, 'replayed': true});
    }
    if (batch['contractVersion'] != SilexgisContract.version) {
      return _Answer.problem(
        409,
        SilexgisCodes.contractUnsupported,
        'This installation speaks another version.',
      );
    }

    var written = 0;
    var refused = 0;
    final conflicts = <Map<String, Object?>>[];
    final answer = <String, Object?>{
      'batchId': batchId,
      'importBatchId': 'import-$batchId',
      'replayed': false,
    };
    // The server's apply order, which is the order of the sections here.
    for (final section in SyncUploadSection.values) {
      final sent = batch[section.wireName];
      if (sent is! List) continue;
      final verdicts = <Map<String, Object?>>[];
      for (final item in sent.cast<Map<String, Object?>>()) {
        final verdict = section == SyncUploadSection.rows
            ? _applyRow(item, conflicts)
            : _applyItem(section, item);
        final status = verdict['status'];
        if (status == 'created' || status == 'updated' || status == 'deleted') {
          written++;
        } else if (status == 'conflict' || status == 'rejected') {
          refused++;
        }
        verdicts.add(verdict);
      }
      answer[section.wireName] = verdicts;
    }
    answer
      ..['written'] = written
      ..['refused'] = refused
      ..['conflicts'] = conflicts
      ..['duplicates'] = const <Object?>[];
    answer.putIfAbsent('rows', () => const <Object?>[]);
    _answered[batchId] = answer;
    return _Answer.json(200, answer);
  }

  Map<String, Object?> _applyRow(
    Map<String, Object?> row,
    List<Map<String, Object?>> conflicts,
  ) {
    final id = row['id']! as String;
    final base = row['baseRevision'] as String?;
    final existing = _features[id];
    final rejectedWith = rejectRows[id];
    if (rejectedWith != null) {
      return _verdict(id, 'rejected', code: rejectedWith);
    }

    if (row['deleted'] == true) {
      if (existing == null || existing.deleted) {
        return _verdict(id, 'unchanged');
      }
      if (base != existing.revision) {
        conflicts.add(existing.json);
        return _conflict(existing);
      }
      _removeSubtree(id);
      return _verdict(id, 'deleted');
    }

    if (existing != null && existing.deleted) {
      return _verdict(id, 'rejected', code: SilexgisCodes.rowDeleted);
    }
    if (base == null && existing != null) {
      // A create sent again whose first answer was lost.
      return _verdict(id, 'unchanged', revision: existing.revision);
    }
    if (base != null && existing == null) {
      return _verdict(id, 'rejected', code: SilexgisCodes.rowNotFound);
    }
    if (existing != null && base != existing.revision) {
      conflicts.add(existing.json);
      return _conflict(existing);
    }
    final parentId = row['parentId'] as String?;
    if (existing == null && parentId != null && feature(parentId) == null) {
      return _verdict(id, 'rejected', code: SilexgisCodes.parentNotFound);
    }

    final revision = putFeature(_asServed(row, existing?.json));
    return _verdict(
      id,
      existing == null ? 'created' : 'updated',
      revision: revision,
    );
  }

  /// A device's row as the download serves it back. The parent and the type
  /// are read on a create only, and an absent position or property document
  /// leaves the stored one alone.
  static Map<String, Object?> _asServed(
    Map<String, Object?> row,
    Map<String, Object?>? existing,
  ) {
    final parentId = row['parentId'] as String?;
    Object? geometry = row['geometry'] ?? existing?['geometry'];
    final altitude = row['altitude'];
    if (geometry is Map && geometry['type'] == 'Point' && altitude != null) {
      final coordinates = (geometry['coordinates']! as List).take(2).toList();
      geometry = <String, Object?>{
        'type': 'Point',
        'coordinates': <Object?>[...coordinates, altitude],
      };
    }
    return <String, Object?>{
      'category': null,
      'propertiesSchemaVersion': 1,
      'locationProtected': false,
      'protectedEffective': false,
      'visibility': 'private',
      'featureTypeCode': row['featureTypeCode'],
      'parents': <Object?>[
        if (parentId != null)
          <String, Object?>{'parentId': parentId, 'isPrimary': true},
      ],
      ...?existing,
      'id': row['id'],
      'kind': row['kind'],
      'name': row['name'],
      'description': row['description'],
      'geometry': geometry,
      'properties':
          row['properties'] ??
          existing?['properties'] ??
          const <String, Object?>{},
      'clientUpdatedAt': row['clientUpdatedAt'],
    };
  }

  Map<String, Object?> _applyItem(
    SyncUploadSection section,
    Map<String, Object?> item,
  ) {
    final store = _items[section] ??= <String, _Item>{};
    final id = item['id']! as String;
    final base = item['baseRevision'] as String?;
    final existing = store[id];
    final rejectedWith = rejectRows[id];
    if (rejectedWith != null) {
      return _verdict(id, 'rejected', code: rejectedWith);
    }

    if (item['deleted'] == true) {
      if (existing == null || existing.deleted)
        return _verdict(id, 'unchanged');
      if (base != null && base != existing.revision) {
        return _verdict(id, 'conflict', code: SilexgisCodes.conflict);
      }
      existing.deleted = true;
      if (section == SyncUploadSection.rasterMaps) {
        // A map takes its pins with it.
        final pins =
            _items[SyncUploadSection.rasterPins] ?? const <String, _Item>{};
        for (final pin in pins.values) {
          if (pin.json['rasterMapId'] == id) pin.deleted = true;
        }
      }
      return _verdict(id, 'deleted');
    }

    if (existing != null && !existing.deleted && base == null) {
      return _verdict(id, 'unchanged', revision: existing.revision);
    }
    if (existing != null && base != null && base != existing.revision) {
      return _verdict(id, 'conflict', code: SilexgisCodes.conflict);
    }
    final refusal = _ruleFor(section, item);
    if (refusal != null) return _verdict(id, 'rejected', code: refusal);

    final revision = _nextRevision();
    store[id] = _Item(id, item, revision);
    return _verdict(
      id,
      existing == null || existing.deleted ? 'created' : 'updated',
      revision: revision,
    );
  }

  /// The one-live-per-place rules, and a pin's map.
  String? _ruleFor(SyncUploadSection section, Map<String, Object?> item) {
    bool takenBy(SyncUploadSection s, bool Function(_Item) same) =>
        (_items[s] ?? const <String, _Item>{}).values.any(
          (other) => !other.deleted && other.id != item['id'] && same(other),
        );
    switch (section) {
      case SyncUploadSection.rasterPins:
        final mapId = item['rasterMapId'];
        final maps = _items[SyncUploadSection.rasterMaps];
        if (maps?[mapId] == null || maps![mapId]!.deleted) {
          return SilexgisCodes.rasterMapNotFound;
        }
        if (takenBy(
          section,
          (other) =>
              other.json['rasterMapId'] == mapId &&
              other.json['placeId'] == item['placeId'],
        )) {
          return SilexgisCodes.pinExists;
        }
      case SyncUploadSection.placeStations:
        if (takenBy(
          section,
          (other) => other.json['placeId'] == item['placeId'],
        )) {
          return SilexgisCodes.placeStationExists;
        }
      case SyncUploadSection.rows:
      case SyncUploadSection.people:
      case SyncUploadSection.documents:
      case SyncUploadSection.rasterMaps:
      case SyncUploadSection.tripRecordings:
      case SyncUploadSection.tripPoints:
      case SyncUploadSection.documentLinks:
        break;
    }
    return null;
  }

  static Map<String, Object?> _verdict(
    String id,
    String status, {
    String? revision,
    String? code,
  }) => <String, Object?>{
    'id': id,
    'status': status,
    'revision': revision,
    'code': code,
    'detail': null,
  };

  static Map<String, Object?> _conflict(_Feature existing) => _verdict(
    existing.id,
    'conflict',
    revision: existing.revision,
    code: SilexgisCodes.conflict,
  );

  // -------------------------------------------------------------- transfers

  final Map<String, List<int>> _transfers = <String, List<int>>{};

  /// The bytes staged under each transfer, completed or not.
  Map<String, List<int>> get stagedBytes => Map.unmodifiable(_transfers);

  _Answer _transfer(FakeSilexgisRequest request, List<int> bodyBytes) {
    final path = request.path;
    if (path == SilexgisContract.filesConfigPath) {
      return _Answer.json(200, <String, Object?>{
        'maxUploadBytes': 1 << 30,
        'remainingBytes': null,
        'chunkBytes': 8 * 1024 * 1024,
      });
    }
    if (path == SilexgisContract.fileUploadsPath && request.method == 'POST') {
      final id = 'transfer-${_transfers.length + 1}';
      _transfers[id] = <int>[];
      return _Answer.json(201, _transferJson(id));
    }
    final rest = path.substring(SilexgisContract.fileUploadsPath.length + 1);
    final id = rest.split('/').first;
    final bytes = _transfers[id];
    if (bytes == null) {
      return _Answer.problem(404, 'files.not_found', 'No such transfer.');
    }
    if (rest.endsWith('/complete')) {
      return _Answer.json(200, <String, Object?>{
        'id': id,
        'sizeBytes': bytes.length,
        'sha256': sha256.convert(bytes).toString(),
        'mimeType': 'application/octet-stream',
        'expiresAt': _clock
            .now()
            .add(const Duration(days: 7))
            .toIso8601String(),
      });
    }
    if (request.method == 'PUT') bytes.addAll(bodyBytes);
    if (request.method == 'DELETE') _transfers.remove(id);
    return _Answer.json(200, _transferJson(id));
  }

  Map<String, Object?> _transferJson(String id) => <String, Object?>{
    'id': id,
    'receivedBytes': _transfers[id]?.length ?? 0,
    'chunkBytes': 8 * 1024 * 1024,
    'expiresAt': _clock.now().add(const Duration(days: 1)).toIso8601String(),
  };

  // ---------------------------------------------------------------- routing

  _Answer _route(FakeSilexgisRequest request, List<int> bodyBytes) {
    final path = request.path;
    if (path == SilexgisContract.tokenPath) return _token(request);
    if (!_authorized(request)) return _Answer.json(401, null);
    if (path == SilexgisContract.capabilitiesPath) {
      return _Answer.json(200, <String, Object?>{
        'contractVersion': SilexgisContract.version,
        'pageSizeMax': pageSizeMax,
        'uploadRowsMax': uploadRowsMax,
        'features': features,
      });
    }
    if (path.startsWith('/api/v1/files/')) return _transfer(request, bodyBytes);
    if (path == SilexgisContract.downloadPath(setId) &&
        features.contains(SilexgisContract.featureDownload)) {
      return _download(request);
    }
    if (path == SilexgisContract.uploadPath(setId) &&
        features.contains(SilexgisContract.featureUpload)) {
      return _upload(request);
    }
    if (path.startsWith(SilexgisContract.setsPath)) {
      return _Answer.problem(
        404,
        SilexgisCodes.setNotFound,
        'No such set, or not one this fake serves.',
      );
    }
    return _Answer.problem(404, 'route.not_found', 'Not served by the fake.');
  }

  Future<http.StreamedResponse> _handle(http.BaseRequest request) async {
    final bodyBytes = request is http.Request ? request.bodyBytes : <int>[];
    final recorded = FakeSilexgisRequest(
      request.method,
      request.url,
      Map<String, String>.of(request.headers),
      utf8.decode(bodyBytes, allowMalformed: true),
    );
    requests.add(recorded);

    final path = request.url.path;
    final refusal = _refuseNext.remove(path);
    final answer = refusal != null
        ? _Answer.problem(refusal.status, refusal.code, refusal.detail)
        : _route(recorded, bodyBytes);
    if (_loseNext.remove(path)) {
      throw const SocketException('Connection reset by peer');
    }
    final body = answer.body == null ? '' : jsonEncode(answer.body);
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      answer.status,
      headers: <String, String>{
        if (answer.body != null) 'content-type': answer.contentType,
      },
      request: request,
    );
  }
}

class _FakeSilexgisClient extends http.BaseClient {
  _FakeSilexgisClient(this._server);

  final FakeSilexgisServer _server;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      _server._handle(request);
}

class _Answer {
  _Answer.json(this.status, this.body) : contentType = 'application/json';

  _Answer.problem(int status, String code, String? detail)
    : this._(status, 'application/problem+json', <String, Object?>{
        'status': status,
        'title': code,
        'code': code,
        'detail': detail,
      });

  _Answer._(this.status, this.contentType, this.body);

  final int status;
  final Object? body;
  final String contentType;
}

class _Refusal {
  const _Refusal(this.status, this.code, this.detail);

  final int status;
  final String code;
  final String? detail;
}

class _RefreshToken {
  _RefreshToken(this.chain);

  final int chain;
  DateTime? redeemedAt;
  String? successor;
}

class _Feature {
  _Feature(this.json, this.seq);

  final Map<String, Object?> json;
  int seq;
  bool deleted = false;
  String? deletedAt;

  String get id => json['id']! as String;
  String get revision => json['updatedAt']! as String;

  Set<String> get parentIds => <String>{
    for (final parent in (json['parents'] as List? ?? const <Object?>[]))
      if (parent is Map && parent['parentId'] is String)
        parent['parentId']! as String,
  };
}

class _Item {
  _Item(this.id, this.json, this.revision);

  final String id;
  final Map<String, Object?> json;
  final String revision;
  bool deleted = false;
}
