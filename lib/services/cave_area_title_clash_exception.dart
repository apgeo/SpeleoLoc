import 'package:speleoloc/utils/app_exceptions.dart';

/// Deleting a cave area moves its places out of any area, and one of them
/// would then share its title with a place already outside every area of
/// the cave. Nothing is changed; renaming either place lets the area go.
class CaveAreaTitleClashException extends DuplicateEntryException {
  const CaveAreaTitleClashException(this.placeTitle)
    : super('A place outside any area already has this title');

  /// The title the two places share.
  final String placeTitle;
}
