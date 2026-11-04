import 'package:speleoloc/services/network/network_kind_probe.dart';
import 'package:speleoloc/services/silexgis/silexgis_file_sending_gate.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile_repository.dart';

/// What the caver answered when asked to send files over mobile data.
class SilexgisMobileDataAnswer {
  const SilexgisMobileDataAnswer({required this.send, this.remember = false});

  /// Send the files now.
  final bool send;

  /// Keep this answer for the profile, and stop asking.
  final bool remember;
}

/// Asks the caver whether files may go over mobile data now.
///
/// Implemented by the screen that started the run: a service never shows a
/// dialog. Null means nobody could be asked — the screen was gone — and the
/// files wait.
abstract interface class SilexgisMobileDataDecider {
  Future<SilexgisMobileDataAnswer?> askToSendOverMobileData({
    required int files,
    required int bytes,
  });
}

/// What to do with files on a network of some kind.
enum SilexgisFilesVerdict { send, ask, wait }

/// The rule, apart from asking: files go when the caver does not keep them
/// for Wi-Fi, or when the device is on Wi-Fi or a cable; otherwise the caver
/// is asked, unless they chose to let files simply wait.
///
/// The network is told by its transport alone. A phone's hotspot is Wi-Fi to
/// the phone using it, and a metered Wi-Fi is not told apart; an unknown
/// network is treated as one that may cost, so the caver is asked.
SilexgisFilesVerdict silexgisFilesVerdict(
  SilexgisProfile profile,
  NetworkKind kind,
) {
  if (!profile.filesOnlyOverWifi || kind.isUnmetered) {
    return SilexgisFilesVerdict.send;
  }
  return profile.asksBeforeMobileData
      ? SilexgisFilesVerdict.ask
      : SilexgisFilesVerdict.wait;
}

/// The profile's "only over Wi-Fi" setting, applied across one run.
///
/// One gate serves every part of a run that sends bytes — photos, documents
/// and map pictures. The network is looked at once. A "wait" stands for the
/// rest of the run, so the caver is not asked again after saying no; a "send"
/// covers only the files it was asked about, because the question named their
/// number and size, and a later part's files are asked about in their turn.
///
/// An answer the caver asks to remember is written to the profile: "send"
/// turns "only over Wi-Fi" off, "wait" stops the asking and lets files wait
/// for Wi-Fi from then on. Either then stands for the rest of the run.
class SilexgisFilesNetworkGate implements SilexgisFileSendingGate {
  SilexgisFilesNetworkGate({
    required SilexgisProfile profile,
    required SilexgisProfileRepository profiles,
    required NetworkKindProbe probe,
    SilexgisMobileDataDecider? decider,
  }) : _profile = profile,
       _profiles = profiles,
       _probe = probe,
       _decider = decider;

  final SilexgisProfile _profile;
  final SilexgisProfileRepository _profiles;
  final NetworkKindProbe _probe;
  final SilexgisMobileDataDecider? _decider;

  /// What the network allows, or what the caver settled for the whole run.
  SilexgisFilesVerdict? _verdict;

  /// Parts ask one after another; a question still open is answered before
  /// the next part's is considered, whatever became of it.
  Future<bool> _last = Future<bool>.value(true);

  @override
  Future<bool> mayFilesGo({required int files, required int bytes}) {
    Future<bool> decide(Object? _) => _decide(files: files, bytes: bytes);
    return _last = _last.then(decide, onError: decide);
  }

  Future<bool> _decide({required int files, required int bytes}) async {
    final verdict = _verdict ??= silexgisFilesVerdict(
      _profile,
      _profile.filesOnlyOverWifi ? await _probe.current() : NetworkKind.unknown,
    );
    switch (verdict) {
      case SilexgisFilesVerdict.send:
        return true;
      case SilexgisFilesVerdict.wait:
        return false;
      case SilexgisFilesVerdict.ask:
        break;
    }
    final answer = await _decider?.askToSendOverMobileData(
      files: files,
      bytes: bytes,
    );
    if (answer == null) {
      _verdict = SilexgisFilesVerdict.wait;
      return false;
    }
    if (answer.remember) await _remember(answer.send);
    if (!answer.send || answer.remember) {
      _verdict = answer.send
          ? SilexgisFilesVerdict.send
          : SilexgisFilesVerdict.wait;
    }
    return answer.send;
  }

  Future<void> _remember(bool send) async {
    // Read again: the caver may have changed another setting meanwhile, or
    // forgotten the server, which saving the run's copy would bring back.
    final current = await _profiles.find(_profile.profileUuid);
    if (current == null) return;
    await _profiles.save(
      send
          ? current.copyWith(filesOnlyOverWifi: false)
          : current.copyWith(asksBeforeMobileData: false),
    );
  }
}
