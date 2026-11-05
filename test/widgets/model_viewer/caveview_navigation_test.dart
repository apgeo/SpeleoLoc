import 'package:flutter_test/flutter_test.dart';
import 'package:speleoloc/widgets/model_viewer/caveview_web_view.dart';

void main() {
  final page = Uri.parse(
    'http://127.0.0.1:40123/viewer/index.html?model=m.lox',
  );

  test('the viewer page and its own files are allowed', () {
    expect(
      allowsViewerNavigation(page, 'http://127.0.0.1:40123/viewer/model.lox'),
      isTrue,
    );
  });

  test('the blank page it is parked on is allowed', () {
    expect(allowsViewerNavigation(page, 'about:blank'), isTrue);
  });

  test('another host, port or scheme is refused', () {
    expect(allowsViewerNavigation(page, 'http://example.test/'), isFalse);
    expect(allowsViewerNavigation(page, 'http://127.0.0.1:40124/'), isFalse);
    expect(allowsViewerNavigation(page, 'https://127.0.0.1:40123/'), isFalse);
  });

  test('links without an origin are refused instead of throwing', () {
    expect(
      allowsViewerNavigation(page, 'mailto:someone@example.test'),
      isFalse,
    );
    expect(allowsViewerNavigation(page, 'intent://scan#Intent;end'), isFalse);
    expect(allowsViewerNavigation(page, 'javascript:void(0)'), isFalse);
    expect(allowsViewerNavigation(page, 'about:srcdoc'), isFalse);
    expect(allowsViewerNavigation(page, 'not a url at all'), isFalse);
  });
}
