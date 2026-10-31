import 'dart:convert';

import 'package:speleoloc/services/cave_model/model_viewer_event.dart';

/// The directions the viewer can be turned to look from in one step.
enum ModelView { plan, north, east, south, west }

/// What the app asks of the 3D viewer's page (protocol 1, see
/// `assets/caveview/host/bridge.js`).
sealed class ModelViewerCommand {
  const ModelViewerCommand();

  Map<String, Object?> get _fields;

  String encode() => jsonEncode({'v': ModelViewerEvent.protocol, ..._fields});
}

final class SetModelView extends ModelViewerCommand {
  const SetModelView(this.view);

  final ModelView view;

  @override
  Map<String, Object?> get _fields => {'type': 'setView', 'view': view.name};
}

/// Centres the camera on [station]; [spanMetres] narrows the view to about
/// that width of survey around it.
final class FocusModelStation extends ModelViewerCommand {
  const FocusModelStation(this.station, {this.spanMetres});

  final String station;
  final double? spanMetres;

  @override
  Map<String, Object?> get _fields => {
    'type': 'focusStation',
    'station': station,
    if (spanMetres != null) 'span': spanMetres,
  };
}
