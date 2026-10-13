import 'app_smoke_test.dart' as smoke;
import 'trip_media_fixture_test.dart' as trip_media;

/// Set by `tool/ui_check.sh` only when the seeding step reported that the
/// device holds the invented fixture. The flows behind it assert on invented
/// names, which a curated or real dataset will not contain.
const _fixtureIsInvented = bool.fromEnvironment('SPELEO_FIXTURE_INVENTED');

/// One entry point, so a run builds and installs the app once rather than
/// once per file.
void main() {
  smoke.main();
  if (_fixtureIsInvented) trip_media.main();
}
