import 'package:speleoloc/services/silexgis/silexgis_http.dart';

/// A credential that is always good, for tests about something other than
/// signing in.
class FixedTokenSource implements SilexgisTokenSource {
  FixedTokenSource([this.token = 'access-1']);

  final String? token;
  int refreshes = 0;

  @override
  Future<String?> accessToken() async => token;

  @override
  Future<bool> refresh() async {
    refreshes++;
    return true;
  }
}
