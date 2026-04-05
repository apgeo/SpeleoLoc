// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class SurfaceAreas extends Table with TableInfo<SurfaceAreas, SurfaceArea> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SurfaceAreas(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    createdAt,
    updatedAt,
    deletedAt,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurfaceArea map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurfaceArea(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
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
    );
  }

  @override
  SurfaceAreas createAlias(String alias) {
    return SurfaceAreas(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SurfaceArea extends DataClass implements Insertable<SurfaceArea> {
  final int id;
  final String title;
  final String? description;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const SurfaceArea({
    required this.id,
    required this.title,
    this.description,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
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
    return map;
  }

  SurfaceAreasCompanion toCompanion(bool nullToAbsent) {
    return SurfaceAreasCompanion(
      id: Value(id),
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
    );
  }

  factory SurfaceArea.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurfaceArea(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  SurfaceArea copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => SurfaceArea(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  SurfaceArea copyWithCompanion(SurfaceAreasCompanion data) {
    return SurfaceArea(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurfaceArea(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, title, description, createdAt, updatedAt, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurfaceArea &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SurfaceAreasCompanion extends UpdateCompanion<SurfaceArea> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  const SurfaceAreasCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  SurfaceAreasCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<SurfaceArea> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  SurfaceAreasCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return SurfaceAreasCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurfaceAreasCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class Caves extends Table with TableInfo<Caves, Cave> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Caves(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL',
  );
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
  static const VerificationMeta _surfaceAreaIdMeta = const VerificationMeta(
    'surfaceAreaId',
  );
  late final GeneratedColumn<int> surfaceAreaId = GeneratedColumn<int>(
    'surface_area_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES surface_areas(id)',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    surfaceAreaId,
    createdAt,
    updatedAt,
    deletedAt,
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('surface_area_id')) {
      context.handle(
        _surfaceAreaIdMeta,
        surfaceAreaId.isAcceptableOrUnknown(
          data['surface_area_id']!,
          _surfaceAreaIdMeta,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title, surfaceAreaId},
  ];
  @override
  Cave map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Cave(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      surfaceAreaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surface_area_id'],
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
    );
  }

  @override
  Caves createAlias(String alias) {
    return Caves(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(title, surface_area_id)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class Cave extends DataClass implements Insertable<Cave> {
  final int id;
  final String title;
  final String? description;
  final int? surfaceAreaId;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const Cave({
    required this.id,
    required this.title,
    this.description,
    this.surfaceAreaId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || surfaceAreaId != null) {
      map['surface_area_id'] = Variable<int>(surfaceAreaId);
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
    return map;
  }

  CavesCompanion toCompanion(bool nullToAbsent) {
    return CavesCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      surfaceAreaId: surfaceAreaId == null && nullToAbsent
          ? const Value.absent()
          : Value(surfaceAreaId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory Cave.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Cave(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      surfaceAreaId: serializer.fromJson<int?>(json['surface_area_id']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'surface_area_id': serializer.toJson<int?>(surfaceAreaId),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  Cave copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<int?> surfaceAreaId = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => Cave(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    surfaceAreaId: surfaceAreaId.present
        ? surfaceAreaId.value
        : this.surfaceAreaId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Cave copyWithCompanion(CavesCompanion data) {
    return Cave(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      surfaceAreaId: data.surfaceAreaId.present
          ? data.surfaceAreaId.value
          : this.surfaceAreaId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Cave(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('surfaceAreaId: $surfaceAreaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    surfaceAreaId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Cave &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.surfaceAreaId == this.surfaceAreaId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CavesCompanion extends UpdateCompanion<Cave> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int?> surfaceAreaId;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  const CavesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.surfaceAreaId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  CavesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.surfaceAreaId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<Cave> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? surfaceAreaId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (surfaceAreaId != null) 'surface_area_id': surfaceAreaId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  CavesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<int?>? surfaceAreaId,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return CavesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      surfaceAreaId: surfaceAreaId ?? this.surfaceAreaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (surfaceAreaId.present) {
      map['surface_area_id'] = Variable<int>(surfaceAreaId.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CavesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('surfaceAreaId: $surfaceAreaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class CaveAreas extends Table with TableInfo<CaveAreas, CaveArea> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CaveAreas(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL',
  );
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
  static const VerificationMeta _caveIdMeta = const VerificationMeta('caveId');
  late final GeneratedColumn<int> caveId = GeneratedColumn<int>(
    'cave_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES caves(id)',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    caveId,
    createdAt,
    updatedAt,
    deletedAt,
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cave_id')) {
      context.handle(
        _caveIdMeta,
        caveId.isAcceptableOrUnknown(data['cave_id']!, _caveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caveIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title, caveId},
  ];
  @override
  CaveArea map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaveArea(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      caveId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cave_id'],
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
    );
  }

  @override
  CaveAreas createAlias(String alias) {
    return CaveAreas(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(title, cave_id)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CaveArea extends DataClass implements Insertable<CaveArea> {
  final int id;
  final String title;
  final String? description;
  final int caveId;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const CaveArea({
    required this.id,
    required this.title,
    this.description,
    required this.caveId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['cave_id'] = Variable<int>(caveId);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  CaveAreasCompanion toCompanion(bool nullToAbsent) {
    return CaveAreasCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      caveId: Value(caveId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CaveArea.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaveArea(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      caveId: serializer.fromJson<int>(json['cave_id']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'cave_id': serializer.toJson<int>(caveId),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  CaveArea copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    int? caveId,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => CaveArea(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    caveId: caveId ?? this.caveId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CaveArea copyWithCompanion(CaveAreasCompanion data) {
    return CaveArea(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      caveId: data.caveId.present ? data.caveId.value : this.caveId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaveArea(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('caveId: $caveId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    caveId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaveArea &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.caveId == this.caveId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CaveAreasCompanion extends UpdateCompanion<CaveArea> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> caveId;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  const CaveAreasCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.caveId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  CaveAreasCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required int caveId,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title),
       caveId = Value(caveId);
  static Insertable<CaveArea> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? caveId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (caveId != null) 'cave_id': caveId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  CaveAreasCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<int>? caveId,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return CaveAreasCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      caveId: caveId ?? this.caveId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (caveId.present) {
      map['cave_id'] = Variable<int>(caveId.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaveAreasCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('caveId: $caveId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class SurfacePlaces extends Table with TableInfo<SurfacePlaces, SurfacePlace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SurfacePlaces(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL',
  );
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    type,
    surfacePlaceQrCodeIdentifier,
    latitude,
    longitude,
    createdAt,
    updatedAt,
    deletedAt,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SurfacePlace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SurfacePlace(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
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
    );
  }

  @override
  SurfacePlaces createAlias(String alias) {
    return SurfacePlaces(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
}

class SurfacePlace extends DataClass implements Insertable<SurfacePlace> {
  final int id;
  final String title;
  final String? description;
  final String? type;
  final int? surfacePlaceQrCodeIdentifier;
  final double? latitude;
  final double? longitude;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const SurfacePlace({
    required this.id,
    required this.title,
    this.description,
    this.type,
    this.surfacePlaceQrCodeIdentifier,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
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
    return map;
  }

  SurfacePlacesCompanion toCompanion(bool nullToAbsent) {
    return SurfacePlacesCompanion(
      id: Value(id),
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
    );
  }

  factory SurfacePlace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SurfacePlace(
      id: serializer.fromJson<int>(json['id']),
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
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
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
    };
  }

  SurfacePlace copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> type = const Value.absent(),
    Value<int?> surfacePlaceQrCodeIdentifier = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => SurfacePlace(
    id: id ?? this.id,
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
  );
  SurfacePlace copyWithCompanion(SurfacePlacesCompanion data) {
    return SurfacePlace(
      id: data.id.present ? data.id.value : this.id,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('SurfacePlace(')
          ..write('id: $id, ')
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
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    type,
    surfacePlaceQrCodeIdentifier,
    latitude,
    longitude,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SurfacePlace &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.surfacePlaceQrCodeIdentifier ==
              this.surfacePlaceQrCodeIdentifier &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class SurfacePlacesCompanion extends UpdateCompanion<SurfacePlace> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> type;
  final Value<int?> surfacePlaceQrCodeIdentifier;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  const SurfacePlacesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.surfacePlaceQrCodeIdentifier = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  SurfacePlacesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.surfacePlaceQrCodeIdentifier = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title);
  static Insertable<SurfacePlace> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? type,
    Expression<int>? surfacePlaceQrCodeIdentifier,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
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
    });
  }

  SurfacePlacesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? type,
    Value<int?>? surfacePlaceQrCodeIdentifier,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return SurfacePlacesCompanion(
      id: id ?? this.id,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SurfacePlacesCompanion(')
          ..write('id: $id, ')
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
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class CaveEntrances extends Table with TableInfo<CaveEntrances, CaveEntrance> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CaveEntrances(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL',
  );
  static const VerificationMeta _caveIdMeta = const VerificationMeta('caveId');
  late final GeneratedColumn<int> caveId = GeneratedColumn<int>(
    'cave_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES caves(id)',
  );
  static const VerificationMeta _surfacePlaceIdMeta = const VerificationMeta(
    'surfacePlaceId',
  );
  late final GeneratedColumn<int> surfacePlaceId = GeneratedColumn<int>(
    'surface_place_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES surface_places(id)',
  );
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    caveId,
    surfacePlaceId,
    isMainEntrance,
    title,
    createdAt,
    updatedAt,
    deletedAt,
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('cave_id')) {
      context.handle(
        _caveIdMeta,
        caveId.isAcceptableOrUnknown(data['cave_id']!, _caveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caveIdMeta);
    }
    if (data.containsKey('surface_place_id')) {
      context.handle(
        _surfacePlaceIdMeta,
        surfacePlaceId.isAcceptableOrUnknown(
          data['surface_place_id']!,
          _surfacePlaceIdMeta,
        ),
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {caveId, title},
  ];
  @override
  CaveEntrance map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaveEntrance(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      caveId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cave_id'],
      )!,
      surfacePlaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}surface_place_id'],
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
    );
  }

  @override
  CaveEntrances createAlias(String alias) {
    return CaveEntrances(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(cave_id, title)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CaveEntrance extends DataClass implements Insertable<CaveEntrance> {
  final int id;
  final int caveId;
  final int? surfacePlaceId;
  final int? isMainEntrance;
  final String? title;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const CaveEntrance({
    required this.id,
    required this.caveId,
    this.surfacePlaceId,
    this.isMainEntrance,
    this.title,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['cave_id'] = Variable<int>(caveId);
    if (!nullToAbsent || surfacePlaceId != null) {
      map['surface_place_id'] = Variable<int>(surfacePlaceId);
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
    return map;
  }

  CaveEntrancesCompanion toCompanion(bool nullToAbsent) {
    return CaveEntrancesCompanion(
      id: Value(id),
      caveId: Value(caveId),
      surfacePlaceId: surfacePlaceId == null && nullToAbsent
          ? const Value.absent()
          : Value(surfacePlaceId),
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
    );
  }

  factory CaveEntrance.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaveEntrance(
      id: serializer.fromJson<int>(json['id']),
      caveId: serializer.fromJson<int>(json['cave_id']),
      surfacePlaceId: serializer.fromJson<int?>(json['surface_place_id']),
      isMainEntrance: serializer.fromJson<int?>(json['is_main_entrance']),
      title: serializer.fromJson<String?>(json['title']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'cave_id': serializer.toJson<int>(caveId),
      'surface_place_id': serializer.toJson<int?>(surfacePlaceId),
      'is_main_entrance': serializer.toJson<int?>(isMainEntrance),
      'title': serializer.toJson<String?>(title),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  CaveEntrance copyWith({
    int? id,
    int? caveId,
    Value<int?> surfacePlaceId = const Value.absent(),
    Value<int?> isMainEntrance = const Value.absent(),
    Value<String?> title = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => CaveEntrance(
    id: id ?? this.id,
    caveId: caveId ?? this.caveId,
    surfacePlaceId: surfacePlaceId.present
        ? surfacePlaceId.value
        : this.surfacePlaceId,
    isMainEntrance: isMainEntrance.present
        ? isMainEntrance.value
        : this.isMainEntrance,
    title: title.present ? title.value : this.title,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CaveEntrance copyWithCompanion(CaveEntrancesCompanion data) {
    return CaveEntrance(
      id: data.id.present ? data.id.value : this.id,
      caveId: data.caveId.present ? data.caveId.value : this.caveId,
      surfacePlaceId: data.surfacePlaceId.present
          ? data.surfacePlaceId.value
          : this.surfacePlaceId,
      isMainEntrance: data.isMainEntrance.present
          ? data.isMainEntrance.value
          : this.isMainEntrance,
      title: data.title.present ? data.title.value : this.title,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaveEntrance(')
          ..write('id: $id, ')
          ..write('caveId: $caveId, ')
          ..write('surfacePlaceId: $surfacePlaceId, ')
          ..write('isMainEntrance: $isMainEntrance, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    caveId,
    surfacePlaceId,
    isMainEntrance,
    title,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaveEntrance &&
          other.id == this.id &&
          other.caveId == this.caveId &&
          other.surfacePlaceId == this.surfacePlaceId &&
          other.isMainEntrance == this.isMainEntrance &&
          other.title == this.title &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CaveEntrancesCompanion extends UpdateCompanion<CaveEntrance> {
  final Value<int> id;
  final Value<int> caveId;
  final Value<int?> surfacePlaceId;
  final Value<int?> isMainEntrance;
  final Value<String?> title;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  const CaveEntrancesCompanion({
    this.id = const Value.absent(),
    this.caveId = const Value.absent(),
    this.surfacePlaceId = const Value.absent(),
    this.isMainEntrance = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  CaveEntrancesCompanion.insert({
    this.id = const Value.absent(),
    required int caveId,
    this.surfacePlaceId = const Value.absent(),
    this.isMainEntrance = const Value.absent(),
    this.title = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : caveId = Value(caveId);
  static Insertable<CaveEntrance> custom({
    Expression<int>? id,
    Expression<int>? caveId,
    Expression<int>? surfacePlaceId,
    Expression<int>? isMainEntrance,
    Expression<String>? title,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (caveId != null) 'cave_id': caveId,
      if (surfacePlaceId != null) 'surface_place_id': surfacePlaceId,
      if (isMainEntrance != null) 'is_main_entrance': isMainEntrance,
      if (title != null) 'title': title,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  CaveEntrancesCompanion copyWith({
    Value<int>? id,
    Value<int>? caveId,
    Value<int?>? surfacePlaceId,
    Value<int?>? isMainEntrance,
    Value<String?>? title,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return CaveEntrancesCompanion(
      id: id ?? this.id,
      caveId: caveId ?? this.caveId,
      surfacePlaceId: surfacePlaceId ?? this.surfacePlaceId,
      isMainEntrance: isMainEntrance ?? this.isMainEntrance,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (caveId.present) {
      map['cave_id'] = Variable<int>(caveId.value);
    }
    if (surfacePlaceId.present) {
      map['surface_place_id'] = Variable<int>(surfacePlaceId.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CaveEntrancesCompanion(')
          ..write('id: $id, ')
          ..write('caveId: $caveId, ')
          ..write('surfacePlaceId: $surfacePlaceId, ')
          ..write('isMainEntrance: $isMainEntrance, ')
          ..write('title: $title, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class CavePlaces extends Table with TableInfo<CavePlaces, CavePlace> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  CavePlaces(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL',
  );
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
  static const VerificationMeta _caveIdMeta = const VerificationMeta('caveId');
  late final GeneratedColumn<int> caveId = GeneratedColumn<int>(
    'cave_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES caves(id)',
  );
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
  static const VerificationMeta _caveAreaIdMeta = const VerificationMeta(
    'caveAreaId',
  );
  late final GeneratedColumn<int> caveAreaId = GeneratedColumn<int>(
    'cave_area_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES cave_areas(id)',
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
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    caveId,
    placeQrCodeIdentifier,
    caveAreaId,
    latitude,
    longitude,
    depthInCave,
    isEntrance,
    isMainEntrance,
    createdAt,
    updatedAt,
    deletedAt,
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
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('cave_id')) {
      context.handle(
        _caveIdMeta,
        caveId.isAcceptableOrUnknown(data['cave_id']!, _caveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caveIdMeta);
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
    if (data.containsKey('cave_area_id')) {
      context.handle(
        _caveAreaIdMeta,
        caveAreaId.isAcceptableOrUnknown(
          data['cave_area_id']!,
          _caveAreaIdMeta,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title, caveId, caveAreaId},
  ];
  @override
  CavePlace map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CavePlace(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      caveId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cave_id'],
      )!,
      placeQrCodeIdentifier: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}place_qr_code_identifier'],
      ),
      caveAreaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cave_area_id'],
      ),
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      depthInCave: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}depth_in_cave'],
      ),
      isEntrance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_entrance'],
      ),
      isMainEntrance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_main_entrance'],
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
    );
  }

  @override
  CavePlaces createAlias(String alias) {
    return CavePlaces(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(title, cave_id, cave_area_id)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CavePlace extends DataClass implements Insertable<CavePlace> {
  final int id;
  final String title;
  final String? description;
  final int caveId;
  final int? placeQrCodeIdentifier;
  final int? caveAreaId;
  final double? latitude;

  /// GPS in WGS84
  final double? longitude;

  /// GPS in WGS84
  final double? depthInCave;

  /// can be positive or negative, e.g. for places above the entrance or in a pit
  final int? isEntrance;

  /// if 1, this place is an entrance;
  final int? isMainEntrance;

  /// if 1, this place is the main entrance
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const CavePlace({
    required this.id,
    required this.title,
    this.description,
    required this.caveId,
    this.placeQrCodeIdentifier,
    this.caveAreaId,
    this.latitude,
    this.longitude,
    this.depthInCave,
    this.isEntrance,
    this.isMainEntrance,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['cave_id'] = Variable<int>(caveId);
    if (!nullToAbsent || placeQrCodeIdentifier != null) {
      map['place_qr_code_identifier'] = Variable<int>(placeQrCodeIdentifier);
    }
    if (!nullToAbsent || caveAreaId != null) {
      map['cave_area_id'] = Variable<int>(caveAreaId);
    }
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || depthInCave != null) {
      map['depth_in_cave'] = Variable<double>(depthInCave);
    }
    if (!nullToAbsent || isEntrance != null) {
      map['is_entrance'] = Variable<int>(isEntrance);
    }
    if (!nullToAbsent || isMainEntrance != null) {
      map['is_main_entrance'] = Variable<int>(isMainEntrance);
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
    return map;
  }

  CavePlacesCompanion toCompanion(bool nullToAbsent) {
    return CavePlacesCompanion(
      id: Value(id),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      caveId: Value(caveId),
      placeQrCodeIdentifier: placeQrCodeIdentifier == null && nullToAbsent
          ? const Value.absent()
          : Value(placeQrCodeIdentifier),
      caveAreaId: caveAreaId == null && nullToAbsent
          ? const Value.absent()
          : Value(caveAreaId),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      depthInCave: depthInCave == null && nullToAbsent
          ? const Value.absent()
          : Value(depthInCave),
      isEntrance: isEntrance == null && nullToAbsent
          ? const Value.absent()
          : Value(isEntrance),
      isMainEntrance: isMainEntrance == null && nullToAbsent
          ? const Value.absent()
          : Value(isMainEntrance),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CavePlace.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CavePlace(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      caveId: serializer.fromJson<int>(json['cave_id']),
      placeQrCodeIdentifier: serializer.fromJson<int?>(
        json['place_qr_code_identifier'],
      ),
      caveAreaId: serializer.fromJson<int?>(json['cave_area_id']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      depthInCave: serializer.fromJson<double?>(json['depth_in_cave']),
      isEntrance: serializer.fromJson<int?>(json['is_entrance']),
      isMainEntrance: serializer.fromJson<int?>(json['is_main_entrance']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'cave_id': serializer.toJson<int>(caveId),
      'place_qr_code_identifier': serializer.toJson<int?>(
        placeQrCodeIdentifier,
      ),
      'cave_area_id': serializer.toJson<int?>(caveAreaId),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'depth_in_cave': serializer.toJson<double?>(depthInCave),
      'is_entrance': serializer.toJson<int?>(isEntrance),
      'is_main_entrance': serializer.toJson<int?>(isMainEntrance),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  CavePlace copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    int? caveId,
    Value<int?> placeQrCodeIdentifier = const Value.absent(),
    Value<int?> caveAreaId = const Value.absent(),
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<double?> depthInCave = const Value.absent(),
    Value<int?> isEntrance = const Value.absent(),
    Value<int?> isMainEntrance = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => CavePlace(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    caveId: caveId ?? this.caveId,
    placeQrCodeIdentifier: placeQrCodeIdentifier.present
        ? placeQrCodeIdentifier.value
        : this.placeQrCodeIdentifier,
    caveAreaId: caveAreaId.present ? caveAreaId.value : this.caveAreaId,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    depthInCave: depthInCave.present ? depthInCave.value : this.depthInCave,
    isEntrance: isEntrance.present ? isEntrance.value : this.isEntrance,
    isMainEntrance: isMainEntrance.present
        ? isMainEntrance.value
        : this.isMainEntrance,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CavePlace copyWithCompanion(CavePlacesCompanion data) {
    return CavePlace(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      caveId: data.caveId.present ? data.caveId.value : this.caveId,
      placeQrCodeIdentifier: data.placeQrCodeIdentifier.present
          ? data.placeQrCodeIdentifier.value
          : this.placeQrCodeIdentifier,
      caveAreaId: data.caveAreaId.present
          ? data.caveAreaId.value
          : this.caveAreaId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('CavePlace(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('caveId: $caveId, ')
          ..write('placeQrCodeIdentifier: $placeQrCodeIdentifier, ')
          ..write('caveAreaId: $caveAreaId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('depthInCave: $depthInCave, ')
          ..write('isEntrance: $isEntrance, ')
          ..write('isMainEntrance: $isMainEntrance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    caveId,
    placeQrCodeIdentifier,
    caveAreaId,
    latitude,
    longitude,
    depthInCave,
    isEntrance,
    isMainEntrance,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CavePlace &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.caveId == this.caveId &&
          other.placeQrCodeIdentifier == this.placeQrCodeIdentifier &&
          other.caveAreaId == this.caveAreaId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.depthInCave == this.depthInCave &&
          other.isEntrance == this.isEntrance &&
          other.isMainEntrance == this.isMainEntrance &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CavePlacesCompanion extends UpdateCompanion<CavePlace> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<int> caveId;
  final Value<int?> placeQrCodeIdentifier;
  final Value<int?> caveAreaId;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<double?> depthInCave;
  final Value<int?> isEntrance;
  final Value<int?> isMainEntrance;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  const CavePlacesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.caveId = const Value.absent(),
    this.placeQrCodeIdentifier = const Value.absent(),
    this.caveAreaId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.depthInCave = const Value.absent(),
    this.isEntrance = const Value.absent(),
    this.isMainEntrance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  CavePlacesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required int caveId,
    this.placeQrCodeIdentifier = const Value.absent(),
    this.caveAreaId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.depthInCave = const Value.absent(),
    this.isEntrance = const Value.absent(),
    this.isMainEntrance = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title),
       caveId = Value(caveId);
  static Insertable<CavePlace> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<int>? caveId,
    Expression<int>? placeQrCodeIdentifier,
    Expression<int>? caveAreaId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? depthInCave,
    Expression<int>? isEntrance,
    Expression<int>? isMainEntrance,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (caveId != null) 'cave_id': caveId,
      if (placeQrCodeIdentifier != null)
        'place_qr_code_identifier': placeQrCodeIdentifier,
      if (caveAreaId != null) 'cave_area_id': caveAreaId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (depthInCave != null) 'depth_in_cave': depthInCave,
      if (isEntrance != null) 'is_entrance': isEntrance,
      if (isMainEntrance != null) 'is_main_entrance': isMainEntrance,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  CavePlacesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<int>? caveId,
    Value<int?>? placeQrCodeIdentifier,
    Value<int?>? caveAreaId,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<double?>? depthInCave,
    Value<int?>? isEntrance,
    Value<int?>? isMainEntrance,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return CavePlacesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      caveId: caveId ?? this.caveId,
      placeQrCodeIdentifier:
          placeQrCodeIdentifier ?? this.placeQrCodeIdentifier,
      caveAreaId: caveAreaId ?? this.caveAreaId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      depthInCave: depthInCave ?? this.depthInCave,
      isEntrance: isEntrance ?? this.isEntrance,
      isMainEntrance: isMainEntrance ?? this.isMainEntrance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (caveId.present) {
      map['cave_id'] = Variable<int>(caveId.value);
    }
    if (placeQrCodeIdentifier.present) {
      map['place_qr_code_identifier'] = Variable<int>(
        placeQrCodeIdentifier.value,
      );
    }
    if (caveAreaId.present) {
      map['cave_area_id'] = Variable<int>(caveAreaId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CavePlacesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('caveId: $caveId, ')
          ..write('placeQrCodeIdentifier: $placeQrCodeIdentifier, ')
          ..write('caveAreaId: $caveAreaId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('depthInCave: $depthInCave, ')
          ..write('isEntrance: $isEntrance, ')
          ..write('isMainEntrance: $isMainEntrance, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class RasterMaps extends Table with TableInfo<RasterMaps, RasterMap> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RasterMaps(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL',
  );
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
  static const VerificationMeta _caveIdMeta = const VerificationMeta('caveId');
  late final GeneratedColumn<int> caveId = GeneratedColumn<int>(
    'cave_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES caves(id)',
  );
  static const VerificationMeta _caveAreaIdMeta = const VerificationMeta(
    'caveAreaId',
  );
  late final GeneratedColumn<int> caveAreaId = GeneratedColumn<int>(
    'cave_area_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'REFERENCES cave_areas(id)',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    mapType,
    fileName,
    caveId,
    caveAreaId,
    createdAt,
    updatedAt,
    deletedAt,
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
    if (data.containsKey('cave_id')) {
      context.handle(
        _caveIdMeta,
        caveId.isAcceptableOrUnknown(data['cave_id']!, _caveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_caveIdMeta);
    }
    if (data.containsKey('cave_area_id')) {
      context.handle(
        _caveAreaIdMeta,
        caveAreaId.isAcceptableOrUnknown(
          data['cave_area_id']!,
          _caveAreaIdMeta,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title, mapType, caveId},
    {fileName, mapType, caveId},
  ];
  @override
  RasterMap map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RasterMap(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
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
      caveId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cave_id'],
      )!,
      caveAreaId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cave_area_id'],
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
    );
  }

  @override
  RasterMaps createAlias(String alias) {
    return RasterMaps(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(title, map_type, cave_id)ON CONFLICT ROLLBACK',
    'UNIQUE(file_name, map_type, cave_id)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class RasterMap extends DataClass implements Insertable<RasterMap> {
  final int id;
  final String title;
  final String mapType;
  final String fileName;
  final int caveId;
  final int? caveAreaId;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const RasterMap({
    required this.id,
    required this.title,
    required this.mapType,
    required this.fileName,
    required this.caveId,
    this.caveAreaId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['title'] = Variable<String>(title);
    map['map_type'] = Variable<String>(mapType);
    map['file_name'] = Variable<String>(fileName);
    map['cave_id'] = Variable<int>(caveId);
    if (!nullToAbsent || caveAreaId != null) {
      map['cave_area_id'] = Variable<int>(caveAreaId);
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
    return map;
  }

  RasterMapsCompanion toCompanion(bool nullToAbsent) {
    return RasterMapsCompanion(
      id: Value(id),
      title: Value(title),
      mapType: Value(mapType),
      fileName: Value(fileName),
      caveId: Value(caveId),
      caveAreaId: caveAreaId == null && nullToAbsent
          ? const Value.absent()
          : Value(caveAreaId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory RasterMap.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RasterMap(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      mapType: serializer.fromJson<String>(json['map_type']),
      fileName: serializer.fromJson<String>(json['file_name']),
      caveId: serializer.fromJson<int>(json['cave_id']),
      caveAreaId: serializer.fromJson<int?>(json['cave_area_id']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'map_type': serializer.toJson<String>(mapType),
      'file_name': serializer.toJson<String>(fileName),
      'cave_id': serializer.toJson<int>(caveId),
      'cave_area_id': serializer.toJson<int?>(caveAreaId),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  RasterMap copyWith({
    int? id,
    String? title,
    String? mapType,
    String? fileName,
    int? caveId,
    Value<int?> caveAreaId = const Value.absent(),
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => RasterMap(
    id: id ?? this.id,
    title: title ?? this.title,
    mapType: mapType ?? this.mapType,
    fileName: fileName ?? this.fileName,
    caveId: caveId ?? this.caveId,
    caveAreaId: caveAreaId.present ? caveAreaId.value : this.caveAreaId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  RasterMap copyWithCompanion(RasterMapsCompanion data) {
    return RasterMap(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      mapType: data.mapType.present ? data.mapType.value : this.mapType,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      caveId: data.caveId.present ? data.caveId.value : this.caveId,
      caveAreaId: data.caveAreaId.present
          ? data.caveAreaId.value
          : this.caveAreaId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RasterMap(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('mapType: $mapType, ')
          ..write('fileName: $fileName, ')
          ..write('caveId: $caveId, ')
          ..write('caveAreaId: $caveAreaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    mapType,
    fileName,
    caveId,
    caveAreaId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RasterMap &&
          other.id == this.id &&
          other.title == this.title &&
          other.mapType == this.mapType &&
          other.fileName == this.fileName &&
          other.caveId == this.caveId &&
          other.caveAreaId == this.caveAreaId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class RasterMapsCompanion extends UpdateCompanion<RasterMap> {
  final Value<int> id;
  final Value<String> title;
  final Value<String> mapType;
  final Value<String> fileName;
  final Value<int> caveId;
  final Value<int?> caveAreaId;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  const RasterMapsCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.mapType = const Value.absent(),
    this.fileName = const Value.absent(),
    this.caveId = const Value.absent(),
    this.caveAreaId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  RasterMapsCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    required String mapType,
    required String fileName,
    required int caveId,
    this.caveAreaId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title),
       mapType = Value(mapType),
       fileName = Value(fileName),
       caveId = Value(caveId);
  static Insertable<RasterMap> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? mapType,
    Expression<String>? fileName,
    Expression<int>? caveId,
    Expression<int>? caveAreaId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (mapType != null) 'map_type': mapType,
      if (fileName != null) 'file_name': fileName,
      if (caveId != null) 'cave_id': caveId,
      if (caveAreaId != null) 'cave_area_id': caveAreaId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  RasterMapsCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String>? mapType,
    Value<String>? fileName,
    Value<int>? caveId,
    Value<int?>? caveAreaId,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return RasterMapsCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      mapType: mapType ?? this.mapType,
      fileName: fileName ?? this.fileName,
      caveId: caveId ?? this.caveId,
      caveAreaId: caveAreaId ?? this.caveAreaId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    if (mapType.present) {
      map['map_type'] = Variable<String>(mapType.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (caveId.present) {
      map['cave_id'] = Variable<int>(caveId.value);
    }
    if (caveAreaId.present) {
      map['cave_area_id'] = Variable<int>(caveAreaId.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RasterMapsCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('mapType: $mapType, ')
          ..write('fileName: $fileName, ')
          ..write('caveId: $caveId, ')
          ..write('caveAreaId: $caveAreaId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL',
  );
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
  static const VerificationMeta _cavePlaceIdMeta = const VerificationMeta(
    'cavePlaceId',
  );
  late final GeneratedColumn<int> cavePlaceId = GeneratedColumn<int>(
    'cave_place_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES cave_places(id)',
  );
  static const VerificationMeta _rasterMapIdMeta = const VerificationMeta(
    'rasterMapId',
  );
  late final GeneratedColumn<int> rasterMapId = GeneratedColumn<int>(
    'raster_map_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES raster_maps(id)',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    xCoordinate,
    yCoordinate,
    cavePlaceId,
    rasterMapId,
    createdAt,
    updatedAt,
    deletedAt,
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
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
    if (data.containsKey('cave_place_id')) {
      context.handle(
        _cavePlaceIdMeta,
        cavePlaceId.isAcceptableOrUnknown(
          data['cave_place_id']!,
          _cavePlaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_cavePlaceIdMeta);
    }
    if (data.containsKey('raster_map_id')) {
      context.handle(
        _rasterMapIdMeta,
        rasterMapId.isAcceptableOrUnknown(
          data['raster_map_id']!,
          _rasterMapIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_rasterMapIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {cavePlaceId, rasterMapId},
  ];
  @override
  CavePlaceToRasterMapDefinition map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CavePlaceToRasterMapDefinition(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      xCoordinate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}x_coordinate'],
      ),
      yCoordinate: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}y_coordinate'],
      ),
      cavePlaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}cave_place_id'],
      )!,
      rasterMapId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}raster_map_id'],
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
    );
  }

  @override
  CavePlaceToRasterMapDefinitions createAlias(String alias) {
    return CavePlaceToRasterMapDefinitions(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(cave_place_id, raster_map_id)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class CavePlaceToRasterMapDefinition extends DataClass
    implements Insertable<CavePlaceToRasterMapDefinition> {
  final int id;
  final int? xCoordinate;

  /// x coordinate of the place's point on the raster map image; can be null if the place is not defined on a raster map; otherwise, it is required and should be a non-negative integer
  final int? yCoordinate;

  /// y coordinate of the place's point on the raster map image; can be null if the place is not defined on a raster map; otherwise, it is required and should be a non-negative integer
  final int cavePlaceId;
  final int rasterMapId;
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const CavePlaceToRasterMapDefinition({
    required this.id,
    this.xCoordinate,
    this.yCoordinate,
    required this.cavePlaceId,
    required this.rasterMapId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || xCoordinate != null) {
      map['x_coordinate'] = Variable<int>(xCoordinate);
    }
    if (!nullToAbsent || yCoordinate != null) {
      map['y_coordinate'] = Variable<int>(yCoordinate);
    }
    map['cave_place_id'] = Variable<int>(cavePlaceId);
    map['raster_map_id'] = Variable<int>(rasterMapId);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<int>(createdAt);
    }
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  CavePlaceToRasterMapDefinitionsCompanion toCompanion(bool nullToAbsent) {
    return CavePlaceToRasterMapDefinitionsCompanion(
      id: Value(id),
      xCoordinate: xCoordinate == null && nullToAbsent
          ? const Value.absent()
          : Value(xCoordinate),
      yCoordinate: yCoordinate == null && nullToAbsent
          ? const Value.absent()
          : Value(yCoordinate),
      cavePlaceId: Value(cavePlaceId),
      rasterMapId: Value(rasterMapId),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory CavePlaceToRasterMapDefinition.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CavePlaceToRasterMapDefinition(
      id: serializer.fromJson<int>(json['id']),
      xCoordinate: serializer.fromJson<int?>(json['x_coordinate']),
      yCoordinate: serializer.fromJson<int?>(json['y_coordinate']),
      cavePlaceId: serializer.fromJson<int>(json['cave_place_id']),
      rasterMapId: serializer.fromJson<int>(json['raster_map_id']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'x_coordinate': serializer.toJson<int?>(xCoordinate),
      'y_coordinate': serializer.toJson<int?>(yCoordinate),
      'cave_place_id': serializer.toJson<int>(cavePlaceId),
      'raster_map_id': serializer.toJson<int>(rasterMapId),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  CavePlaceToRasterMapDefinition copyWith({
    int? id,
    Value<int?> xCoordinate = const Value.absent(),
    Value<int?> yCoordinate = const Value.absent(),
    int? cavePlaceId,
    int? rasterMapId,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => CavePlaceToRasterMapDefinition(
    id: id ?? this.id,
    xCoordinate: xCoordinate.present ? xCoordinate.value : this.xCoordinate,
    yCoordinate: yCoordinate.present ? yCoordinate.value : this.yCoordinate,
    cavePlaceId: cavePlaceId ?? this.cavePlaceId,
    rasterMapId: rasterMapId ?? this.rasterMapId,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  CavePlaceToRasterMapDefinition copyWithCompanion(
    CavePlaceToRasterMapDefinitionsCompanion data,
  ) {
    return CavePlaceToRasterMapDefinition(
      id: data.id.present ? data.id.value : this.id,
      xCoordinate: data.xCoordinate.present
          ? data.xCoordinate.value
          : this.xCoordinate,
      yCoordinate: data.yCoordinate.present
          ? data.yCoordinate.value
          : this.yCoordinate,
      cavePlaceId: data.cavePlaceId.present
          ? data.cavePlaceId.value
          : this.cavePlaceId,
      rasterMapId: data.rasterMapId.present
          ? data.rasterMapId.value
          : this.rasterMapId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CavePlaceToRasterMapDefinition(')
          ..write('id: $id, ')
          ..write('xCoordinate: $xCoordinate, ')
          ..write('yCoordinate: $yCoordinate, ')
          ..write('cavePlaceId: $cavePlaceId, ')
          ..write('rasterMapId: $rasterMapId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    xCoordinate,
    yCoordinate,
    cavePlaceId,
    rasterMapId,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CavePlaceToRasterMapDefinition &&
          other.id == this.id &&
          other.xCoordinate == this.xCoordinate &&
          other.yCoordinate == this.yCoordinate &&
          other.cavePlaceId == this.cavePlaceId &&
          other.rasterMapId == this.rasterMapId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class CavePlaceToRasterMapDefinitionsCompanion
    extends UpdateCompanion<CavePlaceToRasterMapDefinition> {
  final Value<int> id;
  final Value<int?> xCoordinate;
  final Value<int?> yCoordinate;
  final Value<int> cavePlaceId;
  final Value<int> rasterMapId;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  const CavePlaceToRasterMapDefinitionsCompanion({
    this.id = const Value.absent(),
    this.xCoordinate = const Value.absent(),
    this.yCoordinate = const Value.absent(),
    this.cavePlaceId = const Value.absent(),
    this.rasterMapId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  CavePlaceToRasterMapDefinitionsCompanion.insert({
    this.id = const Value.absent(),
    this.xCoordinate = const Value.absent(),
    this.yCoordinate = const Value.absent(),
    required int cavePlaceId,
    required int rasterMapId,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : cavePlaceId = Value(cavePlaceId),
       rasterMapId = Value(rasterMapId);
  static Insertable<CavePlaceToRasterMapDefinition> custom({
    Expression<int>? id,
    Expression<int>? xCoordinate,
    Expression<int>? yCoordinate,
    Expression<int>? cavePlaceId,
    Expression<int>? rasterMapId,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (xCoordinate != null) 'x_coordinate': xCoordinate,
      if (yCoordinate != null) 'y_coordinate': yCoordinate,
      if (cavePlaceId != null) 'cave_place_id': cavePlaceId,
      if (rasterMapId != null) 'raster_map_id': rasterMapId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  CavePlaceToRasterMapDefinitionsCompanion copyWith({
    Value<int>? id,
    Value<int?>? xCoordinate,
    Value<int?>? yCoordinate,
    Value<int>? cavePlaceId,
    Value<int>? rasterMapId,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return CavePlaceToRasterMapDefinitionsCompanion(
      id: id ?? this.id,
      xCoordinate: xCoordinate ?? this.xCoordinate,
      yCoordinate: yCoordinate ?? this.yCoordinate,
      cavePlaceId: cavePlaceId ?? this.cavePlaceId,
      rasterMapId: rasterMapId ?? this.rasterMapId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (xCoordinate.present) {
      map['x_coordinate'] = Variable<int>(xCoordinate.value);
    }
    if (yCoordinate.present) {
      map['y_coordinate'] = Variable<int>(yCoordinate.value);
    }
    if (cavePlaceId.present) {
      map['cave_place_id'] = Variable<int>(cavePlaceId.value);
    }
    if (rasterMapId.present) {
      map['raster_map_id'] = Variable<int>(rasterMapId.value);
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CavePlaceToRasterMapDefinitionsCompanion(')
          ..write('id: $id, ')
          ..write('xCoordinate: $xCoordinate, ')
          ..write('yCoordinate: $yCoordinate, ')
          ..write('cavePlaceId: $cavePlaceId, ')
          ..write('rasterMapId: $rasterMapId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL',
  );
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    description,
    fileName,
    fileSize,
    fileHash,
    fileType,
    createdAt,
    updatedAt,
    deletedAt,
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {title, fileName, fileSize, fileHash},
  ];
  @override
  DocumentationFile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentationFile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
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
    );
  }

  @override
  DocumentationFiles createAlias(String alias) {
    return DocumentationFiles(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(title, file_name, file_size, file_hash)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class DocumentationFile extends DataClass
    implements Insertable<DocumentationFile> {
  final int id;
  final String title;
  final String? description;
  final String fileName;
  final int fileSize;
  final String? fileHash;
  final String fileType;

  /// "photo", "video", "audio", "text_document", "web_link", etc.
  final int? createdAt;
  final int? updatedAt;
  final int? deletedAt;
  const DocumentationFile({
    required this.id,
    required this.title,
    this.description,
    required this.fileName,
    required this.fileSize,
    this.fileHash,
    required this.fileType,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
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
    return map;
  }

  DocumentationFilesCompanion toCompanion(bool nullToAbsent) {
    return DocumentationFilesCompanion(
      id: Value(id),
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
    );
  }

  factory DocumentationFile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentationFile(
      id: serializer.fromJson<int>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      fileName: serializer.fromJson<String>(json['file_name']),
      fileSize: serializer.fromJson<int>(json['file_size']),
      fileHash: serializer.fromJson<String?>(json['file_hash']),
      fileType: serializer.fromJson<String>(json['file_type']),
      createdAt: serializer.fromJson<int?>(json['created_at']),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'file_name': serializer.toJson<String>(fileName),
      'file_size': serializer.toJson<int>(fileSize),
      'file_hash': serializer.toJson<String?>(fileHash),
      'file_type': serializer.toJson<String>(fileType),
      'created_at': serializer.toJson<int?>(createdAt),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  DocumentationFile copyWith({
    int? id,
    String? title,
    Value<String?> description = const Value.absent(),
    String? fileName,
    int? fileSize,
    Value<String?> fileHash = const Value.absent(),
    String? fileType,
    Value<int?> createdAt = const Value.absent(),
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => DocumentationFile(
    id: id ?? this.id,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    fileName: fileName ?? this.fileName,
    fileSize: fileSize ?? this.fileSize,
    fileHash: fileHash.present ? fileHash.value : this.fileHash,
    fileType: fileType ?? this.fileType,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  DocumentationFile copyWithCompanion(DocumentationFilesCompanion data) {
    return DocumentationFile(
      id: data.id.present ? data.id.value : this.id,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentationFile(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileType: $fileType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    fileName,
    fileSize,
    fileHash,
    fileType,
    createdAt,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentationFile &&
          other.id == this.id &&
          other.title == this.title &&
          other.description == this.description &&
          other.fileName == this.fileName &&
          other.fileSize == this.fileSize &&
          other.fileHash == this.fileHash &&
          other.fileType == this.fileType &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class DocumentationFilesCompanion extends UpdateCompanion<DocumentationFile> {
  final Value<int> id;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> fileName;
  final Value<int> fileSize;
  final Value<String?> fileHash;
  final Value<String> fileType;
  final Value<int?> createdAt;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  const DocumentationFilesCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSize = const Value.absent(),
    this.fileHash = const Value.absent(),
    this.fileType = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  DocumentationFilesCompanion.insert({
    this.id = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required String fileName,
    required int fileSize,
    this.fileHash = const Value.absent(),
    required String fileType,
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : title = Value(title),
       fileName = Value(fileName),
       fileSize = Value(fileSize),
       fileType = Value(fileType);
  static Insertable<DocumentationFile> custom({
    Expression<int>? id,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? fileName,
    Expression<int>? fileSize,
    Expression<String>? fileHash,
    Expression<String>? fileType,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (fileName != null) 'file_name': fileName,
      if (fileSize != null) 'file_size': fileSize,
      if (fileHash != null) 'file_hash': fileHash,
      if (fileType != null) 'file_type': fileType,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  DocumentationFilesCompanion copyWith({
    Value<int>? id,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? fileName,
    Value<int>? fileSize,
    Value<String?>? fileHash,
    Value<String>? fileType,
    Value<int?>? createdAt,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return DocumentationFilesCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      fileHash: fileHash ?? this.fileHash,
      fileType: fileType ?? this.fileType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
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
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentationFilesCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('fileName: $fileName, ')
          ..write('fileSize: $fileSize, ')
          ..write('fileHash: $fileHash, ')
          ..write('fileType: $fileType, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
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
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL',
  );
  static const VerificationMeta _geofeatureIdMeta = const VerificationMeta(
    'geofeatureId',
  );
  late final GeneratedColumn<int> geofeatureId = GeneratedColumn<int>(
    'geofeature_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
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
  static const VerificationMeta _documentationFileIdMeta =
      const VerificationMeta('documentationFileId');
  late final GeneratedColumn<int> documentationFileId = GeneratedColumn<int>(
    'documentation_file_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL REFERENCES documentation_files(id)',
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    geofeatureId,
    geofeatureType,
    documentationFileId,
    updatedAt,
    deletedAt,
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
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('geofeature_id')) {
      context.handle(
        _geofeatureIdMeta,
        geofeatureId.isAcceptableOrUnknown(
          data['geofeature_id']!,
          _geofeatureIdMeta,
        ),
      );
    }
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
    if (data.containsKey('documentation_file_id')) {
      context.handle(
        _documentationFileIdMeta,
        documentationFileId.isAcceptableOrUnknown(
          data['documentation_file_id']!,
          _documentationFileIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_documentationFileIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {geofeatureId, geofeatureType, documentationFileId},
  ];
  @override
  DocumentationFilesToGeofeature map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DocumentationFilesToGeofeature(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      geofeatureId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}geofeature_id'],
      ),
      geofeatureType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}geofeature_type'],
      )!,
      documentationFileId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}documentation_file_id'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      ),
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  DocumentationFilesToGeofeatures createAlias(String alias) {
    return DocumentationFilesToGeofeatures(attachedDatabase, alias);
  }

  @override
  List<String> get customConstraints => const [
    'UNIQUE(geofeature_id, geofeature_type, documentation_file_id)ON CONFLICT ROLLBACK',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class DocumentationFilesToGeofeature extends DataClass
    implements Insertable<DocumentationFilesToGeofeature> {
  final int id;
  final int? geofeatureId;

  /// pseudo foreign key to one of these tables: {caves, cave_places, cave_areas}; enforced by code
  final String geofeatureType;

  /// can be "cave", "cave_place", or "cave_area"; enforced by code
  final int documentationFileId;
  final int? updatedAt;
  final int? deletedAt;
  const DocumentationFilesToGeofeature({
    required this.id,
    this.geofeatureId,
    required this.geofeatureType,
    required this.documentationFileId,
    this.updatedAt,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    if (!nullToAbsent || geofeatureId != null) {
      map['geofeature_id'] = Variable<int>(geofeatureId);
    }
    map['geofeature_type'] = Variable<String>(geofeatureType);
    map['documentation_file_id'] = Variable<int>(documentationFileId);
    if (!nullToAbsent || updatedAt != null) {
      map['updated_at'] = Variable<int>(updatedAt);
    }
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  DocumentationFilesToGeofeaturesCompanion toCompanion(bool nullToAbsent) {
    return DocumentationFilesToGeofeaturesCompanion(
      id: Value(id),
      geofeatureId: geofeatureId == null && nullToAbsent
          ? const Value.absent()
          : Value(geofeatureId),
      geofeatureType: Value(geofeatureType),
      documentationFileId: Value(documentationFileId),
      updatedAt: updatedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory DocumentationFilesToGeofeature.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DocumentationFilesToGeofeature(
      id: serializer.fromJson<int>(json['id']),
      geofeatureId: serializer.fromJson<int?>(json['geofeature_id']),
      geofeatureType: serializer.fromJson<String>(json['geofeature_type']),
      documentationFileId: serializer.fromJson<int>(
        json['documentation_file_id'],
      ),
      updatedAt: serializer.fromJson<int?>(json['updated_at']),
      deletedAt: serializer.fromJson<int?>(json['deleted_at']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'geofeature_id': serializer.toJson<int?>(geofeatureId),
      'geofeature_type': serializer.toJson<String>(geofeatureType),
      'documentation_file_id': serializer.toJson<int>(documentationFileId),
      'updated_at': serializer.toJson<int?>(updatedAt),
      'deleted_at': serializer.toJson<int?>(deletedAt),
    };
  }

  DocumentationFilesToGeofeature copyWith({
    int? id,
    Value<int?> geofeatureId = const Value.absent(),
    String? geofeatureType,
    int? documentationFileId,
    Value<int?> updatedAt = const Value.absent(),
    Value<int?> deletedAt = const Value.absent(),
  }) => DocumentationFilesToGeofeature(
    id: id ?? this.id,
    geofeatureId: geofeatureId.present ? geofeatureId.value : this.geofeatureId,
    geofeatureType: geofeatureType ?? this.geofeatureType,
    documentationFileId: documentationFileId ?? this.documentationFileId,
    updatedAt: updatedAt.present ? updatedAt.value : this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  DocumentationFilesToGeofeature copyWithCompanion(
    DocumentationFilesToGeofeaturesCompanion data,
  ) {
    return DocumentationFilesToGeofeature(
      id: data.id.present ? data.id.value : this.id,
      geofeatureId: data.geofeatureId.present
          ? data.geofeatureId.value
          : this.geofeatureId,
      geofeatureType: data.geofeatureType.present
          ? data.geofeatureType.value
          : this.geofeatureType,
      documentationFileId: data.documentationFileId.present
          ? data.documentationFileId.value
          : this.documentationFileId,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DocumentationFilesToGeofeature(')
          ..write('id: $id, ')
          ..write('geofeatureId: $geofeatureId, ')
          ..write('geofeatureType: $geofeatureType, ')
          ..write('documentationFileId: $documentationFileId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    geofeatureId,
    geofeatureType,
    documentationFileId,
    updatedAt,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DocumentationFilesToGeofeature &&
          other.id == this.id &&
          other.geofeatureId == this.geofeatureId &&
          other.geofeatureType == this.geofeatureType &&
          other.documentationFileId == this.documentationFileId &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt);
}

class DocumentationFilesToGeofeaturesCompanion
    extends UpdateCompanion<DocumentationFilesToGeofeature> {
  final Value<int> id;
  final Value<int?> geofeatureId;
  final Value<String> geofeatureType;
  final Value<int> documentationFileId;
  final Value<int?> updatedAt;
  final Value<int?> deletedAt;
  const DocumentationFilesToGeofeaturesCompanion({
    this.id = const Value.absent(),
    this.geofeatureId = const Value.absent(),
    this.geofeatureType = const Value.absent(),
    this.documentationFileId = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  DocumentationFilesToGeofeaturesCompanion.insert({
    this.id = const Value.absent(),
    this.geofeatureId = const Value.absent(),
    required String geofeatureType,
    required int documentationFileId,
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
  }) : geofeatureType = Value(geofeatureType),
       documentationFileId = Value(documentationFileId);
  static Insertable<DocumentationFilesToGeofeature> custom({
    Expression<int>? id,
    Expression<int>? geofeatureId,
    Expression<String>? geofeatureType,
    Expression<int>? documentationFileId,
    Expression<int>? updatedAt,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (geofeatureId != null) 'geofeature_id': geofeatureId,
      if (geofeatureType != null) 'geofeature_type': geofeatureType,
      if (documentationFileId != null)
        'documentation_file_id': documentationFileId,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  DocumentationFilesToGeofeaturesCompanion copyWith({
    Value<int>? id,
    Value<int?>? geofeatureId,
    Value<String>? geofeatureType,
    Value<int>? documentationFileId,
    Value<int?>? updatedAt,
    Value<int?>? deletedAt,
  }) {
    return DocumentationFilesToGeofeaturesCompanion(
      id: id ?? this.id,
      geofeatureId: geofeatureId ?? this.geofeatureId,
      geofeatureType: geofeatureType ?? this.geofeatureType,
      documentationFileId: documentationFileId ?? this.documentationFileId,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (geofeatureId.present) {
      map['geofeature_id'] = Variable<int>(geofeatureId.value);
    }
    if (geofeatureType.present) {
      map['geofeature_type'] = Variable<String>(geofeatureType.value);
    }
    if (documentationFileId.present) {
      map['documentation_file_id'] = Variable<int>(documentationFileId.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DocumentationFilesToGeofeaturesCompanion(')
          ..write('id: $id, ')
          ..write('geofeatureId: $geofeatureId, ')
          ..write('geofeatureType: $geofeatureType, ')
          ..write('documentationFileId: $documentationFileId, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt')
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
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT UNIQUE NOT NULL',
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
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
  ];
}

typedef $SurfaceAreasCreateCompanionBuilder =
    SurfaceAreasCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });
typedef $SurfaceAreasUpdateCompanionBuilder =
    SurfaceAreasCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });

final class $SurfaceAreasReferences
    extends BaseReferences<_$AppDatabase, SurfaceAreas, SurfaceArea> {
  $SurfaceAreasReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<Caves, List<Cave>> _cavesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.caves,
    aliasName: $_aliasNameGenerator(db.surfaceAreas.id, db.caves.surfaceAreaId),
  );

  $CavesProcessedTableManager get cavesRefs {
    final manager = $CavesTableManager(
      $_db,
      $_db.caves,
    ).filter((f) => f.surfaceAreaId.id.sqlEquals($_itemColumn<int>('id')!));

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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
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

  Expression<bool> cavesRefs(
    Expression<bool> Function($CavesFilterComposer f) f,
  ) {
    final $CavesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.surfaceAreaId,
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

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

  Expression<T> cavesRefs<T extends Object>(
    Expression<T> Function($CavesAnnotationComposer a) f,
  ) {
    final $CavesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.surfaceAreaId,
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
          PrefetchHooks Function({bool cavesRefs})
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
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => SurfaceAreasCompanion(
                id: id,
                title: title,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => SurfaceAreasCompanion.insert(
                id: id,
                title: title,
                description: description,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $SurfaceAreasReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({cavesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (cavesRefs) db.caves],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (cavesRefs)
                    await $_getPrefetchedData<SurfaceArea, SurfaceAreas, Cave>(
                      currentTable: table,
                      referencedTable: $SurfaceAreasReferences._cavesRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $SurfaceAreasReferences(db, table, p0).cavesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.surfaceAreaId == item.id,
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
      PrefetchHooks Function({bool cavesRefs})
    >;
typedef $CavesCreateCompanionBuilder =
    CavesCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      Value<int?> surfaceAreaId,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });
typedef $CavesUpdateCompanionBuilder =
    CavesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<int?> surfaceAreaId,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });

final class $CavesReferences
    extends BaseReferences<_$AppDatabase, Caves, Cave> {
  $CavesReferences(super.$_db, super.$_table, super.$_typedResult);

  static SurfaceAreas _surfaceAreaIdTable(_$AppDatabase db) =>
      db.surfaceAreas.createAlias(
        $_aliasNameGenerator(db.caves.surfaceAreaId, db.surfaceAreas.id),
      );

  $SurfaceAreasProcessedTableManager? get surfaceAreaId {
    final $_column = $_itemColumn<int>('surface_area_id');
    if ($_column == null) return null;
    final manager = $SurfaceAreasTableManager(
      $_db,
      $_db.surfaceAreas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surfaceAreaIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<CaveAreas, List<CaveArea>> _caveAreasRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.caveAreas,
    aliasName: $_aliasNameGenerator(db.caves.id, db.caveAreas.caveId),
  );

  $CaveAreasProcessedTableManager get caveAreasRefs {
    final manager = $CaveAreasTableManager(
      $_db,
      $_db.caveAreas,
    ).filter((f) => f.caveId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_caveAreasRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CaveEntrances, List<CaveEntrance>>
  _caveEntrancesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.caveEntrances,
    aliasName: $_aliasNameGenerator(db.caves.id, db.caveEntrances.caveId),
  );

  $CaveEntrancesProcessedTableManager get caveEntrancesRefs {
    final manager = $CaveEntrancesTableManager(
      $_db,
      $_db.caveEntrances,
    ).filter((f) => f.caveId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_caveEntrancesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<CavePlaces, List<CavePlace>> _cavePlacesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cavePlaces,
    aliasName: $_aliasNameGenerator(db.caves.id, db.cavePlaces.caveId),
  );

  $CavePlacesProcessedTableManager get cavePlacesRefs {
    final manager = $CavePlacesTableManager(
      $_db,
      $_db.cavePlaces,
    ).filter((f) => f.caveId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cavePlacesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<RasterMaps, List<RasterMap>> _rasterMapsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rasterMaps,
    aliasName: $_aliasNameGenerator(db.caves.id, db.rasterMaps.caveId),
  );

  $RasterMapsProcessedTableManager get rasterMapsRefs {
    final manager = $RasterMapsTableManager(
      $_db,
      $_db.rasterMaps,
    ).filter((f) => f.caveId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_rasterMapsRefsTable($_db));
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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
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

  $SurfaceAreasFilterComposer get surfaceAreaId {
    final $SurfaceAreasFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfaceAreaId,
      referencedTable: $db.surfaceAreas,
      getReferencedColumn: (t) => t.id,
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

  Expression<bool> caveAreasRefs(
    Expression<bool> Function($CaveAreasFilterComposer f) f,
  ) {
    final $CaveAreasFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.caveId,
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.caveEntrances,
      getReferencedColumn: (t) => t.caveId,
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.caveId,
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.caveId,
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

class $CavesOrderingComposer extends Composer<_$AppDatabase, Caves> {
  $CavesOrderingComposer({
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

  $SurfaceAreasOrderingComposer get surfaceAreaId {
    final $SurfaceAreasOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfaceAreaId,
      referencedTable: $db.surfaceAreas,
      getReferencedColumn: (t) => t.id,
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
}

class $CavesAnnotationComposer extends Composer<_$AppDatabase, Caves> {
  $CavesAnnotationComposer({
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

  $SurfaceAreasAnnotationComposer get surfaceAreaId {
    final $SurfaceAreasAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfaceAreaId,
      referencedTable: $db.surfaceAreas,
      getReferencedColumn: (t) => t.id,
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

  Expression<T> caveAreasRefs<T extends Object>(
    Expression<T> Function($CaveAreasAnnotationComposer a) f,
  ) {
    final $CaveAreasAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.caveId,
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.caveEntrances,
      getReferencedColumn: (t) => t.caveId,
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.caveId,
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.caveId,
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
            bool surfaceAreaId,
            bool caveAreasRefs,
            bool caveEntrancesRefs,
            bool cavePlacesRefs,
            bool rasterMapsRefs,
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
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int?> surfaceAreaId = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => CavesCompanion(
                id: id,
                title: title,
                description: description,
                surfaceAreaId: surfaceAreaId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<int?> surfaceAreaId = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => CavesCompanion.insert(
                id: id,
                title: title,
                description: description,
                surfaceAreaId: surfaceAreaId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), $CavesReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback:
              ({
                surfaceAreaId = false,
                caveAreasRefs = false,
                caveEntrancesRefs = false,
                cavePlacesRefs = false,
                rasterMapsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (caveAreasRefs) db.caveAreas,
                    if (caveEntrancesRefs) db.caveEntrances,
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
                        if (surfaceAreaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.surfaceAreaId,
                                    referencedTable: $CavesReferences
                                        ._surfaceAreaIdTable(db),
                                    referencedColumn: $CavesReferences
                                        ._surfaceAreaIdTable(db)
                                        .id,
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
                                (e) => e.caveId == item.id,
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
                                (e) => e.caveId == item.id,
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
                                (e) => e.caveId == item.id,
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
                                (e) => e.caveId == item.id,
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
        bool surfaceAreaId,
        bool caveAreasRefs,
        bool caveEntrancesRefs,
        bool cavePlacesRefs,
        bool rasterMapsRefs,
      })
    >;
typedef $CaveAreasCreateCompanionBuilder =
    CaveAreasCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      required int caveId,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });
typedef $CaveAreasUpdateCompanionBuilder =
    CaveAreasCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<int> caveId,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });

final class $CaveAreasReferences
    extends BaseReferences<_$AppDatabase, CaveAreas, CaveArea> {
  $CaveAreasReferences(super.$_db, super.$_table, super.$_typedResult);

  static Caves _caveIdTable(_$AppDatabase db) => db.caves.createAlias(
    $_aliasNameGenerator(db.caveAreas.caveId, db.caves.id),
  );

  $CavesProcessedTableManager get caveId {
    final $_column = $_itemColumn<int>('cave_id')!;

    final manager = $CavesTableManager(
      $_db,
      $_db.caves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<CavePlaces, List<CavePlace>> _cavePlacesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.cavePlaces,
    aliasName: $_aliasNameGenerator(db.caveAreas.id, db.cavePlaces.caveAreaId),
  );

  $CavePlacesProcessedTableManager get cavePlacesRefs {
    final manager = $CavePlacesTableManager(
      $_db,
      $_db.cavePlaces,
    ).filter((f) => f.caveAreaId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_cavePlacesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<RasterMaps, List<RasterMap>> _rasterMapsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.rasterMaps,
    aliasName: $_aliasNameGenerator(db.caveAreas.id, db.rasterMaps.caveAreaId),
  );

  $RasterMapsProcessedTableManager get rasterMapsRefs {
    final manager = $RasterMapsTableManager(
      $_db,
      $_db.rasterMaps,
    ).filter((f) => f.caveAreaId.id.sqlEquals($_itemColumn<int>('id')!));

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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
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

  $CavesFilterComposer get caveId {
    final $CavesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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

  Expression<bool> cavePlacesRefs(
    Expression<bool> Function($CavePlacesFilterComposer f) f,
  ) {
    final $CavePlacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.caveAreaId,
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.caveAreaId,
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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

  $CavesOrderingComposer get caveId {
    final $CavesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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
}

class $CaveAreasAnnotationComposer extends Composer<_$AppDatabase, CaveAreas> {
  $CaveAreasAnnotationComposer({
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

  $CavesAnnotationComposer get caveId {
    final $CavesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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

  Expression<T> cavePlacesRefs<T extends Object>(
    Expression<T> Function($CavePlacesAnnotationComposer a) f,
  ) {
    final $CavePlacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.caveAreaId,
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
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.caveAreaId,
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
            bool caveId,
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
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> caveId = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => CaveAreasCompanion(
                id: id,
                title: title,
                description: description,
                caveId: caveId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required int caveId,
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => CaveAreasCompanion.insert(
                id: id,
                title: title,
                description: description,
                caveId: caveId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (e.readTable(table), $CaveAreasReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                caveId = false,
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
                        if (caveId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveId,
                                    referencedTable: $CaveAreasReferences
                                        ._caveIdTable(db),
                                    referencedColumn: $CaveAreasReferences
                                        ._caveIdTable(db)
                                        .id,
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
                                (e) => e.caveAreaId == item.id,
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
                                (e) => e.caveAreaId == item.id,
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
        bool caveId,
        bool cavePlacesRefs,
        bool rasterMapsRefs,
      })
    >;
typedef $SurfacePlacesCreateCompanionBuilder =
    SurfacePlacesCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      Value<String?> type,
      Value<int?> surfacePlaceQrCodeIdentifier,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });
typedef $SurfacePlacesUpdateCompanionBuilder =
    SurfacePlacesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<String?> type,
      Value<int?> surfacePlaceQrCodeIdentifier,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });

final class $SurfacePlacesReferences
    extends BaseReferences<_$AppDatabase, SurfacePlaces, SurfacePlace> {
  $SurfacePlacesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<CaveEntrances, List<CaveEntrance>>
  _caveEntrancesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.caveEntrances,
    aliasName: $_aliasNameGenerator(
      db.surfacePlaces.id,
      db.caveEntrances.surfacePlaceId,
    ),
  );

  $CaveEntrancesProcessedTableManager get caveEntrancesRefs {
    final manager = $CaveEntrancesTableManager(
      $_db,
      $_db.caveEntrances,
    ).filter((f) => f.surfacePlaceId.id.sqlEquals($_itemColumn<int>('id')!));

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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
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

  Expression<bool> caveEntrancesRefs(
    Expression<bool> Function($CaveEntrancesFilterComposer f) f,
  ) {
    final $CaveEntrancesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.caveEntrances,
      getReferencedColumn: (t) => t.surfacePlaceId,
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

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

  Expression<T> caveEntrancesRefs<T extends Object>(
    Expression<T> Function($CaveEntrancesAnnotationComposer a) f,
  ) {
    final $CaveEntrancesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.caveEntrances,
      getReferencedColumn: (t) => t.surfacePlaceId,
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
          PrefetchHooks Function({bool caveEntrancesRefs})
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
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<int?> surfacePlaceQrCodeIdentifier = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => SurfacePlacesCompanion(
                id: id,
                title: title,
                description: description,
                type: type,
                surfacePlaceQrCodeIdentifier: surfacePlaceQrCodeIdentifier,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> type = const Value.absent(),
                Value<int?> surfacePlaceQrCodeIdentifier = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => SurfacePlacesCompanion.insert(
                id: id,
                title: title,
                description: description,
                type: type,
                surfacePlaceQrCodeIdentifier: surfacePlaceQrCodeIdentifier,
                latitude: latitude,
                longitude: longitude,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $SurfacePlacesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({caveEntrancesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (caveEntrancesRefs) db.caveEntrances,
              ],
              addJoins: null,
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
                      managerFromTypedResult: (p0) => $SurfacePlacesReferences(
                        db,
                        table,
                        p0,
                      ).caveEntrancesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.surfacePlaceId == item.id,
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
      PrefetchHooks Function({bool caveEntrancesRefs})
    >;
typedef $CaveEntrancesCreateCompanionBuilder =
    CaveEntrancesCompanion Function({
      Value<int> id,
      required int caveId,
      Value<int?> surfacePlaceId,
      Value<int?> isMainEntrance,
      Value<String?> title,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });
typedef $CaveEntrancesUpdateCompanionBuilder =
    CaveEntrancesCompanion Function({
      Value<int> id,
      Value<int> caveId,
      Value<int?> surfacePlaceId,
      Value<int?> isMainEntrance,
      Value<String?> title,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });

final class $CaveEntrancesReferences
    extends BaseReferences<_$AppDatabase, CaveEntrances, CaveEntrance> {
  $CaveEntrancesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Caves _caveIdTable(_$AppDatabase db) => db.caves.createAlias(
    $_aliasNameGenerator(db.caveEntrances.caveId, db.caves.id),
  );

  $CavesProcessedTableManager get caveId {
    final $_column = $_itemColumn<int>('cave_id')!;

    final manager = $CavesTableManager(
      $_db,
      $_db.caves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static SurfacePlaces _surfacePlaceIdTable(_$AppDatabase db) =>
      db.surfacePlaces.createAlias(
        $_aliasNameGenerator(
          db.caveEntrances.surfacePlaceId,
          db.surfacePlaces.id,
        ),
      );

  $SurfacePlacesProcessedTableManager? get surfacePlaceId {
    final $_column = $_itemColumn<int>('surface_place_id');
    if ($_column == null) return null;
    final manager = $SurfacePlacesTableManager(
      $_db,
      $_db.surfacePlaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_surfacePlaceIdTable($_db));
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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
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

  $CavesFilterComposer get caveId {
    final $CavesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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

  $SurfacePlacesFilterComposer get surfacePlaceId {
    final $SurfacePlacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfacePlaceId,
      referencedTable: $db.surfacePlaces,
      getReferencedColumn: (t) => t.id,
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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

  $CavesOrderingComposer get caveId {
    final $CavesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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

  $SurfacePlacesOrderingComposer get surfacePlaceId {
    final $SurfacePlacesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfacePlaceId,
      referencedTable: $db.surfacePlaces,
      getReferencedColumn: (t) => t.id,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

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

  $CavesAnnotationComposer get caveId {
    final $CavesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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

  $SurfacePlacesAnnotationComposer get surfacePlaceId {
    final $SurfacePlacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.surfacePlaceId,
      referencedTable: $db.surfacePlaces,
      getReferencedColumn: (t) => t.id,
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
          PrefetchHooks Function({bool caveId, bool surfacePlaceId})
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
                Value<int> id = const Value.absent(),
                Value<int> caveId = const Value.absent(),
                Value<int?> surfacePlaceId = const Value.absent(),
                Value<int?> isMainEntrance = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => CaveEntrancesCompanion(
                id: id,
                caveId: caveId,
                surfacePlaceId: surfacePlaceId,
                isMainEntrance: isMainEntrance,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int caveId,
                Value<int?> surfacePlaceId = const Value.absent(),
                Value<int?> isMainEntrance = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => CaveEntrancesCompanion.insert(
                id: id,
                caveId: caveId,
                surfacePlaceId: surfacePlaceId,
                isMainEntrance: isMainEntrance,
                title: title,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CaveEntrancesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({caveId = false, surfacePlaceId = false}) {
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
                    if (caveId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.caveId,
                                referencedTable: $CaveEntrancesReferences
                                    ._caveIdTable(db),
                                referencedColumn: $CaveEntrancesReferences
                                    ._caveIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (surfacePlaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.surfacePlaceId,
                                referencedTable: $CaveEntrancesReferences
                                    ._surfacePlaceIdTable(db),
                                referencedColumn: $CaveEntrancesReferences
                                    ._surfacePlaceIdTable(db)
                                    .id,
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
      PrefetchHooks Function({bool caveId, bool surfacePlaceId})
    >;
typedef $CavePlacesCreateCompanionBuilder =
    CavePlacesCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      required int caveId,
      Value<int?> placeQrCodeIdentifier,
      Value<int?> caveAreaId,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<double?> depthInCave,
      Value<int?> isEntrance,
      Value<int?> isMainEntrance,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });
typedef $CavePlacesUpdateCompanionBuilder =
    CavePlacesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<int> caveId,
      Value<int?> placeQrCodeIdentifier,
      Value<int?> caveAreaId,
      Value<double?> latitude,
      Value<double?> longitude,
      Value<double?> depthInCave,
      Value<int?> isEntrance,
      Value<int?> isMainEntrance,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });

final class $CavePlacesReferences
    extends BaseReferences<_$AppDatabase, CavePlaces, CavePlace> {
  $CavePlacesReferences(super.$_db, super.$_table, super.$_typedResult);

  static Caves _caveIdTable(_$AppDatabase db) => db.caves.createAlias(
    $_aliasNameGenerator(db.cavePlaces.caveId, db.caves.id),
  );

  $CavesProcessedTableManager get caveId {
    final $_column = $_itemColumn<int>('cave_id')!;

    final manager = $CavesTableManager(
      $_db,
      $_db.caves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static CaveAreas _caveAreaIdTable(_$AppDatabase db) =>
      db.caveAreas.createAlias(
        $_aliasNameGenerator(db.cavePlaces.caveAreaId, db.caveAreas.id),
      );

  $CaveAreasProcessedTableManager? get caveAreaId {
    final $_column = $_itemColumn<int>('cave_area_id');
    if ($_column == null) return null;
    final manager = $CaveAreasTableManager(
      $_db,
      $_db.caveAreas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveAreaIdTable($_db));
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
          db.cavePlaces.id,
          db.cavePlaceToRasterMapDefinitions.cavePlaceId,
        ),
      );

  $CavePlaceToRasterMapDefinitionsProcessedTableManager
  get cavePlaceToRasterMapDefinitionsRefs {
    final manager = $CavePlaceToRasterMapDefinitionsTableManager(
      $_db,
      $_db.cavePlaceToRasterMapDefinitions,
    ).filter((f) => f.cavePlaceId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _cavePlaceToRasterMapDefinitionsRefsTable($_db),
    );
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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
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

  $CavesFilterComposer get caveId {
    final $CavesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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

  $CaveAreasFilterComposer get caveAreaId {
    final $CaveAreasFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaId,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.id,
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

  Expression<bool> cavePlaceToRasterMapDefinitionsRefs(
    Expression<bool> Function($CavePlaceToRasterMapDefinitionsFilterComposer f)
    f,
  ) {
    final $CavePlaceToRasterMapDefinitionsFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cavePlaceToRasterMapDefinitions,
          getReferencedColumn: (t) => t.cavePlaceId,
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

class $CavePlacesOrderingComposer extends Composer<_$AppDatabase, CavePlaces> {
  $CavePlacesOrderingComposer({
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

  $CavesOrderingComposer get caveId {
    final $CavesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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

  $CaveAreasOrderingComposer get caveAreaId {
    final $CaveAreasOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaId,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.id,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

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

  $CavesAnnotationComposer get caveId {
    final $CavesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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

  $CaveAreasAnnotationComposer get caveAreaId {
    final $CaveAreasAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaId,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.id,
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

  Expression<T> cavePlaceToRasterMapDefinitionsRefs<T extends Object>(
    Expression<T> Function($CavePlaceToRasterMapDefinitionsAnnotationComposer a)
    f,
  ) {
    final $CavePlaceToRasterMapDefinitionsAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cavePlaceToRasterMapDefinitions,
          getReferencedColumn: (t) => t.cavePlaceId,
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
            bool caveId,
            bool caveAreaId,
            bool cavePlaceToRasterMapDefinitionsRefs,
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
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> caveId = const Value.absent(),
                Value<int?> placeQrCodeIdentifier = const Value.absent(),
                Value<int?> caveAreaId = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> depthInCave = const Value.absent(),
                Value<int?> isEntrance = const Value.absent(),
                Value<int?> isMainEntrance = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => CavePlacesCompanion(
                id: id,
                title: title,
                description: description,
                caveId: caveId,
                placeQrCodeIdentifier: placeQrCodeIdentifier,
                caveAreaId: caveAreaId,
                latitude: latitude,
                longitude: longitude,
                depthInCave: depthInCave,
                isEntrance: isEntrance,
                isMainEntrance: isMainEntrance,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required int caveId,
                Value<int?> placeQrCodeIdentifier = const Value.absent(),
                Value<int?> caveAreaId = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<double?> depthInCave = const Value.absent(),
                Value<int?> isEntrance = const Value.absent(),
                Value<int?> isMainEntrance = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => CavePlacesCompanion.insert(
                id: id,
                title: title,
                description: description,
                caveId: caveId,
                placeQrCodeIdentifier: placeQrCodeIdentifier,
                caveAreaId: caveAreaId,
                latitude: latitude,
                longitude: longitude,
                depthInCave: depthInCave,
                isEntrance: isEntrance,
                isMainEntrance: isMainEntrance,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $CavePlacesReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                caveId = false,
                caveAreaId = false,
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
                        if (caveId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveId,
                                    referencedTable: $CavePlacesReferences
                                        ._caveIdTable(db),
                                    referencedColumn: $CavePlacesReferences
                                        ._caveIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (caveAreaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveAreaId,
                                    referencedTable: $CavePlacesReferences
                                        ._caveAreaIdTable(db),
                                    referencedColumn: $CavePlacesReferences
                                        ._caveAreaIdTable(db)
                                        .id,
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
                                (e) => e.cavePlaceId == item.id,
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
        bool caveId,
        bool caveAreaId,
        bool cavePlaceToRasterMapDefinitionsRefs,
      })
    >;
typedef $RasterMapsCreateCompanionBuilder =
    RasterMapsCompanion Function({
      Value<int> id,
      required String title,
      required String mapType,
      required String fileName,
      required int caveId,
      Value<int?> caveAreaId,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });
typedef $RasterMapsUpdateCompanionBuilder =
    RasterMapsCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String> mapType,
      Value<String> fileName,
      Value<int> caveId,
      Value<int?> caveAreaId,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });

final class $RasterMapsReferences
    extends BaseReferences<_$AppDatabase, RasterMaps, RasterMap> {
  $RasterMapsReferences(super.$_db, super.$_table, super.$_typedResult);

  static Caves _caveIdTable(_$AppDatabase db) => db.caves.createAlias(
    $_aliasNameGenerator(db.rasterMaps.caveId, db.caves.id),
  );

  $CavesProcessedTableManager get caveId {
    final $_column = $_itemColumn<int>('cave_id')!;

    final manager = $CavesTableManager(
      $_db,
      $_db.caves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static CaveAreas _caveAreaIdTable(_$AppDatabase db) =>
      db.caveAreas.createAlias(
        $_aliasNameGenerator(db.rasterMaps.caveAreaId, db.caveAreas.id),
      );

  $CaveAreasProcessedTableManager? get caveAreaId {
    final $_column = $_itemColumn<int>('cave_area_id');
    if ($_column == null) return null;
    final manager = $CaveAreasTableManager(
      $_db,
      $_db.caveAreas,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_caveAreaIdTable($_db));
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
          db.rasterMaps.id,
          db.cavePlaceToRasterMapDefinitions.rasterMapId,
        ),
      );

  $CavePlaceToRasterMapDefinitionsProcessedTableManager
  get cavePlaceToRasterMapDefinitionsRefs {
    final manager = $CavePlaceToRasterMapDefinitionsTableManager(
      $_db,
      $_db.cavePlaceToRasterMapDefinitions,
    ).filter((f) => f.rasterMapId.id.sqlEquals($_itemColumn<int>('id')!));

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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
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

  $CavesFilterComposer get caveId {
    final $CavesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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

  $CaveAreasFilterComposer get caveAreaId {
    final $CaveAreasFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaId,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.id,
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

  Expression<bool> cavePlaceToRasterMapDefinitionsRefs(
    Expression<bool> Function($CavePlaceToRasterMapDefinitionsFilterComposer f)
    f,
  ) {
    final $CavePlaceToRasterMapDefinitionsFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cavePlaceToRasterMapDefinitions,
          getReferencedColumn: (t) => t.rasterMapId,
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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

  $CavesOrderingComposer get caveId {
    final $CavesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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

  $CaveAreasOrderingComposer get caveAreaId {
    final $CaveAreasOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaId,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.id,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

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

  $CavesAnnotationComposer get caveId {
    final $CavesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveId,
      referencedTable: $db.caves,
      getReferencedColumn: (t) => t.id,
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

  $CaveAreasAnnotationComposer get caveAreaId {
    final $CaveAreasAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.caveAreaId,
      referencedTable: $db.caveAreas,
      getReferencedColumn: (t) => t.id,
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

  Expression<T> cavePlaceToRasterMapDefinitionsRefs<T extends Object>(
    Expression<T> Function($CavePlaceToRasterMapDefinitionsAnnotationComposer a)
    f,
  ) {
    final $CavePlaceToRasterMapDefinitionsAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.cavePlaceToRasterMapDefinitions,
          getReferencedColumn: (t) => t.rasterMapId,
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
            bool caveId,
            bool caveAreaId,
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
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> mapType = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> caveId = const Value.absent(),
                Value<int?> caveAreaId = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => RasterMapsCompanion(
                id: id,
                title: title,
                mapType: mapType,
                fileName: fileName,
                caveId: caveId,
                caveAreaId: caveAreaId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                required String mapType,
                required String fileName,
                required int caveId,
                Value<int?> caveAreaId = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => RasterMapsCompanion.insert(
                id: id,
                title: title,
                mapType: mapType,
                fileName: fileName,
                caveId: caveId,
                caveAreaId: caveAreaId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $RasterMapsReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                caveId = false,
                caveAreaId = false,
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
                        if (caveId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveId,
                                    referencedTable: $RasterMapsReferences
                                        ._caveIdTable(db),
                                    referencedColumn: $RasterMapsReferences
                                        ._caveIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (caveAreaId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.caveAreaId,
                                    referencedTable: $RasterMapsReferences
                                        ._caveAreaIdTable(db),
                                    referencedColumn: $RasterMapsReferences
                                        ._caveAreaIdTable(db)
                                        .id,
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
                                (e) => e.rasterMapId == item.id,
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
        bool caveId,
        bool caveAreaId,
        bool cavePlaceToRasterMapDefinitionsRefs,
      })
    >;
typedef $CavePlaceToRasterMapDefinitionsCreateCompanionBuilder =
    CavePlaceToRasterMapDefinitionsCompanion Function({
      Value<int> id,
      Value<int?> xCoordinate,
      Value<int?> yCoordinate,
      required int cavePlaceId,
      required int rasterMapId,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });
typedef $CavePlaceToRasterMapDefinitionsUpdateCompanionBuilder =
    CavePlaceToRasterMapDefinitionsCompanion Function({
      Value<int> id,
      Value<int?> xCoordinate,
      Value<int?> yCoordinate,
      Value<int> cavePlaceId,
      Value<int> rasterMapId,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
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

  static CavePlaces _cavePlaceIdTable(_$AppDatabase db) =>
      db.cavePlaces.createAlias(
        $_aliasNameGenerator(
          db.cavePlaceToRasterMapDefinitions.cavePlaceId,
          db.cavePlaces.id,
        ),
      );

  $CavePlacesProcessedTableManager get cavePlaceId {
    final $_column = $_itemColumn<int>('cave_place_id')!;

    final manager = $CavePlacesTableManager(
      $_db,
      $_db.cavePlaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_cavePlaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static RasterMaps _rasterMapIdTable(_$AppDatabase db) =>
      db.rasterMaps.createAlias(
        $_aliasNameGenerator(
          db.cavePlaceToRasterMapDefinitions.rasterMapId,
          db.rasterMaps.id,
        ),
      );

  $RasterMapsProcessedTableManager get rasterMapId {
    final $_column = $_itemColumn<int>('raster_map_id')!;

    final manager = $RasterMapsTableManager(
      $_db,
      $_db.rasterMaps,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_rasterMapIdTable($_db));
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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
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

  $CavePlacesFilterComposer get cavePlaceId {
    final $CavePlacesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cavePlaceId,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.id,
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

  $RasterMapsFilterComposer get rasterMapId {
    final $RasterMapsFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rasterMapId,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.id,
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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

  $CavePlacesOrderingComposer get cavePlaceId {
    final $CavePlacesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cavePlaceId,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.id,
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

  $RasterMapsOrderingComposer get rasterMapId {
    final $RasterMapsOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rasterMapId,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.id,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

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

  $CavePlacesAnnotationComposer get cavePlaceId {
    final $CavePlacesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.cavePlaceId,
      referencedTable: $db.cavePlaces,
      getReferencedColumn: (t) => t.id,
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

  $RasterMapsAnnotationComposer get rasterMapId {
    final $RasterMapsAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.rasterMapId,
      referencedTable: $db.rasterMaps,
      getReferencedColumn: (t) => t.id,
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
          PrefetchHooks Function({bool cavePlaceId, bool rasterMapId})
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
                Value<int> id = const Value.absent(),
                Value<int?> xCoordinate = const Value.absent(),
                Value<int?> yCoordinate = const Value.absent(),
                Value<int> cavePlaceId = const Value.absent(),
                Value<int> rasterMapId = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => CavePlaceToRasterMapDefinitionsCompanion(
                id: id,
                xCoordinate: xCoordinate,
                yCoordinate: yCoordinate,
                cavePlaceId: cavePlaceId,
                rasterMapId: rasterMapId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> xCoordinate = const Value.absent(),
                Value<int?> yCoordinate = const Value.absent(),
                required int cavePlaceId,
                required int rasterMapId,
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => CavePlaceToRasterMapDefinitionsCompanion.insert(
                id: id,
                xCoordinate: xCoordinate,
                yCoordinate: yCoordinate,
                cavePlaceId: cavePlaceId,
                rasterMapId: rasterMapId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $CavePlaceToRasterMapDefinitionsReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({cavePlaceId = false, rasterMapId = false}) {
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
                    if (cavePlaceId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.cavePlaceId,
                                referencedTable:
                                    $CavePlaceToRasterMapDefinitionsReferences
                                        ._cavePlaceIdTable(db),
                                referencedColumn:
                                    $CavePlaceToRasterMapDefinitionsReferences
                                        ._cavePlaceIdTable(db)
                                        .id,
                              )
                              as T;
                    }
                    if (rasterMapId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.rasterMapId,
                                referencedTable:
                                    $CavePlaceToRasterMapDefinitionsReferences
                                        ._rasterMapIdTable(db),
                                referencedColumn:
                                    $CavePlaceToRasterMapDefinitionsReferences
                                        ._rasterMapIdTable(db)
                                        .id,
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
      PrefetchHooks Function({bool cavePlaceId, bool rasterMapId})
    >;
typedef $DocumentationFilesCreateCompanionBuilder =
    DocumentationFilesCompanion Function({
      Value<int> id,
      required String title,
      Value<String?> description,
      required String fileName,
      required int fileSize,
      Value<String?> fileHash,
      required String fileType,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });
typedef $DocumentationFilesUpdateCompanionBuilder =
    DocumentationFilesCompanion Function({
      Value<int> id,
      Value<String> title,
      Value<String?> description,
      Value<String> fileName,
      Value<int> fileSize,
      Value<String?> fileHash,
      Value<String> fileType,
      Value<int?> createdAt,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });

final class $DocumentationFilesReferences
    extends
        BaseReferences<_$AppDatabase, DocumentationFiles, DocumentationFile> {
  $DocumentationFilesReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    DocumentationFilesToGeofeatures,
    List<DocumentationFilesToGeofeature>
  >
  _documentationFilesToGeofeaturesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.documentationFilesToGeofeatures,
        aliasName: $_aliasNameGenerator(
          db.documentationFiles.id,
          db.documentationFilesToGeofeatures.documentationFileId,
        ),
      );

  $DocumentationFilesToGeofeaturesProcessedTableManager
  get documentationFilesToGeofeaturesRefs {
    final manager =
        $DocumentationFilesToGeofeaturesTableManager(
          $_db,
          $_db.documentationFilesToGeofeatures,
        ).filter(
          (f) => f.documentationFileId.id.sqlEquals($_itemColumn<int>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _documentationFilesToGeofeaturesRefsTable($_db),
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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
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

  Expression<bool> documentationFilesToGeofeaturesRefs(
    Expression<bool> Function($DocumentationFilesToGeofeaturesFilterComposer f)
    f,
  ) {
    final $DocumentationFilesToGeofeaturesFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.documentationFilesToGeofeatures,
          getReferencedColumn: (t) => t.documentationFileId,
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

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

  Expression<T> documentationFilesToGeofeaturesRefs<T extends Object>(
    Expression<T> Function($DocumentationFilesToGeofeaturesAnnotationComposer a)
    f,
  ) {
    final $DocumentationFilesToGeofeaturesAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.documentationFilesToGeofeatures,
          getReferencedColumn: (t) => t.documentationFileId,
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
          PrefetchHooks Function({bool documentationFilesToGeofeaturesRefs})
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
                Value<int> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> fileSize = const Value.absent(),
                Value<String?> fileHash = const Value.absent(),
                Value<String> fileType = const Value.absent(),
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => DocumentationFilesCompanion(
                id: id,
                title: title,
                description: description,
                fileName: fileName,
                fileSize: fileSize,
                fileHash: fileHash,
                fileType: fileType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required String fileName,
                required int fileSize,
                Value<String?> fileHash = const Value.absent(),
                required String fileType,
                Value<int?> createdAt = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => DocumentationFilesCompanion.insert(
                id: id,
                title: title,
                description: description,
                fileName: fileName,
                fileSize: fileSize,
                fileHash: fileHash,
                fileType: fileType,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
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
              ({documentationFilesToGeofeaturesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (documentationFilesToGeofeaturesRefs)
                      db.documentationFilesToGeofeatures,
                  ],
                  addJoins: null,
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
                                (e) => e.documentationFileId == item.id,
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
      PrefetchHooks Function({bool documentationFilesToGeofeaturesRefs})
    >;
typedef $DocumentationFilesToGeofeaturesCreateCompanionBuilder =
    DocumentationFilesToGeofeaturesCompanion Function({
      Value<int> id,
      Value<int?> geofeatureId,
      required String geofeatureType,
      required int documentationFileId,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
    });
typedef $DocumentationFilesToGeofeaturesUpdateCompanionBuilder =
    DocumentationFilesToGeofeaturesCompanion Function({
      Value<int> id,
      Value<int?> geofeatureId,
      Value<String> geofeatureType,
      Value<int> documentationFileId,
      Value<int?> updatedAt,
      Value<int?> deletedAt,
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

  static DocumentationFiles _documentationFileIdTable(_$AppDatabase db) =>
      db.documentationFiles.createAlias(
        $_aliasNameGenerator(
          db.documentationFilesToGeofeatures.documentationFileId,
          db.documentationFiles.id,
        ),
      );

  $DocumentationFilesProcessedTableManager get documentationFileId {
    final $_column = $_itemColumn<int>('documentation_file_id')!;

    final manager = $DocumentationFilesTableManager(
      $_db,
      $_db.documentationFiles,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentationFileIdTable($_db));
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
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get geofeatureId => $composableBuilder(
    column: $table.geofeatureId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get geofeatureType => $composableBuilder(
    column: $table.geofeatureType,
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

  $DocumentationFilesFilterComposer get documentationFileId {
    final $DocumentationFilesFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentationFileId,
      referencedTable: $db.documentationFiles,
      getReferencedColumn: (t) => t.id,
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
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get geofeatureId => $composableBuilder(
    column: $table.geofeatureId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get geofeatureType => $composableBuilder(
    column: $table.geofeatureType,
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

  $DocumentationFilesOrderingComposer get documentationFileId {
    final $DocumentationFilesOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentationFileId,
      referencedTable: $db.documentationFiles,
      getReferencedColumn: (t) => t.id,
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
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get geofeatureId => $composableBuilder(
    column: $table.geofeatureId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get geofeatureType => $composableBuilder(
    column: $table.geofeatureType,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $DocumentationFilesAnnotationComposer get documentationFileId {
    final $DocumentationFilesAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentationFileId,
      referencedTable: $db.documentationFiles,
      getReferencedColumn: (t) => t.id,
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
          PrefetchHooks Function({bool documentationFileId})
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
                Value<int> id = const Value.absent(),
                Value<int?> geofeatureId = const Value.absent(),
                Value<String> geofeatureType = const Value.absent(),
                Value<int> documentationFileId = const Value.absent(),
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => DocumentationFilesToGeofeaturesCompanion(
                id: id,
                geofeatureId: geofeatureId,
                geofeatureType: geofeatureType,
                documentationFileId: documentationFileId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int?> geofeatureId = const Value.absent(),
                required String geofeatureType,
                required int documentationFileId,
                Value<int?> updatedAt = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
              }) => DocumentationFilesToGeofeaturesCompanion.insert(
                id: id,
                geofeatureId: geofeatureId,
                geofeatureType: geofeatureType,
                documentationFileId: documentationFileId,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $DocumentationFilesToGeofeaturesReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentationFileId = false}) {
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
                    if (documentationFileId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.documentationFileId,
                                referencedTable:
                                    $DocumentationFilesToGeofeaturesReferences
                                        ._documentationFileIdTable(db),
                                referencedColumn:
                                    $DocumentationFilesToGeofeaturesReferences
                                        ._documentationFileIdTable(db)
                                        .id,
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
      PrefetchHooks Function({bool documentationFileId})
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
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
}
