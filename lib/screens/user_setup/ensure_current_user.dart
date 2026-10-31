import 'package:flutter/material.dart';
import 'package:speleoloc/screens/user_setup/user_setup_page.dart';
import 'package:speleoloc/services/user_identity/current_user_resolver.dart';
import 'package:speleoloc/utils/app_logger.dart';

/// Shows [UserSetupPage] when no usable current user is known, and returns
/// once one has been chosen.
///
/// A failure to resolve is logged and lets the app go on: writes then fall
/// back to the automatic `system` user, which is better than a start-up
/// that cannot get past this page.
Future<void> ensureCurrentUser(
  BuildContext context,
  CurrentUserResolver resolver,
) async {
  final UserResolution resolution;
  try {
    resolution = await resolver.resolve();
  } catch (e, st) {
    AppLogger.of(
      'ensureCurrentUser',
    ).warning('Resolving the current user failed', e, st);
    return;
  }
  if (resolution is! UserChoiceNeeded || !context.mounted) return;
  final need = resolution;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => UserSetupPage(need: need),
    ),
  );
}
