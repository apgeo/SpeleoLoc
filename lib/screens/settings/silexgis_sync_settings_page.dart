import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_auth_service.dart';
import 'package:speleoloc/services/silexgis/auth/silexgis_tokens.dart';
import 'package:speleoloc/services/silexgis/model/silexgis_problem.dart';
import 'package:speleoloc/services/silexgis/model/sync_set.dart';
import 'package:speleoloc/services/silexgis/silexgis_exception.dart';
import 'package:speleoloc/services/silexgis/silexgis_http.dart';
import 'package:speleoloc/services/silexgis/silexgis_profile.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_api.dart';
import 'package:speleoloc/services/silexgis/silexgis_sync_progress.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/uuid.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/silexgis_sync_report_card.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Configures the club's SilexGIS installation, and runs a sync.
///
/// Everything here is optional. With nothing configured the page shows an
/// invitation and the rest of the application is untouched — the local
/// database is the source of truth whether a server exists or not.
class SilexgisSyncSettingsPage extends ConsumerStatefulWidget {
  const SilexgisSyncSettingsPage({super.key});

  @override
  ConsumerState<SilexgisSyncSettingsPage> createState() =>
      _SilexgisSyncSettingsPageState();
}

class _SilexgisSyncSettingsPageState
    extends ConsumerState<SilexgisSyncSettingsPage>
    with AppBarMenuMixin<SilexgisSyncSettingsPage> {
  SilexgisProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final profile = await ref
        .read(silexgisProfileRepositoryProvider)
        .getDefaultProfile();
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(silexgisSyncControllerProvider).progress;
    final profile = _profile;

    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('silexgis_title')),
        actions: [buildAppBarMenuButton()],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                if (profile == null)
                  _NoServerCard(onAdd: _editProfile)
                else ...<Widget>[
                  _ServerCard(
                    profile: profile,
                    onEdit: () => _editProfile(profile),
                    onSignIn: () => _signIn(profile),
                    onForget: () => _forget(profile),
                  ),
                  const SizedBox(height: 12),
                  _SelectionCard(
                    profile: profile,
                    onChoose: () => _chooseSet(profile),
                    onCarryOwnChanged: (value) async {
                      await ref
                          .read(silexgisProfileRepositoryProvider)
                          .save(profile.copyWith(uploadsNewRoots: value));
                      await _reload();
                    },
                  ),
                  const SizedBox(height: 12),
                  _RunCard(
                    profile: profile,
                    progress: progress,
                    onSync: () =>
                        ref.read(silexgisSyncControllerProvider).syncDefault(),
                    onFullRead: () => ref
                        .read(silexgisSyncControllerProvider)
                        .syncDefault(fromBeginning: true),
                  ),
                  if (progress.needsAttention) ...<Widget>[
                    const SizedBox(height: 12),
                    SilexgisSyncReportCard(progress: progress),
                  ],
                ],
              ],
            ),
    );
  }

  // ------------------------------------------------------------------ actions

  Future<void> _editProfile([SilexgisProfile? existing]) async {
    final edited = await showDialog<SilexgisProfile>(
      context: context,
      builder: (_) => _ProfileDialog(existing: existing),
    );
    if (edited == null) return;
    await ref.read(silexgisProfileRepositoryProvider).save(edited);
    await _reload();
  }

  /// Signs in and stores the refresh token. The password is collected here,
  /// posted, and never kept: what is stored is the credential the server hands
  /// back, and it goes to the platform keystore.
  Future<void> _signIn(SilexgisProfile profile) async {
    final credentials = await showDialog<_Credentials>(
      context: context,
      builder: (_) => _SignInDialog(email: profile.accountEmail),
    );
    if (credentials == null) return;

    final auth = SilexgisAuthService(
      baseUri: profile.baseUri,
      profileUuid: profile.profileUuid,
      store: ref.read(silexgisTokenStoreProvider),
    );
    try {
      var tokens = await _attemptSignIn(auth, credentials);
      if (tokens == null) return;
      if (!tokens.hasOfflineAccess && mounted) {
        // The exchange succeeded and looks healthy; it simply has no refresh
        // token, so the caver would be asked for a password every 15 minutes.
        SnackBarService.showWarning(
          LocServ.inst.t('silexgis_no_offline_access'),
        );
      }
      await ref
          .read(silexgisProfileRepositoryProvider)
          .save(profile.copyWith(accountEmail: credentials.email));
      if (!mounted) return;
      SnackBarService.showSuccess(LocServ.inst.t('silexgis_signed_in'));
      await _reload();
    } on SilexgisException catch (e) {
      // The server's own sentence, not a diagnosis this application invented.
      if (mounted) SnackBarService.showError(e.message);
    } finally {
      auth.close();
    }
  }

  /// Drives the two-factor exchange when the account asks for one.
  Future<SilexgisTokens?> _attemptSignIn(
    SilexgisAuthService auth,
    _Credentials credentials,
  ) async {
    try {
      return await auth.signIn(
        email: credentials.email,
        password: credentials.password,
      );
    } on TwoFactorRequiredException catch (e) {
      if (!mounted) return null;
      final code = await showDialog<String>(
        context: context,
        builder: (_) => _TwoFactorDialog(challenge: e.challenge, auth: auth),
      );
      if (code == null) return null;
      return auth.signIn(
        email: credentials.email,
        password: credentials.password,
        twoFactorCode: code,
        twoFactorCookie: e.challenge.cookie,
      );
    }
  }

  /// Lists the sets this account owns and lets the caver pick one.
  Future<void> _chooseSet(SilexgisProfile profile) async {
    final auth = SilexgisAuthService(
      baseUri: profile.baseUri,
      profileUuid: profile.profileUuid,
      store: ref.read(silexgisTokenStoreProvider),
    );
    try {
      if (!await auth.restore()) {
        if (mounted) {
          SnackBarService.showError(LocServ.inst.t('silexgis_sign_in_first'));
        }
        return;
      }
      final api = SilexgisSyncApi(
        SilexgisHttp(baseUri: profile.baseUri, tokens: auth),
      );
      final sets = await api.listSets();
      if (!mounted) return;

      final chosen = await showDialog<SyncSet>(
        context: context,
        builder: (_) => _SetPickerDialog(sets: sets),
      );
      if (chosen == null) return;
      await ref
          .read(silexgisProfileRepositoryProvider)
          .save(profile.copyWith(syncSetId: chosen.id));
      if (!mounted) return;
      if (chosen.cavingGroupId == null) {
        // A selection with no caving group refuses every row this account
        // creates, and the refusal names the selection rather than the row.
        SnackBarService.showWarning(LocServ.inst.t('silexgis_set_unbound'));
      }
      await _reload();
    } on SilexgisException catch (e) {
      if (mounted) SnackBarService.showError(e.message);
    } finally {
      auth.close();
    }
  }

  Future<void> _forget(SilexgisProfile profile) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(LocServ.inst.t('silexgis_forget_title')),
        content: Text(LocServ.inst.t('silexgis_forget_body')),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(LocServ.inst.t('silexgis_forget_confirm')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref
        .read(silexgisProfileRepositoryProvider)
        .delete(profile.profileUuid);
    await _reload();
  }
}

