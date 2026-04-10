import 'package:flutter_test/flutter_test.dart';

import 'package:speleoloc/app.dart';
import 'package:speleoloc/utils/constants.dart';

void main() {
  testWidgets('App boots and shows home shell', (WidgetTester tester) async {
    await tester.pumpWidget(const SpeleoLocApp());
    await tester.pumpAndSettle();

    expect(find.text(appName), findsOneWidget);
  });
}
