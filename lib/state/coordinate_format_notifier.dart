import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/coordinate_formats.dart';

/// App-wide coordinate display preference, backed by the `configurations`
/// table. Display surfaces watch [coordinateFormatProvider] and fall back
/// to decimal degrees while the first read is in flight.
class CoordinateFormatNotifier extends AsyncNotifier<CoordinateDisplayFormat> {
  @override
  Future<CoordinateDisplayFormat> build() async {
    final raw = await ref
        .watch(configurationRepositoryProvider)
        .readString(coordinateFormatKey);
    return CoordinateDisplayFormat.fromId(raw);
  }

  Future<void> set(CoordinateDisplayFormat format) async {
    state = AsyncData(format);
    await ref
        .read(configurationRepositoryProvider)
        .writeString(coordinateFormatKey, format.id);
  }
}

final coordinateFormatProvider =
    AsyncNotifierProvider<CoordinateFormatNotifier, CoordinateDisplayFormat>(
      CoordinateFormatNotifier.new,
    );
