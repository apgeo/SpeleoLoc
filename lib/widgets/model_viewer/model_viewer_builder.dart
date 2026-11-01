import 'package:flutter/widgets.dart';
import 'package:speleoloc/services/cave_model/model_viewer_event.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_controller.dart';

/// Builds the widget that draws a model from the host page at [pageUri],
/// reporting what the page says through [onEvent].
typedef ModelViewerBuilder =
    Widget Function({
      required Uri pageUri,
      required ModelViewerController controller,
      required ValueChanged<ModelViewerEvent> onEvent,
    });
