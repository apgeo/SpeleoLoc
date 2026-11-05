import 'package:speleoloc/data/source/database/app_database.dart';

/// A survey model a server hands this account whose file is not on this
/// device yet.
class ServerSurveyModel {
  const ServerSurveyModel({
    required this.profileUuid,
    required this.modelId,
    required this.documentId,
    required this.format,
    this.name,
    this.sizeBytes,
    this.isCurrent = false,
  });

  /// The installation it is on.
  final String profileUuid;
  final Uuid modelId;

  /// The documentation file the model is stored as once fetched.
  final Uuid documentId;
  final String? name;

  /// `lox` or `3d`.
  final String format;
  final int? sizeBytes;
  final bool isCurrent;
}

/// What servers say about a cave's survey models, for choosing which one
/// opens and offering the ones still to fetch.
abstract interface class CurrentSurveyModels {
  /// The model documents a server marks as the cave's current line plot.
  Future<Set<Uuid>> currentModelDocuments(Uuid caveUuid);

  /// The cave's server models whose file this device does not hold.
  Future<List<ServerSurveyModel>> notHeld(Uuid caveUuid);
}

/// No server: nothing is current and nothing waits.
class NoServerSurveyModels implements CurrentSurveyModels {
  const NoServerSurveyModels();

  @override
  Future<Set<Uuid>> currentModelDocuments(Uuid caveUuid) async => const {};

  @override
  Future<List<ServerSurveyModel>> notHeld(Uuid caveUuid) async => const [];
}

/// How fetching one server model on the caver's request went.
enum ServerModelFetchOutcome {
  /// The file is here now.
  fetched,

  /// The server's sign-in has lapsed; the caver signs in again first.
  signIn,

  /// The server no longer hands this model over to this account.
  refused,

  /// The fetch broke off, or brought other bytes than listed. Nothing was
  /// stored.
  failed,

  /// The server could not be reached; the phone has no usable connection.
  offline,
}

/// Fetches a server model's file when the caver asks for it.
abstract interface class ServerSurveyModelFetcher {
  Future<ServerModelFetchOutcome> fetch(ServerSurveyModel model);
}