// -----------------------------------------------------------------------------
// Cards
// -----------------------------------------------------------------------------

class _NoServerCard extends StatelessWidget {
  const _NoServerCard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            LocServ.inst.t('silexgis_none_title'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(LocServ.inst.t('silexgis_none_body')),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(LocServ.inst.t('silexgis_add_server')),
          ),
        ],
      ),
    ),
  );
}

class _ServerCard extends StatelessWidget {
  const _ServerCard({
    required this.profile,
    required this.onEdit,
    required this.onSignIn,
    required this.onForget,
  });

  final SilexgisProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onSignIn;
  final VoidCallback onForget;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.dns_outlined),
          title: Text(profile.displayName),
          subtitle: Text(
            profile.accountEmail.isEmpty
                ? profile.baseUrl
                : '${profile.baseUrl}\n${profile.accountEmail}',
          ),
          isThreeLine: profile.accountEmail.isNotEmpty,
          trailing: IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: onEdit,
            tooltip: LocServ.inst.t('edit'),
          ),
        ),
        OverflowBar(
          alignment: MainAxisAlignment.end,
          children: <Widget>[
            TextButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login),
              label: Text(LocServ.inst.t('silexgis_sign_in')),
            ),
            TextButton.icon(
              onPressed: onForget,
              icon: const Icon(Icons.delete_outline),
              label: Text(LocServ.inst.t('silexgis_forget')),
            ),
          ],
        ),
      ],
    ),
  );
}

class _SelectionCard extends StatelessWidget {
  const _SelectionCard({
    required this.profile,
    required this.onChoose,
    required this.onCarryOwnChanged,
  });

