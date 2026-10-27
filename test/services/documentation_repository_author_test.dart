import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/service_locator.dart';

/// A new documentation file, and the link that attaches it, must say who made
/// them and when, whichever screen or service inserted the row.
void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late Uuid caveUuid;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
    caveUuid = await container.read(caveRepositoryProvider).addCave('Cave');
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  DocumentationFilesCompanion bare() => DocumentationFilesCompanion.insert(
    uuid: Uuid.v7(),
    title: 'Invented photo',
    fileName: 'documentation_files/invented.jpg',
    fileSize: 10,
    fileType: 'photo',
  );

  test('author and timestamps are stamped on the file and its link', () async {
    final author = await container
        .read(currentUserServiceProvider)
        .currentOrSystem();
    final repo = container.read(documentationRepositoryProvider);
    final link = await repo.getDocumentationParentLink(caveUuid: caveUuid);

    final uuid = await repo.insertDocumentationFile(
      companion: bare(),
      parentLink: link,
    );

    final file = await (db.select(
      db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(uuid))).getSingle();
    expect(file.createdByUserUuid, author);
    expect(file.createdAt, isNotNull);
    expect(file.updatedAt, isNotNull);

    final links = await db.select(db.documentationFilesToGeofeatures).get();
    expect(links, hasLength(1));
    expect(links.single.createdByUserUuid, author);
    expect(links.single.createdAt, file.createdAt);
    expect(links.single.updatedAt, isNotNull);
  });

  test('an author the caller already set is kept', () async {
    final current = await container
        .read(currentUserServiceProvider)
        .currentOrSystem();
    final other = await container
        .read(userRepositoryProvider)
        .addUser(username: 'other', firstName: 'Other');
    expect(other, isNot(current));
    final repo = container.read(documentationRepositoryProvider);

    final uuid = await repo.insertDocumentationFile(
      companion: bare().copyWith(createdByUserUuid: Value(other)),
    );

    final file = await (db.select(
      db.documentationFiles,
    )..where((t) => t.uuid.equalsValue(uuid))).getSingle();
    expect(file.createdByUserUuid, other);
  });
}
