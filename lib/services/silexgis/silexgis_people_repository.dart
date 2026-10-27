import 'package:drift/drift.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/services/silexgis/model/sync_people.dart';
import 'package:speleoloc/utils/clock.dart';

/// Who made the link a phone user has on an installation.
enum SilexgisLinkSource {
  /// Chosen on this phone.
  phone,

  /// Read from the directory, and not what this phone chose: made in the
  /// browser, or while an archive was imported.
  server,
}

/// One caver of an installation's people directory, as last read.
class SilexgisCaver {
  const SilexgisCaver({
    required this.caverId,
    required this.fullName,
    this.shortName,
    this.hasAccount = false,
    this.isMe = false,
  });

  final String caverId;
  final String fullName;
  final String? shortName;
  final bool hasAccount;
  final bool isMe;
}

/// What one installation knows about one phone user, as far as this device
/// can tell.
class SilexgisCaverLink {
  const SilexgisCaverLink({
    required this.userUuid,
    this.caverId,
    this.source,
    this.choicePending = false,
    this.sentNamesHash,
    this.sentAt,
  });

  final Uuid userUuid;
  final String? caverId;
  final SilexgisLinkSource? source;

  /// A caver chosen on this phone and not yet sent.
  final bool choicePending;

  /// The digest of the names last sent, or null for a user never sent.
  final String? sentNamesHash;
  final int? sentAt;
}

/// The device's local-only copy of an installation's people directory, and
/// its own choice of caver per phone user there.
class SilexgisPeopleRepository {
  SilexgisPeopleRepository(this._db, {Clock clock = const SystemClock()})
    : _clock = clock;

  final AppDatabase _db;
  final Clock _clock;

  // --------------------------------------------------------------- directory

  Future<List<SilexgisCaver>> readDirectory(String profileUuid) async {
    final rows =
        await (_db.select(_db.silexgisPerson)
              ..where((t) => t.profileUuid.equals(profileUuid))
              ..orderBy(<OrderClauseGenerator<SilexgisPerson>>[
                (t) => OrderingTerm(expression: t.fullName),
              ]))
            .get();
    return <SilexgisCaver>[
      for (final row in rows)
        SilexgisCaver(
          caverId: row.caverId,
          fullName: row.fullName,
          shortName: row.shortName,
          hasAccount: row.hasAccount,
          isMe: row.isMe,
        ),
    ];
  }

