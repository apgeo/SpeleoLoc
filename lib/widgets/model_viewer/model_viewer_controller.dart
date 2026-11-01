import 'package:speleoloc/services/cave_model/model_viewer_command.dart';
import 'package:speleoloc/widgets/model_viewer/model_viewer_host.dart';

/// Lets a screen drive the 3D viewer widget it shows, whichever widget the
/// platform builds. Commands sent while no viewer is attached are dropped.
class ModelViewerController {
  ModelViewerHost? _host;

  void attach(ModelViewerHost host) => _host = host;

  void detach(ModelViewerHost host) {
    if (identical(_host, host)) _host = null;
  }

  Future<void> send(ModelViewerCommand command) async {
    await _host?.send(command);
  }
}
