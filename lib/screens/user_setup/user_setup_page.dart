import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/user_identity/current_user_resolver.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';
import 'package:speleoloc/widgets/user_details_fields.dart';

/// Asks who is using the app: on first start, after a replaced dataset
/// turned out not to contain the user selected before it, and after the
/// selected user was deleted.
///
/// It cannot be dismissed without a choice. Every write is attributed to
/// the current user, and anything written before a choice would be
/// attributed to the automatic `system` user instead.
class UserSetupPage extends ConsumerStatefulWidget {
  const UserSetupPage({super.key, required this.need});

  final UserChoiceNeeded need;

  @override
  ConsumerState<UserSetupPage> createState() => _UserSetupPageState();
}

class _UserSetupPageState extends ConsumerState<UserSetupPage> {
  final _log = AppLogger.of('UserSetupPage');
  final _fields = UserDetailsControllers();
  late final Stream<List<User>> _users = ref
      .read(currentUserResolverProvider)
      .watchChoosableUsers();
  String? _usernameError;
  bool _busy = false;

  @override
  void dispose() {
    _fields.dispose();
    super.dispose();
  }

  String? get _warning {
    final name = {'username': widget.need.previousUsername ?? ''};
    return switch (widget.need.reason) {
      UserChoiceReason.firstRun => null,
      UserChoiceReason.previousUserMissing => LocServ.inst.t(
        'user_setup_previous_missing',
        name,
      ),
      UserChoiceReason.currentUserDeleted => LocServ.inst.t(
        'user_setup_current_deleted',
        name,
      ),
    };
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) Navigator.of(context).pop();
    } catch (e, st) {
      _log.warning('Choosing the current user failed', e, st);
      SnackBarService.showError('${LocServ.inst.t('user_setup_failed')}: $e');
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _create() async {
    final resolver = ref.read(currentUserResolverProvider);
    final username = _fields.usernameValue;
    final error = username.isEmpty
        ? LocServ.inst.t('user_setup_username_required')
        : await resolver.isUsernameTaken(username)
        ? LocServ.inst.t('user_setup_username_taken')
        : null;
    if (!mounted) return;
    setState(() => _usernameError = error);
    if (error != null) return;
    await _run(
      () => resolver.createAndChoose(
        username: username,
        firstName: _fields.firstNameValue,
        lastName: _fields.lastNameValue,
        details: _fields.detailsValue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolver = ref.read(currentUserResolverProvider);
    final theme = Theme.of(context);
    final warning = _warning;
    final bringOver = widget.need.bringOver;

    Widget heading(String key) => Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(LocServ.inst.t(key), style: theme.textTheme.titleMedium),
    );

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocServ.inst.t('user_setup_title')),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (warning != null)
                Card(
                  color: theme.colorScheme.errorContainer,
                  child: ListTile(
                    leading: Icon(
                      Icons.warning_amber,
                      color: theme.colorScheme.onErrorContainer,
                    ),
                    title: Text(
                      warning,
                      style: TextStyle(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(LocServ.inst.t('user_setup_intro')),
              ),
              if (bringOver != null) ...[
                heading('user_setup_keep_previous'),
                FilledButton.tonalIcon(
                  onPressed: _busy
                      ? null
                      : () => _run(() => resolver.bringOver(bringOver)),
                  icon: const Icon(Icons.person),
                  label: Text(
                    LocServ.inst.t('user_setup_bring_over', {
                      'username': bringOver.username,
                    }),
                  ),
                ),
              ],
              StreamBuilder<List<User>>(
                stream: _users,
                builder: (context, snapshot) {
                  final users = snapshot.data ?? const <User>[];
                  if (users.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heading('user_setup_pick_existing'),
                      for (final u in users)
                        ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(u.username),
                          subtitle: _fullName(u) == null
                              ? null
                              : Text(_fullName(u)!),
                          trailing: const Icon(Icons.chevron_right),
                          enabled: !_busy,
                          onTap: () => _run(() => resolver.choose(u.uuid)),
                        ),
                    ],
                  );
                },
              ),
              heading('user_setup_create_new'),
              UserDetailsFields(
                controllers: _fields,
                usernameError: _usernameError,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _busy ? null : _create,
                icon: const Icon(Icons.person_add),
                label: Text(LocServ.inst.t('user_setup_create_and_continue')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _fullName(User u) {
    final name = [
      u.firstName,
      u.lastName,
    ].whereType<String>().where((s) => s.isNotEmpty).join(' ');
    return name.isEmpty ? null : name;
  }
}
