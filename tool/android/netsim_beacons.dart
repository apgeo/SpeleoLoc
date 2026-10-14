// Advertises beacons shaped like the app's into the emulators' simulated
// Bluetooth, so a test can watch the app's own detection find them.
//
//   dart run tool/android/netsim_beacons.dart [--for <seconds>]
//
// Runs until stopped (or for the given time); the beacons exist only while
// it runs. The emulator's netsim daemon is shared by every running
// emulator, so the beacons are part of the room, not of one device: all
// emulators hear them.
//
// netsim's gRPC frontend would be the obvious way in, but the daemon the
// emulator ships starts with it switched off whatever it is told. Its HCI
// socket is always open: a program that connects becomes one more
// Bluetooth controller in the simulation, and a handful of standard HCI
// commands make that controller advertise. One connection per beacon.
//
// The identities match tool/android/generate_fixture_archive.dart: the
// fixture's first cave registers an iBeacon and a Ruuvi tag with exactly
// these identifiers. A Ruuvi tag is known by the MAC inside its payload,
// and an iBeacon by UUID, major and minor, so the addresses netsim gives
// the advertisers do not matter.
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

Future<void> main(List<String> args) async {
  Duration? lifetime;
  final at = args.indexOf('--for');
  if (at >= 0 && at + 1 < args.length) {
    lifetime = Duration(seconds: int.parse(args[at + 1]));
  }
  final port = _hciPort();
  if (port == null) {
    stderr.writeln('netsim is not running: start an emulator first');
    exit(2);
  }

  final controllers = <_Controller>[];
  try {
    for (final beacon in _fixtureBeacons) {
      final c = await _Controller.connect(port);
      controllers.add(c);
      await c.advertise(beacon.advertisingData);
      stdout.writeln('advertising: ${beacon.name}');
    }
  } on Object catch (e) {
    stderr.writeln('could not start the beacons: $e');
    for (final c in controllers) {
      c.close();
    }
    exit(1);
  }

  final done = Completer<void>();
  void finish() {
    if (!done.isCompleted) done.complete();
  }

  ProcessSignal.sigterm.watch().listen((_) => finish());
  ProcessSignal.sigint.watch().listen((_) => finish());
  for (final c in controllers) {
    // netsim going away (the last emulator stopped) ends the run too.
    unawaited(c.closed.then((_) => finish()));
  }
  if (lifetime != null) Timer(lifetime, finish);
  await done.future;
  for (final c in controllers) {
    c.close();
  }
  exit(0);
}

/// netsim writes its ports to $XDG_RUNTIME_DIR/netsim.ini while it runs;
/// a daemon started with another instance number, to netsim_<n>.ini.
int? _hciPort() {
  final env = Platform.environment;
  final dir =
      env['XDG_RUNTIME_DIR'] ??
      '/run/user/${Process.runSync('id', ['-u']).stdout.toString().trim()}';
  final instance = env['NETSIM_INSTANCE'];
  final ini = File(
    instance == null ? '$dir/netsim.ini' : '$dir/netsim_$instance.ini',
  );
  if (!ini.existsSync()) return null;
  for (final line in ini.readAsLinesSync()) {
    if (line.startsWith('hci.port=')) {
      return int.tryParse(line.substring('hci.port='.length));
    }
  }
  return null;
}

class _Beacon {
  const _Beacon(this.name, this.manufacturerData);

  final String name;

  /// Company identifier (little-endian) followed by the payload, as the
  /// advertisement carries it.
  final List<int> manufacturerData;

  /// Flags (LE only, general discoverable) and the manufacturer data: the
  /// 31 bytes a legacy advertisement has room for, as real tags send them.
  List<int> get advertisingData => [
    0x02, 0x01, 0x06, //
    manufacturerData.length + 1, 0xFF, ...manufacturerData,
  ];
}

