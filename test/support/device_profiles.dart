import 'package:flutter/material.dart';

/// A form factor to render a screen at.
///
/// Sizes are **logical** pixels — what layout code actually sees — paired
/// with the device pixel ratio that produces them on the real hardware, so
/// a profile named after a phone behaves like that phone.
class DeviceProfile {
  const DeviceProfile({
    required this.name,
    required this.size,
    required this.devicePixelRatio,
    this.textScale = 1.0,
  });

  final String name;
  final Size size;
  final double devicePixelRatio;

  /// Font scale the user has chosen in system settings. A value above 1 is
  /// the most common cause of a layout that fits on the designer's phone
  /// and overflows on a real one.
  final double textScale;

  Size get physicalSize => size * devicePixelRatio;

  @override
  String toString() => name;
}

/// The profiles every layout and golden check runs against.
///
/// Chosen to bracket what the app actually meets rather than to enumerate
/// devices: the narrowest phone still in use, the common and large phone
/// shapes, a tablet, the landscape phone shape the trip screen has its own
/// branch for, and an accessibility font scale.
const List<DeviceProfile> deviceProfiles = [
  DeviceProfile(
    name: 'phone_small',
    size: Size(360, 640),
    devicePixelRatio: 2.0,
  ),
  DeviceProfile(
    name: 'phone_common',
    size: Size(412, 915),
    devicePixelRatio: 2.625,
  ),
  DeviceProfile(
    name: 'phone_large',
    size: Size(412, 892),
    devicePixelRatio: 3.5,
  ),
  DeviceProfile(
    name: 'phone_landscape',
    size: Size(915, 412),
    devicePixelRatio: 2.625,
  ),
  DeviceProfile(
    name: 'tablet_portrait',
    size: Size(800, 1280),
    devicePixelRatio: 2.0,
  ),
  DeviceProfile(
    name: 'phone_large_text',
    size: Size(412, 915),
    devicePixelRatio: 2.625,
    textScale: 1.5,
  ),
];

/// The subset worth committing golden images for.
///
/// Goldens cost a reviewed binary per case, so they cover the two extremes
/// that catch the most — the narrowest phone and a large font — rather than
/// every profile. Overflow checking runs against all of them regardless,
/// because it costs nothing to review.
const List<DeviceProfile> goldenProfiles = [
  DeviceProfile(
    name: 'phone_small',
    size: Size(360, 640),
    devicePixelRatio: 2.0,
  ),
  DeviceProfile(
    name: 'phone_large_text',
    size: Size(412, 915),
    devicePixelRatio: 2.625,
    textScale: 1.5,
  ),
];
