import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/wav_splice.dart';

/// Builds a canonical 44-byte-header PCM WAV whose samples are all [fill].
Uint8List wav({
  int sampleRate = 8000,
  int channels = 1,
  int bits = 16,
  int dataBytes = 16000,
  int fill = 1,
  int audioFormat = 1,
  int? claimedDataBytes,
  List<int> chunkBeforeData = const [],
}) {
  final out = BytesBuilder();
  final header = ByteData(44 + chunkBeforeData.length);
  var o = 0;
  void tag(String s) {
    for (final c in s.codeUnits) {
      header.setUint8(o++, c);
    }
  }

  tag('RIFF');
  header.setUint32(o, 36 + dataBytes, Endian.little);
  o += 4;
  tag('WAVE');
  tag('fmt ');
  header.setUint32(o, 16, Endian.little);
  o += 4;
  header.setUint16(o, audioFormat, Endian.little);
  o += 2;
  header.setUint16(o, channels, Endian.little);
  o += 2;
  header.setUint32(o, sampleRate, Endian.little);
  o += 4;
  header.setUint32(o, sampleRate * channels * (bits ~/ 8), Endian.little);
  o += 4;
  header.setUint16(o, channels * (bits ~/ 8), Endian.little);
  o += 2;
  header.setUint16(o, bits, Endian.little);
  o += 2;
  for (final b in chunkBeforeData) {
    header.setUint8(o++, b);
  }
  tag('data');
  header.setUint32(o, claimedDataBytes ?? dataBytes, Endian.little);
  out
    ..add(header.buffer.asUint8List())
    ..add(Uint8List(dataBytes)..fillRange(0, dataBytes, fill));
  return out.toBytes();
}

void main() {
  group('WavPcmInfo.parse', () {
    test('reads a canonical header', () {
      final info = WavPcmInfo.parse(wav())!;
      expect(info.sampleRate, 8000);
      expect(info.numChannels, 1);
      expect(info.bitsPerSample, 16);
      expect(info.dataOffset, 44);
      expect(info.dataSize, 16000);
    });

    test('finds the data chunk after an extra chunk', () {
      // A 'LIST' chunk of 4 bytes (8 byte header + 4 payload).
      final extra = [...'LIST'.codeUnits, 4, 0, 0, 0, 1, 2, 3, 4];
      final info = WavPcmInfo.parse(wav(chunkBeforeData: extra))!;
      expect(info.dataOffset, 44 + extra.length);
      expect(info.dataSize, 16000);
    });

    test('clamps a data size larger than the file', () {
      final info = WavPcmInfo.parse(wav(claimedDataBytes: 0xFFFFFFFF))!;
      expect(info.dataSize, 16000);
    });

    test('rejects bytes that are not a WAV file', () {
      // The start of an MPEG-4 audio file: an 'ftyp' box, not RIFF.
      final m4a = Uint8List.fromList([
        0, 0, 0, 0x20, ...'ftypM4A '.codeUnits, ...List.filled(64, 0x41), //
      ]);
      expect(WavPcmInfo.parse(m4a), isNull);
      expect(WavPcmInfo.parse(Uint8List(0)), isNull);
      expect(WavPcmInfo.parse(Uint8List(5)), isNull);
    });

    test('rejects a WAV that is not plain PCM', () {
      expect(WavPcmInfo.parse(wav(audioFormat: 3)), isNull);
    });
  });

  group('spliceWav', () {
    test('keeps the prefix up to the position and appends the new audio', () {
      final original = wav(fill: 1); // 1 s at 8 kHz, 16-bit mono
      final recorded = wav(dataBytes: 4000, fill: 2);

      final merged = spliceWav(original, recorded, 500)!;
      final info = WavPcmInfo.parse(merged)!;

      expect(info.dataSize, 8000 + 4000);
      expect(merged.length, 44 + 12000);
      expect(merged[44], 1);
      expect(merged[44 + 7999], 1);
      expect(merged[44 + 8000], 2);
      final bd = ByteData.sublistView(merged);
      expect(bd.getUint32(4, Endian.little), merged.length - 8);
    });

    test('a position past the end keeps the whole original', () {
      final merged = spliceWav(
        wav(fill: 1),
        wav(dataBytes: 400, fill: 2),
        99999,
      )!;
      expect(WavPcmInfo.parse(merged)!.dataSize, 16000 + 400);
    });

    test('a position at zero replaces the original entirely', () {
      final merged = spliceWav(wav(fill: 1), wav(dataBytes: 400, fill: 2), 0)!;
      expect(WavPcmInfo.parse(merged)!.dataSize, 400);
      expect(merged[44], 2);
    });

    test('cuts on a whole sample frame', () {
      final merged = spliceWav(
        wav(channels: 2, dataBytes: 32000, fill: 1),
        wav(channels: 2, dataBytes: 40, fill: 2),
        1,
      )!;
      // 1 ms at 8 kHz stereo 16-bit is 32 bytes: already a whole frame.
      expect(WavPcmInfo.parse(merged)!.dataSize % 4, 0);
    });

    test('refuses a recording with another sample rate', () {
      expect(
        spliceWav(wav(sampleRate: 8000), wav(sampleRate: 16000), 100),
        isNull,
      );
    });

    test('refuses a recording with another channel count', () {
      expect(spliceWav(wav(channels: 2), wav(channels: 1), 100), isNull);
    });

    test('refuses an original that is not a WAV', () {
      final notWav = Uint8List.fromList(List.filled(200, 0x41));
      expect(spliceWav(notWav, wav(), 100), isNull);
    });
  });
}
