// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class Users extends Table with TableInfo<Users, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Users(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(Users.$converteruuid);
  static const VerificationMeta _usernameMeta = const VerificationMeta(
    'username',
  );
  late final GeneratedColumn<String> username = GeneratedColumn<String>(
    'username',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _firstNameMeta = const VerificationMeta(
    'firstName',
  );
  late final GeneratedColumn<String> firstName = GeneratedColumn<String>(
    'first_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _lastNameMeta = const VerificationMeta(
    'lastName',
  );
  late final GeneratedColumn<String> lastName = GeneratedColumn<String>(
    'last_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _detailsMeta = const VerificationMeta(
    'details',
  );
  late final GeneratedColumn<String> details = GeneratedColumn<String>(
    'details',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(Users.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(Users.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    username,
    firstName,
    lastName,
    details,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('username')) {
      context.handle(
        _usernameMeta,
        username.isAcceptableOrUnknown(data['username']!, _usernameMeta),
      );
    } else if (isInserting) {
      context.missing(_usernameMeta);
    }
    if (data.containsKey('first_name')) {
      context.handle(
        _firstNameMeta,
        firstName.isAcceptableOrUnknown(data['first_name']!, _firstNameMeta),
      );
    }
    if (data.containsKey('last_name')) {
      context.handle(
        _lastNameMeta,
        lastName.isAcceptableOrUnknown(data['last_name']!, _lastNameMeta),
      );
    }
    if (data.containsKey('details')) {
      context.handle(
        _detailsMeta,
        details.isAcceptableOrUnknown(data['details']!, _detailsMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      uuid: Users.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      username: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}username'],
      )!,
      firstName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}first_name'],
      ),
      lastName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_name'],
      ),
      details: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}details'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: Users.$convertercreatedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}created_by_user_uuid'],
        ),
      ),
      lastModifiedByUserUuid: Users.$converterlastModifiedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}last_modified_by_user_uuid'],
        ),
      ),
    );
  }

  @override
  Users createAlias(String alias) {
    return Users(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  bool get dontWriteConstraints => true;
}

class User extends DataClass implements Insertable<User> {
  final Uuid uuid;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? details;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const User({
    required this.uuid,
    required this.username,
    this.firstName,
    this.lastName,
    this.details,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(Users.$converteruuid.toSql(uuid));
    }
    map['username'] = Variable<String>(username);
    if (!nullToAbsent || firstName != null) {
      map['first_name'] = Variable<String>(firstName);
    }
    if (!nullToAbsent || lastName != null) {
      map['last_name'] = Variable<String>(lastName);
    }
    if (!nullToAbsent || details != null) {
      map['details'] = Variable<String>(details);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        Users.$convertercreatedByUserUuidn.toSql(createdByUserUuid),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        Users.$converterlastModifiedByUserUuidn.toSql(lastModifiedByUserUuid),
      );
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      uuid: Value(uuid),
      username: Value(username),
      firstName: firstName == null && nullToAbsent
          ? const Value.absent()
          : Value(firstName),
      lastName: lastName == null && nullToAbsent
          ? const Value.absent()
          : Value(lastName),
      details: details == null && nullToAbsent
          ? const Value.absent()
          : Value(details),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      username: serializer.fromJson<String>(json['username']),
      firstName: serializer.fromJson<String?>(json['first_name']),
      lastName: serializer.fromJson<String?>(json['last_name']),
      details: serializer.fromJson<String?>(json['details']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'username': serializer.toJson<String>(username),
      'first_name': serializer.toJson<String?>(firstName),
      'last_name': serializer.toJson<String?>(lastName),
      'details': serializer.toJson<String?>(details),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  User copyWith({
    Uuid? uuid,
    String? username,
    Value<String?> firstName = const Value.absent(),
    Value<String?> lastName = const Value.absent(),
    Value<String?> details = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => User(
    uuid: uuid ?? this.uuid,
    username: username ?? this.username,
    firstName: firstName.present ? firstName.value : this.firstName,
    lastName: lastName.present ? lastName.value : this.lastName,
    details: details.present ? details.value : this.details,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      username: data.username.present ? data.username.value : this.username,
      firstName: data.firstName.present ? data.firstName.value : this.firstName,
      lastName: data.lastName.present ? data.lastName.value : this.lastName,
      details: data.details.present ? data.details.value : this.details,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('uuid: $uuid, ')
          ..write('username: $username, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('details: $details, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    username,
    firstName,
    lastName,
    details,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.uuid == this.uuid &&
          other.username == this.username &&
          other.firstName == this.firstName &&
          other.lastName == this.lastName &&
          other.details == this.details &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<Uuid> uuid;
  final Value<String> username;
  final Value<String?> firstName;
  final Value<String?> lastName;
  final Value<String?> details;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const UsersCompanion({
    this.uuid = const Value.absent(),
    this.username = const Value.absent(),
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.details = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required Uuid uuid,
    required String username,
    this.firstName = const Value.absent(),
    this.lastName = const Value.absent(),
    this.details = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       username = Value(username);
  static Insertable<User> custom({
    Expression<Uint8List>? uuid,
    Expression<String>? username,
    Expression<String>? firstName,
    Expression<String>? lastName,
    Expression<String>? details,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (username != null) 'username': username,
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (details != null) 'details': details,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<Uuid>? uuid,
    Value<String>? username,
    Value<String?>? firstName,
    Value<String?>? lastName,
    Value<String?>? details,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      uuid: uuid ?? this.uuid,
      username: username ?? this.username,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      details: details ?? this.details,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(Users.$converteruuid.toSql(uuid.value));
    }
    if (username.present) {
      map['username'] = Variable<String>(username.value);
    }
    if (firstName.present) {
      map['first_name'] = Variable<String>(firstName.value);
    }
    if (lastName.present) {
      map['last_name'] = Variable<String>(lastName.value);
    }
    if (details.present) {
      map['details'] = Variable<String>(details.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        Users.$convertercreatedByUserUuidn.toSql(createdByUserUuid.value),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        Users.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('uuid: $uuid, ')
          ..write('username: $username, ')
          ..write('firstName: $firstName, ')
          ..write('lastName: $lastName, ')
          ..write('details: $details, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SurfaceAreas extends Table with TableInfo<SurfaceAreas, SurfaceArea> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SurfaceAreas(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(SurfaceAreas.$converteruuid);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(SurfaceAreas.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(SurfaceAreas.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    title,
    description,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surface_areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<SurfaceArea> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  SurfaceArea map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurfaceArea(
      uuid: SurfaceAreas.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: SurfaceAreas.$convertercreatedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}created_by_user_uuid'],
        ),
      ),
      lastModifiedByUserUuid: SurfaceAreas.$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  SurfaceAreas createAlias(String alias) {
    return SurfaceAreas(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  bool get dontWriteConstraints => true;
}

class SurfaceArea extends DataClass implements Insertable<SurfaceArea> {
  final Uuid uuid;
  final String title;
  final String? description;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const SurfaceArea({
    required this.uuid,
    required this.title,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(
        SurfaceAreas.$converteruuid.toSql(uuid),
      );
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        SurfaceAreas.$convertercreatedByUserUuidn.toSql(createdByUserUuid),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        SurfaceAreas.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  SurfaceAreasCompanion toCompanion(bool nullToAbsent) {
    return SurfaceAreasCompanion(
      uuid: Value(uuid),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory SurfaceArea.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurfaceArea(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  SurfaceArea copyWith({
    Uuid? uuid,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => SurfaceArea(
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  SurfaceArea copyWithCompanion(SurfaceAreasCompanion data) {
    return SurfaceArea(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurfaceArea(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    title,
    description,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurfaceArea &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class SurfaceAreasCompanion extends UpdateCompanion<SurfaceArea> {
  final Value<Uuid> uuid;
  final Value<String> title;
  final Value<String?> description;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const SurfaceAreasCompanion({
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurfaceAreasCompanion.insert({
    required Uuid uuid,
    required String title,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       title = Value(title);
  static Insertable<SurfaceArea> custom({
    Expression<Uint8List>? uuid,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurfaceAreasCompanion copyWith({
    Value<Uuid>? uuid,
    Value<String>? title,
    Value<String?>? description,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return SurfaceAreasCompanion(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        SurfaceAreas.$converteruuid.toSql(uuid.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        SurfaceAreas.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid.value,
        ),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        SurfaceAreas.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurfaceAreasCompanion(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Caves extends Table with TableInfo<Caves, Cave> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Caves(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(Caves.$converteruuid);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  surfaceAreaUuid = GeneratedColumn<Uint8List>(
    'surface_area_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES surface_areas(uuid)',
  ).withConverter<Uuid?>(Caves.$convertersurfaceAreaUuidn);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(Caves.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(Caves.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    title,
    description,
    surfaceAreaUuid,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'caves';
  @override
  VerificationContext validateIntegrity(
    Insertable<Cave> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title, surfaceAreaUuid},
  ];
  @override
  Cave map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cave(
      uuid: Caves.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      surfaceAreaUuid: Caves.$convertersurfaceAreaUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}surface_area_uuid'],
        ),
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: Caves.$convertercreatedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}created_by_user_uuid'],
        ),
      ),
      lastModifiedByUserUuid: Caves.$converterlastModifiedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}last_modified_by_user_uuid'],
        ),
      ),
    );
  }

  @override
  Caves createAlias(String alias) {
    return Caves(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertersurfaceAreaUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertersurfaceAreaUuidn =
      NullAwareTypeConverter.wrap($convertersurfaceAreaUuid);
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(title, surface_area_uuid)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Cave extends DataClass implements Insertable<Cave> {
  final Uuid uuid;
  final String title;
  final String? description;
  final Uuid? surfaceAreaUuid;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const Cave({
    required this.uuid,
    required this.title,
    this.description,
    this.surfaceAreaUuid,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(Caves.$converteruuid.toSql(uuid));
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || surfaceAreaUuid != null) {
      map['surface_area_uuid'] = Variable<Uint8List>(
        Caves.$convertersurfaceAreaUuidn.toSql(surfaceAreaUuid),
      );
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        Caves.$convertercreatedByUserUuidn.toSql(createdByUserUuid),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        Caves.$converterlastModifiedByUserUuidn.toSql(lastModifiedByUserUuid),
      );
    }
    return map;
  }

  CavesCompanion toCompanion(bool nullToAbsent) {
    return CavesCompanion(
      uuid: Value(uuid),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      surfaceAreaUuid: surfaceAreaUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(surfaceAreaUuid),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory Cave.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cave(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      surfaceAreaUuid: serializer.fromJson<Uuid?>(json['surface_area_uuid']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'surface_area_uuid': serializer.toJson<Uuid?>(surfaceAreaUuid),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  Cave copyWith({
    Uuid? uuid,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<Uuid?> surfaceAreaUuid = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => Cave(
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    surfaceAreaUuid: surfaceAreaUuid.present
        ? surfaceAreaUuid.value
        : this.surfaceAreaUuid,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  Cave copyWithCompanion(CavesCompanion data) {
    return Cave(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      surfaceAreaUuid: data.surfaceAreaUuid.present
          ? data.surfaceAreaUuid.value
          : this.surfaceAreaUuid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cave(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('surfaceAreaUuid: $surfaceAreaUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    title,
    description,
    surfaceAreaUuid,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cave &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.description == this.description &&
          other.surfaceAreaUuid == this.surfaceAreaUuid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class CavesCompanion extends UpdateCompanion<Cave> {
  final Value<Uuid> uuid;
  final Value<String> title;
  final Value<String?> description;
  final Value<Uuid?> surfaceAreaUuid;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const CavesCompanion({
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.surfaceAreaUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CavesCompanion.insert({
    required Uuid uuid,
    required String title,
    this.description = const Value.absent(),
    this.surfaceAreaUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       title = Value(title);
  static Insertable<Cave> custom({
    Expression<Uint8List>? uuid,
    Expression<String>? title,
    Expression<String>? description,
    Expression<Uint8List>? surfaceAreaUuid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (surfaceAreaUuid != null) 'surface_area_uuid': surfaceAreaUuid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CavesCompanion copyWith({
    Value<Uuid>? uuid,
    Value<String>? title,
    Value<String?>? description,
    Value<Uuid?>? surfaceAreaUuid,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return CavesCompanion(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      surfaceAreaUuid: surfaceAreaUuid ?? this.surfaceAreaUuid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(Caves.$converteruuid.toSql(uuid.value));
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (surfaceAreaUuid.present) {
      map['surface_area_uuid'] = Variable<Uint8List>(
        Caves.$convertersurfaceAreaUuidn.toSql(surfaceAreaUuid.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        Caves.$convertercreatedByUserUuidn.toSql(createdByUserUuid.value),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        Caves.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CavesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('surfaceAreaUuid: $surfaceAreaUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CaveAreas extends Table with TableInfo<CaveAreas, CaveArea> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CaveAreas(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(CaveAreas.$converteruuid);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> caveUuid =
      GeneratedColumn<Uint8List>(
        'cave_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL REFERENCES caves(uuid)',
      ).withConverter<Uuid>(CaveAreas.$convertercaveUuid);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(CaveAreas.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(CaveAreas.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    title,
    description,
    caveUuid,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cave_areas';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaveArea> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title, caveUuid},
  ];
  @override
  CaveArea map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaveArea(
      uuid: CaveAreas.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      caveUuid: CaveAreas.$convertercaveUuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}cave_uuid'],
        )!,
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: CaveAreas.$convertercreatedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}created_by_user_uuid'],
        ),
      ),
      lastModifiedByUserUuid: CaveAreas.$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  CaveAreas createAlias(String alias) {
    return CaveAreas(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercaveUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(title, cave_uuid)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CaveArea extends DataClass implements Insertable<CaveArea> {
  final Uuid uuid;
  final String title;
  final String? description;
  final Uuid caveUuid;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const CaveArea({
    required this.uuid,
    required this.title,
    this.description,
    required this.caveUuid,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(CaveAreas.$converteruuid.toSql(uuid));
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    {
      map['cave_uuid'] = Variable<Uint8List>(
        CaveAreas.$convertercaveUuid.toSql(caveUuid),
      );
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CaveAreas.$convertercreatedByUserUuidn.toSql(createdByUserUuid),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CaveAreas.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  CaveAreasCompanion toCompanion(bool nullToAbsent) {
    return CaveAreasCompanion(
      uuid: Value(uuid),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      caveUuid: Value(caveUuid),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory CaveArea.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaveArea(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      caveUuid: serializer.fromJson<Uuid>(json['cave_uuid']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'cave_uuid': serializer.toJson<Uuid>(caveUuid),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  CaveArea copyWith({
    Uuid? uuid,
    String? title,
    Value<String?> description = const Value.absent(),
    Uuid? caveUuid,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => CaveArea(
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    caveUuid: caveUuid ?? this.caveUuid,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  CaveArea copyWithCompanion(CaveAreasCompanion data) {
    return CaveArea(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      caveUuid: data.caveUuid.present ? data.caveUuid.value : this.caveUuid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaveArea(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('caveUuid: $caveUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    title,
    description,
    caveUuid,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaveArea &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.description == this.description &&
          other.caveUuid == this.caveUuid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class CaveAreasCompanion extends UpdateCompanion<CaveArea> {
  final Value<Uuid> uuid;
  final Value<String> title;
  final Value<String?> description;
  final Value<Uuid> caveUuid;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const CaveAreasCompanion({
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.caveUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaveAreasCompanion.insert({
    required Uuid uuid,
    required String title,
    this.description = const Value.absent(),
    required Uuid caveUuid,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       title = Value(title),
       caveUuid = Value(caveUuid);
  static Insertable<CaveArea> custom({
    Expression<Uint8List>? uuid,
    Expression<String>? title,
    Expression<String>? description,
    Expression<Uint8List>? caveUuid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (caveUuid != null) 'cave_uuid': caveUuid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaveAreasCompanion copyWith({
    Value<Uuid>? uuid,
    Value<String>? title,
    Value<String?>? description,
    Value<Uuid>? caveUuid,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return CaveAreasCompanion(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      caveUuid: caveUuid ?? this.caveUuid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        CaveAreas.$converteruuid.toSql(uuid.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (caveUuid.present) {
      map['cave_uuid'] = Variable<Uint8List>(
        CaveAreas.$convertercaveUuid.toSql(caveUuid.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CaveAreas.$convertercreatedByUserUuidn.toSql(createdByUserUuid.value),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CaveAreas.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaveAreasCompanion(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('caveUuid: $caveUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SurfacePlaces extends Table with TableInfo<SurfacePlaces, SurfacePlace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SurfacePlaces(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(SurfacePlaces.$converteruuid);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _surfacePlaceQrCodeIdentifierMeta =
      const VerificationMeta('surfacePlaceQrCodeIdentifier');
  late final GeneratedColumn<int> surfacePlaceQrCodeIdentifier =
      GeneratedColumn<int>(
        'surface_place_qr_code_identifier',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        $customConstraints: 'DEFAULT NULL UNIQUE',
        defaultValue: const CustomExpression('NULL'),
      );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(SurfacePlaces.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(SurfacePlaces.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    title,
    description,
    type,
    surfacePlaceQrCodeIdentifier,
    latitude,
    longitude,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'surface_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<SurfacePlace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    }
    if (data.containsKey('surface_place_qr_code_identifier')) {
      context.handle(
        _surfacePlaceQrCodeIdentifierMeta,
        surfacePlaceQrCodeIdentifier.isAcceptableOrUnknown(
          data['surface_place_qr_code_identifier']!,
          _surfacePlaceQrCodeIdentifierMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  SurfacePlace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurfacePlace(
      uuid: SurfacePlaces.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      ),
      surfacePlaceQrCodeIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surface_place_qr_code_identifier'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: SurfacePlaces.$convertercreatedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}created_by_user_uuid'],
        ),
      ),
      lastModifiedByUserUuid: SurfacePlaces.$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  SurfacePlaces createAlias(String alias) {
    return SurfacePlaces(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  bool get dontWriteConstraints => true;
}

class SurfacePlace extends DataClass implements Insertable<SurfacePlace> {
  final Uuid uuid;
  final String title;
  final String? description;
  final String? type;
  final int? surfacePlaceQrCodeIdentifier;
  final double? latitude;
  final double? longitude;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const SurfacePlace({
    required this.uuid,
    required this.title,
    this.description,
    this.type,
    this.surfacePlaceQrCodeIdentifier,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(
        SurfacePlaces.$converteruuid.toSql(uuid),
      );
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || type != null) {
      map['type'] = Variable<String>(type);
    }
    if (!nullToAbsent || surfacePlaceQrCodeIdentifier != null) {
      map['surface_place_qr_code_identifier'] = Variable<int>(
        surfacePlaceQrCodeIdentifier,
      );
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        SurfacePlaces.$convertercreatedByUserUuidn.toSql(createdByUserUuid),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        SurfacePlaces.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  SurfacePlacesCompanion toCompanion(bool nullToAbsent) {
    return SurfacePlacesCompanion(
      uuid: Value(uuid),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      type: type == null && nullToAbsent ? const Value.absent() : Value(type),
      surfacePlaceQrCodeIdentifier:
          surfacePlaceQrCodeIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(surfacePlaceQrCodeIdentifier),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory SurfacePlace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurfacePlace(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      type: serializer.fromJson<String?>(json['type']),
      surfacePlaceQrCodeIdentifier: serializer.fromJson<int?>(
        json['surface_place_qr_code_identifier'],
      ),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'type': serializer.toJson<String?>(type),
      'surface_place_qr_code_identifier': serializer.toJson<int?>(
        surfacePlaceQrCodeIdentifier,
      ),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  SurfacePlace copyWith({
    Uuid? uuid,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<int?> surfacePlaceQrCodeIdentifier = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => SurfacePlace(
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    type: type.present ? type.value : this.type,
    surfacePlaceQrCodeIdentifier: surfacePlaceQrCodeIdentifier.present
        ? surfacePlaceQrCodeIdentifier.value
        : this.surfacePlaceQrCodeIdentifier,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  SurfacePlace copyWithCompanion(SurfacePlacesCompanion data) {
    return SurfacePlace(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      surfacePlaceQrCodeIdentifier: data.surfacePlaceQrCodeIdentifier.present
          ? data.surfacePlaceQrCodeIdentifier.value
          : this.surfacePlaceQrCodeIdentifier,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurfacePlace(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write(
            'surfacePlaceQrCodeIdentifier: $surfacePlaceQrCodeIdentifier, ',
          )
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    title,
    description,
    type,
    surfacePlaceQrCodeIdentifier,
    latitude,
    longitude,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurfacePlace &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.surfacePlaceQrCodeIdentifier ==
              this.surfacePlaceQrCodeIdentifier &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class SurfacePlacesCompanion extends UpdateCompanion<SurfacePlace> {
  final Value<Uuid> uuid;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> type;
  final Value<int?> surfacePlaceQrCodeIdentifier;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const SurfacePlacesCompanion({
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.surfacePlaceQrCodeIdentifier = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SurfacePlacesCompanion.insert({
    required Uuid uuid,
    required String title,
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.surfacePlaceQrCodeIdentifier = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       title = Value(title);
  static Insertable<SurfacePlace> custom({
    Expression<Uint8List>? uuid,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? type,
    Expression<int>? surfacePlaceQrCodeIdentifier,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (surfacePlaceQrCodeIdentifier != null)
        'surface_place_qr_code_identifier': surfacePlaceQrCodeIdentifier,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SurfacePlacesCompanion copyWith({
    Value<Uuid>? uuid,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? type,
    Value<int?>? surfacePlaceQrCodeIdentifier,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return SurfacePlacesCompanion(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      surfacePlaceQrCodeIdentifier:
          surfacePlaceQrCodeIdentifier ?? this.surfacePlaceQrCodeIdentifier,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        SurfacePlaces.$converteruuid.toSql(uuid.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (surfacePlaceQrCodeIdentifier.present) {
      map['surface_place_qr_code_identifier'] = Variable<int>(
        surfacePlaceQrCodeIdentifier.value,
      );
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        SurfacePlaces.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid.value,
        ),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        SurfacePlaces.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurfacePlacesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write(
            'surfacePlaceQrCodeIdentifier: $surfacePlaceQrCodeIdentifier, ',
          )
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CaveEntrances extends Table with TableInfo<CaveEntrances, CaveEntrance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CaveEntrances(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(CaveEntrances.$converteruuid);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> caveUuid =
      GeneratedColumn<Uint8List>(
        'cave_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL REFERENCES caves(uuid)',
      ).withConverter<Uuid>(CaveEntrances.$convertercaveUuid);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  surfacePlaceUuid = GeneratedColumn<Uint8List>(
    'surface_place_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES surface_places(uuid)',
  ).withConverter<Uuid?>(CaveEntrances.$convertersurfacePlaceUuidn);
  static const VerificationMeta _isMainEntranceMeta = const VerificationMeta(
    'isMainEntrance',
  );
  late final GeneratedColumn<int> isMainEntrance = GeneratedColumn<int>(
    'is_main_entrance',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(CaveEntrances.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(CaveEntrances.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    caveUuid,
    surfacePlaceUuid,
    isMainEntrance,
    title,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cave_entrances';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaveEntrance> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('is_main_entrance')) {
      context.handle(
        _isMainEntranceMeta,
        isMainEntrance.isAcceptableOrUnknown(
          data['is_main_entrance']!,
          _isMainEntranceMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {caveUuid, title},
  ];
  @override
  CaveEntrance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaveEntrance(
      uuid: CaveEntrances.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      caveUuid: CaveEntrances.$convertercaveUuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}cave_uuid'],
        )!,
      ),
      surfacePlaceUuid: CaveEntrances.$convertersurfacePlaceUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}surface_place_uuid'],
        ),
      ),
      isMainEntrance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_main_entrance'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: CaveEntrances.$convertercreatedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}created_by_user_uuid'],
        ),
      ),
      lastModifiedByUserUuid: CaveEntrances.$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  CaveEntrances createAlias(String alias) {
    return CaveEntrances(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercaveUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertersurfacePlaceUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertersurfacePlaceUuidn =
      NullAwareTypeConverter.wrap($convertersurfacePlaceUuid);
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(cave_uuid, title)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CaveEntrance extends DataClass implements Insertable<CaveEntrance> {
  final Uuid uuid;
  final Uuid caveUuid;
  final Uuid? surfacePlaceUuid;
  final int? isMainEntrance;
  final String? title;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const CaveEntrance({
    required this.uuid,
    required this.caveUuid,
    this.surfacePlaceUuid,
    this.isMainEntrance,
    this.title,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(
        CaveEntrances.$converteruuid.toSql(uuid),
      );
    }
    {
      map['cave_uuid'] = Variable<Uint8List>(
        CaveEntrances.$convertercaveUuid.toSql(caveUuid),
      );
    }
    if (!nullToAbsent || surfacePlaceUuid != null) {
      map['surface_place_uuid'] = Variable<Uint8List>(
        CaveEntrances.$convertersurfacePlaceUuidn.toSql(surfacePlaceUuid),
      );
    }
    if (!nullToAbsent || isMainEntrance != null) {
      map['is_main_entrance'] = Variable<int>(isMainEntrance);
    }
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CaveEntrances.$convertercreatedByUserUuidn.toSql(createdByUserUuid),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CaveEntrances.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  CaveEntrancesCompanion toCompanion(bool nullToAbsent) {
    return CaveEntrancesCompanion(
      uuid: Value(uuid),
      caveUuid: Value(caveUuid),
      surfacePlaceUuid: surfacePlaceUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(surfacePlaceUuid),
      isMainEntrance: isMainEntrance == null && nullToAbsent
          ? const Value.absent()
          : Value(isMainEntrance),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory CaveEntrance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaveEntrance(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      caveUuid: serializer.fromJson<Uuid>(json['cave_uuid']),
      surfacePlaceUuid: serializer.fromJson<Uuid?>(json['surface_place_uuid']),
      isMainEntrance: serializer.fromJson<int?>(json['is_main_entrance']),
      title: serializer.fromJson<String?>(json['title']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'cave_uuid': serializer.toJson<Uuid>(caveUuid),
      'surface_place_uuid': serializer.toJson<Uuid?>(surfacePlaceUuid),
      'is_main_entrance': serializer.toJson<int?>(isMainEntrance),
      'title': serializer.toJson<String?>(title),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  CaveEntrance copyWith({
    Uuid? uuid,
    Uuid? caveUuid,
    Value<Uuid?> surfacePlaceUuid = const Value.absent(),
    Value<int?> isMainEntrance = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => CaveEntrance(
    uuid: uuid ?? this.uuid,
    caveUuid: caveUuid ?? this.caveUuid,
    surfacePlaceUuid: surfacePlaceUuid.present
        ? surfacePlaceUuid.value
        : this.surfacePlaceUuid,
    isMainEntrance: isMainEntrance.present
        ? isMainEntrance.value
        : this.isMainEntrance,
    title: title.present ? title.value : this.title,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  CaveEntrance copyWithCompanion(CaveEntrancesCompanion data) {
    return CaveEntrance(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      caveUuid: data.caveUuid.present ? data.caveUuid.value : this.caveUuid,
      surfacePlaceUuid: data.surfacePlaceUuid.present
          ? data.surfacePlaceUuid.value
          : this.surfacePlaceUuid,
      isMainEntrance: data.isMainEntrance.present
          ? data.isMainEntrance.value
          : this.isMainEntrance,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaveEntrance(')
          ..write('uuid: $uuid, ')
          ..write('caveUuid: $caveUuid, ')
          ..write('surfacePlaceUuid: $surfacePlaceUuid, ')
          ..write('isMainEntrance: $isMainEntrance, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    caveUuid,
    surfacePlaceUuid,
    isMainEntrance,
    title,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaveEntrance &&
          other.uuid == this.uuid &&
          other.caveUuid == this.caveUuid &&
          other.surfacePlaceUuid == this.surfacePlaceUuid &&
          other.isMainEntrance == this.isMainEntrance &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class CaveEntrancesCompanion extends UpdateCompanion<CaveEntrance> {
  final Value<Uuid> uuid;
  final Value<Uuid> caveUuid;
  final Value<Uuid?> surfacePlaceUuid;
  final Value<int?> isMainEntrance;
  final Value<String?> title;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const CaveEntrancesCompanion({
    this.uuid = const Value.absent(),
    this.caveUuid = const Value.absent(),
    this.surfacePlaceUuid = const Value.absent(),
    this.isMainEntrance = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaveEntrancesCompanion.insert({
    required Uuid uuid,
    required Uuid caveUuid,
    this.surfacePlaceUuid = const Value.absent(),
    this.isMainEntrance = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       caveUuid = Value(caveUuid);
  static Insertable<CaveEntrance> custom({
    Expression<Uint8List>? uuid,
    Expression<Uint8List>? caveUuid,
    Expression<Uint8List>? surfacePlaceUuid,
    Expression<int>? isMainEntrance,
    Expression<String>? title,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (caveUuid != null) 'cave_uuid': caveUuid,
      if (surfacePlaceUuid != null) 'surface_place_uuid': surfacePlaceUuid,
      if (isMainEntrance != null) 'is_main_entrance': isMainEntrance,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaveEntrancesCompanion copyWith({
    Value<Uuid>? uuid,
    Value<Uuid>? caveUuid,
    Value<Uuid?>? surfacePlaceUuid,
    Value<int?>? isMainEntrance,
    Value<String?>? title,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return CaveEntrancesCompanion(
      uuid: uuid ?? this.uuid,
      caveUuid: caveUuid ?? this.caveUuid,
      surfacePlaceUuid: surfacePlaceUuid ?? this.surfacePlaceUuid,
      isMainEntrance: isMainEntrance ?? this.isMainEntrance,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        CaveEntrances.$converteruuid.toSql(uuid.value),
      );
    }
    if (caveUuid.present) {
      map['cave_uuid'] = Variable<Uint8List>(
        CaveEntrances.$convertercaveUuid.toSql(caveUuid.value),
      );
    }
    if (surfacePlaceUuid.present) {
      map['surface_place_uuid'] = Variable<Uint8List>(
        CaveEntrances.$convertersurfacePlaceUuidn.toSql(surfacePlaceUuid.value),
      );
    }
    if (isMainEntrance.present) {
      map['is_main_entrance'] = Variable<int>(isMainEntrance.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CaveEntrances.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid.value,
        ),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CaveEntrances.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaveEntrancesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('caveUuid: $caveUuid, ')
          ..write('surfacePlaceUuid: $surfacePlaceUuid, ')
          ..write('isMainEntrance: $isMainEntrance, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CavePlaces extends Table with TableInfo<CavePlaces, CavePlace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CavePlaces(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(CavePlaces.$converteruuid);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> caveUuid =
      GeneratedColumn<Uint8List>(
        'cave_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL REFERENCES caves(uuid)',
      ).withConverter<Uuid>(CavePlaces.$convertercaveUuid);
  static const VerificationMeta _placeQrCodeIdentifierMeta =
      const VerificationMeta('placeQrCodeIdentifier');
  late final GeneratedColumn<int> placeQrCodeIdentifier = GeneratedColumn<int>(
    'place_qr_code_identifier',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List> caveAreaUuid =
      GeneratedColumn<Uint8List>(
        'cave_area_uuid',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES cave_areas(uuid)',
      ).withConverter<Uuid?>(CavePlaces.$convertercaveAreaUuidn);
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _altitudeMeta = const VerificationMeta(
    'altitude',
  );
  late final GeneratedColumn<double> altitude = GeneratedColumn<double>(
    'altitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _depthInCaveMeta = const VerificationMeta(
    'depthInCave',
  );
  late final GeneratedColumn<double> depthInCave = GeneratedColumn<double>(
    'depth_in_cave',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _isEntranceMeta = const VerificationMeta(
    'isEntrance',
  );
  late final GeneratedColumn<int> isEntrance = GeneratedColumn<int>(
    'is_entrance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _isMainEntranceMeta = const VerificationMeta(
    'isMainEntrance',
  );
  late final GeneratedColumn<int> isMainEntrance = GeneratedColumn<int>(
    'is_main_entrance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(CavePlaces.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(CavePlaces.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    title,
    description,
    caveUuid,
    placeQrCodeIdentifier,
    caveAreaUuid,
    latitude,
    longitude,
    altitude,
    depthInCave,
    isEntrance,
    isMainEntrance,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cave_places';
  @override
  VerificationContext validateIntegrity(
    Insertable<CavePlace> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('place_qr_code_identifier')) {
      context.handle(
        _placeQrCodeIdentifierMeta,
        placeQrCodeIdentifier.isAcceptableOrUnknown(
          data['place_qr_code_identifier']!,
          _placeQrCodeIdentifierMeta,
        ),
      );
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('altitude')) {
      context.handle(
        _altitudeMeta,
        altitude.isAcceptableOrUnknown(data['altitude']!, _altitudeMeta),
      );
    }
    if (data.containsKey('depth_in_cave')) {
      context.handle(
        _depthInCaveMeta,
        depthInCave.isAcceptableOrUnknown(
          data['depth_in_cave']!,
          _depthInCaveMeta,
        ),
      );
    }
    if (data.containsKey('is_entrance')) {
      context.handle(
        _isEntranceMeta,
        isEntrance.isAcceptableOrUnknown(data['is_entrance']!, _isEntranceMeta),
      );
    }
    if (data.containsKey('is_main_entrance')) {
      context.handle(
        _isMainEntranceMeta,
        isMainEntrance.isAcceptableOrUnknown(
          data['is_main_entrance']!,
          _isMainEntranceMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title, caveUuid, caveAreaUuid},
  ];
  @override
  CavePlace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CavePlace(
      uuid: CavePlaces.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      caveUuid: CavePlaces.$convertercaveUuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}cave_uuid'],
        )!,
      ),
      placeQrCodeIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}place_qr_code_identifier'],
      ),
      caveAreaUuid: CavePlaces.$convertercaveAreaUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}cave_area_uuid'],
        ),
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      altitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}altitude'],
      ),
      depthInCave: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}depth_in_cave'],
      ),
      isEntrance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_entrance'],
      )!,
      isMainEntrance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_main_entrance'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: CavePlaces.$convertercreatedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}created_by_user_uuid'],
        ),
      ),
      lastModifiedByUserUuid: CavePlaces.$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  CavePlaces createAlias(String alias) {
    return CavePlaces(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercaveUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercaveAreaUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercaveAreaUuidn =
      NullAwareTypeConverter.wrap($convertercaveAreaUuid);
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(title, cave_uuid, cave_area_uuid)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CavePlace extends DataClass implements Insertable<CavePlace> {
  final Uuid uuid;
  final String title;
  final String? description;
  final Uuid caveUuid;
  final int? placeQrCodeIdentifier;

  /// QR codes are either globally unique, either per-cave unique, either per surface area unique, depending on user configured choice in his dataset rules
  final Uuid? caveAreaUuid;

  ///todo: redesign - SQLite stores everything as REAL (the actual DB schema confirms this). The NUMERIC(p,s) type affinity in SQLite is effectively ignored — scale/precision are cosmetic
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final double? depthInCave;
  final int isEntrance;
  final int isMainEntrance;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const CavePlace({
    required this.uuid,
    required this.title,
    this.description,
    required this.caveUuid,
    this.placeQrCodeIdentifier,
    this.caveAreaUuid,
    this.latitude,
    this.longitude,
    this.altitude,
    this.depthInCave,
    required this.isEntrance,
    required this.isMainEntrance,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(CavePlaces.$converteruuid.toSql(uuid));
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    {
      map['cave_uuid'] = Variable<Uint8List>(
        CavePlaces.$convertercaveUuid.toSql(caveUuid),
      );
    }
    if (!nullToAbsent || placeQrCodeIdentifier != null) {
      map['place_qr_code_identifier'] = Variable<int>(placeQrCodeIdentifier);
    }
    if (!nullToAbsent || caveAreaUuid != null) {
      map['cave_area_uuid'] = Variable<Uint8List>(
        CavePlaces.$convertercaveAreaUuidn.toSql(caveAreaUuid),
      );
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || altitude != null) {
      map['altitude'] = Variable<double>(altitude);
    }
    if (!nullToAbsent || depthInCave != null) {
      map['depth_in_cave'] = Variable<double>(depthInCave);
    }
    map['is_entrance'] = Variable<int>(isEntrance);
    map['is_main_entrance'] = Variable<int>(isMainEntrance);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CavePlaces.$convertercreatedByUserUuidn.toSql(createdByUserUuid),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CavePlaces.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  CavePlacesCompanion toCompanion(bool nullToAbsent) {
    return CavePlacesCompanion(
      uuid: Value(uuid),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      caveUuid: Value(caveUuid),
      placeQrCodeIdentifier: placeQrCodeIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(placeQrCodeIdentifier),
      caveAreaUuid: caveAreaUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(caveAreaUuid),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      altitude: altitude == null && nullToAbsent
          ? const Value.absent()
          : Value(altitude),
      depthInCave: depthInCave == null && nullToAbsent
          ? const Value.absent()
          : Value(depthInCave),
      isEntrance: Value(isEntrance),
      isMainEntrance: Value(isMainEntrance),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory CavePlace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CavePlace(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      caveUuid: serializer.fromJson<Uuid>(json['cave_uuid']),
      placeQrCodeIdentifier: serializer.fromJson<int?>(
        json['place_qr_code_identifier'],
      ),
      caveAreaUuid: serializer.fromJson<Uuid?>(json['cave_area_uuid']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      altitude: serializer.fromJson<double?>(json['altitude']),
      depthInCave: serializer.fromJson<double?>(json['depth_in_cave']),
      isEntrance: serializer.fromJson<int>(json['is_entrance']),
      isMainEntrance: serializer.fromJson<int>(json['is_main_entrance']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'cave_uuid': serializer.toJson<Uuid>(caveUuid),
      'place_qr_code_identifier': serializer.toJson<int?>(
        placeQrCodeIdentifier,
      ),
      'cave_area_uuid': serializer.toJson<Uuid?>(caveAreaUuid),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'altitude': serializer.toJson<double?>(altitude),
      'depth_in_cave': serializer.toJson<double?>(depthInCave),
      'is_entrance': serializer.toJson<int>(isEntrance),
      'is_main_entrance': serializer.toJson<int>(isMainEntrance),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  CavePlace copyWith({
    Uuid? uuid,
    String? title,
    Value<String?> description = const Value.absent(),
    Uuid? caveUuid,
    Value<int?> placeQrCodeIdentifier = const Value.absent(),
    Value<Uuid?> caveAreaUuid = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<double?> altitude = const Value.absent(),
    Value<double?> depthInCave = const Value.absent(),
    int? isEntrance,
    int? isMainEntrance,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => CavePlace(
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    caveUuid: caveUuid ?? this.caveUuid,
    placeQrCodeIdentifier: placeQrCodeIdentifier.present
        ? placeQrCodeIdentifier.value
        : this.placeQrCodeIdentifier,
    caveAreaUuid: caveAreaUuid.present ? caveAreaUuid.value : this.caveAreaUuid,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    altitude: altitude.present ? altitude.value : this.altitude,
    depthInCave: depthInCave.present ? depthInCave.value : this.depthInCave,
    isEntrance: isEntrance ?? this.isEntrance,
    isMainEntrance: isMainEntrance ?? this.isMainEntrance,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  CavePlace copyWithCompanion(CavePlacesCompanion data) {
    return CavePlace(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      caveUuid: data.caveUuid.present ? data.caveUuid.value : this.caveUuid,
      placeQrCodeIdentifier: data.placeQrCodeIdentifier.present
          ? data.placeQrCodeIdentifier.value
          : this.placeQrCodeIdentifier,
      caveAreaUuid: data.caveAreaUuid.present
          ? data.caveAreaUuid.value
          : this.caveAreaUuid,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      altitude: data.altitude.present ? data.altitude.value : this.altitude,
      depthInCave: data.depthInCave.present
          ? data.depthInCave.value
          : this.depthInCave,
      isEntrance: data.isEntrance.present
          ? data.isEntrance.value
          : this.isEntrance,
      isMainEntrance: data.isMainEntrance.present
          ? data.isMainEntrance.value
          : this.isMainEntrance,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CavePlace(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('caveUuid: $caveUuid, ')
          ..write('placeQrCodeIdentifier: $placeQrCodeIdentifier, ')
          ..write('caveAreaUuid: $caveAreaUuid, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('depthInCave: $depthInCave, ')
          ..write('isEntrance: $isEntrance, ')
          ..write('isMainEntrance: $isMainEntrance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    title,
    description,
    caveUuid,
    placeQrCodeIdentifier,
    caveAreaUuid,
    latitude,
    longitude,
    altitude,
    depthInCave,
    isEntrance,
    isMainEntrance,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CavePlace &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.description == this.description &&
          other.caveUuid == this.caveUuid &&
          other.placeQrCodeIdentifier == this.placeQrCodeIdentifier &&
          other.caveAreaUuid == this.caveAreaUuid &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.altitude == this.altitude &&
          other.depthInCave == this.depthInCave &&
          other.isEntrance == this.isEntrance &&
          other.isMainEntrance == this.isMainEntrance &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class CavePlacesCompanion extends UpdateCompanion<CavePlace> {
  final Value<Uuid> uuid;
  final Value<String> title;
  final Value<String?> description;
  final Value<Uuid> caveUuid;
  final Value<int?> placeQrCodeIdentifier;
  final Value<Uuid?> caveAreaUuid;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<double?> altitude;
  final Value<double?> depthInCave;
  final Value<int> isEntrance;
  final Value<int> isMainEntrance;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const CavePlacesCompanion({
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.caveUuid = const Value.absent(),
    this.placeQrCodeIdentifier = const Value.absent(),
    this.caveAreaUuid = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.altitude = const Value.absent(),
    this.depthInCave = const Value.absent(),
    this.isEntrance = const Value.absent(),
    this.isMainEntrance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CavePlacesCompanion.insert({
    required Uuid uuid,
    required String title,
    this.description = const Value.absent(),
    required Uuid caveUuid,
    this.placeQrCodeIdentifier = const Value.absent(),
    this.caveAreaUuid = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.altitude = const Value.absent(),
    this.depthInCave = const Value.absent(),
    this.isEntrance = const Value.absent(),
    this.isMainEntrance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       title = Value(title),
       caveUuid = Value(caveUuid);
  static Insertable<CavePlace> custom({
    Expression<Uint8List>? uuid,
    Expression<String>? title,
    Expression<String>? description,
    Expression<Uint8List>? caveUuid,
    Expression<int>? placeQrCodeIdentifier,
    Expression<Uint8List>? caveAreaUuid,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? altitude,
    Expression<double>? depthInCave,
    Expression<int>? isEntrance,
    Expression<int>? isMainEntrance,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (caveUuid != null) 'cave_uuid': caveUuid,
      if (placeQrCodeIdentifier != null)
        'place_qr_code_identifier': placeQrCodeIdentifier,
      if (caveAreaUuid != null) 'cave_area_uuid': caveAreaUuid,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (altitude != null) 'altitude': altitude,
      if (depthInCave != null) 'depth_in_cave': depthInCave,
      if (isEntrance != null) 'is_entrance': isEntrance,
      if (isMainEntrance != null) 'is_main_entrance': isMainEntrance,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CavePlacesCompanion copyWith({
    Value<Uuid>? uuid,
    Value<String>? title,
    Value<String?>? description,
    Value<Uuid>? caveUuid,
    Value<int?>? placeQrCodeIdentifier,
    Value<Uuid?>? caveAreaUuid,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<double?>? altitude,
    Value<double?>? depthInCave,
    Value<int>? isEntrance,
    Value<int>? isMainEntrance,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return CavePlacesCompanion(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      caveUuid: caveUuid ?? this.caveUuid,
      placeQrCodeIdentifier:
          placeQrCodeIdentifier ?? this.placeQrCodeIdentifier,
      caveAreaUuid: caveAreaUuid ?? this.caveAreaUuid,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      depthInCave: depthInCave ?? this.depthInCave,
      isEntrance: isEntrance ?? this.isEntrance,
      isMainEntrance: isMainEntrance ?? this.isMainEntrance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        CavePlaces.$converteruuid.toSql(uuid.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (caveUuid.present) {
      map['cave_uuid'] = Variable<Uint8List>(
        CavePlaces.$convertercaveUuid.toSql(caveUuid.value),
      );
    }
    if (placeQrCodeIdentifier.present) {
      map['place_qr_code_identifier'] = Variable<int>(
        placeQrCodeIdentifier.value,
      );
    }
    if (caveAreaUuid.present) {
      map['cave_area_uuid'] = Variable<Uint8List>(
        CavePlaces.$convertercaveAreaUuidn.toSql(caveAreaUuid.value),
      );
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (altitude.present) {
      map['altitude'] = Variable<double>(altitude.value);
    }
    if (depthInCave.present) {
      map['depth_in_cave'] = Variable<double>(depthInCave.value);
    }
    if (isEntrance.present) {
      map['is_entrance'] = Variable<int>(isEntrance.value);
    }
    if (isMainEntrance.present) {
      map['is_main_entrance'] = Variable<int>(isMainEntrance.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CavePlaces.$convertercreatedByUserUuidn.toSql(createdByUserUuid.value),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CavePlaces.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CavePlacesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('caveUuid: $caveUuid, ')
          ..write('placeQrCodeIdentifier: $placeQrCodeIdentifier, ')
          ..write('caveAreaUuid: $caveAreaUuid, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('altitude: $altitude, ')
          ..write('depthInCave: $depthInCave, ')
          ..write('isEntrance: $isEntrance, ')
          ..write('isMainEntrance: $isMainEntrance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class RasterMaps extends Table with TableInfo<RasterMaps, RasterMap> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RasterMaps(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(RasterMaps.$converteruuid);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _mapTypeMeta = const VerificationMeta(
    'mapType',
  );
  late final GeneratedColumn<String> mapType = GeneratedColumn<String>(
    'map_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (map_type IN (\'plane view\', \'projected profile\', \'extended profile\'))',
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> caveUuid =
      GeneratedColumn<Uint8List>(
        'cave_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL REFERENCES caves(uuid)',
      ).withConverter<Uuid>(RasterMaps.$convertercaveUuid);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List> caveAreaUuid =
      GeneratedColumn<Uint8List>(
        'cave_area_uuid',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES cave_areas(uuid)',
      ).withConverter<Uuid?>(RasterMaps.$convertercaveAreaUuidn);
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(RasterMaps.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(RasterMaps.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    title,
    mapType,
    fileName,
    caveUuid,
    caveAreaUuid,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'raster_maps';
  @override
  VerificationContext validateIntegrity(
    Insertable<RasterMap> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('map_type')) {
      context.handle(
        _mapTypeMeta,
        mapType.isAcceptableOrUnknown(data['map_type']!, _mapTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mapTypeMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title, mapType, caveUuid},
    {fileName, mapType, caveUuid},
  ];
  @override
  RasterMap map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RasterMap(
      uuid: RasterMaps.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      mapType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}map_type'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      caveUuid: RasterMaps.$convertercaveUuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}cave_uuid'],
        )!,
      ),
      caveAreaUuid: RasterMaps.$convertercaveAreaUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}cave_area_uuid'],
        ),
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: RasterMaps.$convertercreatedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}created_by_user_uuid'],
        ),
      ),
      lastModifiedByUserUuid: RasterMaps.$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  RasterMaps createAlias(String alias) {
    return RasterMaps(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercaveUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercaveAreaUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercaveAreaUuidn =
      NullAwareTypeConverter.wrap($convertercaveAreaUuid);
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(title, map_type, cave_uuid)ON CONFLICT ROLLBACK',
    'UNIQUE(file_name, map_type, cave_uuid)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class RasterMap extends DataClass implements Insertable<RasterMap> {
  final Uuid uuid;
  final String title;
  final String mapType;
  final String fileName;
  final Uuid caveUuid;
  final Uuid? caveAreaUuid;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const RasterMap({
    required this.uuid,
    required this.title,
    required this.mapType,
    required this.fileName,
    required this.caveUuid,
    this.caveAreaUuid,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(RasterMaps.$converteruuid.toSql(uuid));
    }
    map['title'] = Variable<String>(title);
    map['map_type'] = Variable<String>(mapType);
    map['file_name'] = Variable<String>(fileName);
    {
      map['cave_uuid'] = Variable<Uint8List>(
        RasterMaps.$convertercaveUuid.toSql(caveUuid),
      );
    }
    if (!nullToAbsent || caveAreaUuid != null) {
      map['cave_area_uuid'] = Variable<Uint8List>(
        RasterMaps.$convertercaveAreaUuidn.toSql(caveAreaUuid),
      );
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        RasterMaps.$convertercreatedByUserUuidn.toSql(createdByUserUuid),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        RasterMaps.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  RasterMapsCompanion toCompanion(bool nullToAbsent) {
    return RasterMapsCompanion(
      uuid: Value(uuid),
      title: Value(title),
      mapType: Value(mapType),
      fileName: Value(fileName),
      caveUuid: Value(caveUuid),
      caveAreaUuid: caveAreaUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(caveAreaUuid),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory RasterMap.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RasterMap(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      mapType: serializer.fromJson<String>(json['map_type']),
      fileName: serializer.fromJson<String>(json['file_name']),
      caveUuid: serializer.fromJson<Uuid>(json['cave_uuid']),
      caveAreaUuid: serializer.fromJson<Uuid?>(json['cave_area_uuid']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'title': serializer.toJson<String>(title),
      'map_type': serializer.toJson<String>(mapType),
      'file_name': serializer.toJson<String>(fileName),
      'cave_uuid': serializer.toJson<Uuid>(caveUuid),
      'cave_area_uuid': serializer.toJson<Uuid?>(caveAreaUuid),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  RasterMap copyWith({
    Uuid? uuid,
    String? title,
    String? mapType,
    String? fileName,
    Uuid? caveUuid,
    Value<Uuid?> caveAreaUuid = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => RasterMap(
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    mapType: mapType ?? this.mapType,
    fileName: fileName ?? this.fileName,
    caveUuid: caveUuid ?? this.caveUuid,
    caveAreaUuid: caveAreaUuid.present ? caveAreaUuid.value : this.caveAreaUuid,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  RasterMap copyWithCompanion(RasterMapsCompanion data) {
    return RasterMap(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      mapType: data.mapType.present ? data.mapType.value : this.mapType,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      caveUuid: data.caveUuid.present ? data.caveUuid.value : this.caveUuid,
      caveAreaUuid: data.caveAreaUuid.present
          ? data.caveAreaUuid.value
          : this.caveAreaUuid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RasterMap(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('mapType: $mapType, ')
          ..write('fileName: $fileName, ')
          ..write('caveUuid: $caveUuid, ')
          ..write('caveAreaUuid: $caveAreaUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    title,
    mapType,
    fileName,
    caveUuid,
    caveAreaUuid,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RasterMap &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.mapType == this.mapType &&
          other.fileName == this.fileName &&
          other.caveUuid == this.caveUuid &&
          other.caveAreaUuid == this.caveAreaUuid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class RasterMapsCompanion extends UpdateCompanion<RasterMap> {
  final Value<Uuid> uuid;
  final Value<String> title;
  final Value<String> mapType;
  final Value<String> fileName;
  final Value<Uuid> caveUuid;
  final Value<Uuid?> caveAreaUuid;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const RasterMapsCompanion({
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.mapType = const Value.absent(),
    this.fileName = const Value.absent(),
    this.caveUuid = const Value.absent(),
    this.caveAreaUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RasterMapsCompanion.insert({
    required Uuid uuid,
    required String title,
    required String mapType,
    required String fileName,
    required Uuid caveUuid,
    this.caveAreaUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       title = Value(title),
       mapType = Value(mapType),
       fileName = Value(fileName),
       caveUuid = Value(caveUuid);
  static Insertable<RasterMap> custom({
    Expression<Uint8List>? uuid,
    Expression<String>? title,
    Expression<String>? mapType,
    Expression<String>? fileName,
    Expression<Uint8List>? caveUuid,
    Expression<Uint8List>? caveAreaUuid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (mapType != null) 'map_type': mapType,
      if (fileName != null) 'file_name': fileName,
      if (caveUuid != null) 'cave_uuid': caveUuid,
      if (caveAreaUuid != null) 'cave_area_uuid': caveAreaUuid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RasterMapsCompanion copyWith({
    Value<Uuid>? uuid,
    Value<String>? title,
    Value<String>? mapType,
    Value<String>? fileName,
    Value<Uuid>? caveUuid,
    Value<Uuid?>? caveAreaUuid,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return RasterMapsCompanion(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      mapType: mapType ?? this.mapType,
      fileName: fileName ?? this.fileName,
      caveUuid: caveUuid ?? this.caveUuid,
      caveAreaUuid: caveAreaUuid ?? this.caveAreaUuid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        RasterMaps.$converteruuid.toSql(uuid.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (mapType.present) {
      map['map_type'] = Variable<String>(mapType.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (caveUuid.present) {
      map['cave_uuid'] = Variable<Uint8List>(
        RasterMaps.$convertercaveUuid.toSql(caveUuid.value),
      );
    }
    if (caveAreaUuid.present) {
      map['cave_area_uuid'] = Variable<Uint8List>(
        RasterMaps.$convertercaveAreaUuidn.toSql(caveAreaUuid.value),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        RasterMaps.$convertercreatedByUserUuidn.toSql(createdByUserUuid.value),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        RasterMaps.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RasterMapsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('mapType: $mapType, ')
          ..write('fileName: $fileName, ')
          ..write('caveUuid: $caveUuid, ')
          ..write('caveAreaUuid: $caveAreaUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CavePlaceToRasterMapDefinitions extends Table
    with
        TableInfo<
          CavePlaceToRasterMapDefinitions,
          CavePlaceToRasterMapDefinition
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CavePlaceToRasterMapDefinitions(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(CavePlaceToRasterMapDefinitions.$converteruuid);
  static const VerificationMeta _xCoordinateMeta = const VerificationMeta(
    'xCoordinate',
  );
  late final GeneratedColumn<int> xCoordinate = GeneratedColumn<int>(
    'x_coordinate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _yCoordinateMeta = const VerificationMeta(
    'yCoordinate',
  );
  late final GeneratedColumn<int> yCoordinate = GeneratedColumn<int>(
    'y_coordinate',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> cavePlaceUuid =
      GeneratedColumn<Uint8List>(
        'cave_place_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL REFERENCES cave_places(uuid)',
      ).withConverter<Uuid>(
        CavePlaceToRasterMapDefinitions.$convertercavePlaceUuid,
      );
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> rasterMapUuid =
      GeneratedColumn<Uint8List>(
        'raster_map_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL REFERENCES raster_maps(uuid)',
      ).withConverter<Uuid>(
        CavePlaceToRasterMapDefinitions.$converterrasterMapUuid,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid =
      GeneratedColumn<Uint8List>(
        'created_by_user_uuid',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES users(uuid)',
      ).withConverter<Uuid?>(
        CavePlaceToRasterMapDefinitions.$convertercreatedByUserUuidn,
      );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid =
      GeneratedColumn<Uint8List>(
        'last_modified_by_user_uuid',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES users(uuid)',
      ).withConverter<Uuid?>(
        CavePlaceToRasterMapDefinitions.$converterlastModifiedByUserUuidn,
      );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    xCoordinate,
    yCoordinate,
    cavePlaceUuid,
    rasterMapUuid,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cave_place_to_raster_map_definitions';
  @override
  VerificationContext validateIntegrity(
    Insertable<CavePlaceToRasterMapDefinition> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('x_coordinate')) {
      context.handle(
        _xCoordinateMeta,
        xCoordinate.isAcceptableOrUnknown(
          data['x_coordinate']!,
          _xCoordinateMeta,
        ),
      );
    }
    if (data.containsKey('y_coordinate')) {
      context.handle(
        _yCoordinateMeta,
        yCoordinate.isAcceptableOrUnknown(
          data['y_coordinate']!,
          _yCoordinateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {cavePlaceUuid, rasterMapUuid},
  ];
  @override
  CavePlaceToRasterMapDefinition map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CavePlaceToRasterMapDefinition(
      uuid: CavePlaceToRasterMapDefinitions.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      xCoordinate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x_coordinate'],
      ),
      yCoordinate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y_coordinate'],
      ),
      cavePlaceUuid: CavePlaceToRasterMapDefinitions.$convertercavePlaceUuid
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}cave_place_uuid'],
            )!,
          ),
      rasterMapUuid: CavePlaceToRasterMapDefinitions.$converterrasterMapUuid
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}raster_map_uuid'],
            )!,
          ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: CavePlaceToRasterMapDefinitions
          .$convertercreatedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}created_by_user_uuid'],
            ),
          ),
      lastModifiedByUserUuid: CavePlaceToRasterMapDefinitions
          .$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  CavePlaceToRasterMapDefinitions createAlias(String alias) {
    return CavePlaceToRasterMapDefinitions(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercavePlaceUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $converterrasterMapUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(cave_place_uuid, raster_map_uuid)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CavePlaceToRasterMapDefinition extends DataClass
    implements Insertable<CavePlaceToRasterMapDefinition> {
  final Uuid uuid;
  final int? xCoordinate;
  final int? yCoordinate;
  final Uuid cavePlaceUuid;
  final Uuid rasterMapUuid;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const CavePlaceToRasterMapDefinition({
    required this.uuid,
    this.xCoordinate,
    this.yCoordinate,
    required this.cavePlaceUuid,
    required this.rasterMapUuid,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(
        CavePlaceToRasterMapDefinitions.$converteruuid.toSql(uuid),
      );
    }
    if (!nullToAbsent || xCoordinate != null) {
      map['x_coordinate'] = Variable<int>(xCoordinate);
    }
    if (!nullToAbsent || yCoordinate != null) {
      map['y_coordinate'] = Variable<int>(yCoordinate);
    }
    {
      map['cave_place_uuid'] = Variable<Uint8List>(
        CavePlaceToRasterMapDefinitions.$convertercavePlaceUuid.toSql(
          cavePlaceUuid,
        ),
      );
    }
    {
      map['raster_map_uuid'] = Variable<Uint8List>(
        CavePlaceToRasterMapDefinitions.$converterrasterMapUuid.toSql(
          rasterMapUuid,
        ),
      );
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CavePlaceToRasterMapDefinitions.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid,
        ),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CavePlaceToRasterMapDefinitions.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  CavePlaceToRasterMapDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return CavePlaceToRasterMapDefinitionsCompanion(
      uuid: Value(uuid),
      xCoordinate: xCoordinate == null && nullToAbsent
          ? const Value.absent()
          : Value(xCoordinate),
      yCoordinate: yCoordinate == null && nullToAbsent
          ? const Value.absent()
          : Value(yCoordinate),
      cavePlaceUuid: Value(cavePlaceUuid),
      rasterMapUuid: Value(rasterMapUuid),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory CavePlaceToRasterMapDefinition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CavePlaceToRasterMapDefinition(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      xCoordinate: serializer.fromJson<int?>(json['x_coordinate']),
      yCoordinate: serializer.fromJson<int?>(json['y_coordinate']),
      cavePlaceUuid: serializer.fromJson<Uuid>(json['cave_place_uuid']),
      rasterMapUuid: serializer.fromJson<Uuid>(json['raster_map_uuid']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'x_coordinate': serializer.toJson<int?>(xCoordinate),
      'y_coordinate': serializer.toJson<int?>(yCoordinate),
      'cave_place_uuid': serializer.toJson<Uuid>(cavePlaceUuid),
      'raster_map_uuid': serializer.toJson<Uuid>(rasterMapUuid),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  CavePlaceToRasterMapDefinition copyWith({
    Uuid? uuid,
    Value<int?> xCoordinate = const Value.absent(),
    Value<int?> yCoordinate = const Value.absent(),
    Uuid? cavePlaceUuid,
    Uuid? rasterMapUuid,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => CavePlaceToRasterMapDefinition(
    uuid: uuid ?? this.uuid,
    xCoordinate: xCoordinate.present ? xCoordinate.value : this.xCoordinate,
    yCoordinate: yCoordinate.present ? yCoordinate.value : this.yCoordinate,
    cavePlaceUuid: cavePlaceUuid ?? this.cavePlaceUuid,
    rasterMapUuid: rasterMapUuid ?? this.rasterMapUuid,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  CavePlaceToRasterMapDefinition copyWithCompanion(
    CavePlaceToRasterMapDefinitionsCompanion data,
  ) {
    return CavePlaceToRasterMapDefinition(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      xCoordinate: data.xCoordinate.present
          ? data.xCoordinate.value
          : this.xCoordinate,
      yCoordinate: data.yCoordinate.present
          ? data.yCoordinate.value
          : this.yCoordinate,
      cavePlaceUuid: data.cavePlaceUuid.present
          ? data.cavePlaceUuid.value
          : this.cavePlaceUuid,
      rasterMapUuid: data.rasterMapUuid.present
          ? data.rasterMapUuid.value
          : this.rasterMapUuid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CavePlaceToRasterMapDefinition(')
          ..write('uuid: $uuid, ')
          ..write('xCoordinate: $xCoordinate, ')
          ..write('yCoordinate: $yCoordinate, ')
          ..write('cavePlaceUuid: $cavePlaceUuid, ')
          ..write('rasterMapUuid: $rasterMapUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    xCoordinate,
    yCoordinate,
    cavePlaceUuid,
    rasterMapUuid,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CavePlaceToRasterMapDefinition &&
          other.uuid == this.uuid &&
          other.xCoordinate == this.xCoordinate &&
          other.yCoordinate == this.yCoordinate &&
          other.cavePlaceUuid == this.cavePlaceUuid &&
          other.rasterMapUuid == this.rasterMapUuid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class CavePlaceToRasterMapDefinitionsCompanion
    extends UpdateCompanion<CavePlaceToRasterMapDefinition> {
  final Value<Uuid> uuid;
  final Value<int?> xCoordinate;
  final Value<int?> yCoordinate;
  final Value<Uuid> cavePlaceUuid;
  final Value<Uuid> rasterMapUuid;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const CavePlaceToRasterMapDefinitionsCompanion({
    this.uuid = const Value.absent(),
    this.xCoordinate = const Value.absent(),
    this.yCoordinate = const Value.absent(),
    this.cavePlaceUuid = const Value.absent(),
    this.rasterMapUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CavePlaceToRasterMapDefinitionsCompanion.insert({
    required Uuid uuid,
    this.xCoordinate = const Value.absent(),
    this.yCoordinate = const Value.absent(),
    required Uuid cavePlaceUuid,
    required Uuid rasterMapUuid,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       cavePlaceUuid = Value(cavePlaceUuid),
       rasterMapUuid = Value(rasterMapUuid);
  static Insertable<CavePlaceToRasterMapDefinition> custom({
    Expression<Uint8List>? uuid,
    Expression<int>? xCoordinate,
    Expression<int>? yCoordinate,
    Expression<Uint8List>? cavePlaceUuid,
    Expression<Uint8List>? rasterMapUuid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (xCoordinate != null) 'x_coordinate': xCoordinate,
      if (yCoordinate != null) 'y_coordinate': yCoordinate,
      if (cavePlaceUuid != null) 'cave_place_uuid': cavePlaceUuid,
      if (rasterMapUuid != null) 'raster_map_uuid': rasterMapUuid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CavePlaceToRasterMapDefinitionsCompanion copyWith({
    Value<Uuid>? uuid,
    Value<int?>? xCoordinate,
    Value<int?>? yCoordinate,
    Value<Uuid>? cavePlaceUuid,
    Value<Uuid>? rasterMapUuid,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return CavePlaceToRasterMapDefinitionsCompanion(
      uuid: uuid ?? this.uuid,
      xCoordinate: xCoordinate ?? this.xCoordinate,
      yCoordinate: yCoordinate ?? this.yCoordinate,
      cavePlaceUuid: cavePlaceUuid ?? this.cavePlaceUuid,
      rasterMapUuid: rasterMapUuid ?? this.rasterMapUuid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        CavePlaceToRasterMapDefinitions.$converteruuid.toSql(uuid.value),
      );
    }
    if (xCoordinate.present) {
      map['x_coordinate'] = Variable<int>(xCoordinate.value);
    }
    if (yCoordinate.present) {
      map['y_coordinate'] = Variable<int>(yCoordinate.value);
    }
    if (cavePlaceUuid.present) {
      map['cave_place_uuid'] = Variable<Uint8List>(
        CavePlaceToRasterMapDefinitions.$convertercavePlaceUuid.toSql(
          cavePlaceUuid.value,
        ),
      );
    }
    if (rasterMapUuid.present) {
      map['raster_map_uuid'] = Variable<Uint8List>(
        CavePlaceToRasterMapDefinitions.$converterrasterMapUuid.toSql(
          rasterMapUuid.value,
        ),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CavePlaceToRasterMapDefinitions.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid.value,
        ),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CavePlaceToRasterMapDefinitions.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CavePlaceToRasterMapDefinitionsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('xCoordinate: $xCoordinate, ')
          ..write('yCoordinate: $yCoordinate, ')
          ..write('cavePlaceUuid: $cavePlaceUuid, ')
          ..write('rasterMapUuid: $rasterMapUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DocumentationFiles extends Table
    with TableInfo<DocumentationFiles, DocumentationFile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DocumentationFiles(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(DocumentationFiles.$converteruuid);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fileHashMeta = const VerificationMeta(
    'fileHash',
  );
  late final GeneratedColumn<String> fileHash = GeneratedColumn<String>(
    'file_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _fileTypeMeta = const VerificationMeta(
    'fileType',
  );
  late final GeneratedColumn<String> fileType = GeneratedColumn<String>(
    'file_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(DocumentationFiles.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(DocumentationFiles.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    title,
    description,
    fileName,
    fileSize,
    fileHash,
    fileType,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documentation_files';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentationFile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('file_hash')) {
      context.handle(
        _fileHashMeta,
        fileHash.isAcceptableOrUnknown(data['file_hash']!, _fileHashMeta),
      );
    }
    if (data.containsKey('file_type')) {
      context.handle(
        _fileTypeMeta,
        fileType.isAcceptableOrUnknown(data['file_type']!, _fileTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title, fileName, fileSize, fileHash},
  ];
  @override
  DocumentationFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentationFile(
      uuid: DocumentationFiles.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      fileHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_hash'],
      ),
      fileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_type'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: DocumentationFiles.$convertercreatedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}created_by_user_uuid'],
            ),
          ),
      lastModifiedByUserUuid: DocumentationFiles
          .$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  DocumentationFiles createAlias(String alias) {
    return DocumentationFiles(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(title, file_name, file_size, file_hash)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class DocumentationFile extends DataClass
    implements Insertable<DocumentationFile> {
  final Uuid uuid;
  final String title;
  final String? description;
  final String fileName;
  final int fileSize;
  final String? fileHash;
  final String fileType;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const DocumentationFile({
    required this.uuid,
    required this.title,
    this.description,
    required this.fileName,
    required this.fileSize,
    this.fileHash,
    required this.fileType,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(
        DocumentationFiles.$converteruuid.toSql(uuid),
      );
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['file_name'] = Variable<String>(fileName);
    map['file_size'] = Variable<int>(fileSize);
    if (!nullToAbsent || fileHash != null) {
      map['file_hash'] = Variable<String>(fileHash);
    }
    map['file_type'] = Variable<String>(fileType);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFiles.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid,
        ),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFiles.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  DocumentationFilesCompanion toCompanion(bool nullToAbsent) {
    return DocumentationFilesCompanion(
      uuid: Value(uuid),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      fileName: Value(fileName),
      fileSize: Value(fileSize),
      fileHash: fileHash == null && nullToAbsent
          ? const Value.absent()
          : Value(fileHash),
      fileType: Value(fileType),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory DocumentationFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentationFile(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      fileName: serializer.fromJson<String>(json['file_name']),
      fileSize: serializer.fromJson<int>(json['file_size']),
      fileHash: serializer.fromJson<String?>(json['file_hash']),
      fileType: serializer.fromJson<String>(json['file_type']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'file_name': serializer.toJson<String>(fileName),
      'file_size': serializer.toJson<int>(fileSize),
      'file_hash': serializer.toJson<String?>(fileHash),
      'file_type': serializer.toJson<String>(fileType),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  DocumentationFile copyWith({
    Uuid? uuid,
    String? title,
    Value<String?> description = const Value.absent(),
    String? fileName,
    int? fileSize,
    Value<String?> fileHash = const Value.absent(),
    String? fileType,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => DocumentationFile(
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    fileName: fileName ?? this.fileName,
    fileSize: fileSize ?? this.fileSize,
    fileHash: fileHash.present ? fileHash.value : this.fileHash,
    fileType: fileType ?? this.fileType,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  DocumentationFile copyWithCompanion(DocumentationFilesCompanion data) {
    return DocumentationFile(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      fileHash: data.fileHash.present ? data.fileHash.value : this.fileHash,
      fileType: data.fileType.present ? data.fileType.value : this.fileType,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentationFile(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileType: $fileType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    title,
    description,
    fileName,
    fileSize,
    fileHash,
    fileType,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentationFile &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.description == this.description &&
          other.fileName == this.fileName &&
          other.fileSize == this.fileSize &&
          other.fileHash == this.fileHash &&
          other.fileType == this.fileType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class DocumentationFilesCompanion extends UpdateCompanion<DocumentationFile> {
  final Value<Uuid> uuid;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> fileName;
  final Value<int> fileSize;
  final Value<String?> fileHash;
  final Value<String> fileType;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const DocumentationFilesCompanion({
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.fileType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentationFilesCompanion.insert({
    required Uuid uuid,
    required String title,
    this.description = const Value.absent(),
    required String fileName,
    required int fileSize,
    this.fileHash = const Value.absent(),
    required String fileType,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       title = Value(title),
       fileName = Value(fileName),
       fileSize = Value(fileSize),
       fileType = Value(fileType);
  static Insertable<DocumentationFile> custom({
    Expression<Uint8List>? uuid,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? fileName,
    Expression<int>? fileSize,
    Expression<String>? fileHash,
    Expression<String>? fileType,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (fileHash != null) 'file_hash': fileHash,
      if (fileType != null) 'file_type': fileType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentationFilesCompanion copyWith({
    Value<Uuid>? uuid,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? fileName,
    Value<int>? fileSize,
    Value<String?>? fileHash,
    Value<String>? fileType,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return DocumentationFilesCompanion(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileHash: fileHash ?? this.fileHash,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        DocumentationFiles.$converteruuid.toSql(uuid.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (fileHash.present) {
      map['file_hash'] = Variable<String>(fileHash.value);
    }
    if (fileType.present) {
      map['file_type'] = Variable<String>(fileType.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFiles.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid.value,
        ),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFiles.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentationFilesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileType: $fileType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DocumentationFilesToGeofeatures extends Table
    with
        TableInfo<
          DocumentationFilesToGeofeatures,
          DocumentationFilesToGeofeature
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DocumentationFilesToGeofeatures(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(DocumentationFilesToGeofeatures.$converteruuid);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List> geofeatureUuid =
      GeneratedColumn<Uint8List>(
        'geofeature_uuid',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: '',
      ).withConverter<Uuid?>(
        DocumentationFilesToGeofeatures.$convertergeofeatureUuidn,
      );
  static const VerificationMeta _geofeatureTypeMeta = const VerificationMeta(
    'geofeatureType',
  );
  late final GeneratedColumn<String> geofeatureType = GeneratedColumn<String>(
    'geofeature_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List>
  documentationFileUuid =
      GeneratedColumn<Uint8List>(
        'documentation_file_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL REFERENCES documentation_files(uuid)',
      ).withConverter<Uuid>(
        DocumentationFilesToGeofeatures.$converterdocumentationFileUuid,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid =
      GeneratedColumn<Uint8List>(
        'created_by_user_uuid',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES users(uuid)',
      ).withConverter<Uuid?>(
        DocumentationFilesToGeofeatures.$convertercreatedByUserUuidn,
      );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid =
      GeneratedColumn<Uint8List>(
        'last_modified_by_user_uuid',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES users(uuid)',
      ).withConverter<Uuid?>(
        DocumentationFilesToGeofeatures.$converterlastModifiedByUserUuidn,
      );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    geofeatureUuid,
    geofeatureType,
    documentationFileUuid,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documentation_files_to_geofeatures';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentationFilesToGeofeature> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('geofeature_type')) {
      context.handle(
        _geofeatureTypeMeta,
        geofeatureType.isAcceptableOrUnknown(
          data['geofeature_type']!,
          _geofeatureTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_geofeatureTypeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {geofeatureUuid, geofeatureType, documentationFileUuid},
  ];
  @override
  DocumentationFilesToGeofeature map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentationFilesToGeofeature(
      uuid: DocumentationFilesToGeofeatures.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      geofeatureUuid: DocumentationFilesToGeofeatures.$convertergeofeatureUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}geofeature_uuid'],
            ),
          ),
      geofeatureType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geofeature_type'],
      )!,
      documentationFileUuid: DocumentationFilesToGeofeatures
          .$converterdocumentationFileUuid
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}documentation_file_uuid'],
            )!,
          ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: DocumentationFilesToGeofeatures
          .$convertercreatedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}created_by_user_uuid'],
            ),
          ),
      lastModifiedByUserUuid: DocumentationFilesToGeofeatures
          .$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  DocumentationFilesToGeofeatures createAlias(String alias) {
    return DocumentationFilesToGeofeatures(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertergeofeatureUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertergeofeatureUuidn =
      NullAwareTypeConverter.wrap($convertergeofeatureUuid);
  static TypeConverter<Uuid, Uint8List> $converterdocumentationFileUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(geofeature_uuid, geofeature_type, documentation_file_uuid)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class DocumentationFilesToGeofeature extends DataClass
    implements Insertable<DocumentationFilesToGeofeature> {
  final Uuid uuid;
  final Uuid? geofeatureUuid;
  final String geofeatureType;
  final Uuid documentationFileUuid;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const DocumentationFilesToGeofeature({
    required this.uuid,
    this.geofeatureUuid,
    required this.geofeatureType,
    required this.documentationFileUuid,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(
        DocumentationFilesToGeofeatures.$converteruuid.toSql(uuid),
      );
    }
    if (!nullToAbsent || geofeatureUuid != null) {
      map['geofeature_uuid'] = Variable<Uint8List>(
        DocumentationFilesToGeofeatures.$convertergeofeatureUuidn.toSql(
          geofeatureUuid,
        ),
      );
    }
    map['geofeature_type'] = Variable<String>(geofeatureType);
    {
      map['documentation_file_uuid'] = Variable<Uint8List>(
        DocumentationFilesToGeofeatures.$converterdocumentationFileUuid.toSql(
          documentationFileUuid,
        ),
      );
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFilesToGeofeatures.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid,
        ),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFilesToGeofeatures.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  DocumentationFilesToGeofeaturesCompanion toCompanion(bool nullToAbsent) {
    return DocumentationFilesToGeofeaturesCompanion(
      uuid: Value(uuid),
      geofeatureUuid: geofeatureUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(geofeatureUuid),
      geofeatureType: Value(geofeatureType),
      documentationFileUuid: Value(documentationFileUuid),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory DocumentationFilesToGeofeature.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentationFilesToGeofeature(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      geofeatureUuid: serializer.fromJson<Uuid?>(json['geofeature_uuid']),
      geofeatureType: serializer.fromJson<String>(json['geofeature_type']),
      documentationFileUuid: serializer.fromJson<Uuid>(
        json['documentation_file_uuid'],
      ),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'geofeature_uuid': serializer.toJson<Uuid?>(geofeatureUuid),
      'geofeature_type': serializer.toJson<String>(geofeatureType),
      'documentation_file_uuid': serializer.toJson<Uuid>(documentationFileUuid),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  DocumentationFilesToGeofeature copyWith({
    Uuid? uuid,
    Value<Uuid?> geofeatureUuid = const Value.absent(),
    String? geofeatureType,
    Uuid? documentationFileUuid,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => DocumentationFilesToGeofeature(
    uuid: uuid ?? this.uuid,
    geofeatureUuid: geofeatureUuid.present
        ? geofeatureUuid.value
        : this.geofeatureUuid,
    geofeatureType: geofeatureType ?? this.geofeatureType,
    documentationFileUuid: documentationFileUuid ?? this.documentationFileUuid,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  DocumentationFilesToGeofeature copyWithCompanion(
    DocumentationFilesToGeofeaturesCompanion data,
  ) {
    return DocumentationFilesToGeofeature(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      geofeatureUuid: data.geofeatureUuid.present
          ? data.geofeatureUuid.value
          : this.geofeatureUuid,
      geofeatureType: data.geofeatureType.present
          ? data.geofeatureType.value
          : this.geofeatureType,
      documentationFileUuid: data.documentationFileUuid.present
          ? data.documentationFileUuid.value
          : this.documentationFileUuid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentationFilesToGeofeature(')
          ..write('uuid: $uuid, ')
          ..write('geofeatureUuid: $geofeatureUuid, ')
          ..write('geofeatureType: $geofeatureType, ')
          ..write('documentationFileUuid: $documentationFileUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    geofeatureUuid,
    geofeatureType,
    documentationFileUuid,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentationFilesToGeofeature &&
          other.uuid == this.uuid &&
          other.geofeatureUuid == this.geofeatureUuid &&
          other.geofeatureType == this.geofeatureType &&
          other.documentationFileUuid == this.documentationFileUuid &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class DocumentationFilesToGeofeaturesCompanion
    extends UpdateCompanion<DocumentationFilesToGeofeature> {
  final Value<Uuid> uuid;
  final Value<Uuid?> geofeatureUuid;
  final Value<String> geofeatureType;
  final Value<Uuid> documentationFileUuid;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const DocumentationFilesToGeofeaturesCompanion({
    this.uuid = const Value.absent(),
    this.geofeatureUuid = const Value.absent(),
    this.geofeatureType = const Value.absent(),
    this.documentationFileUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentationFilesToGeofeaturesCompanion.insert({
    required Uuid uuid,
    this.geofeatureUuid = const Value.absent(),
    required String geofeatureType,
    required Uuid documentationFileUuid,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       geofeatureType = Value(geofeatureType),
       documentationFileUuid = Value(documentationFileUuid);
  static Insertable<DocumentationFilesToGeofeature> custom({
    Expression<Uint8List>? uuid,
    Expression<Uint8List>? geofeatureUuid,
    Expression<String>? geofeatureType,
    Expression<Uint8List>? documentationFileUuid,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (geofeatureUuid != null) 'geofeature_uuid': geofeatureUuid,
      if (geofeatureType != null) 'geofeature_type': geofeatureType,
      if (documentationFileUuid != null)
        'documentation_file_uuid': documentationFileUuid,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentationFilesToGeofeaturesCompanion copyWith({
    Value<Uuid>? uuid,
    Value<Uuid?>? geofeatureUuid,
    Value<String>? geofeatureType,
    Value<Uuid>? documentationFileUuid,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return DocumentationFilesToGeofeaturesCompanion(
      uuid: uuid ?? this.uuid,
      geofeatureUuid: geofeatureUuid ?? this.geofeatureUuid,
      geofeatureType: geofeatureType ?? this.geofeatureType,
      documentationFileUuid:
          documentationFileUuid ?? this.documentationFileUuid,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        DocumentationFilesToGeofeatures.$converteruuid.toSql(uuid.value),
      );
    }
    if (geofeatureUuid.present) {
      map['geofeature_uuid'] = Variable<Uint8List>(
        DocumentationFilesToGeofeatures.$convertergeofeatureUuidn.toSql(
          geofeatureUuid.value,
        ),
      );
    }
    if (geofeatureType.present) {
      map['geofeature_type'] = Variable<String>(geofeatureType.value);
    }
    if (documentationFileUuid.present) {
      map['documentation_file_uuid'] = Variable<Uint8List>(
        DocumentationFilesToGeofeatures.$converterdocumentationFileUuid.toSql(
          documentationFileUuid.value,
        ),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFilesToGeofeatures.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid.value,
        ),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFilesToGeofeatures.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentationFilesToGeofeaturesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('geofeatureUuid: $geofeatureUuid, ')
          ..write('geofeatureType: $geofeatureType, ')
          ..write('documentationFileUuid: $documentationFileUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Configurations extends Table
    with TableInfo<Configurations, Configuration> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Configurations(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT NOT NULL',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    value,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'configurations';
  @override
  VerificationContext validateIntegrity(
    Insertable<Configuration> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Configuration map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Configuration(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
    );
  }

  @override
  Configurations createAlias(String alias) {
    return Configurations(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class Configuration extends DataClass implements Insertable<Configuration> {
  final int id;
  final String title;
  final String? value;
  final int? createdAt;
  final int? updatedAt;
  const Configuration({
    required this.id,
    required this.title,
    this.value,
    this.createdAt,
    this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    return map;
  }

  ConfigurationsCompanion toCompanion(bool nullToAbsent) {
    return ConfigurationsCompanion(
      id: Value(id),
      title: Value(title),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
    );
  }

  factory Configuration.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Configuration(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      value: serializer.fromJson<String?>(json['value']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'value': serializer.toJson<String?>(value),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
    };
  }

  Configuration copyWith({
    int? id,
    String? title,
    Value<String?> value = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
  }) => Configuration(
    id: id ?? this.id,
    title: title ?? this.title,
    value: value.present ? value.value : this.value,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
  );
  Configuration copyWithCompanion(ConfigurationsCompanion data) {
    return Configuration(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      value: data.value.present ? data.value.value : this.value,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Configuration(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, title, value, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Configuration &&
          other.id == this.id &&
          other.title == this.title &&
          other.value == this.value &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ConfigurationsCompanion extends UpdateCompanion<Configuration> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> value;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  const ConfigurationsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  ConfigurationsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.value = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Configuration> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? value,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (value != null) 'value': value,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  ConfigurationsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? value,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
  }) {
    return ConfigurationsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      value: value ?? this.value,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConfigurationsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('value: $value, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

class CaveTrips extends Table with TableInfo<CaveTrips, CaveTrip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CaveTrips(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(CaveTrips.$converteruuid);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> caveUuid =
      GeneratedColumn<Uint8List>(
        'cave_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL REFERENCES caves(uuid)',
      ).withConverter<Uuid>(CaveTrips.$convertercaveUuid);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _tripStartedAtMeta = const VerificationMeta(
    'tripStartedAt',
  );
  late final GeneratedColumn<int> tripStartedAt = GeneratedColumn<int>(
    'trip_started_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _tripEndedAtMeta = const VerificationMeta(
    'tripEndedAt',
  );
  late final GeneratedColumn<int> tripEndedAt = GeneratedColumn<int>(
    'trip_ended_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _logMeta = const VerificationMeta('log');
  late final GeneratedColumn<String> log = GeneratedColumn<String>(
    'log',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(CaveTrips.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(CaveTrips.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    caveUuid,
    title,
    description,
    tripStartedAt,
    tripEndedAt,
    log,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cave_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaveTrip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('trip_started_at')) {
      context.handle(
        _tripStartedAtMeta,
        tripStartedAt.isAcceptableOrUnknown(
          data['trip_started_at']!,
          _tripStartedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tripStartedAtMeta);
    }
    if (data.containsKey('trip_ended_at')) {
      context.handle(
        _tripEndedAtMeta,
        tripEndedAt.isAcceptableOrUnknown(
          data['trip_ended_at']!,
          _tripEndedAtMeta,
        ),
      );
    }
    if (data.containsKey('log')) {
      context.handle(
        _logMeta,
        log.isAcceptableOrUnknown(data['log']!, _logMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title, caveUuid},
  ];
  @override
  CaveTrip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaveTrip(
      uuid: CaveTrips.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      caveUuid: CaveTrips.$convertercaveUuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}cave_uuid'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      tripStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trip_started_at'],
      )!,
      tripEndedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}trip_ended_at'],
      ),
      log: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: CaveTrips.$convertercreatedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}created_by_user_uuid'],
        ),
      ),
      lastModifiedByUserUuid: CaveTrips.$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  CaveTrips createAlias(String alias) {
    return CaveTrips(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercaveUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(title, cave_uuid)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CaveTrip extends DataClass implements Insertable<CaveTrip> {
  final Uuid uuid;
  final Uuid caveUuid;
  final String title;
  final String? description;
  final int tripStartedAt;
  final int? tripEndedAt;
  final String? log;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const CaveTrip({
    required this.uuid,
    required this.caveUuid,
    required this.title,
    this.description,
    required this.tripStartedAt,
    this.tripEndedAt,
    this.log,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(CaveTrips.$converteruuid.toSql(uuid));
    }
    {
      map['cave_uuid'] = Variable<Uint8List>(
        CaveTrips.$convertercaveUuid.toSql(caveUuid),
      );
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['trip_started_at'] = Variable<int>(tripStartedAt);
    if (!nullToAbsent || tripEndedAt != null) {
      map['trip_ended_at'] = Variable<int>(tripEndedAt);
    }
    if (!nullToAbsent || log != null) {
      map['log'] = Variable<String>(log);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CaveTrips.$convertercreatedByUserUuidn.toSql(createdByUserUuid),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CaveTrips.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  CaveTripsCompanion toCompanion(bool nullToAbsent) {
    return CaveTripsCompanion(
      uuid: Value(uuid),
      caveUuid: Value(caveUuid),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      tripStartedAt: Value(tripStartedAt),
      tripEndedAt: tripEndedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(tripEndedAt),
      log: log == null && nullToAbsent ? const Value.absent() : Value(log),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory CaveTrip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaveTrip(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      caveUuid: serializer.fromJson<Uuid>(json['cave_uuid']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      tripStartedAt: serializer.fromJson<int>(json['trip_started_at']),
      tripEndedAt: serializer.fromJson<int?>(json['trip_ended_at']),
      log: serializer.fromJson<String?>(json['log']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'cave_uuid': serializer.toJson<Uuid>(caveUuid),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'trip_started_at': serializer.toJson<int>(tripStartedAt),
      'trip_ended_at': serializer.toJson<int?>(tripEndedAt),
      'log': serializer.toJson<String?>(log),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  CaveTrip copyWith({
    Uuid? uuid,
    Uuid? caveUuid,
    String? title,
    Value<String?> description = const Value.absent(),
    int? tripStartedAt,
    Value<int?> tripEndedAt = const Value.absent(),
    Value<String?> log = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => CaveTrip(
    uuid: uuid ?? this.uuid,
    caveUuid: caveUuid ?? this.caveUuid,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    tripStartedAt: tripStartedAt ?? this.tripStartedAt,
    tripEndedAt: tripEndedAt.present ? tripEndedAt.value : this.tripEndedAt,
    log: log.present ? log.value : this.log,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  CaveTrip copyWithCompanion(CaveTripsCompanion data) {
    return CaveTrip(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      caveUuid: data.caveUuid.present ? data.caveUuid.value : this.caveUuid,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      tripStartedAt: data.tripStartedAt.present
          ? data.tripStartedAt.value
          : this.tripStartedAt,
      tripEndedAt: data.tripEndedAt.present
          ? data.tripEndedAt.value
          : this.tripEndedAt,
      log: data.log.present ? data.log.value : this.log,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaveTrip(')
          ..write('uuid: $uuid, ')
          ..write('caveUuid: $caveUuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('tripStartedAt: $tripStartedAt, ')
          ..write('tripEndedAt: $tripEndedAt, ')
          ..write('log: $log, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    caveUuid,
    title,
    description,
    tripStartedAt,
    tripEndedAt,
    log,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaveTrip &&
          other.uuid == this.uuid &&
          other.caveUuid == this.caveUuid &&
          other.title == this.title &&
          other.description == this.description &&
          other.tripStartedAt == this.tripStartedAt &&
          other.tripEndedAt == this.tripEndedAt &&
          other.log == this.log &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class CaveTripsCompanion extends UpdateCompanion<CaveTrip> {
  final Value<Uuid> uuid;
  final Value<Uuid> caveUuid;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> tripStartedAt;
  final Value<int?> tripEndedAt;
  final Value<String?> log;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const CaveTripsCompanion({
    this.uuid = const Value.absent(),
    this.caveUuid = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.tripStartedAt = const Value.absent(),
    this.tripEndedAt = const Value.absent(),
    this.log = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaveTripsCompanion.insert({
    required Uuid uuid,
    required Uuid caveUuid,
    required String title,
    this.description = const Value.absent(),
    required int tripStartedAt,
    this.tripEndedAt = const Value.absent(),
    this.log = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       caveUuid = Value(caveUuid),
       title = Value(title),
       tripStartedAt = Value(tripStartedAt);
  static Insertable<CaveTrip> custom({
    Expression<Uint8List>? uuid,
    Expression<Uint8List>? caveUuid,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? tripStartedAt,
    Expression<int>? tripEndedAt,
    Expression<String>? log,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (caveUuid != null) 'cave_uuid': caveUuid,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (tripStartedAt != null) 'trip_started_at': tripStartedAt,
      if (tripEndedAt != null) 'trip_ended_at': tripEndedAt,
      if (log != null) 'log': log,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaveTripsCompanion copyWith({
    Value<Uuid>? uuid,
    Value<Uuid>? caveUuid,
    Value<String>? title,
    Value<String?>? description,
    Value<int>? tripStartedAt,
    Value<int?>? tripEndedAt,
    Value<String?>? log,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return CaveTripsCompanion(
      uuid: uuid ?? this.uuid,
      caveUuid: caveUuid ?? this.caveUuid,
      title: title ?? this.title,
      description: description ?? this.description,
      tripStartedAt: tripStartedAt ?? this.tripStartedAt,
      tripEndedAt: tripEndedAt ?? this.tripEndedAt,
      log: log ?? this.log,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        CaveTrips.$converteruuid.toSql(uuid.value),
      );
    }
    if (caveUuid.present) {
      map['cave_uuid'] = Variable<Uint8List>(
        CaveTrips.$convertercaveUuid.toSql(caveUuid.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (tripStartedAt.present) {
      map['trip_started_at'] = Variable<int>(tripStartedAt.value);
    }
    if (tripEndedAt.present) {
      map['trip_ended_at'] = Variable<int>(tripEndedAt.value);
    }
    if (log.present) {
      map['log'] = Variable<String>(log.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CaveTrips.$convertercreatedByUserUuidn.toSql(createdByUserUuid.value),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CaveTrips.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaveTripsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('caveUuid: $caveUuid, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('tripStartedAt: $tripStartedAt, ')
          ..write('tripEndedAt: $tripEndedAt, ')
          ..write('log: $log, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class CaveTripPoints extends Table
    with TableInfo<CaveTripPoints, CaveTripPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CaveTripPoints(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(CaveTripPoints.$converteruuid);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> caveTripUuid =
      GeneratedColumn<Uint8List>(
        'cave_trip_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL REFERENCES cave_trips(uuid)',
      ).withConverter<Uuid>(CaveTripPoints.$convertercaveTripUuid);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List> cavePlaceUuid =
      GeneratedColumn<Uint8List>(
        'cave_place_uuid',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES cave_places(uuid)',
      ).withConverter<Uuid?>(CaveTripPoints.$convertercavePlaceUuidn);
  static const VerificationMeta _scannedAtMeta = const VerificationMeta(
    'scannedAt',
  );
  late final GeneratedColumn<int> scannedAt = GeneratedColumn<int>(
    'scanned_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(CaveTripPoints.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(CaveTripPoints.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    caveTripUuid,
    cavePlaceUuid,
    scannedAt,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cave_trip_points';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaveTripPoint> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('scanned_at')) {
      context.handle(
        _scannedAtMeta,
        scannedAt.isAcceptableOrUnknown(data['scanned_at']!, _scannedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_scannedAtMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {caveTripUuid, cavePlaceUuid, scannedAt},
  ];
  @override
  CaveTripPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaveTripPoint(
      uuid: CaveTripPoints.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      caveTripUuid: CaveTripPoints.$convertercaveTripUuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}cave_trip_uuid'],
        )!,
      ),
      cavePlaceUuid: CaveTripPoints.$convertercavePlaceUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}cave_place_uuid'],
        ),
      ),
      scannedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scanned_at'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: CaveTripPoints.$convertercreatedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}created_by_user_uuid'],
        ),
      ),
      lastModifiedByUserUuid: CaveTripPoints.$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  CaveTripPoints createAlias(String alias) {
    return CaveTripPoints(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercaveTripUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercavePlaceUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercavePlaceUuidn =
      NullAwareTypeConverter.wrap($convertercavePlaceUuid);
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(cave_trip_uuid, cave_place_uuid, scanned_at)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CaveTripPoint extends DataClass implements Insertable<CaveTripPoint> {
  final Uuid uuid;
  final Uuid caveTripUuid;
  final Uuid? cavePlaceUuid;
  final int scannedAt;
  final String? notes;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const CaveTripPoint({
    required this.uuid,
    required this.caveTripUuid,
    this.cavePlaceUuid,
    required this.scannedAt,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(
        CaveTripPoints.$converteruuid.toSql(uuid),
      );
    }
    {
      map['cave_trip_uuid'] = Variable<Uint8List>(
        CaveTripPoints.$convertercaveTripUuid.toSql(caveTripUuid),
      );
    }
    if (!nullToAbsent || cavePlaceUuid != null) {
      map['cave_place_uuid'] = Variable<Uint8List>(
        CaveTripPoints.$convertercavePlaceUuidn.toSql(cavePlaceUuid),
      );
    }
    map['scanned_at'] = Variable<int>(scannedAt);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CaveTripPoints.$convertercreatedByUserUuidn.toSql(createdByUserUuid),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CaveTripPoints.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  CaveTripPointsCompanion toCompanion(bool nullToAbsent) {
    return CaveTripPointsCompanion(
      uuid: Value(uuid),
      caveTripUuid: Value(caveTripUuid),
      cavePlaceUuid: cavePlaceUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(cavePlaceUuid),
      scannedAt: Value(scannedAt),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory CaveTripPoint.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaveTripPoint(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      caveTripUuid: serializer.fromJson<Uuid>(json['cave_trip_uuid']),
      cavePlaceUuid: serializer.fromJson<Uuid?>(json['cave_place_uuid']),
      scannedAt: serializer.fromJson<int>(json['scanned_at']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'cave_trip_uuid': serializer.toJson<Uuid>(caveTripUuid),
      'cave_place_uuid': serializer.toJson<Uuid?>(cavePlaceUuid),
      'scanned_at': serializer.toJson<int>(scannedAt),
      'notes': serializer.toJson<String?>(notes),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  CaveTripPoint copyWith({
    Uuid? uuid,
    Uuid? caveTripUuid,
    Value<Uuid?> cavePlaceUuid = const Value.absent(),
    int? scannedAt,
    Value<String?> notes = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => CaveTripPoint(
    uuid: uuid ?? this.uuid,
    caveTripUuid: caveTripUuid ?? this.caveTripUuid,
    cavePlaceUuid: cavePlaceUuid.present
        ? cavePlaceUuid.value
        : this.cavePlaceUuid,
    scannedAt: scannedAt ?? this.scannedAt,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  CaveTripPoint copyWithCompanion(CaveTripPointsCompanion data) {
    return CaveTripPoint(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      caveTripUuid: data.caveTripUuid.present
          ? data.caveTripUuid.value
          : this.caveTripUuid,
      cavePlaceUuid: data.cavePlaceUuid.present
          ? data.cavePlaceUuid.value
          : this.cavePlaceUuid,
      scannedAt: data.scannedAt.present ? data.scannedAt.value : this.scannedAt,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaveTripPoint(')
          ..write('uuid: $uuid, ')
          ..write('caveTripUuid: $caveTripUuid, ')
          ..write('cavePlaceUuid: $cavePlaceUuid, ')
          ..write('scannedAt: $scannedAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    caveTripUuid,
    cavePlaceUuid,
    scannedAt,
    notes,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaveTripPoint &&
          other.uuid == this.uuid &&
          other.caveTripUuid == this.caveTripUuid &&
          other.cavePlaceUuid == this.cavePlaceUuid &&
          other.scannedAt == this.scannedAt &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class CaveTripPointsCompanion extends UpdateCompanion<CaveTripPoint> {
  final Value<Uuid> uuid;
  final Value<Uuid> caveTripUuid;
  final Value<Uuid?> cavePlaceUuid;
  final Value<int> scannedAt;
  final Value<String?> notes;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const CaveTripPointsCompanion({
    this.uuid = const Value.absent(),
    this.caveTripUuid = const Value.absent(),
    this.cavePlaceUuid = const Value.absent(),
    this.scannedAt = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CaveTripPointsCompanion.insert({
    required Uuid uuid,
    required Uuid caveTripUuid,
    this.cavePlaceUuid = const Value.absent(),
    required int scannedAt,
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       caveTripUuid = Value(caveTripUuid),
       scannedAt = Value(scannedAt);
  static Insertable<CaveTripPoint> custom({
    Expression<Uint8List>? uuid,
    Expression<Uint8List>? caveTripUuid,
    Expression<Uint8List>? cavePlaceUuid,
    Expression<int>? scannedAt,
    Expression<String>? notes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (caveTripUuid != null) 'cave_trip_uuid': caveTripUuid,
      if (cavePlaceUuid != null) 'cave_place_uuid': cavePlaceUuid,
      if (scannedAt != null) 'scanned_at': scannedAt,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CaveTripPointsCompanion copyWith({
    Value<Uuid>? uuid,
    Value<Uuid>? caveTripUuid,
    Value<Uuid?>? cavePlaceUuid,
    Value<int>? scannedAt,
    Value<String?>? notes,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return CaveTripPointsCompanion(
      uuid: uuid ?? this.uuid,
      caveTripUuid: caveTripUuid ?? this.caveTripUuid,
      cavePlaceUuid: cavePlaceUuid ?? this.cavePlaceUuid,
      scannedAt: scannedAt ?? this.scannedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        CaveTripPoints.$converteruuid.toSql(uuid.value),
      );
    }
    if (caveTripUuid.present) {
      map['cave_trip_uuid'] = Variable<Uint8List>(
        CaveTripPoints.$convertercaveTripUuid.toSql(caveTripUuid.value),
      );
    }
    if (cavePlaceUuid.present) {
      map['cave_place_uuid'] = Variable<Uint8List>(
        CaveTripPoints.$convertercavePlaceUuidn.toSql(cavePlaceUuid.value),
      );
    }
    if (scannedAt.present) {
      map['scanned_at'] = Variable<int>(scannedAt.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        CaveTripPoints.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid.value,
        ),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        CaveTripPoints.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaveTripPointsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('caveTripUuid: $caveTripUuid, ')
          ..write('cavePlaceUuid: $cavePlaceUuid, ')
          ..write('scannedAt: $scannedAt, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DocumentationFilesToCaveTrips extends Table
    with
        TableInfo<DocumentationFilesToCaveTrips, DocumentationFilesToCaveTrip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  DocumentationFilesToCaveTrips(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(DocumentationFilesToCaveTrips.$converteruuid);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List>
  documentationFileUuid =
      GeneratedColumn<Uint8List>(
        'documentation_file_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL REFERENCES documentation_files(uuid)',
      ).withConverter<Uuid>(
        DocumentationFilesToCaveTrips.$converterdocumentationFileUuid,
      );
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> caveTripUuid =
      GeneratedColumn<Uint8List>(
        'cave_trip_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL REFERENCES cave_trips(uuid)',
      ).withConverter<Uuid>(
        DocumentationFilesToCaveTrips.$convertercaveTripUuid,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid =
      GeneratedColumn<Uint8List>(
        'created_by_user_uuid',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES users(uuid)',
      ).withConverter<Uuid?>(
        DocumentationFilesToCaveTrips.$convertercreatedByUserUuidn,
      );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid =
      GeneratedColumn<Uint8List>(
        'last_modified_by_user_uuid',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: 'REFERENCES users(uuid)',
      ).withConverter<Uuid?>(
        DocumentationFilesToCaveTrips.$converterlastModifiedByUserUuidn,
      );
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    documentationFileUuid,
    caveTripUuid,
    createdAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'documentation_files_to_cave_trips';
  @override
  VerificationContext validateIntegrity(
    Insertable<DocumentationFilesToCaveTrip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {documentationFileUuid, caveTripUuid},
  ];
  @override
  DocumentationFilesToCaveTrip map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentationFilesToCaveTrip(
      uuid: DocumentationFilesToCaveTrips.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      documentationFileUuid: DocumentationFilesToCaveTrips
          .$converterdocumentationFileUuid
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}documentation_file_uuid'],
            )!,
          ),
      caveTripUuid: DocumentationFilesToCaveTrips.$convertercaveTripUuid
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}cave_trip_uuid'],
            )!,
          ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: DocumentationFilesToCaveTrips
          .$convertercreatedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}created_by_user_uuid'],
            ),
          ),
      lastModifiedByUserUuid: DocumentationFilesToCaveTrips
          .$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  DocumentationFilesToCaveTrips createAlias(String alias) {
    return DocumentationFilesToCaveTrips(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $converterdocumentationFileUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercaveTripUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(documentation_file_uuid, cave_trip_uuid)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class DocumentationFilesToCaveTrip extends DataClass
    implements Insertable<DocumentationFilesToCaveTrip> {
  final Uuid uuid;
  final Uuid documentationFileUuid;
  final Uuid caveTripUuid;
  final int? createdAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const DocumentationFilesToCaveTrip({
    required this.uuid,
    required this.documentationFileUuid,
    required this.caveTripUuid,
    this.createdAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(
        DocumentationFilesToCaveTrips.$converteruuid.toSql(uuid),
      );
    }
    {
      map['documentation_file_uuid'] = Variable<Uint8List>(
        DocumentationFilesToCaveTrips.$converterdocumentationFileUuid.toSql(
          documentationFileUuid,
        ),
      );
    }
    {
      map['cave_trip_uuid'] = Variable<Uint8List>(
        DocumentationFilesToCaveTrips.$convertercaveTripUuid.toSql(
          caveTripUuid,
        ),
      );
    }
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFilesToCaveTrips.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid,
        ),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFilesToCaveTrips.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  DocumentationFilesToCaveTripsCompanion toCompanion(bool nullToAbsent) {
    return DocumentationFilesToCaveTripsCompanion(
      uuid: Value(uuid),
      documentationFileUuid: Value(documentationFileUuid),
      caveTripUuid: Value(caveTripUuid),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory DocumentationFilesToCaveTrip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentationFilesToCaveTrip(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      documentationFileUuid: serializer.fromJson<Uuid>(
        json['documentation_file_uuid'],
      ),
      caveTripUuid: serializer.fromJson<Uuid>(json['cave_trip_uuid']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'documentation_file_uuid': serializer.toJson<Uuid>(documentationFileUuid),
      'cave_trip_uuid': serializer.toJson<Uuid>(caveTripUuid),
      'created_at': serializer.toJson<int?>(createdAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  DocumentationFilesToCaveTrip copyWith({
    Uuid? uuid,
    Uuid? documentationFileUuid,
    Uuid? caveTripUuid,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => DocumentationFilesToCaveTrip(
    uuid: uuid ?? this.uuid,
    documentationFileUuid: documentationFileUuid ?? this.documentationFileUuid,
    caveTripUuid: caveTripUuid ?? this.caveTripUuid,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  DocumentationFilesToCaveTrip copyWithCompanion(
    DocumentationFilesToCaveTripsCompanion data,
  ) {
    return DocumentationFilesToCaveTrip(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      documentationFileUuid: data.documentationFileUuid.present
          ? data.documentationFileUuid.value
          : this.documentationFileUuid,
      caveTripUuid: data.caveTripUuid.present
          ? data.caveTripUuid.value
          : this.caveTripUuid,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentationFilesToCaveTrip(')
          ..write('uuid: $uuid, ')
          ..write('documentationFileUuid: $documentationFileUuid, ')
          ..write('caveTripUuid: $caveTripUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    documentationFileUuid,
    caveTripUuid,
    createdAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentationFilesToCaveTrip &&
          other.uuid == this.uuid &&
          other.documentationFileUuid == this.documentationFileUuid &&
          other.caveTripUuid == this.caveTripUuid &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class DocumentationFilesToCaveTripsCompanion
    extends UpdateCompanion<DocumentationFilesToCaveTrip> {
  final Value<Uuid> uuid;
  final Value<Uuid> documentationFileUuid;
  final Value<Uuid> caveTripUuid;
  final Value<int?> createdAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const DocumentationFilesToCaveTripsCompanion({
    this.uuid = const Value.absent(),
    this.documentationFileUuid = const Value.absent(),
    this.caveTripUuid = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DocumentationFilesToCaveTripsCompanion.insert({
    required Uuid uuid,
    required Uuid documentationFileUuid,
    required Uuid caveTripUuid,
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       documentationFileUuid = Value(documentationFileUuid),
       caveTripUuid = Value(caveTripUuid);
  static Insertable<DocumentationFilesToCaveTrip> custom({
    Expression<Uint8List>? uuid,
    Expression<Uint8List>? documentationFileUuid,
    Expression<Uint8List>? caveTripUuid,
    Expression<int>? createdAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (documentationFileUuid != null)
        'documentation_file_uuid': documentationFileUuid,
      if (caveTripUuid != null) 'cave_trip_uuid': caveTripUuid,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DocumentationFilesToCaveTripsCompanion copyWith({
    Value<Uuid>? uuid,
    Value<Uuid>? documentationFileUuid,
    Value<Uuid>? caveTripUuid,
    Value<int?>? createdAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return DocumentationFilesToCaveTripsCompanion(
      uuid: uuid ?? this.uuid,
      documentationFileUuid:
          documentationFileUuid ?? this.documentationFileUuid,
      caveTripUuid: caveTripUuid ?? this.caveTripUuid,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        DocumentationFilesToCaveTrips.$converteruuid.toSql(uuid.value),
      );
    }
    if (documentationFileUuid.present) {
      map['documentation_file_uuid'] = Variable<Uint8List>(
        DocumentationFilesToCaveTrips.$converterdocumentationFileUuid.toSql(
          documentationFileUuid.value,
        ),
      );
    }
    if (caveTripUuid.present) {
      map['cave_trip_uuid'] = Variable<Uint8List>(
        DocumentationFilesToCaveTrips.$convertercaveTripUuid.toSql(
          caveTripUuid.value,
        ),
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFilesToCaveTrips.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid.value,
        ),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        DocumentationFilesToCaveTrips.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentationFilesToCaveTripsCompanion(')
          ..write('uuid: $uuid, ')
          ..write('documentationFileUuid: $documentationFileUuid, ')
          ..write('caveTripUuid: $caveTripUuid, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class TripReportTemplates extends Table
    with TableInfo<TripReportTemplates, TripReportTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  TripReportTemplates(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(TripReportTemplates.$converteruuid);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _fileSizeMeta = const VerificationMeta(
    'fileSize',
  );
  late final GeneratedColumn<int> fileSize = GeneratedColumn<int>(
    'file_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  createdByUserUuid = GeneratedColumn<Uint8List>(
    'created_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(TripReportTemplates.$convertercreatedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  lastModifiedByUserUuid = GeneratedColumn<Uint8List>(
    'last_modified_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(TripReportTemplates.$converterlastModifiedByUserUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    title,
    fileName,
    fileSize,
    format,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'trip_report_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TripReportTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_size')) {
      context.handle(
        _fileSizeMeta,
        fileSize.isAcceptableOrUnknown(data['file_size']!, _fileSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_fileSizeMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title},
  ];
  @override
  TripReportTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TripReportTemplate(
      uuid: TripReportTemplates.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      fileSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
      createdByUserUuid: TripReportTemplates.$convertercreatedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}created_by_user_uuid'],
            ),
          ),
      lastModifiedByUserUuid: TripReportTemplates
          .$converterlastModifiedByUserUuidn
          .fromSql(
            attachedDatabase.typeMapping.read(
              DriftSqlType.blob,
              data['${effectivePrefix}last_modified_by_user_uuid'],
            ),
          ),
    );
  }

  @override
  TripReportTemplates createAlias(String alias) {
    return TripReportTemplates(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $convertercreatedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $convertercreatedByUserUuidn =
      NullAwareTypeConverter.wrap($convertercreatedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterlastModifiedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterlastModifiedByUserUuidn =
      NullAwareTypeConverter.wrap($converterlastModifiedByUserUuid);
  @override
  List<String> get customConstraints => const [
    'UNIQUE(title)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class TripReportTemplate extends DataClass
    implements Insertable<TripReportTemplate> {
  final Uuid uuid;
  final String title;
  final String fileName;
  final int fileSize;
  final String format;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  final Uuid? createdByUserUuid;
  final Uuid? lastModifiedByUserUuid;
  const TripReportTemplate({
    required this.uuid,
    required this.title,
    required this.fileName,
    required this.fileSize,
    required this.format,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.createdByUserUuid,
    this.lastModifiedByUserUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(
        TripReportTemplates.$converteruuid.toSql(uuid),
      );
    }
    map['title'] = Variable<String>(title);
    map['file_name'] = Variable<String>(fileName);
    map['file_size'] = Variable<int>(fileSize);
    map['format'] = Variable<String>(format);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    if (!nullToAbsent || createdByUserUuid != null) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        TripReportTemplates.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid,
        ),
      );
    }
    if (!nullToAbsent || lastModifiedByUserUuid != null) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        TripReportTemplates.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid,
        ),
      );
    }
    return map;
  }

  TripReportTemplatesCompanion toCompanion(bool nullToAbsent) {
    return TripReportTemplatesCompanion(
      uuid: Value(uuid),
      title: Value(title),
      fileName: Value(fileName),
      fileSize: Value(fileSize),
      format: Value(format),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      createdByUserUuid: createdByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(createdByUserUuid),
      lastModifiedByUserUuid: lastModifiedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(lastModifiedByUserUuid),
    );
  }

  factory TripReportTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TripReportTemplate(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      title: serializer.fromJson<String>(json['title']),
      fileName: serializer.fromJson<String>(json['file_name']),
      fileSize: serializer.fromJson<int>(json['file_size']),
      format: serializer.fromJson<String>(json['format']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
      createdByUserUuid: serializer.fromJson<Uuid?>(
        json['created_by_user_uuid'],
      ),
      lastModifiedByUserUuid: serializer.fromJson<Uuid?>(
        json['last_modified_by_user_uuid'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'title': serializer.toJson<String>(title),
      'file_name': serializer.toJson<String>(fileName),
      'file_size': serializer.toJson<int>(fileSize),
      'format': serializer.toJson<String>(format),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
      'created_by_user_uuid': serializer.toJson<Uuid?>(createdByUserUuid),
      'last_modified_by_user_uuid': serializer.toJson<Uuid?>(
        lastModifiedByUserUuid,
      ),
    };
  }

  TripReportTemplate copyWith({
    Uuid? uuid,
    String? title,
    String? fileName,
    int? fileSize,
    String? format,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
    Value<Uuid?> createdByUserUuid = const Value.absent(),
    Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
  }) => TripReportTemplate(
    uuid: uuid ?? this.uuid,
    title: title ?? this.title,
    fileName: fileName ?? this.fileName,
    fileSize: fileSize ?? this.fileSize,
    format: format ?? this.format,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    createdByUserUuid: createdByUserUuid.present
        ? createdByUserUuid.value
        : this.createdByUserUuid,
    lastModifiedByUserUuid: lastModifiedByUserUuid.present
        ? lastModifiedByUserUuid.value
        : this.lastModifiedByUserUuid,
  );
  TripReportTemplate copyWithCompanion(TripReportTemplatesCompanion data) {
    return TripReportTemplate(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      title: data.title.present ? data.title.value : this.title,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileSize: data.fileSize.present ? data.fileSize.value : this.fileSize,
      format: data.format.present ? data.format.value : this.format,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      createdByUserUuid: data.createdByUserUuid.present
          ? data.createdByUserUuid.value
          : this.createdByUserUuid,
      lastModifiedByUserUuid: data.lastModifiedByUserUuid.present
          ? data.lastModifiedByUserUuid.value
          : this.lastModifiedByUserUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TripReportTemplate(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('format: $format, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    title,
    fileName,
    fileSize,
    format,
    createdAt,
    updatedAt,
    deletedAt,
    createdByUserUuid,
    lastModifiedByUserUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TripReportTemplate &&
          other.uuid == this.uuid &&
          other.title == this.title &&
          other.fileName == this.fileName &&
          other.fileSize == this.fileSize &&
          other.format == this.format &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.createdByUserUuid == this.createdByUserUuid &&
          other.lastModifiedByUserUuid == this.lastModifiedByUserUuid);
}

class TripReportTemplatesCompanion extends UpdateCompanion<TripReportTemplate> {
  final Value<Uuid> uuid;
  final Value<String> title;
  final Value<String> fileName;
  final Value<int> fileSize;
  final Value<String> format;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  final Value<Uuid?> createdByUserUuid;
  final Value<Uuid?> lastModifiedByUserUuid;
  final Value<int> rowid;
  const TripReportTemplatesCompanion({
    this.uuid = const Value.absent(),
    this.title = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.format = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TripReportTemplatesCompanion.insert({
    required Uuid uuid,
    required String title,
    required String fileName,
    required int fileSize,
    required String format,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.createdByUserUuid = const Value.absent(),
    this.lastModifiedByUserUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       title = Value(title),
       fileName = Value(fileName),
       fileSize = Value(fileSize),
       format = Value(format);
  static Insertable<TripReportTemplate> custom({
    Expression<Uint8List>? uuid,
    Expression<String>? title,
    Expression<String>? fileName,
    Expression<int>? fileSize,
    Expression<String>? format,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
    Expression<Uint8List>? createdByUserUuid,
    Expression<Uint8List>? lastModifiedByUserUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (title != null) 'title': title,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (format != null) 'format': format,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (createdByUserUuid != null) 'created_by_user_uuid': createdByUserUuid,
      if (lastModifiedByUserUuid != null)
        'last_modified_by_user_uuid': lastModifiedByUserUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TripReportTemplatesCompanion copyWith({
    Value<Uuid>? uuid,
    Value<String>? title,
    Value<String>? fileName,
    Value<int>? fileSize,
    Value<String>? format,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
    Value<Uuid?>? createdByUserUuid,
    Value<Uuid?>? lastModifiedByUserUuid,
    Value<int>? rowid,
  }) {
    return TripReportTemplatesCompanion(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      format: format ?? this.format,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      createdByUserUuid: createdByUserUuid ?? this.createdByUserUuid,
      lastModifiedByUserUuid:
          lastModifiedByUserUuid ?? this.lastModifiedByUserUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        TripReportTemplates.$converteruuid.toSql(uuid.value),
      );
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileSize.present) {
      map['file_size'] = Variable<int>(fileSize.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (createdByUserUuid.present) {
      map['created_by_user_uuid'] = Variable<Uint8List>(
        TripReportTemplates.$convertercreatedByUserUuidn.toSql(
          createdByUserUuid.value,
        ),
      );
    }
    if (lastModifiedByUserUuid.present) {
      map['last_modified_by_user_uuid'] = Variable<Uint8List>(
        TripReportTemplates.$converterlastModifiedByUserUuidn.toSql(
          lastModifiedByUserUuid.value,
        ),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TripReportTemplatesCompanion(')
          ..write('uuid: $uuid, ')
          ..write('title: $title, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('format: $format, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('createdByUserUuid: $createdByUserUuid, ')
          ..write('lastModifiedByUserUuid: $lastModifiedByUserUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ChangeLog extends Table with TableInfo<ChangeLog, ChangeLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ChangeLog(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> uuid =
      GeneratedColumn<Uint8List>(
        'uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'PRIMARY KEY NOT NULL',
      ).withConverter<Uuid>(ChangeLog.$converteruuid);
  static const VerificationMeta _entityTableMeta = const VerificationMeta(
    'entityTable',
  );
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
    'entity_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> entityUuid =
      GeneratedColumn<Uint8List>(
        'entity_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints: 'NOT NULL',
      ).withConverter<Uuid>(ChangeLog.$converterentityUuid);
  static const VerificationMeta _changeTypeMeta = const VerificationMeta(
    'changeType',
  );
  late final GeneratedColumn<int> changeType = GeneratedColumn<int>(
    'change_type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  late final GeneratedColumn<int> changedAt = GeneratedColumn<int>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  changedByUserUuid = GeneratedColumn<Uint8List>(
    'changed_by_user_uuid',
    aliasedName,
    true,
    type: DriftSqlType.blob,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES users(uuid)',
  ).withConverter<Uuid?>(ChangeLog.$converterchangedByUserUuidn);
  late final GeneratedColumnWithTypeConverter<Uuid?, Uint8List> deviceUuid =
      GeneratedColumn<Uint8List>(
        'device_uuid',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: '',
      ).withConverter<Uuid?>(ChangeLog.$converterdeviceUuidn);
  @override
  List<GeneratedColumn> get $columns => [
    uuid,
    entityTable,
    entityUuid,
    changeType,
    changedAt,
    changedByUserUuid,
    deviceUuid,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'change_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChangeLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_table')) {
      context.handle(
        _entityTableMeta,
        entityTable.isAcceptableOrUnknown(
          data['entity_table']!,
          _entityTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('change_type')) {
      context.handle(
        _changeTypeMeta,
        changeType.isAcceptableOrUnknown(data['change_type']!, _changeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_changeTypeMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_changedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  ChangeLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChangeLogData(
      uuid: ChangeLog.$converteruuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}uuid'],
        )!,
      ),
      entityTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_table'],
      )!,
      entityUuid: ChangeLog.$converterentityUuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}entity_uuid'],
        )!,
      ),
      changeType: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}change_type'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}changed_at'],
      )!,
      changedByUserUuid: ChangeLog.$converterchangedByUserUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}changed_by_user_uuid'],
        ),
      ),
      deviceUuid: ChangeLog.$converterdeviceUuidn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}device_uuid'],
        ),
      ),
    );
  }

  @override
  ChangeLog createAlias(String alias) {
    return ChangeLog(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converteruuid = const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $converterentityUuid =
      const UuidConverter();
  static TypeConverter<Uuid, Uint8List> $converterchangedByUserUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterchangedByUserUuidn =
      NullAwareTypeConverter.wrap($converterchangedByUserUuid);
  static TypeConverter<Uuid, Uint8List> $converterdeviceUuid =
      const UuidConverter();
  static TypeConverter<Uuid?, Uint8List?> $converterdeviceUuidn =
      NullAwareTypeConverter.wrap($converterdeviceUuid);
  @override
  bool get dontWriteConstraints => true;
}

class ChangeLogData extends DataClass implements Insertable<ChangeLogData> {
  final Uuid uuid;
  final String entityTable;
  final Uuid entityUuid;
  final int changeType;
  final int changedAt;
  final Uuid? changedByUserUuid;
  final Uuid? deviceUuid;
  const ChangeLogData({
    required this.uuid,
    required this.entityTable,
    required this.entityUuid,
    required this.changeType,
    required this.changedAt,
    this.changedByUserUuid,
    this.deviceUuid,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['uuid'] = Variable<Uint8List>(ChangeLog.$converteruuid.toSql(uuid));
    }
    map['entity_table'] = Variable<String>(entityTable);
    {
      map['entity_uuid'] = Variable<Uint8List>(
        ChangeLog.$converterentityUuid.toSql(entityUuid),
      );
    }
    map['change_type'] = Variable<int>(changeType);
    map['changed_at'] = Variable<int>(changedAt);
    if (!nullToAbsent || changedByUserUuid != null) {
      map['changed_by_user_uuid'] = Variable<Uint8List>(
        ChangeLog.$converterchangedByUserUuidn.toSql(changedByUserUuid),
      );
    }
    if (!nullToAbsent || deviceUuid != null) {
      map['device_uuid'] = Variable<Uint8List>(
        ChangeLog.$converterdeviceUuidn.toSql(deviceUuid),
      );
    }
    return map;
  }

  ChangeLogCompanion toCompanion(bool nullToAbsent) {
    return ChangeLogCompanion(
      uuid: Value(uuid),
      entityTable: Value(entityTable),
      entityUuid: Value(entityUuid),
      changeType: Value(changeType),
      changedAt: Value(changedAt),
      changedByUserUuid: changedByUserUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(changedByUserUuid),
      deviceUuid: deviceUuid == null && nullToAbsent
          ? const Value.absent()
          : Value(deviceUuid),
    );
  }

  factory ChangeLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChangeLogData(
      uuid: serializer.fromJson<Uuid>(json['uuid']),
      entityTable: serializer.fromJson<String>(json['entity_table']),
      entityUuid: serializer.fromJson<Uuid>(json['entity_uuid']),
      changeType: serializer.fromJson<int>(json['change_type']),
      changedAt: serializer.fromJson<int>(json['changed_at']),
      changedByUserUuid: serializer.fromJson<Uuid?>(
        json['changed_by_user_uuid'],
      ),
      deviceUuid: serializer.fromJson<Uuid?>(json['device_uuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uuid': serializer.toJson<Uuid>(uuid),
      'entity_table': serializer.toJson<String>(entityTable),
      'entity_uuid': serializer.toJson<Uuid>(entityUuid),
      'change_type': serializer.toJson<int>(changeType),
      'changed_at': serializer.toJson<int>(changedAt),
      'changed_by_user_uuid': serializer.toJson<Uuid?>(changedByUserUuid),
      'device_uuid': serializer.toJson<Uuid?>(deviceUuid),
    };
  }

  ChangeLogData copyWith({
    Uuid? uuid,
    String? entityTable,
    Uuid? entityUuid,
    int? changeType,
    int? changedAt,
    Value<Uuid?> changedByUserUuid = const Value.absent(),
    Value<Uuid?> deviceUuid = const Value.absent(),
  }) => ChangeLogData(
    uuid: uuid ?? this.uuid,
    entityTable: entityTable ?? this.entityTable,
    entityUuid: entityUuid ?? this.entityUuid,
    changeType: changeType ?? this.changeType,
    changedAt: changedAt ?? this.changedAt,
    changedByUserUuid: changedByUserUuid.present
        ? changedByUserUuid.value
        : this.changedByUserUuid,
    deviceUuid: deviceUuid.present ? deviceUuid.value : this.deviceUuid,
  );
  ChangeLogData copyWithCompanion(ChangeLogCompanion data) {
    return ChangeLogData(
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      entityTable: data.entityTable.present
          ? data.entityTable.value
          : this.entityTable,
      entityUuid: data.entityUuid.present
          ? data.entityUuid.value
          : this.entityUuid,
      changeType: data.changeType.present
          ? data.changeType.value
          : this.changeType,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      changedByUserUuid: data.changedByUserUuid.present
          ? data.changedByUserUuid.value
          : this.changedByUserUuid,
      deviceUuid: data.deviceUuid.present
          ? data.deviceUuid.value
          : this.deviceUuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogData(')
          ..write('uuid: $uuid, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityUuid: $entityUuid, ')
          ..write('changeType: $changeType, ')
          ..write('changedAt: $changedAt, ')
          ..write('changedByUserUuid: $changedByUserUuid, ')
          ..write('deviceUuid: $deviceUuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    uuid,
    entityTable,
    entityUuid,
    changeType,
    changedAt,
    changedByUserUuid,
    deviceUuid,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChangeLogData &&
          other.uuid == this.uuid &&
          other.entityTable == this.entityTable &&
          other.entityUuid == this.entityUuid &&
          other.changeType == this.changeType &&
          other.changedAt == this.changedAt &&
          other.changedByUserUuid == this.changedByUserUuid &&
          other.deviceUuid == this.deviceUuid);
}

class ChangeLogCompanion extends UpdateCompanion<ChangeLogData> {
  final Value<Uuid> uuid;
  final Value<String> entityTable;
  final Value<Uuid> entityUuid;
  final Value<int> changeType;
  final Value<int> changedAt;
  final Value<Uuid?> changedByUserUuid;
  final Value<Uuid?> deviceUuid;
  final Value<int> rowid;
  const ChangeLogCompanion({
    this.uuid = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.entityUuid = const Value.absent(),
    this.changeType = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.changedByUserUuid = const Value.absent(),
    this.deviceUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChangeLogCompanion.insert({
    required Uuid uuid,
    required String entityTable,
    required Uuid entityUuid,
    required int changeType,
    required int changedAt,
    this.changedByUserUuid = const Value.absent(),
    this.deviceUuid = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid),
       entityTable = Value(entityTable),
       entityUuid = Value(entityUuid),
       changeType = Value(changeType),
       changedAt = Value(changedAt);
  static Insertable<ChangeLogData> custom({
    Expression<Uint8List>? uuid,
    Expression<String>? entityTable,
    Expression<Uint8List>? entityUuid,
    Expression<int>? changeType,
    Expression<int>? changedAt,
    Expression<Uint8List>? changedByUserUuid,
    Expression<Uint8List>? deviceUuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uuid != null) 'uuid': uuid,
      if (entityTable != null) 'entity_table': entityTable,
      if (entityUuid != null) 'entity_uuid': entityUuid,
      if (changeType != null) 'change_type': changeType,
      if (changedAt != null) 'changed_at': changedAt,
      if (changedByUserUuid != null) 'changed_by_user_uuid': changedByUserUuid,
      if (deviceUuid != null) 'device_uuid': deviceUuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChangeLogCompanion copyWith({
    Value<Uuid>? uuid,
    Value<String>? entityTable,
    Value<Uuid>? entityUuid,
    Value<int>? changeType,
    Value<int>? changedAt,
    Value<Uuid?>? changedByUserUuid,
    Value<Uuid?>? deviceUuid,
    Value<int>? rowid,
  }) {
    return ChangeLogCompanion(
      uuid: uuid ?? this.uuid,
      entityTable: entityTable ?? this.entityTable,
      entityUuid: entityUuid ?? this.entityUuid,
      changeType: changeType ?? this.changeType,
      changedAt: changedAt ?? this.changedAt,
      changedByUserUuid: changedByUserUuid ?? this.changedByUserUuid,
      deviceUuid: deviceUuid ?? this.deviceUuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uuid.present) {
      map['uuid'] = Variable<Uint8List>(
        ChangeLog.$converteruuid.toSql(uuid.value),
      );
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (entityUuid.present) {
      map['entity_uuid'] = Variable<Uint8List>(
        ChangeLog.$converterentityUuid.toSql(entityUuid.value),
      );
    }
    if (changeType.present) {
      map['change_type'] = Variable<int>(changeType.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<int>(changedAt.value);
    }
    if (changedByUserUuid.present) {
      map['changed_by_user_uuid'] = Variable<Uint8List>(
        ChangeLog.$converterchangedByUserUuidn.toSql(changedByUserUuid.value),
      );
    }
    if (deviceUuid.present) {
      map['device_uuid'] = Variable<Uint8List>(
        ChangeLog.$converterdeviceUuidn.toSql(deviceUuid.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogCompanion(')
          ..write('uuid: $uuid, ')
          ..write('entityTable: $entityTable, ')
          ..write('entityUuid: $entityUuid, ')
          ..write('changeType: $changeType, ')
          ..write('changedAt: $changedAt, ')
          ..write('changedByUserUuid: $changedByUserUuid, ')
          ..write('deviceUuid: $deviceUuid, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ChangeLogField extends Table
    with TableInfo<ChangeLogField, ChangeLogFieldData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ChangeLogField(this.attachedDatabase, [this._alias]);
  late final GeneratedColumnWithTypeConverter<Uuid, Uint8List> changeUuid =
      GeneratedColumn<Uint8List>(
        'change_uuid',
        aliasedName,
        false,
        type: DriftSqlType.blob,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL REFERENCES change_log(uuid)ON DELETE CASCADE',
      ).withConverter<Uuid>(ChangeLogField.$converterchangeUuid);
  static const VerificationMeta _fieldNameMeta = const VerificationMeta(
    'fieldName',
  );
  late final GeneratedColumn<String> fieldName = GeneratedColumn<String>(
    'field_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _oldValueShortMeta = const VerificationMeta(
    'oldValueShort',
  );
  late final GeneratedColumn<Uint8List> oldValueShort =
      GeneratedColumn<Uint8List>(
        'old_value_short',
        aliasedName,
        true,
        type: DriftSqlType.blob,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _oldValueTruncatedMeta = const VerificationMeta(
    'oldValueTruncated',
  );
  late final GeneratedColumn<int> oldValueTruncated = GeneratedColumn<int>(
    'old_value_truncated',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [
    changeUuid,
    fieldName,
    oldValueShort,
    oldValueTruncated,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'change_log_field';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChangeLogFieldData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('field_name')) {
      context.handle(
        _fieldNameMeta,
        fieldName.isAcceptableOrUnknown(data['field_name']!, _fieldNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fieldNameMeta);
    }
    if (data.containsKey('old_value_short')) {
      context.handle(
        _oldValueShortMeta,
        oldValueShort.isAcceptableOrUnknown(
          data['old_value_short']!,
          _oldValueShortMeta,
        ),
      );
    }
    if (data.containsKey('old_value_truncated')) {
      context.handle(
        _oldValueTruncatedMeta,
        oldValueTruncated.isAcceptableOrUnknown(
          data['old_value_truncated']!,
          _oldValueTruncatedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {changeUuid, fieldName};
  @override
  ChangeLogFieldData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChangeLogFieldData(
      changeUuid: ChangeLogField.$converterchangeUuid.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.blob,
          data['${effectivePrefix}change_uuid'],
        )!,
      ),
      fieldName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}field_name'],
      )!,
      oldValueShort: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}old_value_short'],
      ),
      oldValueTruncated: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}old_value_truncated'],
      )!,
    );
  }

  @override
  ChangeLogField createAlias(String alias) {
    return ChangeLogField(attachedDatabase, alias);
  }

  static TypeConverter<Uuid, Uint8List> $converterchangeUuid =
      const UuidConverter();
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(change_uuid, field_name)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class ChangeLogFieldData extends DataClass
    implements Insertable<ChangeLogFieldData> {
  final Uuid changeUuid;
  final String fieldName;
  final Uint8List? oldValueShort;
  final int oldValueTruncated;
  const ChangeLogFieldData({
    required this.changeUuid,
    required this.fieldName,
    this.oldValueShort,
    required this.oldValueTruncated,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['change_uuid'] = Variable<Uint8List>(
        ChangeLogField.$converterchangeUuid.toSql(changeUuid),
      );
    }
    map['field_name'] = Variable<String>(fieldName);
    if (!nullToAbsent || oldValueShort != null) {
      map['old_value_short'] = Variable<Uint8List>(oldValueShort);
    }
    map['old_value_truncated'] = Variable<int>(oldValueTruncated);
    return map;
  }

  ChangeLogFieldCompanion toCompanion(bool nullToAbsent) {
    return ChangeLogFieldCompanion(
      changeUuid: Value(changeUuid),
      fieldName: Value(fieldName),
      oldValueShort: oldValueShort == null && nullToAbsent
          ? const Value.absent()
          : Value(oldValueShort),
      oldValueTruncated: Value(oldValueTruncated),
    );
  }

  factory ChangeLogFieldData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChangeLogFieldData(
      changeUuid: serializer.fromJson<Uuid>(json['change_uuid']),
      fieldName: serializer.fromJson<String>(json['field_name']),
      oldValueShort: serializer.fromJson<Uint8List?>(json['old_value_short']),
      oldValueTruncated: serializer.fromJson<int>(json['old_value_truncated']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'change_uuid': serializer.toJson<Uuid>(changeUuid),
      'field_name': serializer.toJson<String>(fieldName),
      'old_value_short': serializer.toJson<Uint8List?>(oldValueShort),
      'old_value_truncated': serializer.toJson<int>(oldValueTruncated),
    };
  }

  ChangeLogFieldData copyWith({
    Uuid? changeUuid,
    String? fieldName,
    Value<Uint8List?> oldValueShort = const Value.absent(),
    int? oldValueTruncated,
  }) => ChangeLogFieldData(
    changeUuid: changeUuid ?? this.changeUuid,
    fieldName: fieldName ?? this.fieldName,
    oldValueShort: oldValueShort.present
        ? oldValueShort.value
        : this.oldValueShort,
    oldValueTruncated: oldValueTruncated ?? this.oldValueTruncated,
  );
  ChangeLogFieldData copyWithCompanion(ChangeLogFieldCompanion data) {
    return ChangeLogFieldData(
      changeUuid: data.changeUuid.present
          ? data.changeUuid.value
          : this.changeUuid,
      fieldName: data.fieldName.present ? data.fieldName.value : this.fieldName,
      oldValueShort: data.oldValueShort.present
          ? data.oldValueShort.value
          : this.oldValueShort,
      oldValueTruncated: data.oldValueTruncated.present
          ? data.oldValueTruncated.value
          : this.oldValueTruncated,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogFieldData(')
          ..write('changeUuid: $changeUuid, ')
          ..write('fieldName: $fieldName, ')
          ..write('oldValueShort: $oldValueShort, ')
          ..write('oldValueTruncated: $oldValueTruncated')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    changeUuid,
    fieldName,
    $driftBlobEquality.hash(oldValueShort),
    oldValueTruncated,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChangeLogFieldData &&
          other.changeUuid == this.changeUuid &&
          other.fieldName == this.fieldName &&
          $driftBlobEquality.equals(other.oldValueShort, this.oldValueShort) &&
          other.oldValueTruncated == this.oldValueTruncated);
}

class ChangeLogFieldCompanion extends UpdateCompanion<ChangeLogFieldData> {
  final Value<Uuid> changeUuid;
  final Value<String> fieldName;
  final Value<Uint8List?> oldValueShort;
  final Value<int> oldValueTruncated;
  final Value<int> rowid;
  const ChangeLogFieldCompanion({
    this.changeUuid = const Value.absent(),
    this.fieldName = const Value.absent(),
    this.oldValueShort = const Value.absent(),
    this.oldValueTruncated = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChangeLogFieldCompanion.insert({
    required Uuid changeUuid,
    required String fieldName,
    this.oldValueShort = const Value.absent(),
    this.oldValueTruncated = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : changeUuid = Value(changeUuid),
       fieldName = Value(fieldName);
  static Insertable<ChangeLogFieldData> custom({
    Expression<Uint8List>? changeUuid,
    Expression<String>? fieldName,
    Expression<Uint8List>? oldValueShort,
    Expression<int>? oldValueTruncated,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (changeUuid != null) 'change_uuid': changeUuid,
      if (fieldName != null) 'field_name': fieldName,
      if (oldValueShort != null) 'old_value_short': oldValueShort,
      if (oldValueTruncated != null) 'old_value_truncated': oldValueTruncated,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChangeLogFieldCompanion copyWith({
    Value<Uuid>? changeUuid,
    Value<String>? fieldName,
    Value<Uint8List?>? oldValueShort,
    Value<int>? oldValueTruncated,
    Value<int>? rowid,
  }) {
    return ChangeLogFieldCompanion(
      changeUuid: changeUuid ?? this.changeUuid,
      fieldName: fieldName ?? this.fieldName,
      oldValueShort: oldValueShort ?? this.oldValueShort,
      oldValueTruncated: oldValueTruncated ?? this.oldValueTruncated,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (changeUuid.present) {
      map['change_uuid'] = Variable<Uint8List>(
        ChangeLogField.$converterchangeUuid.toSql(changeUuid.value),
      );
    }
    if (fieldName.present) {
      map['field_name'] = Variable<String>(fieldName.value);
    }
    if (oldValueShort.present) {
      map['old_value_short'] = Variable<Uint8List>(oldValueShort.value);
    }
    if (oldValueTruncated.present) {
      map['old_value_truncated'] = Variable<int>(oldValueTruncated.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChangeLogFieldCompanion(')
          ..write('changeUuid: $changeUuid, ')
          ..write('fieldName: $fieldName, ')
          ..write('oldValueShort: $oldValueShort, ')
          ..write('oldValueTruncated: $oldValueTruncated, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final Users users = Users(this);
  late final SurfaceAreas surfaceAreas = SurfaceAreas(this);
  late final Caves caves = Caves(this);
  late final CaveAreas caveAreas = CaveAreas(this);
  late final SurfacePlaces surfacePlaces = SurfacePlaces(this);
  late final CaveEntrances caveEntrances = CaveEntrances(this);
  late final CavePlaces cavePlaces = CavePlaces(this);
  late final RasterMaps rasterMaps = RasterMaps(this);
  late final CavePlaceToRasterMapDefinitions cavePlaceToRasterMapDefinitions =
      CavePlaceToRasterMapDefinitions(this);
  late final DocumentationFiles documentationFiles = DocumentationFiles(this);
  late final DocumentationFilesToGeofeatures documentationFilesToGeofeatures =
      DocumentationFilesToGeofeatures(this);
  late final Configurations configurations = Configurations(this);
  late final CaveTrips caveTrips = CaveTrips(this);
  late final CaveTripPoints caveTripPoints = CaveTripPoints(this);
  late final DocumentationFilesToCaveTrips documentationFilesToCaveTrips =
      DocumentationFilesToCaveTrips(this);
  late final TripReportTemplates tripReportTemplates = TripReportTemplates(
    this,
  );
  late final ChangeLog changeLog = ChangeLog(this);
  late final ChangeLogField changeLogField = ChangeLogField(this);
  late final Index idxChangeLogEntity = Index(
    'idx_change_log_entity',
    'CREATE INDEX IF NOT EXISTS idx_change_log_entity ON change_log (entity_table, entity_uuid)',
  );
  late final Index idxChangeLogChangedAt = Index(
    'idx_change_log_changed_at',
    'CREATE INDEX IF NOT EXISTS idx_change_log_changed_at ON change_log (changed_at)',
  );
  late final Index idxChangeLogChangedBy = Index(
    'idx_change_log_changed_by',
    'CREATE INDEX IF NOT EXISTS idx_change_log_changed_by ON change_log (changed_by_user_uuid)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    surfaceAreas,
    caves,
    caveAreas,
    surfacePlaces,
    caveEntrances,
    cavePlaces,
    rasterMaps,
    cavePlaceToRasterMapDefinitions,
    documentationFiles,
    documentationFilesToGeofeatures,
    configurations,
    caveTrips,
    caveTripPoints,
    documentationFilesToCaveTrips,
    tripReportTemplates,
    changeLog,
    changeLogField,
    idxChangeLogEntity,
    idxChangeLogChangedAt,
    idxChangeLogChangedBy,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'change_log',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('change_log_field', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $UsersCreateCompanionBuilder =
    UsersCompanion Function({
      required Uuid uuid,
      required String username,
      Value<String?> firstName,
      Value<String?> lastName,
      Value<String?> details,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $UsersUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<Uuid> uuid,
      Value<String> username,
      Value<String?> firstName,
      Value<String?> lastName,
      Value<String?> details,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $UsersReferences
    extends BaseReferences<_$AppDatabase, Users, User> {
  $UsersReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<ChangeLog, List<ChangeLogData>>
  _changeLogRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.changeLog,
    aliasName: $_aliasNameGenerator(
      db.users.uuid,
      db.changeLog.changedByUserUuid,
    ),
  );

  $ChangeLogProcessedTableManager get changeLogRefs {
    final manager = $ChangeLogTableManager($_db, $_db.changeLog).filter(
      (f) =>
          f.changedByUserUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
    );

    final cache = $_typedResult.readTableOrNull(_changeLogRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $UsersFilterComposer extends Composer<_$AppDatabase, Users> {
  $UsersFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Uuid?, Uuid, Uint8List>
  get createdByUserUuid => $composableBuilder(
    column: $table.createdByUserUuid,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<Uuid?, Uuid, Uint8List>
  get lastModifiedByUserUuid => $composableBuilder(
    column: $table.lastModifiedByUserUuid,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  Expression<bool> changeLogRefs(
    Expression<bool> Function($ChangeLogFilterComposer f) f,
  ) {
    final $ChangeLogFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.changeLog,
      getReferencedColumn: (t) => t.changedByUserUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ChangeLogFilterComposer(
            $db: $db,
            $table: $db.changeLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $UsersOrderingComposer extends Composer<_$AppDatabase, Users> {
  $UsersOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get username => $composableBuilder(
    column: $table.username,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get firstName => $composableBuilder(
    column: $table.firstName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastName => $composableBuilder(
    column: $table.lastName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get details => $composableBuilder(
    column: $table.details,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get createdByUserUuid => $composableBuilder(
    column: $table.createdByUserUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get lastModifiedByUserUuid => $composableBuilder(
    column: $table.lastModifiedByUserUuid,
    builder: (column) => ColumnOrderings(column),
  );
}

class $UsersAnnotationComposer extends Composer<_$AppDatabase, Users> {
  $UsersAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get username =>
      $composableBuilder(column: $table.username, builder: (column) => column);

  GeneratedColumn<String> get firstName =>
      $composableBuilder(column: $table.firstName, builder: (column) => column);

  GeneratedColumn<String> get lastName =>
      $composableBuilder(column: $table.lastName, builder: (column) => column);

  GeneratedColumn<String> get details =>
      $composableBuilder(column: $table.details, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Uuid?, Uint8List> get createdByUserUuid =>
      $composableBuilder(
        column: $table.createdByUserUuid,
        builder: (column) => column,
      );

  GeneratedColumnWithTypeConverter<Uuid?, Uint8List>
  get lastModifiedByUserUuid => $composableBuilder(
    column: $table.lastModifiedByUserUuid,
    builder: (column) => column,
  );

  Expression<T> changeLogRefs<T extends Object>(
    Expression<T> Function($ChangeLogAnnotationComposer a) f,
  ) {
    final $ChangeLogAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.changeLog,
      getReferencedColumn: (t) => t.changedByUserUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ChangeLogAnnotationComposer(
            $db: $db,
            $table: $db.changeLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $UsersTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Users,
          User,
          $UsersFilterComposer,
          $UsersOrderingComposer,
          $UsersAnnotationComposer,
          $UsersCreateCompanionBuilder,
          $UsersUpdateCompanionBuilder,
          (User, $UsersReferences),
          User,
          PrefetchHooks Function({bool changeLogRefs})
        > {
  $UsersTableManager(_$AppDatabase db, Users table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $UsersFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $UsersOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $UsersAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<String> username = const Value.absent(),
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                uuid: uuid,
                username: username,
                firstName: firstName,
                lastName: lastName,
                details: details,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required String username,
                Value<String?> firstName = const Value.absent(),
                Value<String?> lastName = const Value.absent(),
                Value<String?> details = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                uuid: uuid,
                username: username,
                firstName: firstName,
                lastName: lastName,
                details: details,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $UsersReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: ({changeLogRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (changeLogRefs) db.changeLog],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (changeLogRefs)
                    await $_getPrefetchedData<User, Users, ChangeLogData>(
                      currentTable: table,
                      referencedTable: $UsersReferences._changeLogRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $UsersReferences(db, table, p0).changeLogRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.changedByUserUuid == item.uuid,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $UsersProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Users,
      User,
      $UsersFilterComposer,
      $UsersOrderingComposer,
      $UsersAnnotationComposer,
      $UsersCreateCompanionBuilder,
      $UsersUpdateCompanionBuilder,
      (User, $UsersReferences),
      User,
      PrefetchHooks Function({bool changeLogRefs})
    >;
typedef $SurfaceAreasCreateCompanionBuilder =
    SurfaceAreasCompanion Function({
      required Uuid uuid,
      required String title,
      Value<String?> description,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $SurfaceAreasUpdateCompanionBuilder =
    SurfaceAreasCompanion Function({
      Value<Uuid> uuid,
      Value<String> title,
      Value<String?> description,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $SurfaceAreasReferences
    extends BaseReferences<_$AppDatabase, SurfaceAreas, SurfaceArea> {
  $SurfaceAreasReferences(super.$_db, super.$_table, super.$_typedResult);

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.surfaceAreas.createdByUserUuid, db.users.uuid),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.surfaceAreas.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<Caves, List<Cave>> _cavesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.caves,
    aliasName: $_aliasNameGenerator(
      db.surfaceAreas.uuid,
      db.caves.surfaceAreaUuid,
    ),
  );

  $CavesProcessedTableManager get cavesRefs {
    final manager = $CavesTableManager($_db, $_db.caves).filter(
      (f) => f.surfaceAreaUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
    );

    final cache = $_typedResult.readTableOrNull(_cavesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $SurfaceAreasFilterComposer
    extends Composer<_$AppDatabase, SurfaceAreas> {
  $SurfaceAreasFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cavesRefs(
    Expression<bool> Function($CavesFilterComposer f) f,
  ) {
    final $CavesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.surfaceAreaUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesFilterComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SurfaceAreasOrderingComposer
    extends Composer<_$AppDatabase, SurfaceAreas> {
  $SurfaceAreasOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SurfaceAreasAnnotationComposer
    extends Composer<_$AppDatabase, SurfaceAreas> {
  $SurfaceAreasAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cavesRefs<T extends Object>(
    Expression<T> Function($CavesAnnotationComposer a) f,
  ) {
    final $CavesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.surfaceAreaUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesAnnotationComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SurfaceAreasTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SurfaceAreas,
          SurfaceArea,
          $SurfaceAreasFilterComposer,
          $SurfaceAreasOrderingComposer,
          $SurfaceAreasAnnotationComposer,
          $SurfaceAreasCreateCompanionBuilder,
          $SurfaceAreasUpdateCompanionBuilder,
          (SurfaceArea, $SurfaceAreasReferences),
          SurfaceArea,
          PrefetchHooks Function({
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
            bool cavesRefs,
          })
        > {
  $SurfaceAreasTableManager(_$AppDatabase db, SurfaceAreas table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SurfaceAreasFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SurfaceAreasOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SurfaceAreasAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurfaceAreasCompanion(
                uuid: uuid,
                title: title,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurfaceAreasCompanion.insert(
                uuid: uuid,
                title: title,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $SurfaceAreasReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
                cavesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (cavesRefs) db.caves],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable: $SurfaceAreasReferences
                                        ._createdByUserUuidTable(db),
                                    referencedColumn: $SurfaceAreasReferences
                                        ._createdByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable: $SurfaceAreasReferences
                                        ._lastModifiedByUserUuidTable(db),
                                    referencedColumn: $SurfaceAreasReferences
                                        ._lastModifiedByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cavesRefs)
                        await $_getPrefetchedData<
                          SurfaceArea,
                          SurfaceAreas,
                          Cave
                        >(
                          currentTable: table,
                          referencedTable: $SurfaceAreasReferences
                              ._cavesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $SurfaceAreasReferences(db, table, p0).cavesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.surfaceAreaUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $SurfaceAreasProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SurfaceAreas,
      SurfaceArea,
      $SurfaceAreasFilterComposer,
      $SurfaceAreasOrderingComposer,
      $SurfaceAreasAnnotationComposer,
      $SurfaceAreasCreateCompanionBuilder,
      $SurfaceAreasUpdateCompanionBuilder,
      (SurfaceArea, $SurfaceAreasReferences),
      SurfaceArea,
      PrefetchHooks Function({
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
        bool cavesRefs,
      })
    >;
typedef $CavesCreateCompanionBuilder =
    CavesCompanion Function({
      required Uuid uuid,
      required String title,
      Value<String?> description,
      Value<Uuid?> surfaceAreaUuid,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $CavesUpdateCompanionBuilder =
    CavesCompanion Function({
      Value<Uuid> uuid,
      Value<String> title,
      Value<String?> description,
      Value<Uuid?> surfaceAreaUuid,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $CavesReferences
    extends BaseReferences<_$AppDatabase, Caves, Cave> {
  $CavesReferences(super.$_db, super.$_table, super.$_typedResult);

  static SurfaceAreas _surfaceAreaUuidTable(_$AppDatabase db) =>
      db.surfaceAreas.createAlias(
        $_aliasNameGenerator(db.caves.surfaceAreaUuid, db.surfaceAreas.uuid),
      );

  $SurfaceAreasProcessedTableManager? get surfaceAreaUuid {
    final $_column = $_itemColumn<Uint8List>('surface_area_uuid');
    if ($_column == null) return null;
    final manager = $SurfaceAreasTableManager(
      $_db,
      $_db.surfaceAreas,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surfaceAreaUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.caves.createdByUserUuid, db.users.uuid),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.caves.lastModifiedByUserUuid, db.users.uuid),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<CaveAreas, List<CaveArea>> _caveAreasRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.caveAreas,
    aliasName: $_aliasNameGenerator(db.caves.uuid, db.caveAreas.caveUuid),
  );

  $CaveAreasProcessedTableManager get caveAreasRefs {
    final manager = $CaveAreasTableManager($_db, $_db.caveAreas).filter(
      (f) => f.caveUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
    );

    final cache = $_typedResult.readTableOrNull(_caveAreasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CaveEntrances, List<CaveEntrance>>
  _caveEntrancesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.caveEntrances,
    aliasName: $_aliasNameGenerator(db.caves.uuid, db.caveEntrances.caveUuid),
  );

  $CaveEntrancesProcessedTableManager get caveEntrancesRefs {
    final manager = $CaveEntrancesTableManager($_db, $_db.caveEntrances).filter(
      (f) => f.caveUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
    );

    final cache = $_typedResult.readTableOrNull(_caveEntrancesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CavePlaces, List<CavePlace>> _cavePlacesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cavePlaces,
    aliasName: $_aliasNameGenerator(db.caves.uuid, db.cavePlaces.caveUuid),
  );

  $CavePlacesProcessedTableManager get cavePlacesRefs {
    final manager = $CavePlacesTableManager($_db, $_db.cavePlaces).filter(
      (f) => f.caveUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
    );

    final cache = $_typedResult.readTableOrNull(_cavePlacesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<RasterMaps, List<RasterMap>> _rasterMapsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rasterMaps,
    aliasName: $_aliasNameGenerator(db.caves.uuid, db.rasterMaps.caveUuid),
  );

  $RasterMapsProcessedTableManager get rasterMapsRefs {
    final manager = $RasterMapsTableManager($_db, $_db.rasterMaps).filter(
      (f) => f.caveUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
    );

    final cache = $_typedResult.readTableOrNull(_rasterMapsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CaveTrips, List<CaveTrip>> _caveTripsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.caveTrips,
    aliasName: $_aliasNameGenerator(db.caves.uuid, db.caveTrips.caveUuid),
  );

  $CaveTripsProcessedTableManager get caveTripsRefs {
    final manager = $CaveTripsTableManager($_db, $_db.caveTrips).filter(
      (f) => f.caveUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
    );

    final cache = $_typedResult.readTableOrNull(_caveTripsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CavesFilterComposer extends Composer<_$AppDatabase, Caves> {
  $CavesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $SurfaceAreasFilterComposer get surfaceAreaUuid {
    final $SurfaceAreasFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfaceAreaUuid,
      referencedTable: $db.surfaceAreas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SurfaceAreasFilterComposer(
            $db: $db,
            $table: $db.surfaceAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> caveAreasRefs(
    Expression<bool> Function($CaveAreasFilterComposer f) f,
  ) {
    final $CaveAreasFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.caveUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveAreasFilterComposer(
            $db: $db,
            $table: $db.caveAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> caveEntrancesRefs(
    Expression<bool> Function($CaveEntrancesFilterComposer f) f,
  ) {
    final $CaveEntrancesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveEntrances,
      getReferencedColumn: (t) => t.caveUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveEntrancesFilterComposer(
            $db: $db,
            $table: $db.caveEntrances,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> cavePlacesRefs(
    Expression<bool> Function($CavePlacesFilterComposer f) f,
  ) {
    final $CavePlacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.caveUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavePlacesFilterComposer(
            $db: $db,
            $table: $db.cavePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rasterMapsRefs(
    Expression<bool> Function($RasterMapsFilterComposer f) f,
  ) {
    final $RasterMapsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.caveUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RasterMapsFilterComposer(
            $db: $db,
            $table: $db.rasterMaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> caveTripsRefs(
    Expression<bool> Function($CaveTripsFilterComposer f) f,
  ) {
    final $CaveTripsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveTrips,
      getReferencedColumn: (t) => t.caveUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripsFilterComposer(
            $db: $db,
            $table: $db.caveTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CavesOrderingComposer extends Composer<_$AppDatabase, Caves> {
  $CavesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $SurfaceAreasOrderingComposer get surfaceAreaUuid {
    final $SurfaceAreasOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfaceAreaUuid,
      referencedTable: $db.surfaceAreas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SurfaceAreasOrderingComposer(
            $db: $db,
            $table: $db.surfaceAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CavesAnnotationComposer extends Composer<_$AppDatabase, Caves> {
  $CavesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $SurfaceAreasAnnotationComposer get surfaceAreaUuid {
    final $SurfaceAreasAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfaceAreaUuid,
      referencedTable: $db.surfaceAreas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SurfaceAreasAnnotationComposer(
            $db: $db,
            $table: $db.surfaceAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> caveAreasRefs<T extends Object>(
    Expression<T> Function($CaveAreasAnnotationComposer a) f,
  ) {
    final $CaveAreasAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.caveUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveAreasAnnotationComposer(
            $db: $db,
            $table: $db.caveAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> caveEntrancesRefs<T extends Object>(
    Expression<T> Function($CaveEntrancesAnnotationComposer a) f,
  ) {
    final $CaveEntrancesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveEntrances,
      getReferencedColumn: (t) => t.caveUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveEntrancesAnnotationComposer(
            $db: $db,
            $table: $db.caveEntrances,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> cavePlacesRefs<T extends Object>(
    Expression<T> Function($CavePlacesAnnotationComposer a) f,
  ) {
    final $CavePlacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.caveUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavePlacesAnnotationComposer(
            $db: $db,
            $table: $db.cavePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rasterMapsRefs<T extends Object>(
    Expression<T> Function($RasterMapsAnnotationComposer a) f,
  ) {
    final $RasterMapsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.caveUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RasterMapsAnnotationComposer(
            $db: $db,
            $table: $db.rasterMaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> caveTripsRefs<T extends Object>(
    Expression<T> Function($CaveTripsAnnotationComposer a) f,
  ) {
    final $CaveTripsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveTrips,
      getReferencedColumn: (t) => t.caveUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripsAnnotationComposer(
            $db: $db,
            $table: $db.caveTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CavesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Caves,
          Cave,
          $CavesFilterComposer,
          $CavesOrderingComposer,
          $CavesAnnotationComposer,
          $CavesCreateCompanionBuilder,
          $CavesUpdateCompanionBuilder,
          (Cave, $CavesReferences),
          Cave,
          PrefetchHooks Function({
            bool surfaceAreaUuid,
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
            bool caveAreasRefs,
            bool caveEntrancesRefs,
            bool cavePlacesRefs,
            bool rasterMapsRefs,
            bool caveTripsRefs,
          })
        > {
  $CavesTableManager(_$AppDatabase db, Caves table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CavesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CavesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CavesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<Uuid?> surfaceAreaUuid = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CavesCompanion(
                uuid: uuid,
                title: title,
                description: description,
                surfaceAreaUuid: surfaceAreaUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<Uuid?> surfaceAreaUuid = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CavesCompanion.insert(
                uuid: uuid,
                title: title,
                description: description,
                surfaceAreaUuid: surfaceAreaUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $CavesReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({
                surfaceAreaUuid = false,
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
                caveAreasRefs = false,
                caveEntrancesRefs = false,
                cavePlacesRefs = false,
                rasterMapsRefs = false,
                caveTripsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (caveAreasRefs) db.caveAreas,
                    if (caveEntrancesRefs) db.caveEntrances,
                    if (cavePlacesRefs) db.cavePlaces,
                    if (rasterMapsRefs) db.rasterMaps,
                    if (caveTripsRefs) db.caveTrips,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (surfaceAreaUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.surfaceAreaUuid,
                                    referencedTable: $CavesReferences
                                        ._surfaceAreaUuidTable(db),
                                    referencedColumn: $CavesReferences
                                        ._surfaceAreaUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable: $CavesReferences
                                        ._createdByUserUuidTable(db),
                                    referencedColumn: $CavesReferences
                                        ._createdByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable: $CavesReferences
                                        ._lastModifiedByUserUuidTable(db),
                                    referencedColumn: $CavesReferences
                                        ._lastModifiedByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (caveAreasRefs)
                        await $_getPrefetchedData<Cave, Caves, CaveArea>(
                          currentTable: table,
                          referencedTable: $CavesReferences._caveAreasRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $CavesReferences(db, table, p0).caveAreasRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.caveUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (caveEntrancesRefs)
                        await $_getPrefetchedData<Cave, Caves, CaveEntrance>(
                          currentTable: table,
                          referencedTable: $CavesReferences
                              ._caveEntrancesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CavesReferences(db, table, p0).caveEntrancesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.caveUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (cavePlacesRefs)
                        await $_getPrefetchedData<Cave, Caves, CavePlace>(
                          currentTable: table,
                          referencedTable: $CavesReferences
                              ._cavePlacesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CavesReferences(db, table, p0).cavePlacesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.caveUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (rasterMapsRefs)
                        await $_getPrefetchedData<Cave, Caves, RasterMap>(
                          currentTable: table,
                          referencedTable: $CavesReferences
                              ._rasterMapsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $CavesReferences(db, table, p0).rasterMapsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.caveUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (caveTripsRefs)
                        await $_getPrefetchedData<Cave, Caves, CaveTrip>(
                          currentTable: table,
                          referencedTable: $CavesReferences._caveTripsRefsTable(
                            db,
                          ),
                          managerFromTypedResult: (p0) =>
                              $CavesReferences(db, table, p0).caveTripsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.caveUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $CavesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Caves,
      Cave,
      $CavesFilterComposer,
      $CavesOrderingComposer,
      $CavesAnnotationComposer,
      $CavesCreateCompanionBuilder,
      $CavesUpdateCompanionBuilder,
      (Cave, $CavesReferences),
      Cave,
      PrefetchHooks Function({
        bool surfaceAreaUuid,
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
        bool caveAreasRefs,
        bool caveEntrancesRefs,
        bool cavePlacesRefs,
        bool rasterMapsRefs,
        bool caveTripsRefs,
      })
    >;
typedef $CaveAreasCreateCompanionBuilder =
    CaveAreasCompanion Function({
      required Uuid uuid,
      required String title,
      Value<String?> description,
      required Uuid caveUuid,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $CaveAreasUpdateCompanionBuilder =
    CaveAreasCompanion Function({
      Value<Uuid> uuid,
      Value<String> title,
      Value<String?> description,
      Value<Uuid> caveUuid,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $CaveAreasReferences
    extends BaseReferences<_$AppDatabase, CaveAreas, CaveArea> {
  $CaveAreasReferences(super.$_db, super.$_table, super.$_typedResult);

  static Caves _caveUuidTable(_$AppDatabase db) => db.caves.createAlias(
    $_aliasNameGenerator(db.caveAreas.caveUuid, db.caves.uuid),
  );

  $CavesProcessedTableManager get caveUuid {
    final $_column = $_itemColumn<Uint8List>('cave_uuid')!;

    final manager = $CavesTableManager(
      $_db,
      $_db.caves,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.caveAreas.createdByUserUuid, db.users.uuid),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.caveAreas.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<CavePlaces, List<CavePlace>> _cavePlacesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cavePlaces,
    aliasName: $_aliasNameGenerator(
      db.caveAreas.uuid,
      db.cavePlaces.caveAreaUuid,
    ),
  );

  $CavePlacesProcessedTableManager get cavePlacesRefs {
    final manager = $CavePlacesTableManager($_db, $_db.cavePlaces).filter(
      (f) => f.caveAreaUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
    );

    final cache = $_typedResult.readTableOrNull(_cavePlacesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<RasterMaps, List<RasterMap>> _rasterMapsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rasterMaps,
    aliasName: $_aliasNameGenerator(
      db.caveAreas.uuid,
      db.rasterMaps.caveAreaUuid,
    ),
  );

  $RasterMapsProcessedTableManager get rasterMapsRefs {
    final manager = $RasterMapsTableManager($_db, $_db.rasterMaps).filter(
      (f) => f.caveAreaUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
    );

    final cache = $_typedResult.readTableOrNull(_rasterMapsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CaveAreasFilterComposer extends Composer<_$AppDatabase, CaveAreas> {
  $CaveAreasFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $CavesFilterComposer get caveUuid {
    final $CavesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesFilterComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cavePlacesRefs(
    Expression<bool> Function($CavePlacesFilterComposer f) f,
  ) {
    final $CavePlacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.caveAreaUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavePlacesFilterComposer(
            $db: $db,
            $table: $db.cavePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> rasterMapsRefs(
    Expression<bool> Function($RasterMapsFilterComposer f) f,
  ) {
    final $RasterMapsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.caveAreaUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RasterMapsFilterComposer(
            $db: $db,
            $table: $db.rasterMaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CaveAreasOrderingComposer extends Composer<_$AppDatabase, CaveAreas> {
  $CaveAreasOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $CavesOrderingComposer get caveUuid {
    final $CavesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesOrderingComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaveAreasAnnotationComposer extends Composer<_$AppDatabase, CaveAreas> {
  $CaveAreasAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $CavesAnnotationComposer get caveUuid {
    final $CavesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesAnnotationComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cavePlacesRefs<T extends Object>(
    Expression<T> Function($CavePlacesAnnotationComposer a) f,
  ) {
    final $CavePlacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.caveAreaUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavePlacesAnnotationComposer(
            $db: $db,
            $table: $db.cavePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> rasterMapsRefs<T extends Object>(
    Expression<T> Function($RasterMapsAnnotationComposer a) f,
  ) {
    final $RasterMapsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.caveAreaUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RasterMapsAnnotationComposer(
            $db: $db,
            $table: $db.rasterMaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CaveAreasTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CaveAreas,
          CaveArea,
          $CaveAreasFilterComposer,
          $CaveAreasOrderingComposer,
          $CaveAreasAnnotationComposer,
          $CaveAreasCreateCompanionBuilder,
          $CaveAreasUpdateCompanionBuilder,
          (CaveArea, $CaveAreasReferences),
          CaveArea,
          PrefetchHooks Function({
            bool caveUuid,
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
            bool cavePlacesRefs,
            bool rasterMapsRefs,
          })
        > {
  $CaveAreasTableManager(_$AppDatabase db, CaveAreas table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CaveAreasFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CaveAreasOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CaveAreasAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<Uuid> caveUuid = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CaveAreasCompanion(
                uuid: uuid,
                title: title,
                description: description,
                caveUuid: caveUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required String title,
                Value<String?> description = const Value.absent(),
                required Uuid caveUuid,
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CaveAreasCompanion.insert(
                uuid: uuid,
                title: title,
                description: description,
                caveUuid: caveUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $CaveAreasReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                caveUuid = false,
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
                cavePlacesRefs = false,
                rasterMapsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cavePlacesRefs) db.cavePlaces,
                    if (rasterMapsRefs) db.rasterMaps,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (caveUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveUuid,
                                    referencedTable: $CaveAreasReferences
                                        ._caveUuidTable(db),
                                    referencedColumn: $CaveAreasReferences
                                        ._caveUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable: $CaveAreasReferences
                                        ._createdByUserUuidTable(db),
                                    referencedColumn: $CaveAreasReferences
                                        ._createdByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable: $CaveAreasReferences
                                        ._lastModifiedByUserUuidTable(db),
                                    referencedColumn: $CaveAreasReferences
                                        ._lastModifiedByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cavePlacesRefs)
                        await $_getPrefetchedData<
                          CaveArea,
                          CaveAreas,
                          CavePlace
                        >(
                          currentTable: table,
                          referencedTable: $CaveAreasReferences
                              ._cavePlacesRefsTable(db),
                          managerFromTypedResult: (p0) => $CaveAreasReferences(
                            db,
                            table,
                            p0,
                          ).cavePlacesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.caveAreaUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (rasterMapsRefs)
                        await $_getPrefetchedData<
                          CaveArea,
                          CaveAreas,
                          RasterMap
                        >(
                          currentTable: table,
                          referencedTable: $CaveAreasReferences
                              ._rasterMapsRefsTable(db),
                          managerFromTypedResult: (p0) => $CaveAreasReferences(
                            db,
                            table,
                            p0,
                          ).rasterMapsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.caveAreaUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $CaveAreasProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CaveAreas,
      CaveArea,
      $CaveAreasFilterComposer,
      $CaveAreasOrderingComposer,
      $CaveAreasAnnotationComposer,
      $CaveAreasCreateCompanionBuilder,
      $CaveAreasUpdateCompanionBuilder,
      (CaveArea, $CaveAreasReferences),
      CaveArea,
      PrefetchHooks Function({
        bool caveUuid,
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
        bool cavePlacesRefs,
        bool rasterMapsRefs,
      })
    >;
typedef $SurfacePlacesCreateCompanionBuilder =
    SurfacePlacesCompanion Function({
      required Uuid uuid,
      required String title,
      Value<String?> description,
      Value<String?> type,
      Value<int?> surfacePlaceQrCodeIdentifier,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $SurfacePlacesUpdateCompanionBuilder =
    SurfacePlacesCompanion Function({
      Value<Uuid> uuid,
      Value<String> title,
      Value<String?> description,
      Value<String?> type,
      Value<int?> surfacePlaceQrCodeIdentifier,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $SurfacePlacesReferences
    extends BaseReferences<_$AppDatabase, SurfacePlaces, SurfacePlace> {
  $SurfacePlacesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.surfacePlaces.createdByUserUuid, db.users.uuid),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.surfacePlaces.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<CaveEntrances, List<CaveEntrance>>
  _caveEntrancesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.caveEntrances,
    aliasName: $_aliasNameGenerator(
      db.surfacePlaces.uuid,
      db.caveEntrances.surfacePlaceUuid,
    ),
  );

  $CaveEntrancesProcessedTableManager get caveEntrancesRefs {
    final manager = $CaveEntrancesTableManager($_db, $_db.caveEntrances).filter(
      (f) =>
          f.surfacePlaceUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
    );

    final cache = $_typedResult.readTableOrNull(_caveEntrancesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $SurfacePlacesFilterComposer
    extends Composer<_$AppDatabase, SurfacePlaces> {
  $SurfacePlacesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get surfacePlaceQrCodeIdentifier => $composableBuilder(
    column: $table.surfacePlaceQrCodeIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> caveEntrancesRefs(
    Expression<bool> Function($CaveEntrancesFilterComposer f) f,
  ) {
    final $CaveEntrancesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveEntrances,
      getReferencedColumn: (t) => t.surfacePlaceUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveEntrancesFilterComposer(
            $db: $db,
            $table: $db.caveEntrances,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SurfacePlacesOrderingComposer
    extends Composer<_$AppDatabase, SurfacePlaces> {
  $SurfacePlacesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get surfacePlaceQrCodeIdentifier => $composableBuilder(
    column: $table.surfacePlaceQrCodeIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $SurfacePlacesAnnotationComposer
    extends Composer<_$AppDatabase, SurfacePlaces> {
  $SurfacePlacesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<int> get surfacePlaceQrCodeIdentifier => $composableBuilder(
    column: $table.surfacePlaceQrCodeIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> caveEntrancesRefs<T extends Object>(
    Expression<T> Function($CaveEntrancesAnnotationComposer a) f,
  ) {
    final $CaveEntrancesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveEntrances,
      getReferencedColumn: (t) => t.surfacePlaceUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveEntrancesAnnotationComposer(
            $db: $db,
            $table: $db.caveEntrances,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $SurfacePlacesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          SurfacePlaces,
          SurfacePlace,
          $SurfacePlacesFilterComposer,
          $SurfacePlacesOrderingComposer,
          $SurfacePlacesAnnotationComposer,
          $SurfacePlacesCreateCompanionBuilder,
          $SurfacePlacesUpdateCompanionBuilder,
          (SurfacePlace, $SurfacePlacesReferences),
          SurfacePlace,
          PrefetchHooks Function({
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
            bool caveEntrancesRefs,
          })
        > {
  $SurfacePlacesTableManager(_$AppDatabase db, SurfacePlaces table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $SurfacePlacesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $SurfacePlacesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $SurfacePlacesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<int?> surfacePlaceQrCodeIdentifier = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurfacePlacesCompanion(
                uuid: uuid,
                title: title,
                description: description,
                type: type,
                surfacePlaceQrCodeIdentifier: surfacePlaceQrCodeIdentifier,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<int?> surfacePlaceQrCodeIdentifier = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SurfacePlacesCompanion.insert(
                uuid: uuid,
                title: title,
                description: description,
                type: type,
                surfacePlaceQrCodeIdentifier: surfacePlaceQrCodeIdentifier,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $SurfacePlacesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
                caveEntrancesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (caveEntrancesRefs) db.caveEntrances,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable: $SurfacePlacesReferences
                                        ._createdByUserUuidTable(db),
                                    referencedColumn: $SurfacePlacesReferences
                                        ._createdByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable: $SurfacePlacesReferences
                                        ._lastModifiedByUserUuidTable(db),
                                    referencedColumn: $SurfacePlacesReferences
                                        ._lastModifiedByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (caveEntrancesRefs)
                        await $_getPrefetchedData<
                          SurfacePlace,
                          SurfacePlaces,
                          CaveEntrance
                        >(
                          currentTable: table,
                          referencedTable: $SurfacePlacesReferences
                              ._caveEntrancesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $SurfacePlacesReferences(
                                db,
                                table,
                                p0,
                              ).caveEntrancesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.surfacePlaceUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $SurfacePlacesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      SurfacePlaces,
      SurfacePlace,
      $SurfacePlacesFilterComposer,
      $SurfacePlacesOrderingComposer,
      $SurfacePlacesAnnotationComposer,
      $SurfacePlacesCreateCompanionBuilder,
      $SurfacePlacesUpdateCompanionBuilder,
      (SurfacePlace, $SurfacePlacesReferences),
      SurfacePlace,
      PrefetchHooks Function({
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
        bool caveEntrancesRefs,
      })
    >;
typedef $CaveEntrancesCreateCompanionBuilder =
    CaveEntrancesCompanion Function({
      required Uuid uuid,
      required Uuid caveUuid,
      Value<Uuid?> surfacePlaceUuid,
      Value<int?> isMainEntrance,
      Value<String?> title,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $CaveEntrancesUpdateCompanionBuilder =
    CaveEntrancesCompanion Function({
      Value<Uuid> uuid,
      Value<Uuid> caveUuid,
      Value<Uuid?> surfacePlaceUuid,
      Value<int?> isMainEntrance,
      Value<String?> title,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $CaveEntrancesReferences
    extends BaseReferences<_$AppDatabase, CaveEntrances, CaveEntrance> {
  $CaveEntrancesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Caves _caveUuidTable(_$AppDatabase db) => db.caves.createAlias(
    $_aliasNameGenerator(db.caveEntrances.caveUuid, db.caves.uuid),
  );

  $CavesProcessedTableManager get caveUuid {
    final $_column = $_itemColumn<Uint8List>('cave_uuid')!;

    final manager = $CavesTableManager(
      $_db,
      $_db.caves,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static SurfacePlaces _surfacePlaceUuidTable(_$AppDatabase db) =>
      db.surfacePlaces.createAlias(
        $_aliasNameGenerator(
          db.caveEntrances.surfacePlaceUuid,
          db.surfacePlaces.uuid,
        ),
      );

  $SurfacePlacesProcessedTableManager? get surfacePlaceUuid {
    final $_column = $_itemColumn<Uint8List>('surface_place_uuid');
    if ($_column == null) return null;
    final manager = $SurfacePlacesTableManager(
      $_db,
      $_db.surfacePlaces,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surfacePlaceUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.caveEntrances.createdByUserUuid, db.users.uuid),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.caveEntrances.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CaveEntrancesFilterComposer
    extends Composer<_$AppDatabase, CaveEntrances> {
  $CaveEntrancesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get isMainEntrance => $composableBuilder(
    column: $table.isMainEntrance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $CavesFilterComposer get caveUuid {
    final $CavesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesFilterComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SurfacePlacesFilterComposer get surfacePlaceUuid {
    final $SurfacePlacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfacePlaceUuid,
      referencedTable: $db.surfacePlaces,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SurfacePlacesFilterComposer(
            $db: $db,
            $table: $db.surfacePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaveEntrancesOrderingComposer
    extends Composer<_$AppDatabase, CaveEntrances> {
  $CaveEntrancesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isMainEntrance => $composableBuilder(
    column: $table.isMainEntrance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $CavesOrderingComposer get caveUuid {
    final $CavesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesOrderingComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SurfacePlacesOrderingComposer get surfacePlaceUuid {
    final $SurfacePlacesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfacePlaceUuid,
      referencedTable: $db.surfacePlaces,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SurfacePlacesOrderingComposer(
            $db: $db,
            $table: $db.surfacePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaveEntrancesAnnotationComposer
    extends Composer<_$AppDatabase, CaveEntrances> {
  $CaveEntrancesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get isMainEntrance => $composableBuilder(
    column: $table.isMainEntrance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $CavesAnnotationComposer get caveUuid {
    final $CavesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesAnnotationComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $SurfacePlacesAnnotationComposer get surfacePlaceUuid {
    final $SurfacePlacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfacePlaceUuid,
      referencedTable: $db.surfacePlaces,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $SurfacePlacesAnnotationComposer(
            $db: $db,
            $table: $db.surfacePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaveEntrancesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CaveEntrances,
          CaveEntrance,
          $CaveEntrancesFilterComposer,
          $CaveEntrancesOrderingComposer,
          $CaveEntrancesAnnotationComposer,
          $CaveEntrancesCreateCompanionBuilder,
          $CaveEntrancesUpdateCompanionBuilder,
          (CaveEntrance, $CaveEntrancesReferences),
          CaveEntrance,
          PrefetchHooks Function({
            bool caveUuid,
            bool surfacePlaceUuid,
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
          })
        > {
  $CaveEntrancesTableManager(_$AppDatabase db, CaveEntrances table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CaveEntrancesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CaveEntrancesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CaveEntrancesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<Uuid> caveUuid = const Value.absent(),
                Value<Uuid?> surfacePlaceUuid = const Value.absent(),
                Value<int?> isMainEntrance = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CaveEntrancesCompanion(
                uuid: uuid,
                caveUuid: caveUuid,
                surfacePlaceUuid: surfacePlaceUuid,
                isMainEntrance: isMainEntrance,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required Uuid caveUuid,
                Value<Uuid?> surfacePlaceUuid = const Value.absent(),
                Value<int?> isMainEntrance = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CaveEntrancesCompanion.insert(
                uuid: uuid,
                caveUuid: caveUuid,
                surfacePlaceUuid: surfacePlaceUuid,
                isMainEntrance: isMainEntrance,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CaveEntrancesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                caveUuid = false,
                surfacePlaceUuid = false,
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (caveUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveUuid,
                                    referencedTable: $CaveEntrancesReferences
                                        ._caveUuidTable(db),
                                    referencedColumn: $CaveEntrancesReferences
                                        ._caveUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (surfacePlaceUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.surfacePlaceUuid,
                                    referencedTable: $CaveEntrancesReferences
                                        ._surfacePlaceUuidTable(db),
                                    referencedColumn: $CaveEntrancesReferences
                                        ._surfacePlaceUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable: $CaveEntrancesReferences
                                        ._createdByUserUuidTable(db),
                                    referencedColumn: $CaveEntrancesReferences
                                        ._createdByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable: $CaveEntrancesReferences
                                        ._lastModifiedByUserUuidTable(db),
                                    referencedColumn: $CaveEntrancesReferences
                                        ._lastModifiedByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $CaveEntrancesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CaveEntrances,
      CaveEntrance,
      $CaveEntrancesFilterComposer,
      $CaveEntrancesOrderingComposer,
      $CaveEntrancesAnnotationComposer,
      $CaveEntrancesCreateCompanionBuilder,
      $CaveEntrancesUpdateCompanionBuilder,
      (CaveEntrance, $CaveEntrancesReferences),
      CaveEntrance,
      PrefetchHooks Function({
        bool caveUuid,
        bool surfacePlaceUuid,
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
      })
    >;
typedef $CavePlacesCreateCompanionBuilder =
    CavePlacesCompanion Function({
      required Uuid uuid,
      required String title,
      Value<String?> description,
      required Uuid caveUuid,
      Value<int?> placeQrCodeIdentifier,
      Value<Uuid?> caveAreaUuid,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<double?> altitude,
      Value<double?> depthInCave,
      Value<int> isEntrance,
      Value<int> isMainEntrance,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $CavePlacesUpdateCompanionBuilder =
    CavePlacesCompanion Function({
      Value<Uuid> uuid,
      Value<String> title,
      Value<String?> description,
      Value<Uuid> caveUuid,
      Value<int?> placeQrCodeIdentifier,
      Value<Uuid?> caveAreaUuid,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<double?> altitude,
      Value<double?> depthInCave,
      Value<int> isEntrance,
      Value<int> isMainEntrance,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $CavePlacesReferences
    extends BaseReferences<_$AppDatabase, CavePlaces, CavePlace> {
  $CavePlacesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Caves _caveUuidTable(_$AppDatabase db) => db.caves.createAlias(
    $_aliasNameGenerator(db.cavePlaces.caveUuid, db.caves.uuid),
  );

  $CavesProcessedTableManager get caveUuid {
    final $_column = $_itemColumn<Uint8List>('cave_uuid')!;

    final manager = $CavesTableManager(
      $_db,
      $_db.caves,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static CaveAreas _caveAreaUuidTable(_$AppDatabase db) =>
      db.caveAreas.createAlias(
        $_aliasNameGenerator(db.cavePlaces.caveAreaUuid, db.caveAreas.uuid),
      );

  $CaveAreasProcessedTableManager? get caveAreaUuid {
    final $_column = $_itemColumn<Uint8List>('cave_area_uuid');
    if ($_column == null) return null;
    final manager = $CaveAreasTableManager(
      $_db,
      $_db.caveAreas,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveAreaUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.cavePlaces.createdByUserUuid, db.users.uuid),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.cavePlaces.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    CavePlaceToRasterMapDefinitions,
    List<CavePlaceToRasterMapDefinition>
  >
  _cavePlaceToRasterMapDefinitionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cavePlaceToRasterMapDefinitions,
        aliasName: $_aliasNameGenerator(
          db.cavePlaces.uuid,
          db.cavePlaceToRasterMapDefinitions.cavePlaceUuid,
        ),
      );

  $CavePlaceToRasterMapDefinitionsProcessedTableManager
  get cavePlaceToRasterMapDefinitionsRefs {
    final manager =
        $CavePlaceToRasterMapDefinitionsTableManager(
          $_db,
          $_db.cavePlaceToRasterMapDefinitions,
        ).filter(
          (f) =>
              f.cavePlaceUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _cavePlaceToRasterMapDefinitionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CaveTripPoints, List<CaveTripPoint>>
  _caveTripPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.caveTripPoints,
    aliasName: $_aliasNameGenerator(
      db.cavePlaces.uuid,
      db.caveTripPoints.cavePlaceUuid,
    ),
  );

  $CaveTripPointsProcessedTableManager get caveTripPointsRefs {
    final manager = $CaveTripPointsTableManager($_db, $_db.caveTripPoints)
        .filter(
          (f) =>
              f.cavePlaceUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(_caveTripPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CavePlacesFilterComposer extends Composer<_$AppDatabase, CavePlaces> {
  $CavePlacesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get placeQrCodeIdentifier => $composableBuilder(
    column: $table.placeQrCodeIdentifier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get depthInCave => $composableBuilder(
    column: $table.depthInCave,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isEntrance => $composableBuilder(
    column: $table.isEntrance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isMainEntrance => $composableBuilder(
    column: $table.isMainEntrance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $CavesFilterComposer get caveUuid {
    final $CavesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesFilterComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaveAreasFilterComposer get caveAreaUuid {
    final $CaveAreasFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaUuid,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveAreasFilterComposer(
            $db: $db,
            $table: $db.caveAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cavePlaceToRasterMapDefinitionsRefs(
    Expression<bool> Function($CavePlaceToRasterMapDefinitionsFilterComposer f)
    f,
  ) {
    final $CavePlaceToRasterMapDefinitionsFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.uuid,
          referencedTable: $db.cavePlaceToRasterMapDefinitions,
          getReferencedColumn: (t) => t.cavePlaceUuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $CavePlaceToRasterMapDefinitionsFilterComposer(
                $db: $db,
                $table: $db.cavePlaceToRasterMapDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> caveTripPointsRefs(
    Expression<bool> Function($CaveTripPointsFilterComposer f) f,
  ) {
    final $CaveTripPointsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveTripPoints,
      getReferencedColumn: (t) => t.cavePlaceUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripPointsFilterComposer(
            $db: $db,
            $table: $db.caveTripPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CavePlacesOrderingComposer extends Composer<_$AppDatabase, CavePlaces> {
  $CavePlacesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get placeQrCodeIdentifier => $composableBuilder(
    column: $table.placeQrCodeIdentifier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get altitude => $composableBuilder(
    column: $table.altitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get depthInCave => $composableBuilder(
    column: $table.depthInCave,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isEntrance => $composableBuilder(
    column: $table.isEntrance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isMainEntrance => $composableBuilder(
    column: $table.isMainEntrance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $CavesOrderingComposer get caveUuid {
    final $CavesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesOrderingComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaveAreasOrderingComposer get caveAreaUuid {
    final $CaveAreasOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaUuid,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveAreasOrderingComposer(
            $db: $db,
            $table: $db.caveAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CavePlacesAnnotationComposer
    extends Composer<_$AppDatabase, CavePlaces> {
  $CavePlacesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get placeQrCodeIdentifier => $composableBuilder(
    column: $table.placeQrCodeIdentifier,
    builder: (column) => column,
  );

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get altitude =>
      $composableBuilder(column: $table.altitude, builder: (column) => column);

  GeneratedColumn<double> get depthInCave => $composableBuilder(
    column: $table.depthInCave,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isEntrance => $composableBuilder(
    column: $table.isEntrance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get isMainEntrance => $composableBuilder(
    column: $table.isMainEntrance,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $CavesAnnotationComposer get caveUuid {
    final $CavesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesAnnotationComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaveAreasAnnotationComposer get caveAreaUuid {
    final $CaveAreasAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaUuid,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveAreasAnnotationComposer(
            $db: $db,
            $table: $db.caveAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cavePlaceToRasterMapDefinitionsRefs<T extends Object>(
    Expression<T> Function($CavePlaceToRasterMapDefinitionsAnnotationComposer a)
    f,
  ) {
    final $CavePlaceToRasterMapDefinitionsAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.uuid,
          referencedTable: $db.cavePlaceToRasterMapDefinitions,
          getReferencedColumn: (t) => t.cavePlaceUuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $CavePlaceToRasterMapDefinitionsAnnotationComposer(
                $db: $db,
                $table: $db.cavePlaceToRasterMapDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> caveTripPointsRefs<T extends Object>(
    Expression<T> Function($CaveTripPointsAnnotationComposer a) f,
  ) {
    final $CaveTripPointsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveTripPoints,
      getReferencedColumn: (t) => t.cavePlaceUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripPointsAnnotationComposer(
            $db: $db,
            $table: $db.caveTripPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $CavePlacesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CavePlaces,
          CavePlace,
          $CavePlacesFilterComposer,
          $CavePlacesOrderingComposer,
          $CavePlacesAnnotationComposer,
          $CavePlacesCreateCompanionBuilder,
          $CavePlacesUpdateCompanionBuilder,
          (CavePlace, $CavePlacesReferences),
          CavePlace,
          PrefetchHooks Function({
            bool caveUuid,
            bool caveAreaUuid,
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
            bool cavePlaceToRasterMapDefinitionsRefs,
            bool caveTripPointsRefs,
          })
        > {
  $CavePlacesTableManager(_$AppDatabase db, CavePlaces table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CavePlacesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CavePlacesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CavePlacesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<Uuid> caveUuid = const Value.absent(),
                Value<int?> placeQrCodeIdentifier = const Value.absent(),
                Value<Uuid?> caveAreaUuid = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<double?> depthInCave = const Value.absent(),
                Value<int> isEntrance = const Value.absent(),
                Value<int> isMainEntrance = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CavePlacesCompanion(
                uuid: uuid,
                title: title,
                description: description,
                caveUuid: caveUuid,
                placeQrCodeIdentifier: placeQrCodeIdentifier,
                caveAreaUuid: caveAreaUuid,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                depthInCave: depthInCave,
                isEntrance: isEntrance,
                isMainEntrance: isMainEntrance,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required String title,
                Value<String?> description = const Value.absent(),
                required Uuid caveUuid,
                Value<int?> placeQrCodeIdentifier = const Value.absent(),
                Value<Uuid?> caveAreaUuid = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> altitude = const Value.absent(),
                Value<double?> depthInCave = const Value.absent(),
                Value<int> isEntrance = const Value.absent(),
                Value<int> isMainEntrance = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CavePlacesCompanion.insert(
                uuid: uuid,
                title: title,
                description: description,
                caveUuid: caveUuid,
                placeQrCodeIdentifier: placeQrCodeIdentifier,
                caveAreaUuid: caveAreaUuid,
                latitude: latitude,
                longitude: longitude,
                altitude: altitude,
                depthInCave: depthInCave,
                isEntrance: isEntrance,
                isMainEntrance: isMainEntrance,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $CavePlacesReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                caveUuid = false,
                caveAreaUuid = false,
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
                cavePlaceToRasterMapDefinitionsRefs = false,
                caveTripPointsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cavePlaceToRasterMapDefinitionsRefs)
                      db.cavePlaceToRasterMapDefinitions,
                    if (caveTripPointsRefs) db.caveTripPoints,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (caveUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveUuid,
                                    referencedTable: $CavePlacesReferences
                                        ._caveUuidTable(db),
                                    referencedColumn: $CavePlacesReferences
                                        ._caveUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (caveAreaUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveAreaUuid,
                                    referencedTable: $CavePlacesReferences
                                        ._caveAreaUuidTable(db),
                                    referencedColumn: $CavePlacesReferences
                                        ._caveAreaUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable: $CavePlacesReferences
                                        ._createdByUserUuidTable(db),
                                    referencedColumn: $CavePlacesReferences
                                        ._createdByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable: $CavePlacesReferences
                                        ._lastModifiedByUserUuidTable(db),
                                    referencedColumn: $CavePlacesReferences
                                        ._lastModifiedByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cavePlaceToRasterMapDefinitionsRefs)
                        await $_getPrefetchedData<
                          CavePlace,
                          CavePlaces,
                          CavePlaceToRasterMapDefinition
                        >(
                          currentTable: table,
                          referencedTable: $CavePlacesReferences
                              ._cavePlaceToRasterMapDefinitionsRefsTable(db),
                          managerFromTypedResult: (p0) => $CavePlacesReferences(
                            db,
                            table,
                            p0,
                          ).cavePlaceToRasterMapDefinitionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cavePlaceUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (caveTripPointsRefs)
                        await $_getPrefetchedData<
                          CavePlace,
                          CavePlaces,
                          CaveTripPoint
                        >(
                          currentTable: table,
                          referencedTable: $CavePlacesReferences
                              ._caveTripPointsRefsTable(db),
                          managerFromTypedResult: (p0) => $CavePlacesReferences(
                            db,
                            table,
                            p0,
                          ).caveTripPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.cavePlaceUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $CavePlacesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CavePlaces,
      CavePlace,
      $CavePlacesFilterComposer,
      $CavePlacesOrderingComposer,
      $CavePlacesAnnotationComposer,
      $CavePlacesCreateCompanionBuilder,
      $CavePlacesUpdateCompanionBuilder,
      (CavePlace, $CavePlacesReferences),
      CavePlace,
      PrefetchHooks Function({
        bool caveUuid,
        bool caveAreaUuid,
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
        bool cavePlaceToRasterMapDefinitionsRefs,
        bool caveTripPointsRefs,
      })
    >;
typedef $RasterMapsCreateCompanionBuilder =
    RasterMapsCompanion Function({
      required Uuid uuid,
      required String title,
      required String mapType,
      required String fileName,
      required Uuid caveUuid,
      Value<Uuid?> caveAreaUuid,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $RasterMapsUpdateCompanionBuilder =
    RasterMapsCompanion Function({
      Value<Uuid> uuid,
      Value<String> title,
      Value<String> mapType,
      Value<String> fileName,
      Value<Uuid> caveUuid,
      Value<Uuid?> caveAreaUuid,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $RasterMapsReferences
    extends BaseReferences<_$AppDatabase, RasterMaps, RasterMap> {
  $RasterMapsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Caves _caveUuidTable(_$AppDatabase db) => db.caves.createAlias(
    $_aliasNameGenerator(db.rasterMaps.caveUuid, db.caves.uuid),
  );

  $CavesProcessedTableManager get caveUuid {
    final $_column = $_itemColumn<Uint8List>('cave_uuid')!;

    final manager = $CavesTableManager(
      $_db,
      $_db.caves,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static CaveAreas _caveAreaUuidTable(_$AppDatabase db) =>
      db.caveAreas.createAlias(
        $_aliasNameGenerator(db.rasterMaps.caveAreaUuid, db.caveAreas.uuid),
      );

  $CaveAreasProcessedTableManager? get caveAreaUuid {
    final $_column = $_itemColumn<Uint8List>('cave_area_uuid');
    if ($_column == null) return null;
    final manager = $CaveAreasTableManager(
      $_db,
      $_db.caveAreas,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveAreaUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.rasterMaps.createdByUserUuid, db.users.uuid),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.rasterMaps.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    CavePlaceToRasterMapDefinitions,
    List<CavePlaceToRasterMapDefinition>
  >
  _cavePlaceToRasterMapDefinitionsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.cavePlaceToRasterMapDefinitions,
        aliasName: $_aliasNameGenerator(
          db.rasterMaps.uuid,
          db.cavePlaceToRasterMapDefinitions.rasterMapUuid,
        ),
      );

  $CavePlaceToRasterMapDefinitionsProcessedTableManager
  get cavePlaceToRasterMapDefinitionsRefs {
    final manager =
        $CavePlaceToRasterMapDefinitionsTableManager(
          $_db,
          $_db.cavePlaceToRasterMapDefinitions,
        ).filter(
          (f) =>
              f.rasterMapUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _cavePlaceToRasterMapDefinitionsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $RasterMapsFilterComposer extends Composer<_$AppDatabase, RasterMaps> {
  $RasterMapsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mapType => $composableBuilder(
    column: $table.mapType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $CavesFilterComposer get caveUuid {
    final $CavesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesFilterComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaveAreasFilterComposer get caveAreaUuid {
    final $CaveAreasFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaUuid,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveAreasFilterComposer(
            $db: $db,
            $table: $db.caveAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> cavePlaceToRasterMapDefinitionsRefs(
    Expression<bool> Function($CavePlaceToRasterMapDefinitionsFilterComposer f)
    f,
  ) {
    final $CavePlaceToRasterMapDefinitionsFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.uuid,
          referencedTable: $db.cavePlaceToRasterMapDefinitions,
          getReferencedColumn: (t) => t.rasterMapUuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $CavePlaceToRasterMapDefinitionsFilterComposer(
                $db: $db,
                $table: $db.cavePlaceToRasterMapDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $RasterMapsOrderingComposer extends Composer<_$AppDatabase, RasterMaps> {
  $RasterMapsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mapType => $composableBuilder(
    column: $table.mapType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $CavesOrderingComposer get caveUuid {
    final $CavesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesOrderingComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaveAreasOrderingComposer get caveAreaUuid {
    final $CaveAreasOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaUuid,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveAreasOrderingComposer(
            $db: $db,
            $table: $db.caveAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $RasterMapsAnnotationComposer
    extends Composer<_$AppDatabase, RasterMaps> {
  $RasterMapsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get mapType =>
      $composableBuilder(column: $table.mapType, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $CavesAnnotationComposer get caveUuid {
    final $CavesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesAnnotationComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaveAreasAnnotationComposer get caveAreaUuid {
    final $CaveAreasAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaUuid,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveAreasAnnotationComposer(
            $db: $db,
            $table: $db.caveAreas,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> cavePlaceToRasterMapDefinitionsRefs<T extends Object>(
    Expression<T> Function($CavePlaceToRasterMapDefinitionsAnnotationComposer a)
    f,
  ) {
    final $CavePlaceToRasterMapDefinitionsAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.uuid,
          referencedTable: $db.cavePlaceToRasterMapDefinitions,
          getReferencedColumn: (t) => t.rasterMapUuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $CavePlaceToRasterMapDefinitionsAnnotationComposer(
                $db: $db,
                $table: $db.cavePlaceToRasterMapDefinitions,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $RasterMapsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          RasterMaps,
          RasterMap,
          $RasterMapsFilterComposer,
          $RasterMapsOrderingComposer,
          $RasterMapsAnnotationComposer,
          $RasterMapsCreateCompanionBuilder,
          $RasterMapsUpdateCompanionBuilder,
          (RasterMap, $RasterMapsReferences),
          RasterMap,
          PrefetchHooks Function({
            bool caveUuid,
            bool caveAreaUuid,
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
            bool cavePlaceToRasterMapDefinitionsRefs,
          })
        > {
  $RasterMapsTableManager(_$AppDatabase db, RasterMaps table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $RasterMapsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $RasterMapsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $RasterMapsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> mapType = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<Uuid> caveUuid = const Value.absent(),
                Value<Uuid?> caveAreaUuid = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RasterMapsCompanion(
                uuid: uuid,
                title: title,
                mapType: mapType,
                fileName: fileName,
                caveUuid: caveUuid,
                caveAreaUuid: caveAreaUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required String title,
                required String mapType,
                required String fileName,
                required Uuid caveUuid,
                Value<Uuid?> caveAreaUuid = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RasterMapsCompanion.insert(
                uuid: uuid,
                title: title,
                mapType: mapType,
                fileName: fileName,
                caveUuid: caveUuid,
                caveAreaUuid: caveAreaUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $RasterMapsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                caveUuid = false,
                caveAreaUuid = false,
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
                cavePlaceToRasterMapDefinitionsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (cavePlaceToRasterMapDefinitionsRefs)
                      db.cavePlaceToRasterMapDefinitions,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (caveUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveUuid,
                                    referencedTable: $RasterMapsReferences
                                        ._caveUuidTable(db),
                                    referencedColumn: $RasterMapsReferences
                                        ._caveUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (caveAreaUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveAreaUuid,
                                    referencedTable: $RasterMapsReferences
                                        ._caveAreaUuidTable(db),
                                    referencedColumn: $RasterMapsReferences
                                        ._caveAreaUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable: $RasterMapsReferences
                                        ._createdByUserUuidTable(db),
                                    referencedColumn: $RasterMapsReferences
                                        ._createdByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable: $RasterMapsReferences
                                        ._lastModifiedByUserUuidTable(db),
                                    referencedColumn: $RasterMapsReferences
                                        ._lastModifiedByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (cavePlaceToRasterMapDefinitionsRefs)
                        await $_getPrefetchedData<
                          RasterMap,
                          RasterMaps,
                          CavePlaceToRasterMapDefinition
                        >(
                          currentTable: table,
                          referencedTable: $RasterMapsReferences
                              ._cavePlaceToRasterMapDefinitionsRefsTable(db),
                          managerFromTypedResult: (p0) => $RasterMapsReferences(
                            db,
                            table,
                            p0,
                          ).cavePlaceToRasterMapDefinitionsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.rasterMapUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $RasterMapsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      RasterMaps,
      RasterMap,
      $RasterMapsFilterComposer,
      $RasterMapsOrderingComposer,
      $RasterMapsAnnotationComposer,
      $RasterMapsCreateCompanionBuilder,
      $RasterMapsUpdateCompanionBuilder,
      (RasterMap, $RasterMapsReferences),
      RasterMap,
      PrefetchHooks Function({
        bool caveUuid,
        bool caveAreaUuid,
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
        bool cavePlaceToRasterMapDefinitionsRefs,
      })
    >;
typedef $CavePlaceToRasterMapDefinitionsCreateCompanionBuilder =
    CavePlaceToRasterMapDefinitionsCompanion Function({
      required Uuid uuid,
      Value<int?> xCoordinate,
      Value<int?> yCoordinate,
      required Uuid cavePlaceUuid,
      required Uuid rasterMapUuid,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $CavePlaceToRasterMapDefinitionsUpdateCompanionBuilder =
    CavePlaceToRasterMapDefinitionsCompanion Function({
      Value<Uuid> uuid,
      Value<int?> xCoordinate,
      Value<int?> yCoordinate,
      Value<Uuid> cavePlaceUuid,
      Value<Uuid> rasterMapUuid,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $CavePlaceToRasterMapDefinitionsReferences
    extends
        BaseReferences<
          _$AppDatabase,
          CavePlaceToRasterMapDefinitions,
          CavePlaceToRasterMapDefinition
        > {
  $CavePlaceToRasterMapDefinitionsReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static CavePlaces _cavePlaceUuidTable(_$AppDatabase db) =>
      db.cavePlaces.createAlias(
        $_aliasNameGenerator(
          db.cavePlaceToRasterMapDefinitions.cavePlaceUuid,
          db.cavePlaces.uuid,
        ),
      );

  $CavePlacesProcessedTableManager get cavePlaceUuid {
    final $_column = $_itemColumn<Uint8List>('cave_place_uuid')!;

    final manager = $CavePlacesTableManager(
      $_db,
      $_db.cavePlaces,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cavePlaceUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static RasterMaps _rasterMapUuidTable(_$AppDatabase db) =>
      db.rasterMaps.createAlias(
        $_aliasNameGenerator(
          db.cavePlaceToRasterMapDefinitions.rasterMapUuid,
          db.rasterMaps.uuid,
        ),
      );

  $RasterMapsProcessedTableManager get rasterMapUuid {
    final $_column = $_itemColumn<Uint8List>('raster_map_uuid')!;

    final manager = $RasterMapsTableManager(
      $_db,
      $_db.rasterMaps,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rasterMapUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.cavePlaceToRasterMapDefinitions.createdByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.cavePlaceToRasterMapDefinitions.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CavePlaceToRasterMapDefinitionsFilterComposer
    extends Composer<_$AppDatabase, CavePlaceToRasterMapDefinitions> {
  $CavePlaceToRasterMapDefinitionsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get xCoordinate => $composableBuilder(
    column: $table.xCoordinate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get yCoordinate => $composableBuilder(
    column: $table.yCoordinate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $CavePlacesFilterComposer get cavePlaceUuid {
    final $CavePlacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cavePlaceUuid,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavePlacesFilterComposer(
            $db: $db,
            $table: $db.cavePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $RasterMapsFilterComposer get rasterMapUuid {
    final $RasterMapsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rasterMapUuid,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RasterMapsFilterComposer(
            $db: $db,
            $table: $db.rasterMaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CavePlaceToRasterMapDefinitionsOrderingComposer
    extends Composer<_$AppDatabase, CavePlaceToRasterMapDefinitions> {
  $CavePlaceToRasterMapDefinitionsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xCoordinate => $composableBuilder(
    column: $table.xCoordinate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get yCoordinate => $composableBuilder(
    column: $table.yCoordinate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $CavePlacesOrderingComposer get cavePlaceUuid {
    final $CavePlacesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cavePlaceUuid,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavePlacesOrderingComposer(
            $db: $db,
            $table: $db.cavePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $RasterMapsOrderingComposer get rasterMapUuid {
    final $RasterMapsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rasterMapUuid,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RasterMapsOrderingComposer(
            $db: $db,
            $table: $db.rasterMaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CavePlaceToRasterMapDefinitionsAnnotationComposer
    extends Composer<_$AppDatabase, CavePlaceToRasterMapDefinitions> {
  $CavePlaceToRasterMapDefinitionsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get xCoordinate => $composableBuilder(
    column: $table.xCoordinate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get yCoordinate => $composableBuilder(
    column: $table.yCoordinate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $CavePlacesAnnotationComposer get cavePlaceUuid {
    final $CavePlacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cavePlaceUuid,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavePlacesAnnotationComposer(
            $db: $db,
            $table: $db.cavePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $RasterMapsAnnotationComposer get rasterMapUuid {
    final $RasterMapsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rasterMapUuid,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $RasterMapsAnnotationComposer(
            $db: $db,
            $table: $db.rasterMaps,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CavePlaceToRasterMapDefinitionsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CavePlaceToRasterMapDefinitions,
          CavePlaceToRasterMapDefinition,
          $CavePlaceToRasterMapDefinitionsFilterComposer,
          $CavePlaceToRasterMapDefinitionsOrderingComposer,
          $CavePlaceToRasterMapDefinitionsAnnotationComposer,
          $CavePlaceToRasterMapDefinitionsCreateCompanionBuilder,
          $CavePlaceToRasterMapDefinitionsUpdateCompanionBuilder,
          (
            CavePlaceToRasterMapDefinition,
            $CavePlaceToRasterMapDefinitionsReferences,
          ),
          CavePlaceToRasterMapDefinition,
          PrefetchHooks Function({
            bool cavePlaceUuid,
            bool rasterMapUuid,
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
          })
        > {
  $CavePlaceToRasterMapDefinitionsTableManager(
    _$AppDatabase db,
    CavePlaceToRasterMapDefinitions table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CavePlaceToRasterMapDefinitionsFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $CavePlaceToRasterMapDefinitionsOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $CavePlaceToRasterMapDefinitionsAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<int?> xCoordinate = const Value.absent(),
                Value<int?> yCoordinate = const Value.absent(),
                Value<Uuid> cavePlaceUuid = const Value.absent(),
                Value<Uuid> rasterMapUuid = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CavePlaceToRasterMapDefinitionsCompanion(
                uuid: uuid,
                xCoordinate: xCoordinate,
                yCoordinate: yCoordinate,
                cavePlaceUuid: cavePlaceUuid,
                rasterMapUuid: rasterMapUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                Value<int?> xCoordinate = const Value.absent(),
                Value<int?> yCoordinate = const Value.absent(),
                required Uuid cavePlaceUuid,
                required Uuid rasterMapUuid,
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CavePlaceToRasterMapDefinitionsCompanion.insert(
                uuid: uuid,
                xCoordinate: xCoordinate,
                yCoordinate: yCoordinate,
                cavePlaceUuid: cavePlaceUuid,
                rasterMapUuid: rasterMapUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CavePlaceToRasterMapDefinitionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                cavePlaceUuid = false,
                rasterMapUuid = false,
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (cavePlaceUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cavePlaceUuid,
                                    referencedTable:
                                        $CavePlaceToRasterMapDefinitionsReferences
                                            ._cavePlaceUuidTable(db),
                                    referencedColumn:
                                        $CavePlaceToRasterMapDefinitionsReferences
                                            ._cavePlaceUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }
                        if (rasterMapUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.rasterMapUuid,
                                    referencedTable:
                                        $CavePlaceToRasterMapDefinitionsReferences
                                            ._rasterMapUuidTable(db),
                                    referencedColumn:
                                        $CavePlaceToRasterMapDefinitionsReferences
                                            ._rasterMapUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable:
                                        $CavePlaceToRasterMapDefinitionsReferences
                                            ._createdByUserUuidTable(db),
                                    referencedColumn:
                                        $CavePlaceToRasterMapDefinitionsReferences
                                            ._createdByUserUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable:
                                        $CavePlaceToRasterMapDefinitionsReferences
                                            ._lastModifiedByUserUuidTable(db),
                                    referencedColumn:
                                        $CavePlaceToRasterMapDefinitionsReferences
                                            ._lastModifiedByUserUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $CavePlaceToRasterMapDefinitionsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CavePlaceToRasterMapDefinitions,
      CavePlaceToRasterMapDefinition,
      $CavePlaceToRasterMapDefinitionsFilterComposer,
      $CavePlaceToRasterMapDefinitionsOrderingComposer,
      $CavePlaceToRasterMapDefinitionsAnnotationComposer,
      $CavePlaceToRasterMapDefinitionsCreateCompanionBuilder,
      $CavePlaceToRasterMapDefinitionsUpdateCompanionBuilder,
      (
        CavePlaceToRasterMapDefinition,
        $CavePlaceToRasterMapDefinitionsReferences,
      ),
      CavePlaceToRasterMapDefinition,
      PrefetchHooks Function({
        bool cavePlaceUuid,
        bool rasterMapUuid,
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
      })
    >;
typedef $DocumentationFilesCreateCompanionBuilder =
    DocumentationFilesCompanion Function({
      required Uuid uuid,
      required String title,
      Value<String?> description,
      required String fileName,
      required int fileSize,
      Value<String?> fileHash,
      required String fileType,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $DocumentationFilesUpdateCompanionBuilder =
    DocumentationFilesCompanion Function({
      Value<Uuid> uuid,
      Value<String> title,
      Value<String?> description,
      Value<String> fileName,
      Value<int> fileSize,
      Value<String?> fileHash,
      Value<String> fileType,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $DocumentationFilesReferences
    extends
        BaseReferences<_$AppDatabase, DocumentationFiles, DocumentationFile> {
  $DocumentationFilesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.documentationFiles.createdByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.documentationFiles.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    DocumentationFilesToGeofeatures,
    List<DocumentationFilesToGeofeature>
  >
  _documentationFilesToGeofeaturesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.documentationFilesToGeofeatures,
        aliasName: $_aliasNameGenerator(
          db.documentationFiles.uuid,
          db.documentationFilesToGeofeatures.documentationFileUuid,
        ),
      );

  $DocumentationFilesToGeofeaturesProcessedTableManager
  get documentationFilesToGeofeaturesRefs {
    final manager =
        $DocumentationFilesToGeofeaturesTableManager(
          $_db,
          $_db.documentationFilesToGeofeatures,
        ).filter(
          (f) => f.documentationFileUuid.uuid.sqlEquals(
            $_itemColumn<Uint8List>('uuid')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _documentationFilesToGeofeaturesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    DocumentationFilesToCaveTrips,
    List<DocumentationFilesToCaveTrip>
  >
  _documentationFilesToCaveTripsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.documentationFilesToCaveTrips,
        aliasName: $_aliasNameGenerator(
          db.documentationFiles.uuid,
          db.documentationFilesToCaveTrips.documentationFileUuid,
        ),
      );

  $DocumentationFilesToCaveTripsProcessedTableManager
  get documentationFilesToCaveTripsRefs {
    final manager =
        $DocumentationFilesToCaveTripsTableManager(
          $_db,
          $_db.documentationFilesToCaveTrips,
        ).filter(
          (f) => f.documentationFileUuid.uuid.sqlEquals(
            $_itemColumn<Uint8List>('uuid')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(
      _documentationFilesToCaveTripsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $DocumentationFilesFilterComposer
    extends Composer<_$AppDatabase, DocumentationFiles> {
  $DocumentationFilesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> documentationFilesToGeofeaturesRefs(
    Expression<bool> Function($DocumentationFilesToGeofeaturesFilterComposer f)
    f,
  ) {
    final $DocumentationFilesToGeofeaturesFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.uuid,
          referencedTable: $db.documentationFilesToGeofeatures,
          getReferencedColumn: (t) => t.documentationFileUuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $DocumentationFilesToGeofeaturesFilterComposer(
                $db: $db,
                $table: $db.documentationFilesToGeofeatures,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<bool> documentationFilesToCaveTripsRefs(
    Expression<bool> Function($DocumentationFilesToCaveTripsFilterComposer f) f,
  ) {
    final $DocumentationFilesToCaveTripsFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.uuid,
          referencedTable: $db.documentationFilesToCaveTrips,
          getReferencedColumn: (t) => t.documentationFileUuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $DocumentationFilesToCaveTripsFilterComposer(
                $db: $db,
                $table: $db.documentationFilesToCaveTrips,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $DocumentationFilesOrderingComposer
    extends Composer<_$AppDatabase, DocumentationFiles> {
  $DocumentationFilesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileHash => $composableBuilder(
    column: $table.fileHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileType => $composableBuilder(
    column: $table.fileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DocumentationFilesAnnotationComposer
    extends Composer<_$AppDatabase, DocumentationFiles> {
  $DocumentationFilesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get fileHash =>
      $composableBuilder(column: $table.fileHash, builder: (column) => column);

  GeneratedColumn<String> get fileType =>
      $composableBuilder(column: $table.fileType, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> documentationFilesToGeofeaturesRefs<T extends Object>(
    Expression<T> Function($DocumentationFilesToGeofeaturesAnnotationComposer a)
    f,
  ) {
    final $DocumentationFilesToGeofeaturesAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.uuid,
          referencedTable: $db.documentationFilesToGeofeatures,
          getReferencedColumn: (t) => t.documentationFileUuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $DocumentationFilesToGeofeaturesAnnotationComposer(
                $db: $db,
                $table: $db.documentationFilesToGeofeatures,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> documentationFilesToCaveTripsRefs<T extends Object>(
    Expression<T> Function($DocumentationFilesToCaveTripsAnnotationComposer a)
    f,
  ) {
    final $DocumentationFilesToCaveTripsAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.uuid,
          referencedTable: $db.documentationFilesToCaveTrips,
          getReferencedColumn: (t) => t.documentationFileUuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $DocumentationFilesToCaveTripsAnnotationComposer(
                $db: $db,
                $table: $db.documentationFilesToCaveTrips,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $DocumentationFilesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          DocumentationFiles,
          DocumentationFile,
          $DocumentationFilesFilterComposer,
          $DocumentationFilesOrderingComposer,
          $DocumentationFilesAnnotationComposer,
          $DocumentationFilesCreateCompanionBuilder,
          $DocumentationFilesUpdateCompanionBuilder,
          (DocumentationFile, $DocumentationFilesReferences),
          DocumentationFile,
          PrefetchHooks Function({
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
            bool documentationFilesToGeofeaturesRefs,
            bool documentationFilesToCaveTripsRefs,
          })
        > {
  $DocumentationFilesTableManager(_$AppDatabase db, DocumentationFiles table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DocumentationFilesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $DocumentationFilesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $DocumentationFilesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentationFilesCompanion(
                uuid: uuid,
                title: title,
                description: description,
                fileName: fileName,
                fileSize: fileSize,
                fileHash: fileHash,
                fileType: fileType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required String title,
                Value<String?> description = const Value.absent(),
                required String fileName,
                required int fileSize,
                Value<String?> fileHash = const Value.absent(),
                required String fileType,
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentationFilesCompanion.insert(
                uuid: uuid,
                title: title,
                description: description,
                fileName: fileName,
                fileSize: fileSize,
                fileHash: fileHash,
                fileType: fileType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $DocumentationFilesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
                documentationFilesToGeofeaturesRefs = false,
                documentationFilesToCaveTripsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (documentationFilesToGeofeaturesRefs)
                      db.documentationFilesToGeofeatures,
                    if (documentationFilesToCaveTripsRefs)
                      db.documentationFilesToCaveTrips,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable:
                                        $DocumentationFilesReferences
                                            ._createdByUserUuidTable(db),
                                    referencedColumn:
                                        $DocumentationFilesReferences
                                            ._createdByUserUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable:
                                        $DocumentationFilesReferences
                                            ._lastModifiedByUserUuidTable(db),
                                    referencedColumn:
                                        $DocumentationFilesReferences
                                            ._lastModifiedByUserUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (documentationFilesToGeofeaturesRefs)
                        await $_getPrefetchedData<
                          DocumentationFile,
                          DocumentationFiles,
                          DocumentationFilesToGeofeature
                        >(
                          currentTable: table,
                          referencedTable: $DocumentationFilesReferences
                              ._documentationFilesToGeofeaturesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $DocumentationFilesReferences(
                                db,
                                table,
                                p0,
                              ).documentationFilesToGeofeaturesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.documentationFileUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (documentationFilesToCaveTripsRefs)
                        await $_getPrefetchedData<
                          DocumentationFile,
                          DocumentationFiles,
                          DocumentationFilesToCaveTrip
                        >(
                          currentTable: table,
                          referencedTable: $DocumentationFilesReferences
                              ._documentationFilesToCaveTripsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $DocumentationFilesReferences(
                                db,
                                table,
                                p0,
                              ).documentationFilesToCaveTripsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.documentationFileUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $DocumentationFilesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      DocumentationFiles,
      DocumentationFile,
      $DocumentationFilesFilterComposer,
      $DocumentationFilesOrderingComposer,
      $DocumentationFilesAnnotationComposer,
      $DocumentationFilesCreateCompanionBuilder,
      $DocumentationFilesUpdateCompanionBuilder,
      (DocumentationFile, $DocumentationFilesReferences),
      DocumentationFile,
      PrefetchHooks Function({
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
        bool documentationFilesToGeofeaturesRefs,
        bool documentationFilesToCaveTripsRefs,
      })
    >;
typedef $DocumentationFilesToGeofeaturesCreateCompanionBuilder =
    DocumentationFilesToGeofeaturesCompanion Function({
      required Uuid uuid,
      Value<Uuid?> geofeatureUuid,
      required String geofeatureType,
      required Uuid documentationFileUuid,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $DocumentationFilesToGeofeaturesUpdateCompanionBuilder =
    DocumentationFilesToGeofeaturesCompanion Function({
      Value<Uuid> uuid,
      Value<Uuid?> geofeatureUuid,
      Value<String> geofeatureType,
      Value<Uuid> documentationFileUuid,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $DocumentationFilesToGeofeaturesReferences
    extends
        BaseReferences<
          _$AppDatabase,
          DocumentationFilesToGeofeatures,
          DocumentationFilesToGeofeature
        > {
  $DocumentationFilesToGeofeaturesReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static DocumentationFiles _documentationFileUuidTable(_$AppDatabase db) =>
      db.documentationFiles.createAlias(
        $_aliasNameGenerator(
          db.documentationFilesToGeofeatures.documentationFileUuid,
          db.documentationFiles.uuid,
        ),
      );

  $DocumentationFilesProcessedTableManager get documentationFileUuid {
    final $_column = $_itemColumn<Uint8List>('documentation_file_uuid')!;

    final manager = $DocumentationFilesTableManager(
      $_db,
      $_db.documentationFiles,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _documentationFileUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.documentationFilesToGeofeatures.createdByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.documentationFilesToGeofeatures.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DocumentationFilesToGeofeaturesFilterComposer
    extends Composer<_$AppDatabase, DocumentationFilesToGeofeatures> {
  $DocumentationFilesToGeofeaturesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<Uuid?, Uuid, Uint8List> get geofeatureUuid =>
      $composableBuilder(
        column: $table.geofeatureUuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get geofeatureType => $composableBuilder(
    column: $table.geofeatureType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $DocumentationFilesFilterComposer get documentationFileUuid {
    final $DocumentationFilesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentationFileUuid,
      referencedTable: $db.documentationFiles,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DocumentationFilesFilterComposer(
            $db: $db,
            $table: $db.documentationFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DocumentationFilesToGeofeaturesOrderingComposer
    extends Composer<_$AppDatabase, DocumentationFilesToGeofeatures> {
  $DocumentationFilesToGeofeaturesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get geofeatureUuid => $composableBuilder(
    column: $table.geofeatureUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geofeatureType => $composableBuilder(
    column: $table.geofeatureType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $DocumentationFilesOrderingComposer get documentationFileUuid {
    final $DocumentationFilesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentationFileUuid,
      referencedTable: $db.documentationFiles,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DocumentationFilesOrderingComposer(
            $db: $db,
            $table: $db.documentationFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DocumentationFilesToGeofeaturesAnnotationComposer
    extends Composer<_$AppDatabase, DocumentationFilesToGeofeatures> {
  $DocumentationFilesToGeofeaturesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Uuid?, Uint8List> get geofeatureUuid =>
      $composableBuilder(
        column: $table.geofeatureUuid,
        builder: (column) => column,
      );

  GeneratedColumn<String> get geofeatureType => $composableBuilder(
    column: $table.geofeatureType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $DocumentationFilesAnnotationComposer get documentationFileUuid {
    final $DocumentationFilesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentationFileUuid,
      referencedTable: $db.documentationFiles,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DocumentationFilesAnnotationComposer(
            $db: $db,
            $table: $db.documentationFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DocumentationFilesToGeofeaturesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          DocumentationFilesToGeofeatures,
          DocumentationFilesToGeofeature,
          $DocumentationFilesToGeofeaturesFilterComposer,
          $DocumentationFilesToGeofeaturesOrderingComposer,
          $DocumentationFilesToGeofeaturesAnnotationComposer,
          $DocumentationFilesToGeofeaturesCreateCompanionBuilder,
          $DocumentationFilesToGeofeaturesUpdateCompanionBuilder,
          (
            DocumentationFilesToGeofeature,
            $DocumentationFilesToGeofeaturesReferences,
          ),
          DocumentationFilesToGeofeature,
          PrefetchHooks Function({
            bool documentationFileUuid,
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
          })
        > {
  $DocumentationFilesToGeofeaturesTableManager(
    _$AppDatabase db,
    DocumentationFilesToGeofeatures table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DocumentationFilesToGeofeaturesFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $DocumentationFilesToGeofeaturesOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $DocumentationFilesToGeofeaturesAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<Uuid?> geofeatureUuid = const Value.absent(),
                Value<String> geofeatureType = const Value.absent(),
                Value<Uuid> documentationFileUuid = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentationFilesToGeofeaturesCompanion(
                uuid: uuid,
                geofeatureUuid: geofeatureUuid,
                geofeatureType: geofeatureType,
                documentationFileUuid: documentationFileUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                Value<Uuid?> geofeatureUuid = const Value.absent(),
                required String geofeatureType,
                required Uuid documentationFileUuid,
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentationFilesToGeofeaturesCompanion.insert(
                uuid: uuid,
                geofeatureUuid: geofeatureUuid,
                geofeatureType: geofeatureType,
                documentationFileUuid: documentationFileUuid,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $DocumentationFilesToGeofeaturesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                documentationFileUuid = false,
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (documentationFileUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.documentationFileUuid,
                                    referencedTable:
                                        $DocumentationFilesToGeofeaturesReferences
                                            ._documentationFileUuidTable(db),
                                    referencedColumn:
                                        $DocumentationFilesToGeofeaturesReferences
                                            ._documentationFileUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable:
                                        $DocumentationFilesToGeofeaturesReferences
                                            ._createdByUserUuidTable(db),
                                    referencedColumn:
                                        $DocumentationFilesToGeofeaturesReferences
                                            ._createdByUserUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable:
                                        $DocumentationFilesToGeofeaturesReferences
                                            ._lastModifiedByUserUuidTable(db),
                                    referencedColumn:
                                        $DocumentationFilesToGeofeaturesReferences
                                            ._lastModifiedByUserUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $DocumentationFilesToGeofeaturesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      DocumentationFilesToGeofeatures,
      DocumentationFilesToGeofeature,
      $DocumentationFilesToGeofeaturesFilterComposer,
      $DocumentationFilesToGeofeaturesOrderingComposer,
      $DocumentationFilesToGeofeaturesAnnotationComposer,
      $DocumentationFilesToGeofeaturesCreateCompanionBuilder,
      $DocumentationFilesToGeofeaturesUpdateCompanionBuilder,
      (
        DocumentationFilesToGeofeature,
        $DocumentationFilesToGeofeaturesReferences,
      ),
      DocumentationFilesToGeofeature,
      PrefetchHooks Function({
        bool documentationFileUuid,
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
      })
    >;
typedef $ConfigurationsCreateCompanionBuilder =
    ConfigurationsCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> value,
      Value<int?> createdAt,
      Value<int?> updatedAt,
    });
typedef $ConfigurationsUpdateCompanionBuilder =
    ConfigurationsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> value,
      Value<int?> createdAt,
      Value<int?> updatedAt,
    });

class $ConfigurationsFilterComposer
    extends Composer<_$AppDatabase, Configurations> {
  $ConfigurationsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $ConfigurationsOrderingComposer
    extends Composer<_$AppDatabase, Configurations> {
  $ConfigurationsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $ConfigurationsAnnotationComposer
    extends Composer<_$AppDatabase, Configurations> {
  $ConfigurationsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $ConfigurationsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          Configurations,
          Configuration,
          $ConfigurationsFilterComposer,
          $ConfigurationsOrderingComposer,
          $ConfigurationsAnnotationComposer,
          $ConfigurationsCreateCompanionBuilder,
          $ConfigurationsUpdateCompanionBuilder,
          (
            Configuration,
            BaseReferences<_$AppDatabase, Configurations, Configuration>,
          ),
          Configuration,
          PrefetchHooks Function()
        > {
  $ConfigurationsTableManager(_$AppDatabase db, Configurations table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ConfigurationsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ConfigurationsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ConfigurationsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
              }) => ConfigurationsCompanion(
                id: id,
                title: title,
                value: value,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> value = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
              }) => ConfigurationsCompanion.insert(
                id: id,
                title: title,
                value: value,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $ConfigurationsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      Configurations,
      Configuration,
      $ConfigurationsFilterComposer,
      $ConfigurationsOrderingComposer,
      $ConfigurationsAnnotationComposer,
      $ConfigurationsCreateCompanionBuilder,
      $ConfigurationsUpdateCompanionBuilder,
      (
        Configuration,
        BaseReferences<_$AppDatabase, Configurations, Configuration>,
      ),
      Configuration,
      PrefetchHooks Function()
    >;
typedef $CaveTripsCreateCompanionBuilder =
    CaveTripsCompanion Function({
      required Uuid uuid,
      required Uuid caveUuid,
      required String title,
      Value<String?> description,
      required int tripStartedAt,
      Value<int?> tripEndedAt,
      Value<String?> log,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $CaveTripsUpdateCompanionBuilder =
    CaveTripsCompanion Function({
      Value<Uuid> uuid,
      Value<Uuid> caveUuid,
      Value<String> title,
      Value<String?> description,
      Value<int> tripStartedAt,
      Value<int?> tripEndedAt,
      Value<String?> log,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $CaveTripsReferences
    extends BaseReferences<_$AppDatabase, CaveTrips, CaveTrip> {
  $CaveTripsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Caves _caveUuidTable(_$AppDatabase db) => db.caves.createAlias(
    $_aliasNameGenerator(db.caveTrips.caveUuid, db.caves.uuid),
  );

  $CavesProcessedTableManager get caveUuid {
    final $_column = $_itemColumn<Uint8List>('cave_uuid')!;

    final manager = $CavesTableManager(
      $_db,
      $_db.caves,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.caveTrips.createdByUserUuid, db.users.uuid),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.caveTrips.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<CaveTripPoints, List<CaveTripPoint>>
  _caveTripPointsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.caveTripPoints,
    aliasName: $_aliasNameGenerator(
      db.caveTrips.uuid,
      db.caveTripPoints.caveTripUuid,
    ),
  );

  $CaveTripPointsProcessedTableManager get caveTripPointsRefs {
    final manager = $CaveTripPointsTableManager($_db, $_db.caveTripPoints)
        .filter(
          (f) =>
              f.caveTripUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(_caveTripPointsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    DocumentationFilesToCaveTrips,
    List<DocumentationFilesToCaveTrip>
  >
  _documentationFilesToCaveTripsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.documentationFilesToCaveTrips,
        aliasName: $_aliasNameGenerator(
          db.caveTrips.uuid,
          db.documentationFilesToCaveTrips.caveTripUuid,
        ),
      );

  $DocumentationFilesToCaveTripsProcessedTableManager
  get documentationFilesToCaveTripsRefs {
    final manager =
        $DocumentationFilesToCaveTripsTableManager(
          $_db,
          $_db.documentationFilesToCaveTrips,
        ).filter(
          (f) =>
              f.caveTripUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _documentationFilesToCaveTripsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $CaveTripsFilterComposer extends Composer<_$AppDatabase, CaveTrips> {
  $CaveTripsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tripStartedAt => $composableBuilder(
    column: $table.tripStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tripEndedAt => $composableBuilder(
    column: $table.tripEndedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get log => $composableBuilder(
    column: $table.log,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $CavesFilterComposer get caveUuid {
    final $CavesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesFilterComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> caveTripPointsRefs(
    Expression<bool> Function($CaveTripPointsFilterComposer f) f,
  ) {
    final $CaveTripPointsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveTripPoints,
      getReferencedColumn: (t) => t.caveTripUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripPointsFilterComposer(
            $db: $db,
            $table: $db.caveTripPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> documentationFilesToCaveTripsRefs(
    Expression<bool> Function($DocumentationFilesToCaveTripsFilterComposer f) f,
  ) {
    final $DocumentationFilesToCaveTripsFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.uuid,
          referencedTable: $db.documentationFilesToCaveTrips,
          getReferencedColumn: (t) => t.caveTripUuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $DocumentationFilesToCaveTripsFilterComposer(
                $db: $db,
                $table: $db.documentationFilesToCaveTrips,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $CaveTripsOrderingComposer extends Composer<_$AppDatabase, CaveTrips> {
  $CaveTripsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tripStartedAt => $composableBuilder(
    column: $table.tripStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tripEndedAt => $composableBuilder(
    column: $table.tripEndedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get log => $composableBuilder(
    column: $table.log,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $CavesOrderingComposer get caveUuid {
    final $CavesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesOrderingComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaveTripsAnnotationComposer extends Composer<_$AppDatabase, CaveTrips> {
  $CaveTripsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tripStartedAt => $composableBuilder(
    column: $table.tripStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tripEndedAt => $composableBuilder(
    column: $table.tripEndedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get log =>
      $composableBuilder(column: $table.log, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $CavesAnnotationComposer get caveUuid {
    final $CavesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveUuid,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavesAnnotationComposer(
            $db: $db,
            $table: $db.caves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> caveTripPointsRefs<T extends Object>(
    Expression<T> Function($CaveTripPointsAnnotationComposer a) f,
  ) {
    final $CaveTripPointsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.caveTripPoints,
      getReferencedColumn: (t) => t.caveTripUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripPointsAnnotationComposer(
            $db: $db,
            $table: $db.caveTripPoints,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> documentationFilesToCaveTripsRefs<T extends Object>(
    Expression<T> Function($DocumentationFilesToCaveTripsAnnotationComposer a)
    f,
  ) {
    final $DocumentationFilesToCaveTripsAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.uuid,
          referencedTable: $db.documentationFilesToCaveTrips,
          getReferencedColumn: (t) => t.caveTripUuid,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $DocumentationFilesToCaveTripsAnnotationComposer(
                $db: $db,
                $table: $db.documentationFilesToCaveTrips,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $CaveTripsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CaveTrips,
          CaveTrip,
          $CaveTripsFilterComposer,
          $CaveTripsOrderingComposer,
          $CaveTripsAnnotationComposer,
          $CaveTripsCreateCompanionBuilder,
          $CaveTripsUpdateCompanionBuilder,
          (CaveTrip, $CaveTripsReferences),
          CaveTrip,
          PrefetchHooks Function({
            bool caveUuid,
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
            bool caveTripPointsRefs,
            bool documentationFilesToCaveTripsRefs,
          })
        > {
  $CaveTripsTableManager(_$AppDatabase db, CaveTrips table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CaveTripsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CaveTripsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CaveTripsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<Uuid> caveUuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> tripStartedAt = const Value.absent(),
                Value<int?> tripEndedAt = const Value.absent(),
                Value<String?> log = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CaveTripsCompanion(
                uuid: uuid,
                caveUuid: caveUuid,
                title: title,
                description: description,
                tripStartedAt: tripStartedAt,
                tripEndedAt: tripEndedAt,
                log: log,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required Uuid caveUuid,
                required String title,
                Value<String?> description = const Value.absent(),
                required int tripStartedAt,
                Value<int?> tripEndedAt = const Value.absent(),
                Value<String?> log = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CaveTripsCompanion.insert(
                uuid: uuid,
                caveUuid: caveUuid,
                title: title,
                description: description,
                tripStartedAt: tripStartedAt,
                tripEndedAt: tripEndedAt,
                log: log,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $CaveTripsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                caveUuid = false,
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
                caveTripPointsRefs = false,
                documentationFilesToCaveTripsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (caveTripPointsRefs) db.caveTripPoints,
                    if (documentationFilesToCaveTripsRefs)
                      db.documentationFilesToCaveTrips,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (caveUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveUuid,
                                    referencedTable: $CaveTripsReferences
                                        ._caveUuidTable(db),
                                    referencedColumn: $CaveTripsReferences
                                        ._caveUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable: $CaveTripsReferences
                                        ._createdByUserUuidTable(db),
                                    referencedColumn: $CaveTripsReferences
                                        ._createdByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable: $CaveTripsReferences
                                        ._lastModifiedByUserUuidTable(db),
                                    referencedColumn: $CaveTripsReferences
                                        ._lastModifiedByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (caveTripPointsRefs)
                        await $_getPrefetchedData<
                          CaveTrip,
                          CaveTrips,
                          CaveTripPoint
                        >(
                          currentTable: table,
                          referencedTable: $CaveTripsReferences
                              ._caveTripPointsRefsTable(db),
                          managerFromTypedResult: (p0) => $CaveTripsReferences(
                            db,
                            table,
                            p0,
                          ).caveTripPointsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.caveTripUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                      if (documentationFilesToCaveTripsRefs)
                        await $_getPrefetchedData<
                          CaveTrip,
                          CaveTrips,
                          DocumentationFilesToCaveTrip
                        >(
                          currentTable: table,
                          referencedTable: $CaveTripsReferences
                              ._documentationFilesToCaveTripsRefsTable(db),
                          managerFromTypedResult: (p0) => $CaveTripsReferences(
                            db,
                            table,
                            p0,
                          ).documentationFilesToCaveTripsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.caveTripUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $CaveTripsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CaveTrips,
      CaveTrip,
      $CaveTripsFilterComposer,
      $CaveTripsOrderingComposer,
      $CaveTripsAnnotationComposer,
      $CaveTripsCreateCompanionBuilder,
      $CaveTripsUpdateCompanionBuilder,
      (CaveTrip, $CaveTripsReferences),
      CaveTrip,
      PrefetchHooks Function({
        bool caveUuid,
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
        bool caveTripPointsRefs,
        bool documentationFilesToCaveTripsRefs,
      })
    >;
typedef $CaveTripPointsCreateCompanionBuilder =
    CaveTripPointsCompanion Function({
      required Uuid uuid,
      required Uuid caveTripUuid,
      Value<Uuid?> cavePlaceUuid,
      required int scannedAt,
      Value<String?> notes,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $CaveTripPointsUpdateCompanionBuilder =
    CaveTripPointsCompanion Function({
      Value<Uuid> uuid,
      Value<Uuid> caveTripUuid,
      Value<Uuid?> cavePlaceUuid,
      Value<int> scannedAt,
      Value<String?> notes,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $CaveTripPointsReferences
    extends BaseReferences<_$AppDatabase, CaveTripPoints, CaveTripPoint> {
  $CaveTripPointsReferences(super.$_db, super.$_table, super.$_typedResult);

  static CaveTrips _caveTripUuidTable(_$AppDatabase db) =>
      db.caveTrips.createAlias(
        $_aliasNameGenerator(db.caveTripPoints.caveTripUuid, db.caveTrips.uuid),
      );

  $CaveTripsProcessedTableManager get caveTripUuid {
    final $_column = $_itemColumn<Uint8List>('cave_trip_uuid')!;

    final manager = $CaveTripsTableManager(
      $_db,
      $_db.caveTrips,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveTripUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static CavePlaces _cavePlaceUuidTable(_$AppDatabase db) =>
      db.cavePlaces.createAlias(
        $_aliasNameGenerator(
          db.caveTripPoints.cavePlaceUuid,
          db.cavePlaces.uuid,
        ),
      );

  $CavePlacesProcessedTableManager? get cavePlaceUuid {
    final $_column = $_itemColumn<Uint8List>('cave_place_uuid');
    if ($_column == null) return null;
    final manager = $CavePlacesTableManager(
      $_db,
      $_db.cavePlaces,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cavePlaceUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.caveTripPoints.createdByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.caveTripPoints.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $CaveTripPointsFilterComposer
    extends Composer<_$AppDatabase, CaveTripPoints> {
  $CaveTripPointsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $CaveTripsFilterComposer get caveTripUuid {
    final $CaveTripsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveTripUuid,
      referencedTable: $db.caveTrips,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripsFilterComposer(
            $db: $db,
            $table: $db.caveTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CavePlacesFilterComposer get cavePlaceUuid {
    final $CavePlacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cavePlaceUuid,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavePlacesFilterComposer(
            $db: $db,
            $table: $db.cavePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaveTripPointsOrderingComposer
    extends Composer<_$AppDatabase, CaveTripPoints> {
  $CaveTripPointsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scannedAt => $composableBuilder(
    column: $table.scannedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $CaveTripsOrderingComposer get caveTripUuid {
    final $CaveTripsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveTripUuid,
      referencedTable: $db.caveTrips,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripsOrderingComposer(
            $db: $db,
            $table: $db.caveTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CavePlacesOrderingComposer get cavePlaceUuid {
    final $CavePlacesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cavePlaceUuid,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavePlacesOrderingComposer(
            $db: $db,
            $table: $db.cavePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaveTripPointsAnnotationComposer
    extends Composer<_$AppDatabase, CaveTripPoints> {
  $CaveTripPointsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get scannedAt =>
      $composableBuilder(column: $table.scannedAt, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $CaveTripsAnnotationComposer get caveTripUuid {
    final $CaveTripsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveTripUuid,
      referencedTable: $db.caveTrips,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripsAnnotationComposer(
            $db: $db,
            $table: $db.caveTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CavePlacesAnnotationComposer get cavePlaceUuid {
    final $CavePlacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cavePlaceUuid,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CavePlacesAnnotationComposer(
            $db: $db,
            $table: $db.cavePlaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $CaveTripPointsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          CaveTripPoints,
          CaveTripPoint,
          $CaveTripPointsFilterComposer,
          $CaveTripPointsOrderingComposer,
          $CaveTripPointsAnnotationComposer,
          $CaveTripPointsCreateCompanionBuilder,
          $CaveTripPointsUpdateCompanionBuilder,
          (CaveTripPoint, $CaveTripPointsReferences),
          CaveTripPoint,
          PrefetchHooks Function({
            bool caveTripUuid,
            bool cavePlaceUuid,
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
          })
        > {
  $CaveTripPointsTableManager(_$AppDatabase db, CaveTripPoints table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $CaveTripPointsFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $CaveTripPointsOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $CaveTripPointsAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<Uuid> caveTripUuid = const Value.absent(),
                Value<Uuid?> cavePlaceUuid = const Value.absent(),
                Value<int> scannedAt = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CaveTripPointsCompanion(
                uuid: uuid,
                caveTripUuid: caveTripUuid,
                cavePlaceUuid: cavePlaceUuid,
                scannedAt: scannedAt,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required Uuid caveTripUuid,
                Value<Uuid?> cavePlaceUuid = const Value.absent(),
                required int scannedAt,
                Value<String?> notes = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CaveTripPointsCompanion.insert(
                uuid: uuid,
                caveTripUuid: caveTripUuid,
                cavePlaceUuid: cavePlaceUuid,
                scannedAt: scannedAt,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CaveTripPointsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                caveTripUuid = false,
                cavePlaceUuid = false,
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (caveTripUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveTripUuid,
                                    referencedTable: $CaveTripPointsReferences
                                        ._caveTripUuidTable(db),
                                    referencedColumn: $CaveTripPointsReferences
                                        ._caveTripUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (cavePlaceUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.cavePlaceUuid,
                                    referencedTable: $CaveTripPointsReferences
                                        ._cavePlaceUuidTable(db),
                                    referencedColumn: $CaveTripPointsReferences
                                        ._cavePlaceUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable: $CaveTripPointsReferences
                                        ._createdByUserUuidTable(db),
                                    referencedColumn: $CaveTripPointsReferences
                                        ._createdByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable: $CaveTripPointsReferences
                                        ._lastModifiedByUserUuidTable(db),
                                    referencedColumn: $CaveTripPointsReferences
                                        ._lastModifiedByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $CaveTripPointsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      CaveTripPoints,
      CaveTripPoint,
      $CaveTripPointsFilterComposer,
      $CaveTripPointsOrderingComposer,
      $CaveTripPointsAnnotationComposer,
      $CaveTripPointsCreateCompanionBuilder,
      $CaveTripPointsUpdateCompanionBuilder,
      (CaveTripPoint, $CaveTripPointsReferences),
      CaveTripPoint,
      PrefetchHooks Function({
        bool caveTripUuid,
        bool cavePlaceUuid,
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
      })
    >;
typedef $DocumentationFilesToCaveTripsCreateCompanionBuilder =
    DocumentationFilesToCaveTripsCompanion Function({
      required Uuid uuid,
      required Uuid documentationFileUuid,
      required Uuid caveTripUuid,
      Value<int?> createdAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $DocumentationFilesToCaveTripsUpdateCompanionBuilder =
    DocumentationFilesToCaveTripsCompanion Function({
      Value<Uuid> uuid,
      Value<Uuid> documentationFileUuid,
      Value<Uuid> caveTripUuid,
      Value<int?> createdAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $DocumentationFilesToCaveTripsReferences
    extends
        BaseReferences<
          _$AppDatabase,
          DocumentationFilesToCaveTrips,
          DocumentationFilesToCaveTrip
        > {
  $DocumentationFilesToCaveTripsReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static DocumentationFiles _documentationFileUuidTable(_$AppDatabase db) =>
      db.documentationFiles.createAlias(
        $_aliasNameGenerator(
          db.documentationFilesToCaveTrips.documentationFileUuid,
          db.documentationFiles.uuid,
        ),
      );

  $DocumentationFilesProcessedTableManager get documentationFileUuid {
    final $_column = $_itemColumn<Uint8List>('documentation_file_uuid')!;

    final manager = $DocumentationFilesTableManager(
      $_db,
      $_db.documentationFiles,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _documentationFileUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static CaveTrips _caveTripUuidTable(_$AppDatabase db) =>
      db.caveTrips.createAlias(
        $_aliasNameGenerator(
          db.documentationFilesToCaveTrips.caveTripUuid,
          db.caveTrips.uuid,
        ),
      );

  $CaveTripsProcessedTableManager get caveTripUuid {
    final $_column = $_itemColumn<Uint8List>('cave_trip_uuid')!;

    final manager = $CaveTripsTableManager(
      $_db,
      $_db.caveTrips,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveTripUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.documentationFilesToCaveTrips.createdByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.documentationFilesToCaveTrips.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $DocumentationFilesToCaveTripsFilterComposer
    extends Composer<_$AppDatabase, DocumentationFilesToCaveTrips> {
  $DocumentationFilesToCaveTripsFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $DocumentationFilesFilterComposer get documentationFileUuid {
    final $DocumentationFilesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentationFileUuid,
      referencedTable: $db.documentationFiles,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DocumentationFilesFilterComposer(
            $db: $db,
            $table: $db.documentationFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaveTripsFilterComposer get caveTripUuid {
    final $CaveTripsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveTripUuid,
      referencedTable: $db.caveTrips,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripsFilterComposer(
            $db: $db,
            $table: $db.caveTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DocumentationFilesToCaveTripsOrderingComposer
    extends Composer<_$AppDatabase, DocumentationFilesToCaveTrips> {
  $DocumentationFilesToCaveTripsOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $DocumentationFilesOrderingComposer get documentationFileUuid {
    final $DocumentationFilesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentationFileUuid,
      referencedTable: $db.documentationFiles,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DocumentationFilesOrderingComposer(
            $db: $db,
            $table: $db.documentationFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaveTripsOrderingComposer get caveTripUuid {
    final $CaveTripsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveTripUuid,
      referencedTable: $db.caveTrips,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripsOrderingComposer(
            $db: $db,
            $table: $db.caveTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DocumentationFilesToCaveTripsAnnotationComposer
    extends Composer<_$AppDatabase, DocumentationFilesToCaveTrips> {
  $DocumentationFilesToCaveTripsAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $DocumentationFilesAnnotationComposer get documentationFileUuid {
    final $DocumentationFilesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentationFileUuid,
      referencedTable: $db.documentationFiles,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $DocumentationFilesAnnotationComposer(
            $db: $db,
            $table: $db.documentationFiles,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $CaveTripsAnnotationComposer get caveTripUuid {
    final $CaveTripsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveTripUuid,
      referencedTable: $db.caveTrips,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $CaveTripsAnnotationComposer(
            $db: $db,
            $table: $db.caveTrips,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $DocumentationFilesToCaveTripsTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          DocumentationFilesToCaveTrips,
          DocumentationFilesToCaveTrip,
          $DocumentationFilesToCaveTripsFilterComposer,
          $DocumentationFilesToCaveTripsOrderingComposer,
          $DocumentationFilesToCaveTripsAnnotationComposer,
          $DocumentationFilesToCaveTripsCreateCompanionBuilder,
          $DocumentationFilesToCaveTripsUpdateCompanionBuilder,
          (
            DocumentationFilesToCaveTrip,
            $DocumentationFilesToCaveTripsReferences,
          ),
          DocumentationFilesToCaveTrip,
          PrefetchHooks Function({
            bool documentationFileUuid,
            bool caveTripUuid,
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
          })
        > {
  $DocumentationFilesToCaveTripsTableManager(
    _$AppDatabase db,
    DocumentationFilesToCaveTrips table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $DocumentationFilesToCaveTripsFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $DocumentationFilesToCaveTripsOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $DocumentationFilesToCaveTripsAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<Uuid> documentationFileUuid = const Value.absent(),
                Value<Uuid> caveTripUuid = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentationFilesToCaveTripsCompanion(
                uuid: uuid,
                documentationFileUuid: documentationFileUuid,
                caveTripUuid: caveTripUuid,
                createdAt: createdAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required Uuid documentationFileUuid,
                required Uuid caveTripUuid,
                Value<int?> createdAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DocumentationFilesToCaveTripsCompanion.insert(
                uuid: uuid,
                documentationFileUuid: documentationFileUuid,
                caveTripUuid: caveTripUuid,
                createdAt: createdAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $DocumentationFilesToCaveTripsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                documentationFileUuid = false,
                caveTripUuid = false,
                createdByUserUuid = false,
                lastModifiedByUserUuid = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (documentationFileUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.documentationFileUuid,
                                    referencedTable:
                                        $DocumentationFilesToCaveTripsReferences
                                            ._documentationFileUuidTable(db),
                                    referencedColumn:
                                        $DocumentationFilesToCaveTripsReferences
                                            ._documentationFileUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }
                        if (caveTripUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveTripUuid,
                                    referencedTable:
                                        $DocumentationFilesToCaveTripsReferences
                                            ._caveTripUuidTable(db),
                                    referencedColumn:
                                        $DocumentationFilesToCaveTripsReferences
                                            ._caveTripUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable:
                                        $DocumentationFilesToCaveTripsReferences
                                            ._createdByUserUuidTable(db),
                                    referencedColumn:
                                        $DocumentationFilesToCaveTripsReferences
                                            ._createdByUserUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable:
                                        $DocumentationFilesToCaveTripsReferences
                                            ._lastModifiedByUserUuidTable(db),
                                    referencedColumn:
                                        $DocumentationFilesToCaveTripsReferences
                                            ._lastModifiedByUserUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $DocumentationFilesToCaveTripsProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      DocumentationFilesToCaveTrips,
      DocumentationFilesToCaveTrip,
      $DocumentationFilesToCaveTripsFilterComposer,
      $DocumentationFilesToCaveTripsOrderingComposer,
      $DocumentationFilesToCaveTripsAnnotationComposer,
      $DocumentationFilesToCaveTripsCreateCompanionBuilder,
      $DocumentationFilesToCaveTripsUpdateCompanionBuilder,
      (DocumentationFilesToCaveTrip, $DocumentationFilesToCaveTripsReferences),
      DocumentationFilesToCaveTrip,
      PrefetchHooks Function({
        bool documentationFileUuid,
        bool caveTripUuid,
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
      })
    >;
typedef $TripReportTemplatesCreateCompanionBuilder =
    TripReportTemplatesCompanion Function({
      required Uuid uuid,
      required String title,
      required String fileName,
      required int fileSize,
      required String format,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });
typedef $TripReportTemplatesUpdateCompanionBuilder =
    TripReportTemplatesCompanion Function({
      Value<Uuid> uuid,
      Value<String> title,
      Value<String> fileName,
      Value<int> fileSize,
      Value<String> format,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
      Value<Uuid?> createdByUserUuid,
      Value<Uuid?> lastModifiedByUserUuid,
      Value<int> rowid,
    });

final class $TripReportTemplatesReferences
    extends
        BaseReferences<_$AppDatabase, TripReportTemplates, TripReportTemplate> {
  $TripReportTemplatesReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static Users _createdByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.tripReportTemplates.createdByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get createdByUserUuid {
    final $_column = $_itemColumn<Uint8List>('created_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_createdByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static Users _lastModifiedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(
          db.tripReportTemplates.lastModifiedByUserUuid,
          db.users.uuid,
        ),
      );

  $UsersProcessedTableManager? get lastModifiedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('last_modified_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(
      _lastModifiedByUserUuidTable($_db),
    );
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $TripReportTemplatesFilterComposer
    extends Composer<_$AppDatabase, TripReportTemplates> {
  $TripReportTemplatesFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $UsersFilterComposer get createdByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersFilterComposer get lastModifiedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TripReportTemplatesOrderingComposer
    extends Composer<_$AppDatabase, TripReportTemplates> {
  $TripReportTemplatesOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSize => $composableBuilder(
    column: $table.fileSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get format => $composableBuilder(
    column: $table.format,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $UsersOrderingComposer get createdByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersOrderingComposer get lastModifiedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TripReportTemplatesAnnotationComposer
    extends Composer<_$AppDatabase, TripReportTemplates> {
  $TripReportTemplatesAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get fileSize =>
      $composableBuilder(column: $table.fileSize, builder: (column) => column);

  GeneratedColumn<String> get format =>
      $composableBuilder(column: $table.format, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $UsersAnnotationComposer get createdByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.createdByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $UsersAnnotationComposer get lastModifiedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.lastModifiedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $TripReportTemplatesTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          TripReportTemplates,
          TripReportTemplate,
          $TripReportTemplatesFilterComposer,
          $TripReportTemplatesOrderingComposer,
          $TripReportTemplatesAnnotationComposer,
          $TripReportTemplatesCreateCompanionBuilder,
          $TripReportTemplatesUpdateCompanionBuilder,
          (TripReportTemplate, $TripReportTemplatesReferences),
          TripReportTemplate,
          PrefetchHooks Function({
            bool createdByUserUuid,
            bool lastModifiedByUserUuid,
          })
        > {
  $TripReportTemplatesTableManager(_$AppDatabase db, TripReportTemplates table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $TripReportTemplatesFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $TripReportTemplatesOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $TripReportTemplatesAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String> format = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripReportTemplatesCompanion(
                uuid: uuid,
                title: title,
                fileName: fileName,
                fileSize: fileSize,
                format: format,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required String title,
                required String fileName,
                required int fileSize,
                required String format,
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<Uuid?> createdByUserUuid = const Value.absent(),
                Value<Uuid?> lastModifiedByUserUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TripReportTemplatesCompanion.insert(
                uuid: uuid,
                title: title,
                fileName: fileName,
                fileSize: fileSize,
                format: format,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                createdByUserUuid: createdByUserUuid,
                lastModifiedByUserUuid: lastModifiedByUserUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $TripReportTemplatesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({createdByUserUuid = false, lastModifiedByUserUuid = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (createdByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.createdByUserUuid,
                                    referencedTable:
                                        $TripReportTemplatesReferences
                                            ._createdByUserUuidTable(db),
                                    referencedColumn:
                                        $TripReportTemplatesReferences
                                            ._createdByUserUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }
                        if (lastModifiedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.lastModifiedByUserUuid,
                                    referencedTable:
                                        $TripReportTemplatesReferences
                                            ._lastModifiedByUserUuidTable(db),
                                    referencedColumn:
                                        $TripReportTemplatesReferences
                                            ._lastModifiedByUserUuidTable(db)
                                            .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $TripReportTemplatesProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      TripReportTemplates,
      TripReportTemplate,
      $TripReportTemplatesFilterComposer,
      $TripReportTemplatesOrderingComposer,
      $TripReportTemplatesAnnotationComposer,
      $TripReportTemplatesCreateCompanionBuilder,
      $TripReportTemplatesUpdateCompanionBuilder,
      (TripReportTemplate, $TripReportTemplatesReferences),
      TripReportTemplate,
      PrefetchHooks Function({
        bool createdByUserUuid,
        bool lastModifiedByUserUuid,
      })
    >;
typedef $ChangeLogCreateCompanionBuilder =
    ChangeLogCompanion Function({
      required Uuid uuid,
      required String entityTable,
      required Uuid entityUuid,
      required int changeType,
      required int changedAt,
      Value<Uuid?> changedByUserUuid,
      Value<Uuid?> deviceUuid,
      Value<int> rowid,
    });
typedef $ChangeLogUpdateCompanionBuilder =
    ChangeLogCompanion Function({
      Value<Uuid> uuid,
      Value<String> entityTable,
      Value<Uuid> entityUuid,
      Value<int> changeType,
      Value<int> changedAt,
      Value<Uuid?> changedByUserUuid,
      Value<Uuid?> deviceUuid,
      Value<int> rowid,
    });

final class $ChangeLogReferences
    extends BaseReferences<_$AppDatabase, ChangeLog, ChangeLogData> {
  $ChangeLogReferences(super.$_db, super.$_table, super.$_typedResult);

  static Users _changedByUserUuidTable(_$AppDatabase db) =>
      db.users.createAlias(
        $_aliasNameGenerator(db.changeLog.changedByUserUuid, db.users.uuid),
      );

  $UsersProcessedTableManager? get changedByUserUuid {
    final $_column = $_itemColumn<Uint8List>('changed_by_user_uuid');
    if ($_column == null) return null;
    final manager = $UsersTableManager(
      $_db,
      $_db.users,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_changedByUserUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<ChangeLogField, List<ChangeLogFieldData>>
  _changeLogFieldRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.changeLogField,
    aliasName: $_aliasNameGenerator(
      db.changeLog.uuid,
      db.changeLogField.changeUuid,
    ),
  );

  $ChangeLogFieldProcessedTableManager get changeLogFieldRefs {
    final manager = $ChangeLogFieldTableManager($_db, $_db.changeLogField)
        .filter(
          (f) => f.changeUuid.uuid.sqlEquals($_itemColumn<Uint8List>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(_changeLogFieldRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $ChangeLogFilterComposer extends Composer<_$AppDatabase, ChangeLog> {
  $ChangeLogFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get uuid =>
      $composableBuilder(
        column: $table.uuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Uuid, Uuid, Uint8List> get entityUuid =>
      $composableBuilder(
        column: $table.entityUuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<Uuid?, Uuid, Uint8List> get deviceUuid =>
      $composableBuilder(
        column: $table.deviceUuid,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  $UsersFilterComposer get changedByUserUuid {
    final $UsersFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.changedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersFilterComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> changeLogFieldRefs(
    Expression<bool> Function($ChangeLogFieldFilterComposer f) f,
  ) {
    final $ChangeLogFieldFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.changeLogField,
      getReferencedColumn: (t) => t.changeUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ChangeLogFieldFilterComposer(
            $db: $db,
            $table: $db.changeLogField,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ChangeLogOrderingComposer extends Composer<_$AppDatabase, ChangeLog> {
  $ChangeLogOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<Uint8List> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get entityUuid => $composableBuilder(
    column: $table.entityUuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get deviceUuid => $composableBuilder(
    column: $table.deviceUuid,
    builder: (column) => ColumnOrderings(column),
  );

  $UsersOrderingComposer get changedByUserUuid {
    final $UsersOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.changedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersOrderingComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ChangeLogAnnotationComposer extends Composer<_$AppDatabase, ChangeLog> {
  $ChangeLogAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<Uuid, Uint8List> get entityUuid =>
      $composableBuilder(
        column: $table.entityUuid,
        builder: (column) => column,
      );

  GeneratedColumn<int> get changeType => $composableBuilder(
    column: $table.changeType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<Uuid?, Uint8List> get deviceUuid =>
      $composableBuilder(
        column: $table.deviceUuid,
        builder: (column) => column,
      );

  $UsersAnnotationComposer get changedByUserUuid {
    final $UsersAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.changedByUserUuid,
      referencedTable: $db.users,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $UsersAnnotationComposer(
            $db: $db,
            $table: $db.users,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> changeLogFieldRefs<T extends Object>(
    Expression<T> Function($ChangeLogFieldAnnotationComposer a) f,
  ) {
    final $ChangeLogFieldAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.changeLogField,
      getReferencedColumn: (t) => t.changeUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ChangeLogFieldAnnotationComposer(
            $db: $db,
            $table: $db.changeLogField,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $ChangeLogTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ChangeLog,
          ChangeLogData,
          $ChangeLogFilterComposer,
          $ChangeLogOrderingComposer,
          $ChangeLogAnnotationComposer,
          $ChangeLogCreateCompanionBuilder,
          $ChangeLogUpdateCompanionBuilder,
          (ChangeLogData, $ChangeLogReferences),
          ChangeLogData,
          PrefetchHooks Function({
            bool changedByUserUuid,
            bool changeLogFieldRefs,
          })
        > {
  $ChangeLogTableManager(_$AppDatabase db, ChangeLog table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ChangeLogFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ChangeLogOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ChangeLogAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> uuid = const Value.absent(),
                Value<String> entityTable = const Value.absent(),
                Value<Uuid> entityUuid = const Value.absent(),
                Value<int> changeType = const Value.absent(),
                Value<int> changedAt = const Value.absent(),
                Value<Uuid?> changedByUserUuid = const Value.absent(),
                Value<Uuid?> deviceUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChangeLogCompanion(
                uuid: uuid,
                entityTable: entityTable,
                entityUuid: entityUuid,
                changeType: changeType,
                changedAt: changedAt,
                changedByUserUuid: changedByUserUuid,
                deviceUuid: deviceUuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid uuid,
                required String entityTable,
                required Uuid entityUuid,
                required int changeType,
                required int changedAt,
                Value<Uuid?> changedByUserUuid = const Value.absent(),
                Value<Uuid?> deviceUuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChangeLogCompanion.insert(
                uuid: uuid,
                entityTable: entityTable,
                entityUuid: entityUuid,
                changeType: changeType,
                changedAt: changedAt,
                changedByUserUuid: changedByUserUuid,
                deviceUuid: deviceUuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $ChangeLogReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({changedByUserUuid = false, changeLogFieldRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (changeLogFieldRefs) db.changeLogField,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (changedByUserUuid) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.changedByUserUuid,
                                    referencedTable: $ChangeLogReferences
                                        ._changedByUserUuidTable(db),
                                    referencedColumn: $ChangeLogReferences
                                        ._changedByUserUuidTable(db)
                                        .uuid,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (changeLogFieldRefs)
                        await $_getPrefetchedData<
                          ChangeLogData,
                          ChangeLog,
                          ChangeLogFieldData
                        >(
                          currentTable: table,
                          referencedTable: $ChangeLogReferences
                              ._changeLogFieldRefsTable(db),
                          managerFromTypedResult: (p0) => $ChangeLogReferences(
                            db,
                            table,
                            p0,
                          ).changeLogFieldRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.changeUuid == item.uuid,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $ChangeLogProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ChangeLog,
      ChangeLogData,
      $ChangeLogFilterComposer,
      $ChangeLogOrderingComposer,
      $ChangeLogAnnotationComposer,
      $ChangeLogCreateCompanionBuilder,
      $ChangeLogUpdateCompanionBuilder,
      (ChangeLogData, $ChangeLogReferences),
      ChangeLogData,
      PrefetchHooks Function({bool changedByUserUuid, bool changeLogFieldRefs})
    >;
typedef $ChangeLogFieldCreateCompanionBuilder =
    ChangeLogFieldCompanion Function({
      required Uuid changeUuid,
      required String fieldName,
      Value<Uint8List?> oldValueShort,
      Value<int> oldValueTruncated,
      Value<int> rowid,
    });
typedef $ChangeLogFieldUpdateCompanionBuilder =
    ChangeLogFieldCompanion Function({
      Value<Uuid> changeUuid,
      Value<String> fieldName,
      Value<Uint8List?> oldValueShort,
      Value<int> oldValueTruncated,
      Value<int> rowid,
    });

final class $ChangeLogFieldReferences
    extends BaseReferences<_$AppDatabase, ChangeLogField, ChangeLogFieldData> {
  $ChangeLogFieldReferences(super.$_db, super.$_table, super.$_typedResult);

  static ChangeLog _changeUuidTable(_$AppDatabase db) =>
      db.changeLog.createAlias(
        $_aliasNameGenerator(db.changeLogField.changeUuid, db.changeLog.uuid),
      );

  $ChangeLogProcessedTableManager get changeUuid {
    final $_column = $_itemColumn<Uint8List>('change_uuid')!;

    final manager = $ChangeLogTableManager(
      $_db,
      $_db.changeLog,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_changeUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $ChangeLogFieldFilterComposer
    extends Composer<_$AppDatabase, ChangeLogField> {
  $ChangeLogFieldFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<Uint8List> get oldValueShort => $composableBuilder(
    column: $table.oldValueShort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get oldValueTruncated => $composableBuilder(
    column: $table.oldValueTruncated,
    builder: (column) => ColumnFilters(column),
  );

  $ChangeLogFilterComposer get changeUuid {
    final $ChangeLogFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.changeUuid,
      referencedTable: $db.changeLog,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ChangeLogFilterComposer(
            $db: $db,
            $table: $db.changeLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ChangeLogFieldOrderingComposer
    extends Composer<_$AppDatabase, ChangeLogField> {
  $ChangeLogFieldOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get fieldName => $composableBuilder(
    column: $table.fieldName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<Uint8List> get oldValueShort => $composableBuilder(
    column: $table.oldValueShort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get oldValueTruncated => $composableBuilder(
    column: $table.oldValueTruncated,
    builder: (column) => ColumnOrderings(column),
  );

  $ChangeLogOrderingComposer get changeUuid {
    final $ChangeLogOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.changeUuid,
      referencedTable: $db.changeLog,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ChangeLogOrderingComposer(
            $db: $db,
            $table: $db.changeLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ChangeLogFieldAnnotationComposer
    extends Composer<_$AppDatabase, ChangeLogField> {
  $ChangeLogFieldAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get fieldName =>
      $composableBuilder(column: $table.fieldName, builder: (column) => column);

  GeneratedColumn<Uint8List> get oldValueShort => $composableBuilder(
    column: $table.oldValueShort,
    builder: (column) => column,
  );

  GeneratedColumn<int> get oldValueTruncated => $composableBuilder(
    column: $table.oldValueTruncated,
    builder: (column) => column,
  );

  $ChangeLogAnnotationComposer get changeUuid {
    final $ChangeLogAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.changeUuid,
      referencedTable: $db.changeLog,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $ChangeLogAnnotationComposer(
            $db: $db,
            $table: $db.changeLog,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $ChangeLogFieldTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          ChangeLogField,
          ChangeLogFieldData,
          $ChangeLogFieldFilterComposer,
          $ChangeLogFieldOrderingComposer,
          $ChangeLogFieldAnnotationComposer,
          $ChangeLogFieldCreateCompanionBuilder,
          $ChangeLogFieldUpdateCompanionBuilder,
          (ChangeLogFieldData, $ChangeLogFieldReferences),
          ChangeLogFieldData,
          PrefetchHooks Function({bool changeUuid})
        > {
  $ChangeLogFieldTableManager(_$AppDatabase db, ChangeLogField table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $ChangeLogFieldFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $ChangeLogFieldOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $ChangeLogFieldAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<Uuid> changeUuid = const Value.absent(),
                Value<String> fieldName = const Value.absent(),
                Value<Uint8List?> oldValueShort = const Value.absent(),
                Value<int> oldValueTruncated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChangeLogFieldCompanion(
                changeUuid: changeUuid,
                fieldName: fieldName,
                oldValueShort: oldValueShort,
                oldValueTruncated: oldValueTruncated,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required Uuid changeUuid,
                required String fieldName,
                Value<Uint8List?> oldValueShort = const Value.absent(),
                Value<int> oldValueTruncated = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChangeLogFieldCompanion.insert(
                changeUuid: changeUuid,
                fieldName: fieldName,
                oldValueShort: oldValueShort,
                oldValueTruncated: oldValueTruncated,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $ChangeLogFieldReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({changeUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (changeUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.changeUuid,
                                referencedTable: $ChangeLogFieldReferences
                                    ._changeUuidTable(db),
                                referencedColumn: $ChangeLogFieldReferences
                                    ._changeUuidTable(db)
                                    .uuid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $ChangeLogFieldProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      ChangeLogField,
      ChangeLogFieldData,
      $ChangeLogFieldFilterComposer,
      $ChangeLogFieldOrderingComposer,
      $ChangeLogFieldAnnotationComposer,
      $ChangeLogFieldCreateCompanionBuilder,
      $ChangeLogFieldUpdateCompanionBuilder,
      (ChangeLogFieldData, $ChangeLogFieldReferences),
      ChangeLogFieldData,
      PrefetchHooks Function({bool changeUuid})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $UsersTableManager get users => $UsersTableManager(_db, _db.users);
  $SurfaceAreasTableManager get surfaceAreas =>
      $SurfaceAreasTableManager(_db, _db.surfaceAreas);
  $CavesTableManager get caves => $CavesTableManager(_db, _db.caves);
  $CaveAreasTableManager get caveAreas =>
      $CaveAreasTableManager(_db, _db.caveAreas);
  $SurfacePlacesTableManager get surfacePlaces =>
      $SurfacePlacesTableManager(_db, _db.surfacePlaces);
  $CaveEntrancesTableManager get caveEntrances =>
      $CaveEntrancesTableManager(_db, _db.caveEntrances);
  $CavePlacesTableManager get cavePlaces =>
      $CavePlacesTableManager(_db, _db.cavePlaces);
  $RasterMapsTableManager get rasterMaps =>
      $RasterMapsTableManager(_db, _db.rasterMaps);
  $CavePlaceToRasterMapDefinitionsTableManager
  get cavePlaceToRasterMapDefinitions =>
      $CavePlaceToRasterMapDefinitionsTableManager(
        _db,
        _db.cavePlaceToRasterMapDefinitions,
      );
  $DocumentationFilesTableManager get documentationFiles =>
      $DocumentationFilesTableManager(_db, _db.documentationFiles);
  $DocumentationFilesToGeofeaturesTableManager
  get documentationFilesToGeofeatures =>
      $DocumentationFilesToGeofeaturesTableManager(
        _db,
        _db.documentationFilesToGeofeatures,
      );
  $ConfigurationsTableManager get configurations =>
      $ConfigurationsTableManager(_db, _db.configurations);
  $CaveTripsTableManager get caveTrips =>
      $CaveTripsTableManager(_db, _db.caveTrips);
  $CaveTripPointsTableManager get caveTripPoints =>
      $CaveTripPointsTableManager(_db, _db.caveTripPoints);
  $DocumentationFilesToCaveTripsTableManager
  get documentationFilesToCaveTrips =>
      $DocumentationFilesToCaveTripsTableManager(
        _db,
        _db.documentationFilesToCaveTrips,
      );
  $TripReportTemplatesTableManager get tripReportTemplates =>
      $TripReportTemplatesTableManager(_db, _db.tripReportTemplates);
  $ChangeLogTableManager get changeLog =>
      $ChangeLogTableManager(_db, _db.changeLog);
  $ChangeLogFieldTableManager get changeLogField =>
      $ChangeLogFieldTableManager(_db, _db.changeLogField);
}
