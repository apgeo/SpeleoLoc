import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:speleoloc/services/cave_model/model_viewer_command.dart';
import 'package:speleoloc/services/cave_model/model_viewer_event.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_controller.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_host.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Whether the viewer may navigate to [url]: its own page, or the blank page
/// it is parked on when the screen closes. Everything else, including links
/// with schemes that have no origin (`mailto:`, `intent:`), is refused.
bool allowsViewerNavigation(Uri page, String url) {
  if (url == _blankPage) return true;
  final target = Uri.tryParse(url);
  return target != null &&
      target.scheme == page.scheme &&
      target.host == page.host &&
      target.port == page.port;
}

const _blankPage = 'about:blank';

/// The 3D viewer on Android and iOS: the host page and CaveView in a WebView.
class CaveViewWebView extends StatefulWidget {
  const CaveViewWebView({
    super.key,
    required this.pageUri,
    required this.controller,
    required this.onEvent,
  });

  final Uri pageUri;
  final ModelViewerController controller;
  final ValueChanged<ModelViewerEvent> onEvent;

  @override
  State<CaveViewWebView> createState() => _CaveViewWebViewState();
}

class _CaveViewWebViewState extends State<CaveViewWebView>
    implements ModelViewerHost {
  late final WebViewController _web;

  @override
  void initState() {
    super.initState();
    _web = WebViewController();
    unawaited(_open());
    widget.controller.attach(this);
  }

  Future<void> _open() async {
    await _web.setJavaScriptMode(JavaScriptMode.unrestricted);
    await _web.setBackgroundColor(Colors.black);
    await _web.addJavaScriptChannel(
      'SpeleoLocViewer',
      onMessageReceived: (message) {
        final event = ModelViewerEvent.decode(message.message);
        if (event != null && mounted) widget.onEvent(event);
      },
    );
    // The page is served from a loopback port and needs nothing else; a link
    // in a survey's text must not turn the viewer into a browser.
    final page = widget.pageUri;
    await _web.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) =>
            allowsViewerNavigation(page, request.url)
            ? NavigationDecision.navigate
            : NavigationDecision.prevent,
        // Without this the platform's own error page sits under the loading
        // overlay and the caver never learns the page did not open.
        onWebResourceError: (error) {
          if (error.isForMainFrame == false || !mounted) return;
          widget.onEvent(
            ModelViewerFailed(code: 'page', message: error.description),
          );
        },
        onHttpError: (error) {
          final uri = error.request?.uri;
          if (uri == null || uri.path != page.path || !mounted) return;
          widget.onEvent(
            ModelViewerFailed(
              code: 'page',
              message: 'HTTP ${error.response?.statusCode}',
            ),
          );
        },
      ),
    );
    await _web.loadRequest(widget.pageUri);
  }

  @override
  Future<void> send(ModelViewerCommand command) => _web.runJavaScript(
    'window.speleolocViewer.receive(${jsonEncode(command.encode())})',
  );

  @override
  void dispose() {
    widget.controller.detach(this);
    unawaited(_release());
    super.dispose();
  }

  /// The plugin destroys the native WebView only when the Dart controller is
  /// garbage-collected, which can be long after the screen closed. Parking it
  /// on a blank page frees the model and its WebGL memory at once.
  Future<void> _release() async {
    try {
      await _web.removeJavaScriptChannel('SpeleoLocViewer');
      await _web.loadRequest(Uri.parse(_blankPage));
    } on Exception catch (_) {
      // The platform view may already be gone; there is nothing left to free.
    }
  }

  @override
  Widget build(BuildContext context) => WebViewWidget(
    controller: _web,
    // Every drag over the model turns it; nothing around the viewer may
    // claim the gesture first.
    gestureRecognizers: const {
      Factory<OneSequenceGestureRecognizer>(EagerGestureRecognizer.new),
    },
  );
}
