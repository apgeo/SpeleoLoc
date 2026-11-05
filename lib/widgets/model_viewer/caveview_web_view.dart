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
    await _web.setNavigationDelegate(
      NavigationDelegate(
        onNavigationRequest: (request) =>
            Uri.tryParse(request.url)?.origin == widget.pageUri.origin
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
          if (uri == null || uri.path != widget.pageUri.path || !mounted)
            return;
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
    super.dispose();
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
