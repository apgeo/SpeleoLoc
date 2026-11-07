import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/documents/editors/sound_recorder_page.dart';
import 'package:speleoloc/services/service_locator.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/product_tour.dart';

import '../../support/pump_app.dart';

/// Stands in for the `flutter_sound` recorder: a recording is a small file
/// written at start, and stopping can be held open to model the moment a
/// caver taps Save while the recorder is still flushing.
class _FakeRecorder implements FlutterSoundRecorder {
  final progress = StreamController<RecordingDisposition>.broadcast();
  Completer<void>? stopGate;
  String? _path;
  var stops = 0;

  @override
  Stream<RecordingDisposition>? get onProgress => progress.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName;
    if (name == #startRecorder) {
      _path = invocation.namedArguments[#toFile] as String;
      return File(_path!).writeAsBytes(Uint8List.fromList(List.filled(64, 7)));
    }
    if (name == #stopRecorder) {
      stops++;
      final gate = stopGate;
      return (gate?.future ?? Future<void>.value()).then((_) => _path);
    }
    if (name == #openRecorder) {
      return Future<FlutterSoundRecorder?>.value(this);
    }
    // closeRecorder, setSubscriptionDuration, pause, resume.
    return Future<void>.value();
  }
}

class _FakePlayer implements FlutterSoundPlayer {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      invocation.memberName == #openPlayer
      ? Future<FlutterSoundPlayer?>.value(this)
      : Future<void>.value();
}

