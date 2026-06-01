import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/image_compression_settings.dart';

void main() {
  group('ImageCompressionSettings defaults', () {
    test('disabled by default with medium profile', () {
      const s = ImageCompressionSettings();
      expect(s.enabled, isFalse);
      expect(s.profile, ImageCompressionProfile.medium);
      expect(s.maxResolution, 1920);
      expect(s.quality, 80);
    });
  });

  group('applyProfile', () {
    test('applies preset resolution and quality for every non-manual profile',
        () {
      const base = ImageCompressionSettings(enabled: true);
      for (final p in ImageCompressionProfile.values) {
        if (p == ImageCompressionProfile.manual) continue;
        final applied = base.applyProfile(p);
        final (res, q) = ImageCompressionSettings.presets[p]!;
        expect(applied.profile, p, reason: p.name);
        expect(applied.maxResolution, res, reason: p.name);
        expect(applied.quality, q, reason: p.name);
        expect(applied.enabled, isTrue, reason: 'enabled flag is preserved');
      }
    });

    test('manual profile keeps current maxResolution/quality untouched', () {
      const base = ImageCompressionSettings(
        enabled: true,
        profile: ImageCompressionProfile.high,
        maxResolution: 2048,
        quality: 73,
      );
      final manual = base.applyProfile(ImageCompressionProfile.manual);
      expect(manual.profile, ImageCompressionProfile.manual);
      expect(manual.maxResolution, 2048);
      expect(manual.quality, 73);
      expect(manual.enabled, isTrue);
    });
  });

  group('JSON', () {
    test('toJson contains every field by name', () {
      const s = ImageCompressionSettings(
        enabled: true,
        profile: ImageCompressionProfile.high,
        maxResolution: 1280,
        quality: 65,
      );
      expect(s.toJson(), {
        'enabled': true,
        'profile': 'high',
        'maxResolution': 1280,
        'quality': 65,
      });
    });

    test('fromJson <-> toJson round-trip preserves every field', () {
      for (final p in ImageCompressionProfile.values) {
        final original = ImageCompressionSettings(
          enabled: true,
          profile: p,
          maxResolution: 1234,
          quality: 50,
        );
        final restored =
            ImageCompressionSettings.fromJson(original.toJson());
        expect(restored.enabled, original.enabled, reason: p.name);
        expect(restored.profile, original.profile, reason: p.name);
        expect(restored.maxResolution, original.maxResolution, reason: p.name);
        expect(restored.quality, original.quality, reason: p.name);
      }
    });

    test('fromJson is tolerant of missing/unknown fields', () {
      final empty = ImageCompressionSettings.fromJson(const {});
      expect(empty.enabled, isFalse);
      expect(empty.profile, ImageCompressionProfile.medium);
      expect(empty.maxResolution, 1920);
      expect(empty.quality, 80);

      final unknown = ImageCompressionSettings.fromJson(const {
        'enabled': true,
        'profile': 'super-extreme-not-a-thing',
        'maxResolution': 999,
        'quality': 33,
      });
      // unknown profile falls back to medium but other fields survive
      expect(unknown.enabled, isTrue);
      expect(unknown.profile, ImageCompressionProfile.medium);
      expect(unknown.maxResolution, 999);
      expect(unknown.quality, 33);
    });
  });
}
