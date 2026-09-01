import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// A sync endpoint baked into the binary at build time.
///
/// Field/demo builds (a caving-congress APK, a club hand-out) ship with the
/// shared account already filled in so nobody has to type a host and password
/// on a phone in a cave. Values arrive via `--dart-define-from-file=<settings>`
/// under the `ftp_seed_*` keys; an empty `ftp_seed_host` — the default, and
/// what store builds use — means the build ships no endpoint at all.
class FtpSeedConfig {
  final String displayName;
  final FtpProtocol protocol;
  final String host;

  /// `null` uses the protocol's default port.
  final int? port;

  final String username;

  /// Written to the OS keystore when the profile is created. Anyone with the
  /// APK can recover it, so only ever seed accounts whose credentials are
  /// meant to be shared.
  final String password;

  final String remoteFolder;

  const FtpSeedConfig({
    required this.displayName,
    required this.protocol,
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    required this.remoteFolder,
  });

  /// The values compiled into this build.
  static FtpSeedConfig fromEnvironment() => FtpSeedConfig(
    displayName: const String.fromEnvironment('ftp_seed_name'),
    protocol: _parseProtocol(
      const String.fromEnvironment('ftp_seed_protocol', defaultValue: 'ftp'),
    ),
    host: const String.fromEnvironment('ftp_seed_host'),
    // 0 (the int.fromEnvironment default) means "protocol default port".
    port: const int.fromEnvironment('ftp_seed_port') == 0
        ? null
        : const int.fromEnvironment('ftp_seed_port'),
    username: const String.fromEnvironment('ftp_seed_username'),
    password: const String.fromEnvironment('ftp_seed_password'),
    remoteFolder: const String.fromEnvironment(
      'ftp_seed_remote_folder',
      defaultValue: '/',
    ),
  );

  bool get isConfigured => host.trim().isNotEmpty;

  static FtpProtocol _parseProtocol(String name) => FtpProtocol.values
      .firstWhere((p) => p.name == name, orElse: () => FtpProtocol.ftp);
}

/// Fixed identity of the seeded profile. Stable across builds so a second
/// start does not stack up duplicates; the flip side is that a build shipping
/// *different* seed values leaves an already-seeded install on the old ones
/// until the user edits or deletes that profile.
const String seededFtpProfileUuid = '00000000-0000-7000-8000-000000000001';

/// Creates the build's seeded profile when the database has none yet, and
/// makes it the active (default) endpoint.
///
/// Runs on every start because a replace-import (test-archive load, restore
/// from backup) swaps in a database without it. Never overwrites an existing
/// profile: whatever the user edited afterwards — password included — wins.
Future<void> ensureSeededFtpProfile(
  FtpProfileRepository repository, {
  FtpSeedConfig? config,
}) async {
  final seed = config ?? FtpSeedConfig.fromEnvironment();
  if (!seed.isConfigured) return;

  final existing = await repository.list();
  if (existing.any((p) => p.profileUuid == seededFtpProfileUuid)) return;

  await repository.save(
    FtpProfile(
      profileUuid: seededFtpProfileUuid,
      displayName: seed.displayName.isEmpty ? seed.host : seed.displayName,
      protocol: seed.protocol,
      host: seed.host,
      port: seed.port,
      username: seed.username,
      remoteFolder: seed.remoteFolder.isEmpty ? '/' : seed.remoteFolder,
    ),
    password: seed.password,
  );
  // Unconditional: a replace-import can bring its own default profile in
  // from the archive's configurations, and the shipped endpoint has to be the
  // active one on a hand-out build.
  await repository.setDefaultUuid(seededFtpProfileUuid);
  AppLogger.of(
    'FtpProfileSeed',
  ).info('Seeded built-in FTP profile "${seed.displayName}" (${seed.host})');
}
