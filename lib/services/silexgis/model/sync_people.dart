import 'package:speleoloc/services/silexgis/model/sync_upload_section.dart';

/// A caver a phone user may be said to be. Names only: the directory carries
/// no contact details.
class SyncPerson {
  const SyncPerson({
    required this.id,
    required this.fullName,
    this.shortName,
    this.hasAccount = false,
    this.isMe = false,
  });

  /// The caver identifier an upload names.
  final String id;

  /// The name this account is shown for the person anywhere else.
  final String fullName;
  final String? shortName;
  final bool hasAccount;

  /// The signed-in account's own caver.
  final bool isMe;

  static SyncPerson fromJson(Map<String, Object?> json) => SyncPerson(
    id: json['id']! as String,
    fullName: json['fullName'] as String? ?? '',
    shortName: json['shortName'] as String?,
    hasAccount: json['hasAccount'] as bool? ?? false,
    isMe: json['isMe'] as bool? ?? false,
  );
}

/// The current link of one phone user this account has sent, whoever made it.
class SyncPersonLink {
  const SyncPersonLink({required this.deviceUserId, this.caverId});

  final String deviceUserId;

  /// Null for a phone user nobody has mapped.
  final String? caverId;

  static SyncPersonLink fromJson(Map<String, Object?> json) => SyncPersonLink(
    deviceUserId: json['deviceUserId']! as String,
    caverId: json['caverId'] as String?,
  );
}

/// The people directory, as this account may be shown it.
class SyncPeopleDirectory {
  const SyncPeopleDirectory({required this.people, required this.links});

  final List<SyncPerson> people;

  /// How a mapping made in the browser reaches the phone: it replaces the
  /// phone's own choice.
  final List<SyncPersonLink> links;

  static SyncPeopleDirectory fromJson(Map<String, Object?> json) =>
      SyncPeopleDirectory(
        people: (json['people'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map((e) => SyncPerson.fromJson(Map<String, Object?>.from(e)))
            .toList(growable: false),
        links: (json['links'] as List? ?? const <Object?>[])
            .whereType<Map>()
            .map((e) => SyncPersonLink.fromJson(Map<String, Object?>.from(e)))
            .toList(growable: false),
      );
}

/// One phone user going up in the `people` section.
///
/// Carries what the server keeps about a phone user and nothing else: the
/// phone's identifier for the user, the names, and — only when the caver chose
/// one on the phone — the caver they are. Which device it is, and which user is
/// signed in on it, never travel.
class SyncUploadPerson implements SyncUploadItem {
  const SyncUploadPerson({
    required this.deviceUserId,
    required this.username,
    this.firstName,
    this.lastName,
    this.caverId,
  });

  final String deviceUserId;
  final String username;
  final String? firstName;
  final String? lastName;

  /// Absent means "nothing to say about the link": an existing link is left as
  /// it stands. There is no way to unlink from a phone.
  final String? caverId;

  /// The same person with nothing to say about the link.
  SyncUploadPerson withoutCaver() => SyncUploadPerson(
    deviceUserId: deviceUserId,
    username: username,
    firstName: firstName,
    lastName: lastName,
  );

  @override
  Map<String, Object?> toJson() => <String, Object?>{
    'deviceUserId': deviceUserId,
    'username': username,
    'firstName': firstName,
    'lastName': lastName,
    'caverId': ?caverId,
  };
}
