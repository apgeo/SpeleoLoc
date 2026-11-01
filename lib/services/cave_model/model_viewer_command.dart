import 'dart:convert';

import 'package:speleoloc/services/cave_model/model_splay_offset.dart';
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

/// One of the app's marks on the model: a mapped place, drawn larger than a
/// station and labelled. [color] is a CSS colour.
class ModelMark {
  const ModelMark({
    required this.id,
    required this.station,
    required this.label,
    required this.color,
    this.offset,
  });

  final String id;
  final String station;
  final ModelSplayOffset? offset;
  final String label;
  final String color;

  Map<String, Object?> toJson() => {
    'id': id,
    'station': station,
    if (offset != null) 'offset': offset!.toList(),
    'label': label,
    'color': color,
  };
}

/// Replaces every mark of the app's with [marks]; answered by
/// [ModelMarksResolved].
final class SetModelMarks extends ModelViewerCommand {
  const SetModelMarks(this.marks);

  final List<ModelMark> marks;

  @override
  Map<String, Object?> get _fields => {
    'type': 'setMarks',
    'marks': [for (final m in marks) m.toJson()],
  };
}

/// Highlights [station], or clears the highlight when null.
final class HighlightModelStation extends ModelViewerCommand {
  const HighlightModelStation(this.station);

  final String? station;

  @override
  Map<String, Object?> get _fields => {'type': 'highlight', 'station': station};
}

/// Asks for a station's position and splays; answered by [ModelStationInfo].
final class GetModelStation extends ModelViewerCommand {
  const GetModelStation(this.station);

  final String station;

  @override
  Map<String, Object?> get _fields => {
    'type': 'getStation',
    'station': station,
  };
}

/// Asks for every station's name; answered by [ModelStationList].
final class ListModelStations extends ModelViewerCommand {
  const ListModelStations();

  @override
  Map<String, Object?> get _fields => {'type': 'listStations'};
}

/// Shows the far end of each splay of [station] as a tappable dot; answered
/// by [ModelSplayPicked] or [ModelSplayPickerEmpty].
final class ShowSplayPicker extends ModelViewerCommand {
  const ShowSplayPicker(this.station);

  final String station;

  @override
  Map<String, Object?> get _fields => {
    'type': 'showSplayPicker',
    'station': station,
  };
}

final class HideSplayPicker extends ModelViewerCommand {
  const HideSplayPicker();

  @override
  Map<String, Object?> get _fields => {'type': 'hideSplayPicker'};
}

/// Places, or moves over [durationMs], a labelled marker for someone: "you
/// are here", or a caver on a replayed trip.
final class SetModelPerson extends ModelViewerCommand {
  const SetModelPerson({
    required this.id,
    required this.station,
    required this.label,
    required this.color,
    this.durationMs,
  });

  final String id;
  final String station;
  final String label;
  final String color;
  final int? durationMs;

  @override
  Map<String, Object?> get _fields => {
    'type': 'setPerson',
    'id': id,
    'station': station,
    'label': label,
    'color': color,
    if (durationMs != null) 'duration': durationMs,
  };
}

final class RemoveModelPerson extends ModelViewerCommand {
  const RemoveModelPerson(this.id);

  final String id;

  @override
  Map<String, Object?> get _fields => {'type': 'removePerson', 'id': id};
}

/// Draws a route along the survey's legs through [stations], up to
/// [progress] of its length; answered by [ModelTrailInfo].
final class SetModelTrail extends ModelViewerCommand {
  const SetModelTrail({
    required this.id,
    required this.stations,
    required this.color,
    this.progress = 1,
  });

  final String id;
  final List<String> stations;
  final String color;
  final double progress;

  @override
  Map<String, Object?> get _fields => {
    'type': 'setTrail',
    'id': id,
    'stations': stations,
    'color': color,
    'progress': progress,
  };
}

final class SetModelTrailProgress extends ModelViewerCommand {
  const SetModelTrailProgress(this.id, this.progress);

  final String id;
  final double progress;

  @override
  Map<String, Object?> get _fields => {
    'type': 'setTrailProgress',
    'id': id,
    'progress': progress,
  };
}

final class RemoveModelTrail extends ModelViewerCommand {
  const RemoveModelTrail(this.id);

  final String id;

  @override
  Map<String, Object?> get _fields => {'type': 'removeTrail', 'id': id};
}
