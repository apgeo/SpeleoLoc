import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/utils/deep_link_handler.dart';

const _channel = MethodChannel('speleoloc/deep_link');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger.setMockMethodCallHandler(_channel, null));

  Future<GlobalKey<NavigatorState>> pumpApp(WidgetTester tester) async {
    final key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: key, home: const SizedBox()),
    );
    return key;
  }

  testWidgets('a link that started the app is pulled and resolved', (
    tester,
  ) async {
    final resolved = <String>[];
    final handler = DeepLinkHandler.withResolver((_, code) async {
      resolved.add(code);
    })..init(await pumpApp(tester));
    messenger.setMockMethodCallHandler(_channel, (call) async {
      return call.method == 'getInitialLink' ? 'sp://CAVE-7' : null;
    });

    await handler.handleInitialLink();

    expect(resolved, ['CAVE-7']);
  });

  testWidgets('no launch link resolves nothing', (tester) async {
    final resolved = <String>[];
    final handler = DeepLinkHandler.withResolver((_, code) async {
      resolved.add(code);
    })..init(await pumpApp(tester));
    messenger.setMockMethodCallHandler(_channel, (call) async => null);

    await handler.handleInitialLink();

    expect(resolved, isEmpty);
  });

  testWidgets('a platform without the channel resolves nothing', (
    tester,
  ) async {
    final resolved = <String>[];
    final handler = DeepLinkHandler.withResolver((_, code) async {
      resolved.add(code);
    })..init(await pumpApp(tester));
    messenger.setMockMethodCallHandler(
      _channel,
      (call) async => throw MissingPluginException(),
    );

    await handler.handleInitialLink();

    expect(resolved, isEmpty);
  });
}