  final SilexgisProfile profile;
  final VoidCallback onChoose;
  final ValueChanged<bool> onCarryOwnChanged;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: <Widget>[
        ListTile(
          leading: const Icon(Icons.checklist),
          title: Text(LocServ.inst.t('silexgis_selection')),
          subtitle: Text(
            profile.isReadyToSync
                ? profile.syncSetId!
                : LocServ.inst.t('silexgis_selection_none'),
          ),
          trailing: TextButton(
            onPressed: onChoose,
            child: Text(LocServ.inst.t('choose')),
          ),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.upload_outlined),
          value: profile.uploadsNewRoots,
          onChanged: onCarryOwnChanged,
          title: Text(LocServ.inst.t('silexgis_send_new_caves')),
          subtitle: Text(LocServ.inst.t('silexgis_send_new_caves_desc')),
        ),
      ],
    ),
  );
}

class _RunCard extends StatelessWidget {
  const _RunCard({
    required this.profile,
    required this.progress,
    required this.onSync,
    required this.onFullRead,
  });

  final SilexgisProfile profile;
  final SilexgisSyncProgress progress;
  final VoidCallback onSync;
  final VoidCallback onFullRead;

  @override
  Widget build(BuildContext context) {
    final ready = profile.isReadyToSync;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    LocServ.inst.t('silexgis_run'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (progress.isRunning)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (progress.message.isNotEmpty) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                progress.message,
                style: TextStyle(
                  color: progress.phase == SilexgisSyncPhase.failed
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
              ),
            ],
            if (progress.phase == SilexgisSyncPhase.completed) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                LocServ.inst.t('silexgis_counts', <String, String>{
                  'received': '${progress.rowsApplied}',
                  'sent': '${progress.rowsSent}',
                  'removed': '${progress.rowsDeleted}',
                }),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            OverflowBar(
              alignment: MainAxisAlignment.end,
              children: <Widget>[
                TextButton.icon(
                  onPressed: ready && !progress.isRunning ? onFullRead : null,
                  icon: const Icon(Icons.refresh),
                  label: Text(LocServ.inst.t('silexgis_full_read')),
                ),
                FilledButton.icon(
                  onPressed: ready && !progress.isRunning ? onSync : null,
                  icon: const Icon(Icons.sync),
                  label: Text(LocServ.inst.t('silexgis_sync_now')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Dialogs
// -----------------------------------------------------------------------------

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({this.existing});

  final SilexgisProfile? existing;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  late final TextEditingController _name = TextEditingController(
    text: widget.existing?.displayName ?? '',
  );
  late final TextEditingController _url = TextEditingController(
    text: widget.existing?.baseUrl ?? 'https://',
  );
  String? _urlError;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    super.dispose();
  }

  void _save() {
    final uri = Uri.tryParse(_url.text.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      setState(() => _urlError = LocServ.inst.t('silexgis_url_invalid'));
      return;
    }
    final existing = widget.existing;
    Navigator.pop(
      context,
      existing == null
          ? SilexgisProfile(
              profileUuid: Uuid.v7().toString(),
              displayName: _name.text.trim(),
              baseUrl: _url.text.trim(),
            )
          : existing.copyWith(
              displayName: _name.text.trim(),
              baseUrl: _url.text.trim(),
            ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocServ.inst.t('silexgis_server')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
          controller: _name,
          decoration: InputDecoration(
            labelText: LocServ.inst.t('silexgis_server_name'),
          ),
        ),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: LocServ.inst.t('silexgis_server_url'),
            errorText: _urlError,
          ),
        ),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(LocServ.inst.t('cancel')),
      ),
      FilledButton(onPressed: _save, child: Text(LocServ.inst.t('save'))),
    ],
  );
}

class _Credentials {
  const _Credentials(this.email, this.password);
  final String email;
  final String password;
}

class _SignInDialog extends StatefulWidget {
  const _SignInDialog({required this.email});

  final String email;

  @override
  State<_SignInDialog> createState() => _SignInDialogState();
}

class _SignInDialogState extends State<_SignInDialog> {
  late final TextEditingController _email = TextEditingController(
    text: widget.email,
  );
  final TextEditingController _password = TextEditingController();

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocServ.inst.t('silexgis_sign_in')),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          decoration: InputDecoration(labelText: LocServ.inst.t('email')),
        ),
        TextField(
          controller: _password,
          obscureText: true,
          decoration: InputDecoration(labelText: LocServ.inst.t('password')),
        ),
      ],
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(LocServ.inst.t('cancel')),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(
          context,
          _Credentials(_email.text.trim(), _password.text),
        ),
        child: Text(LocServ.inst.t('silexgis_sign_in')),
      ),
    ],
  );
}

