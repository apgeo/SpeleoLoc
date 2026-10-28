import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_copy_repository.dart';
import 'package:speleoloc/services/silexgis/silexgis_map_pin_rule.dart';
import 'package:speleoloc/services/silexgis/silexgis_picture_frame.dart';
import 'package:speleoloc/services/silexgis/silexgis_pin_placement.dart';

/// Pins are in the pixels of the picture as the installation stores it. On a
/// picture the server drew upright at a smaller size they are carried through
/// the flip, turn and scale it states; when it states no turn they are only
/// scaled, and only when the drawn picture keeps the stored axes. They are
/// never placed on such a picture. Every other picture shows them as stored.
void main() {
  SilexgisPinPlacement onRendition(
    SilexgisPictureFrame frame,
    int? heldWidth,
    int? heldHeight,
  ) => SilexgisMapPinRule.placement(
    picture: SilexgisHeldAs.rendition,
    frame: frame,
    heldWidth: heldWidth,
    heldHeight: heldHeight,
  );

  group('a picture that is the stored one', () {
    test('shows pins where they are stored, and takes new ones', () {
      for (final picture in <SilexgisHeldAs?>[
        null,
        SilexgisHeldAs.own,
        SilexgisHeldAs.original,
        SilexgisHeldAs.locationFree,
      ]) {
        final placement = SilexgisMapPinRule.placement(
          picture: picture,
          frame: const SilexgisPictureFrame(),
          heldWidth: null,
          heldHeight: null,
        );
        expect(placement.shown, isTrue, reason: '$picture');
        expect(placement.editable, isTrue, reason: '$picture');
        expect(placement.place(120, 80), (x: 120.0, y: 80.0));
        expect(SilexgisMapPinRule.pinsPlaceable(picture), isTrue);
      }
    });
  });

  group('a drawn picture whose turn is stated', () {
    // An invented 400 × 300 picture, drawn at half size, and a pin at
    // (100, 50) on it.
    SilexgisPinPlacement turned(int turn, {bool mirrored = false}) =>
        onRendition(
          SilexgisPictureFrame(
            width: 400,
            height: 300,
            mirrored: mirrored,
            turn: turn,
          ),
          turn == 90 || turn == 270 ? 150 : 200,
          turn == 90 || turn == 270 ? 200 : 150,
        );

    test('carries every pin through the turn alone', () {
      expect(turned(0).place(100, 50), (x: 50.0, y: 25.0));
      // (H − 1 − y, x) = (249, 100)
      expect(turned(90).place(100, 50), (x: 124.5, y: 50.0));
      // (W − 1 − x, H − 1 − y) = (299, 249)
      expect(turned(180).place(100, 50), (x: 149.5, y: 124.5));
      // (y, W − 1 − x) = (50, 299)
      expect(turned(270).place(100, 50), (x: 25.0, y: 149.5));
    });

    test('flips first, then turns', () {
      // The flip takes (100, 50) to (299, 50).
      expect(turned(0, mirrored: true).place(100, 50), (x: 149.5, y: 25.0));
      // (H − 1 − 50, 299) = (249, 299)
      expect(turned(90, mirrored: true).place(100, 50), (x: 124.5, y: 149.5));
      // (W − 1 − 299, H − 1 − 50) = (100, 249)
      expect(turned(180, mirrored: true).place(100, 50), (x: 50.0, y: 124.5));
      // (50, W − 1 − 299) = (50, 100)
      expect(turned(270, mirrored: true).place(100, 50), (x: 25.0, y: 50.0));
    });

    test('lands the contract\'s own example where it says', () {
      // A 4000 × 3000 picture with orientation code 6, drawn 900 × 1200, and
      // once more after a further quarter turn, drawn 1200 × 900.
      const frame = SilexgisPictureFrame(
        width: 4000,
        height: 3000,
        mirrored: false,
        turn: 90,
      );
      final once = onRendition(frame, 900, 1200).place(120, 80);
      expect(once.x, closeTo(875.7, 1e-9));
      expect(once.y, closeTo(36, 1e-9));
      final twice = onRendition(
        const SilexgisPictureFrame(
          width: 4000,
          height: 3000,
          mirrored: false,
          turn: 180,
        ),
        1200,
        900,
      ).place(120, 80);
      expect(twice.x, closeTo(1163.7, 1e-9));
      expect(twice.y, closeTo(875.7, 1e-9));
    });

    test('shows the pins but takes none', () {
      for (final turn in <int>[0, 90, 180, 270]) {
        final placement = turned(turn);
        expect(placement.shown, isTrue, reason: '$turn');
        expect(placement.editable, isFalse, reason: '$turn');
      }
      expect(SilexgisMapPinRule.pinsPlaceable(SilexgisHeldAs.rendition), false);
    });

    test('hides them on a picture whose axes are not the stated ones', () {
      // Stated as a quarter turn, but held with the stored axes: an older
      // picture than the one described.
      final placement = onRendition(
        const SilexgisPictureFrame(
          width: 400,
          height: 300,
          mirrored: false,
          turn: 90,
        ),
        200,
        150,
      );
      expect(placement.shown, isFalse);
    });
  });

  group('a drawn picture whose turn is not stated', () {
    const stored = SilexgisPictureFrame(width: 400, height: 300);

    test('scales the pins when it keeps the stored axes', () {
      final placement = onRendition(stored, 200, 150);
      expect(placement.shown, isTrue);
      expect(placement.editable, isFalse);
      expect(placement.place(100, 50), (x: 50.0, y: 25.0));
    });

    test('hides them when its axes are swapped', () {
      expect(onRendition(stored, 150, 200).shown, isFalse);
    });

    test('hides them while the stored size is unknown', () {
      expect(onRendition(const SilexgisPictureFrame(), 200, 150).shown, false);
      expect(
        onRendition(const SilexgisPictureFrame(width: 400), 200, 150).shown,
        isFalse,
      );
    });

    test('hides them while its own size is unknown', () {
      expect(onRendition(stored, null, null).shown, isFalse);
    });

    test('takes a square as unturned', () {
      final placement = onRendition(
        const SilexgisPictureFrame(width: 300, height: 300),
        100,
        100,
      );
      expect(placement.shown, isTrue);
      expect(placement.place(150, 30), (x: 50.0, y: 10.0));
    });

    test('allows its shorter side a pixel of rounding, and no more', () {
      const plan = SilexgisPictureFrame(width: 4000, height: 3000);
      expect(onRendition(plan, 2400, 1800).shown, isTrue);
      expect(onRendition(plan, 2400, 1801).shown, isTrue);
      expect(onRendition(plan, 2400, 1799).shown, isTrue);
      expect(onRendition(plan, 2400, 1802).shown, isFalse);
      // 1000 × 333 fitted to 1200 is 399.6 high, drawn as 400.
      final at = onRendition(
        const SilexgisPictureFrame(width: 1000, height: 333),
        1200,
        400,
      ).place(500, 300);
      expect(at.x, 600);
      expect(at.y, closeTo(360.4, 0.05));
    });

    test('takes a turn it cannot read as unstated', () {
      // A turn outside the four, or one without its flip.
      for (final frame in <SilexgisPictureFrame>[
        const SilexgisPictureFrame(
          width: 400,
          height: 300,
          mirrored: false,
          turn: 45,
        ),
        const SilexgisPictureFrame(width: 400, height: 300, turn: 90),
      ]) {
        expect(onRendition(frame, 150, 200).shown, isFalse);
        expect(onRendition(frame, 200, 150).place(100, 50), (x: 50.0, y: 25.0));
      }
    });
  });
}