  /// Replaces the directory whole: a caver no longer listed is no longer one
  /// a phone user may be said to be.
  Future<void> replaceDirectory(
    String profileUuid,
    List<SyncPerson> people,
  ) async {
    await _db.transaction(() async {
      await clearDirectory(profileUuid);
      await _db.batch((batch) {
        for (final person in people) {
          batch.insert(
            _db.silexgisPerson,
            SilexgisPersonCompanion.insert(
              profileUuid: profileUuid,
              caverId: person.id,
              fullName: person.fullName,
              shortName: Value(person.shortName),
              hasAccount: Value(person.hasAccount),
              isMe: Value(person.isMe),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
    });
  }

  /// Forgets the directory — the installation stopped offering it, or this
  /// account may not be told who people are. That is what hides the choice of
  /// caver; the links stay, for when it is offered again.
  Future<void> clearDirectory(String profileUuid) async {
    await (_db.delete(
      _db.silexgisPerson,
    )..where((t) => t.profileUuid.equals(profileUuid))).go();
  }

  // ------------------------------------------------------------------ links

  Future<Map<Uuid, SilexgisCaverLink>> readLinks(String profileUuid) async {
    final rows = await (_db.select(
      _db.silexgisPersonLink,
    )..where((t) => t.profileUuid.equals(profileUuid))).get();
    return <Uuid, SilexgisCaverLink>{
      for (final row in rows) row.userUuid: _read(row),
    };
  }

  Future<SilexgisCaverLink?> readLink(String profileUuid, Uuid userUuid) async {
    final row = await (_db.select(
      _db.silexgisPersonLink,
    )..where(_key(profileUuid, userUuid))).getSingleOrNull();
    return row == null ? null : _read(row);
  }

  /// The caver chose [caverId] for [userUuid] on this phone. It goes up with
  /// the next sync.
  Future<void> choose(String profileUuid, Uuid userUuid, String caverId) async {
    await _upsert(
      profileUuid,
      userUuid,
      SilexgisPersonLinkCompanion(
        caverId: Value(caverId),
        linkSource: Value(SilexgisLinkSource.phone.name),
        choicePending: const Value(true),
      ),
    );
  }

  /// Takes the directory's links as they stand.
  ///
  /// A link the directory names replaces the phone's own choice, which is how
  /// a mapping made in the browser arrives. A choice made here and not yet
  /// sent is the exception: it goes up first, and the next read says what
  /// stood.
  Future<void> applyServerLinks(
    String profileUuid,
    List<SyncPersonLink> links,
  ) async {
    final known = await readLinks(profileUuid);
    for (final link in links) {
      final userUuid = Uuid.tryParse(link.deviceUserId);
      if (userUuid == null) continue;
      final local = known[userUuid];
      if (local?.choicePending ?? false) continue;
      final keptPhoneChoice =
          local?.source == SilexgisLinkSource.phone &&
          local?.caverId == link.caverId;
      await _upsert(
        profileUuid,
        userUuid,
        SilexgisPersonLinkCompanion(
          caverId: Value(link.caverId),
          linkSource: Value(
            link.caverId == null
                ? null
                : keptPhoneChoice
                ? SilexgisLinkSource.phone.name
                : SilexgisLinkSource.server.name,
          ),
        ),
      );
    }
  }

  /// Records what was sent about [userUuid]. [linkSent] says the choice of
  /// caver went with it, so it is no longer pending.
  Future<void> recordSent(
    String profileUuid,
    Uuid userUuid, {
    required String namesHash,
    required bool linkSent,
  }) async {
    await _upsert(
      profileUuid,
      userUuid,
      SilexgisPersonLinkCompanion(
        sentNamesHash: Value(namesHash),
        sentAt: Value(_clock.nowMs()),
        choicePending: linkSent ? const Value(false) : const Value.absent(),
      ),
    );
  }

  /// Drops a choice the directory does not list.
  Future<void> clearChoice(String profileUuid, Uuid userUuid) async {
    await (_db.update(
      _db.silexgisPersonLink,
    )..where(_key(profileUuid, userUuid))).write(
      const SilexgisPersonLinkCompanion(
        caverId: Value(null),
        linkSource: Value(null),
        choicePending: Value(false),
      ),
    );
  }

  Future<void> _upsert(
    String profileUuid,
    Uuid userUuid,
    SilexgisPersonLinkCompanion values,
  ) async {
    await _db.transaction(() async {
      final updated = await (_db.update(
        _db.silexgisPersonLink,
      )..where(_key(profileUuid, userUuid))).write(values);
      if (updated > 0) return;
      await _db
          .into(_db.silexgisPersonLink)
          .insert(
            values.copyWith(
              profileUuid: Value(profileUuid),
              userUuid: Value(userUuid),
            ),
          );
    });
  }

  Expression<bool> Function(SilexgisPersonLink) _key(
    String profileUuid,
    Uuid userUuid,
  ) =>
      (t) =>
          t.profileUuid.equals(profileUuid) & t.userUuid.equalsValue(userUuid);

  static SilexgisCaverLink _read(SilexgisPersonLinkData row) =>
      SilexgisCaverLink(
        userUuid: row.userUuid,
        caverId: row.caverId,
        source: switch (row.linkSource) {
          'phone' => SilexgisLinkSource.phone,
          'server' => SilexgisLinkSource.server,
          _ => null,
        },
        choicePending: row.choicePending,
        sentNamesHash: row.sentNamesHash,
        sentAt: row.sentAt,
      );
}