/// Asks for a two-factor code.
///
/// The recovery path is always offered, whatever the account lists: every
/// method can be taken away by somebody other than the person signing in, and
/// a client that offered only the listed ones could strand them.
class _TwoFactorDialog extends StatefulWidget {
  const _TwoFactorDialog({required this.challenge, required this.auth});

  final TwoFactorChallenge challenge;
  final SilexgisAuthService auth;

  @override
  State<_TwoFactorDialog> createState() => _TwoFactorDialogState();
}

class _TwoFactorDialogState extends State<_TwoFactorDialog> {
  final TextEditingController _code = TextEditingController();
  bool _recovery = false;
  bool _sending = false;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _send(String method) async {
    setState(() => _sending = true);
    try {
      await widget.auth.sendTwoFactorCode(widget.challenge, method);
      if (mounted) {
        SnackBarService.showSuccess(LocServ.inst.t('silexgis_code_sent'));
      }
    } on SilexgisException catch (e) {
      if (mounted) SnackBarService.showError(e.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // `authenticator` is read from the caver's own application and nothing is
    // sent for it; asking would be answered `auth.mfa_method_not_delivered`.
    final sendable = widget.challenge.methods
        .where((m) => m != TwoFactorChallenge.authenticator)
        .toList(growable: false);

    return AlertDialog(
      title: Text(LocServ.inst.t('silexgis_two_factor')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextField(
            controller: _code,
            autofocus: true,
            decoration: InputDecoration(
              labelText: _recovery
                  ? LocServ.inst.t('silexgis_recovery_code')
                  : LocServ.inst.t('silexgis_code'),
            ),
          ),
          const SizedBox(height: 8),
          for (final method in sendable)
            TextButton(
              onPressed: _sending ? null : () => _send(method),
              child: Text(
                LocServ.inst.t('silexgis_send_code_to', <String, String>{
                  'method': method,
                }),
              ),
            ),
          if (widget.challenge.recoveryAccepted)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _recovery,
              onChanged: (v) => setState(() => _recovery = v),
              title: Text(LocServ.inst.t('silexgis_use_recovery_code')),
            ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocServ.inst.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(
            context,
            _recovery
                ? TwoFactorChallenge.asRecoveryCode(_code.text.trim())
                : _code.text.trim(),
          ),
          child: Text(LocServ.inst.t('ok')),
        ),
      ],
    );
  }
}

class _SetPickerDialog extends StatelessWidget {
  const _SetPickerDialog({required this.sets});

  final List<SyncSet> sets;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(LocServ.inst.t('silexgis_selection')),
    content: SizedBox(
      width: double.maxFinite,
      child: sets.isEmpty
          ? Text(LocServ.inst.t('silexgis_no_sets'))
          : ListView.builder(
              shrinkWrap: true,
              itemCount: sets.length,
              itemBuilder: (_, i) {
                final set = sets[i];
                return ListTile(
                  title: Text(set.name),
                  subtitle: Text(
                    LocServ.inst.t('silexgis_set_roots', <String, String>{
                      'count': '${set.rootFeatureIds.length}',
                    }),
                  ),
                  // A selection with no caving group refuses every row this
                  // account creates.
                  trailing: set.cavingGroupId == null
                      ? const Icon(Icons.warning_amber_outlined)
                      : null,
                  onTap: () => Navigator.pop(context, set),
                );
              },
            ),
    ),
    actions: <Widget>[
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(LocServ.inst.t('cancel')),
      ),
    ],
  );
}

/// The action a failure names, for the run card to hint at.
extension SilexgisActionLabel on SilexgisAction {
  String get locKey => switch (this) {
    SilexgisAction.retry => 'silexgis_action_retry',
    SilexgisAction.reAuth => 'silexgis_action_reauth',
    SilexgisAction.applyAndResubmit => 'silexgis_action_resubmit',
    SilexgisAction.surfaceToUser => 'silexgis_action_user',
    SilexgisAction.stop => 'silexgis_action_stop',
    SilexgisAction.ignore => 'silexgis_action_ignore',
  };
}
