import 'dart:typed_data';

/// Layout of the PCM data inside a RIFF/WAVE file.
class WavPcmInfo {
  const WavPcmInfo({
    required this.sampleRate,
    required this.numChannels,
    required this.bitsPerSample,
    required this.dataOffset,
    required this.dataSize,
  });

  final int sampleRate;
  final int numChannels;
  final int bitsPerSample;

  /// Byte offset where the PCM samples start.
  final int dataOffset;

  /// Number of PCM bytes, clamped to what the file actually holds (a recording
  /// that was cut short can claim more than it contains).
  final int dataSize;

  int get blockAlign => numChannels * (bitsPerSample ~/ 8);

  static const _formatPcm = 0x0001;
  static const _formatExtensible = 0xFFFE;

  /// Reads the header of [wav]. Returns `null` unless it is an uncompressed
  /// PCM WAV (plain, or extensible with a PCM sub-format) with whole-byte
  /// samples and a `data` chunk; anything else (a compressed file saved under
  /// a `.wav` name, a float WAV, a truncated header) cannot be spliced
  /// sample-accurately.
  static WavPcmInfo? parse(Uint8List wav) {
    if (wav.length < 12 || _tag(wav, 0) != 'RIFF' || _tag(wav, 8) != 'WAVE') {
      return null;
    }
    final bd = ByteData.sublistView(wav);
    int? sampleRate;
    int? numChannels;
    int? bitsPerSample;

    var offset = 12;
    while (offset + 8 <= wav.length) {
      final id = _tag(wav, offset);
      final size = bd.getUint32(offset + 4, Endian.little);
      final body = offset + 8;
      if (id == 'fmt ') {
        if (size < 16 || body + 16 > wav.length) return null;
        final format = bd.getUint16(body, Endian.little);
        if (format == _formatExtensible) {
          // The real format code is in the first two bytes of the sub-format
          // GUID, 24 bytes into the 40-byte extensible fmt chunk.
          if (size < 40 || body + 40 > wav.length) return null;
          if (bd.getUint16(body + 24, Endian.little) != _formatPcm) {
            return null;
          }
        } else if (format != _formatPcm) {
          return null;
        }
        numChannels = bd.getUint16(body + 2, Endian.little);
        sampleRate = bd.getUint32(body + 4, Endian.little);
        bitsPerSample = bd.getUint16(body + 14, Endian.little);
      } else if (id == 'data') {
        if (sampleRate == null ||
            numChannels == null ||
            bitsPerSample == null ||
            numChannels == 0 ||
            bitsPerSample == 0 ||
            bitsPerSample % 8 != 0) {
          return null;
        }
        final available = wav.length - body;
        return WavPcmInfo(
          sampleRate: sampleRate,
          numChannels: numChannels,
          bitsPerSample: bitsPerSample,
          dataOffset: body,
          dataSize: size > available ? available : size,
        );
      }
      // Chunks are padded to an even length.
      offset = body + size + (size.isOdd ? 1 : 0);
    }
    return null;
  }

  static String _tag(Uint8List b, int at) =>
      String.fromCharCodes(b.sublist(at, at + 4));
}

/// Keeps the first [prefixMs] milliseconds of [original] and appends all of
/// [recorded] after it, returning one WAV file.
///
/// Returns `null` when either input is not a PCM WAV, or when their sample
/// rate, channel count or sample width differ: concatenating them would play
/// the recorded part at the wrong speed or pitch.
Uint8List? spliceWav(Uint8List original, Uint8List recorded, int prefixMs) {
  final info = WavPcmInfo.parse(original);
  final newInfo = WavPcmInfo.parse(recorded);
  if (info == null || newInfo == null) return null;
  if (info.sampleRate != newInfo.sampleRate ||
      info.numChannels != newInfo.numChannels ||
      info.bitsPerSample != newInfo.bitsPerSample) {
    return null;
  }

  final bytesPerSecond = info.sampleRate * info.blockAlign;
  var prefixBytes = (prefixMs / 1000.0 * bytesPerSecond).round();
  prefixBytes = (prefixBytes ~/ info.blockAlign) * info.blockAlign;
  if (prefixBytes < 0) prefixBytes = 0;
  if (prefixBytes > info.dataSize) prefixBytes = info.dataSize;

  final newData = recorded.sublist(
    newInfo.dataOffset,
    newInfo.dataOffset + newInfo.dataSize,
  );
  final dataSize = prefixBytes + newData.length;

  // The original header is kept, with both length fields patched. Whatever
  // follows the data chunk in the original is dropped.
  final header = Uint8List.fromList(original.sublist(0, info.dataOffset));
  final hd = ByteData.sublistView(header);
  hd.setUint32(4, info.dataOffset - 8 + dataSize, Endian.little);
  hd.setUint32(info.dataOffset - 4, dataSize, Endian.little);

  return (BytesBuilder(copy: false)
        ..add(header)
        ..add(original.sublist(info.dataOffset, info.dataOffset + prefixBytes))
        ..add(newData))
      .toBytes();
}
