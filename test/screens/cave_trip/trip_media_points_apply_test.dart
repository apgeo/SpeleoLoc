import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_points_page.dart';
import 'package:speleoloc/screens/cave_trip/trip_media_tile.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/services/trip_log_update.dart';
import 'package:speleoloc/services/trip_media/trip_media_access.dart';
import 'package:speleoloc/services/trip_media/trip_media_import_service.dart';
import 'package:speleoloc/services/trip_media/trip_media_item.dart';
import 'package:speleoloc/services/trip_media/trip_media_source.dart';

/// Apply on the trip-media screen runs once however often it is tapped, and
/// a failed run leaves the screen usable.
class _Source implements TripMediaSource {
  _Source(this.items);

  final List<TripMediaItem> items;

  /// Holds [file] open, the way copying a picture out of the library does.
  final fileGate = Completer<File?>();
  int fileCalls = 0;

  @override
  String get id => 'fake';
  @override
  bool get choosesItems => false;
  @override
  Future<int> chooseMore() async => 0;
  @override
  Future<List<TripMediaItem>> list({DateTime? from, DateTime? to}) async =>
      items;
  @override
  Future<Uint8List?> thumbnail(TripMediaItem item, {int edge = 200}) async =>
      null;
  @override
  Future<File?> file(TripMediaItem item) {
    fileCalls++;
    return fileGate.future;
  }

  @override
  Future<R?> withScanImage<R>(
    TripMediaItem item,
    Future<R?> Function(File file) use,
  ) async => null;
  @override
  Future<String?> scanKey(TripMediaItem item) async => null;
  @override
  Future<void> release() async {}
}

class _Access extends TripMediaAccessResolver {
  const _Access(this.source);

  final TripMediaSource source;

  @override
  Future<TripMediaResolution> resolve() async =>
      TripMediaResolution(TripMediaAccess.full, source);
}

class _Import implements TripMediaImportService {
  int applyCalls = 0;
  Object? failWith;

  @override
  Future<TripMediaImportOutcome> apply({
    required Uuid tripUuid,
    required List<TripMediaCommit> commits,
    required bool importFiles,
    required bool compressImages,
    List<Uuid> deletePointUuids = const [],
    DateTime? newTripStart,
    DateTime? newTripEnd,
    TripLogUpdate? logUpdate,
    void Function(int done, int total)? onProgress,
  }) async {
    applyCalls++;
    final error = failWith;
    if (error != null) throw error;
    return TripMediaImportOutcome();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late _Source source;
  late _Import import;
  late Uuid tripUuid;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    source = _Source([
      TripMediaItem(
        id: 'clip-1',
        kind: TripMediaKind.video,
        capturedAt: DateTime.now(),
        capturedAtSource: MediaTimeSource.library,
        displayName: 'invented_clip.mp4',
      ),
    ]);
    import = _Import();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        tripMediaAccessResolverProvider.overrideWithValue(_Access(source)),
        tripMediaImportServiceProvider.overrideWithValue(import),
      ],
    );
    initRootContainer(container);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Opens the page above a root route and ticks the one item with the
  /// cave's one place. The returned future completes with the page's result.
  Future<Future<bool?>> openAndAssign(WidgetTester tester) async {
    await tester.runAsync(() async {
      final cave = await container
          .read(caveRepositoryProvider)
          .addCave('Invented cave');
      await container
          .read(cavePlaceRepositoryProvider)
          .addCavePlace(cave, 'Invented hall');
      final service = container.read(caveTripServiceProvider);
      tripUuid = await service.startTrip(cave, 'Invented trip');
      await service.stopTrip();
    });
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(navigatorKey: navigator, home: const Scaffold()),
      ),
    );
    final result = navigator.currentState!.push<bool>(
      MaterialPageRoute(
        builder: (_) => TripMediaPointsPage(tripUuid: tripUuid),
      ),
    );
    await settle(tester);

    await tester.tap(find.byType(TripMediaTile));
    await settle(tester);
    await tester.tap(find.text('Invented hall'));
    await settle(tester);
    return result;
  }

  VoidCallback applyButton(WidgetTester tester) => tester
      .widget<FloatingActionButton>(find.byType(FloatingActionButton))
      .onPressed!;

  testWidgets('a second Apply while the files are resolved does nothing', (
    tester,
  ) async {
    final result = await openAndAssign(tester);

    final apply = applyButton(tester);
    apply();
    apply();
    await settle(tester);

    expect(source.fileCalls, 1);
    // Let the button's exit animation finish.
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(FloatingActionButton), findsNothing);

    source.fileGate.complete(null);
    await settle(tester);

    expect(import.applyCalls, 1);
    expect(await result, isTrue);
  });

  testWidgets('a failed Apply leaves the page usable again', (tester) async {
    import.failWith = StateError('invented failure');
    source.fileGate.complete(null);
    final result = await openAndAssign(tester);

    applyButton(tester)();
    await settle(tester);

    expect(import.applyCalls, 1);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    final pop = tester.widget<PopScope>(
      find.descendant(
        of: find.byType(TripMediaPointsPage),
        matching: find.byWidgetPredicate((w) => w is PopScope),
      ),
    );
    expect(pop.canPop, isTrue);

    // A second try is possible and, this time, succeeds.
    import.failWith = null;
    applyButton(tester)();
    await settle(tester);
    expect(import.applyCalls, 2);
    expect(await result, isTrue);
  });
}