final _fixtureBeacons = [
  _Beacon('fixture iBeacon', [
    0x4C, 0x00, // Apple
    0x02, 0x15, // iBeacon, 21 bytes follow
    ..._uuidBytes('00000000-F1C7-4000-8000-000000000001'),
    ..._be16(1), // major
    ..._be16(101), // minor
    (-59) & 0xFF, // measured power at 1 m
  ]),
  _Beacon('fixture Ruuvi tag', [
    0x99, 0x04, // Ruuvi Innovations
    0x05, // data format 5 (RAWv2)
    ..._be16((9.4 / 0.005).round()), // temperature
    ..._be16((98.5 / 0.0025).round()), // humidity
    ..._be16(96120 - 50000), // pressure, Pa above 50 000
    ..._be16(0), ..._be16(0), ..._be16(1000), // acceleration, mG
    ..._be16(((2950 - 1600) << 5) | ((4 + 40) ~/ 2)), // battery, tx power
    1, // movement counter
    ..._be16(1), // measurement sequence
    0x02, 0x00, 0x00, 0xF1, 0xC7, 0x01, // the tag's MAC
  ]),
];

List<int> _uuidBytes(String uuid) {
  final hex = uuid.replaceAll('-', '');
  return [
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
}

List<int> _be16(int v) => [(v >> 8) & 0xFF, v & 0xFF];

/// One Bluetooth controller in netsim, driven over HCI (H4 framing).
class _Controller {
  _Controller._(this._socket) {
    _socket.listen(
      _onData,
      onDone: () => _closed.complete(),
      onError: (Object _) => _closed.complete(),
      cancelOnError: true,
    );
  }

  static Future<_Controller> connect(int port) async =>
      _Controller._(await Socket.connect(InternetAddress.loopbackIPv4, port));

  final Socket _socket;
  final _buffer = <int>[];
  final _closed = Completer<void>();
  Completer<int>? _pending;
  int _pendingOpcode = 0;

  Future<void> get closed => _closed.future;

  Future<void> advertise(List<int> data) async {
    await _command(0x0C03, const []); // Reset
    await _command(0x2006, [
      // LE Set Advertising Parameters
      ..._le16(0x00A0), ..._le16(0x00A0), // every 100 ms
      0x03, // non-connectable, undirected — what beacons send
      0x00, // own address: the controller's public one
      0x00, 0, 0, 0, 0, 0, 0, // no peer
      0x07, // all three advertising channels
      0x00, // no filter
    ]);
    await _command(0x2008, [
      // LE Set Advertising Data
      data.length, ...data, ...List.filled(31 - data.length, 0),
    ]);
    await _command(0x200A, const [0x01]); // LE Set Advertising Enable
  }

  Future<void> _command(int opcode, List<int> params) async {
    _pending = Completer<int>();
    _pendingOpcode = opcode;
    _socket.add([0x01, ..._le16(opcode), params.length, ...params]);
    final status = await _pending!.future.timeout(const Duration(seconds: 5));
    if (status != 0) {
      throw StateError(
        'HCI command 0x${opcode.toRadixString(16)} failed: status $status',
      );
    }
  }

  void _onData(Uint8List bytes) {
    _buffer.addAll(bytes);
    while (_buffer.length >= 3 && _buffer[0] == 0x04) {
      final length = _buffer[2];
      if (_buffer.length < 3 + length) return;
      final event = _buffer[1];
      final params = _buffer.sublist(3, 3 + length);
      _buffer.removeRange(0, 3 + length);
      // Command Complete: [credits, opcode lo, opcode hi, status, ...]
      // Command Status:   [status, credits, opcode lo, opcode hi]
      int? opcode;
      int? status;
      if (event == 0x0E && params.length >= 4) {
        opcode = params[1] | params[2] << 8;
        status = params[3];
      } else if (event == 0x0F && params.length >= 4) {
        opcode = params[2] | params[3] << 8;
        status = params[0];
      }
      if (opcode == _pendingOpcode && status != null) {
        final pending = _pending;
        _pending = null;
        if (pending != null && !pending.isCompleted) pending.complete(status);
      }
    }
    // Anything that is not an event (ACL or ISO data) is not ours to read.
    if (_buffer.isNotEmpty && _buffer[0] != 0x04) _buffer.clear();
  }

  void close() => _socket.destroy();
}

List<int> _le16(int v) => [v & 0xFF, (v >> 8) & 0xFF];
