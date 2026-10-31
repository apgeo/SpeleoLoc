import 'package:speleoloc/services/cave_model/model_viewer_command.dart';

/// What a 3D viewer widget offers its [ModelViewerController]: the one way to
/// reach the page drawing the model.
abstract interface class ModelViewerHost {
  Future<void> send(ModelViewerCommand command);
}