void main() {
  late Directory docs;
  late Directory tmp;
  late AppDatabase db;
  late ProviderContainer container;
  late _FakeRecorder recorder;

  setUp(() async {
    docs = await Directory.systemTemp.createTemp('speleoloc_rec_docs_');
    tmp = await Directory.systemTemp.createTemp('speleoloc_rec_tmp_');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    mockPathProvider(documents: docs, temporary: tmp);
    // Microphone permission: always granted.
    messenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (call) async => switch (call.method) {
        'checkPermissionStatus' => 1,
        'requestPermissions' => <int, int>{7: 1},
        _ => null,
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('simform_audio_waveforms_plugin/methods'),
      (call) async => switch (call.method) {
        'stopRecording' => <Object?, Object?>{},
        'extractWaveformData' => <double>[],
        'getDuration' => 1000,
        _ => true,
      },
    );
    recorder = _FakeRecorder();
    db = AppDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
    );
    initRootContainer(container);
  });

  tearDown(() async {
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    for (final channel in const [
      'flutter.baseflow.com/permissions/methods',
      'simform_audio_waveforms_plugin/methods',
    ]) {
      messenger.setMockMethodCallHandler(MethodChannel(channel), null);
    }
    await recorder.progress.close();
    container.dispose();
    await db.close();
    await docs.delete(recursive: true);
    await tmp.delete(recursive: true);
  });

  Future<void> settle(WidgetTester tester, [int rounds = 8]) =>
      settleWithRealTime(tester, rounds: rounds);

  /// Opens the recorder over a launcher page and reports what it popped.
  Future<List<Object?>> open(
    WidgetTester tester, {
    DocumentationFile? existing,
  }) async {
    final popped = <Object?>[];
    await tester.runAsync(() => setAutoToursDisabled(true));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () async => popped.add(
                    await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) => SoundRecorderPage(
                          existingDoc: existing,
                          recorder: recorder,
                          player: _FakePlayer(),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('open recorder'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open recorder'));
    await settle(tester);
    return popped;
  }

  Future<void> record(WidgetTester tester) async {
    await tester.tap(find.byIcon(Icons.mic));
    await settle(tester);
    expect(find.byIcon(Icons.stop), findsOneWidget);
  }

  List<String> scratch() => [
    for (final f in tmp.listSync())
      if (f.uri.pathSegments.last.startsWith(RegExp('rec_|edit_')))
        f.uri.pathSegments.last,
  ];

  /// The page removes its scratch files after it has closed, in the
  /// background; give that a bounded time.
  Future<void> expectNoScratch(WidgetTester tester) async {
    for (var i = 0; i < 60 && scratch().isNotEmpty; i++) {
      await settle(tester, 1);
    }
    expect(scratch(), isEmpty);
  }

  Future<List<DocumentationFile>> stored() =>
      db.select(db.documentationFiles).get();

  testWidgets('Save while a stop is still running waits for it and saves', (
    tester,
  ) async {
    final popped = await open(tester);
    recorder.stopGate = Completer<void>();
    await record(tester);

    await tester.tap(find.byIcon(Icons.stop));
    await settle(tester);
    expect(recorder.stops, 1);

    await tester.tap(find.byIcon(Icons.save));
    await settle(tester);
    expect(await stored(), isEmpty, reason: 'Save must wait for the stop');

    recorder.stopGate!.complete();
    await settle(tester, 20);

    final rows = await stored();
    expect(rows, hasLength(1));
    expect(rows.single.fileType, 'audio');
    expect(rows.single.title, startsWith('rec_'));
    expect(File('${docs.path}/${rows.single.fileName}').existsSync(), isTrue);
    expect(popped, [true]);
    await expectNoScratch(tester);
  });

  testWidgets('Save while still recording stops the recorder, then saves', (
    tester,
  ) async {
    final popped = await open(tester);
    await record(tester);

    await tester.tap(find.byIcon(Icons.save));
    await settle(tester, 20);

    expect(recorder.stops, 1);
    expect(await stored(), hasLength(1));
    expect(popped, [true]);
    await expectNoScratch(tester);
  });

  testWidgets('Save from the leave dialog saves the recording', (tester) async {
    final popped = await open(tester);
    await record(tester);
    await tester.tap(find.byIcon(Icons.stop));
    await settle(tester);

    await tester.pageBack();
    await settle(tester);
    await tester.tap(
      find.widgetWithText(ElevatedButton, LocServ.inst.t('save')),
    );
    await settle(tester, 20);

    expect(await stored(), hasLength(1));
    expect(popped, [true]);
    await expectNoScratch(tester);
  });

  testWidgets('Save from the leave dialog during a recording stops and saves', (
    tester,
  ) async {
    final popped = await open(tester);
    await record(tester);

    await tester.pageBack();
    await settle(tester);
    await tester.tap(
      find.widgetWithText(ElevatedButton, LocServ.inst.t('save')),
    );
    await settle(tester, 20);

    expect(recorder.stops, 1);
    expect(await stored(), hasLength(1));
    expect(popped, [true]);
    await expectNoScratch(tester);
  });

  testWidgets('Discard from the leave dialog saves nothing and cleans up', (
    tester,
  ) async {
    final popped = await open(tester);
    await record(tester);
    await tester.tap(find.byIcon(Icons.stop));
    await settle(tester);
    expect(scratch(), isNotEmpty, reason: 'the recording is a scratch file');

    await tester.pageBack();
    await settle(tester);
    await tester.tap(
      find.widgetWithText(TextButton, LocServ.inst.t('discard')),
    );
    await settle(tester, 20);

    expect(await stored(), isEmpty);
    expect(popped, [null]);
    await expectNoScratch(tester);
  });

  testWidgets('Cancel in the leave dialog keeps the page and the recording', (
    tester,
  ) async {
    final popped = await open(tester);
    await record(tester);
    await tester.tap(find.byIcon(Icons.stop));
    await settle(tester);

    await tester.pageBack();
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, LocServ.inst.t('cancel')));
    await settle(tester);

    expect(popped, isEmpty);
    expect(find.byIcon(Icons.save), findsOneWidget);
    expect(scratch(), isNotEmpty);
  });

  group('editing an existing recording', () {
    late DocumentationFile existing;

    setUp(() async {
      final file = File('${docs.path}/documentation_files/doc_1_old.wav');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(Uint8List.fromList(List.filled(32, 1)));
      final uuid = Uuid.v7();
      await db
          .into(db.documentationFiles)
          .insert(
            DocumentationFilesCompanion.insert(
              uuid: uuid,
              title: 'Invented recording',
              fileName: 'documentation_files/doc_1_old.wav',
              fileSize: 32,
              fileType: 'audio',
            ).copyWith(createdAt: Value(DateTime.now().millisecondsSinceEpoch)),
          );
      existing = (await stored()).single;
    });

    testWidgets('the working copy is removed when the page is left', (
      tester,
    ) async {
      final popped = await open(tester, existing: existing);
      expect(
        scratch().where((n) => n.startsWith('edit_')),
        hasLength(1),
        reason: 'the page edits a copy, never the stored file',
      );

      await tester.pageBack();
      await settle(tester);
      expect(popped, [null], reason: 'an untouched copy leaves silently');
      await expectNoScratch(tester);
      expect(
        File('${docs.path}/documentation_files/doc_1_old.wav').existsSync(),
        isTrue,
      );
    });

    testWidgets('re-recording and saving replaces the content and cleans up', (
      tester,
    ) async {
      final popped = await open(tester, existing: existing);
      await record(tester);
      await tester.tap(find.byIcon(Icons.stop));
      await settle(tester);

      await tester.tap(find.byIcon(Icons.save));
      await settle(tester, 20);

      final row = (await stored()).single;
      expect(row.uuid, existing.uuid);
      expect(row.fileSize, isNot(existing.fileSize));
      expect(popped, [true]);
      await expectNoScratch(tester);
    });
  });
}
