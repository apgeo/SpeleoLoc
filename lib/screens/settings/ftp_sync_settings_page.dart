import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/settings/ftps_unsupported_notice.dart';
import 'package:speleoloc/screens/settings/sftp_host_key_dialogs.dart';
import 'package:speleoloc/screens/settings/sftp_host_key_tile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_host_key_store.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile.dart';
import 'package:speleoloc/services/sync/ftp/ftp_profile_repository.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport.dart';
import 'package:speleoloc/services/sync/ftp/ftp_transport_factory.dart';
import 'package:speleoloc/services/sync/ftp/sftp_host_key.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/utils/uuid.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Lists configured FTP/SFTP endpoints, lets the user add/edit/delete them,
/// pick a default, and test connectivity.
///
/// Phase A scope: this screen only manages endpoint configuration. Triggering
/// a sync, progress UI, and background processing arrive in Phase B/C.
class FtpSyncSettingsPage extends ConsumerStatefulWidget {
  const FtpSyncSettingsPage({super.key});

  @override
  ConsumerState<FtpSyncSettingsPage> createState() =>
      _FtpSyncSettingsPageState();
}

class _FtpSyncSettingsPageState extends ConsumerState<FtpSyncSettingsPage>
    with AppBarMenuMixin<FtpSyncSettingsPage> {
  List<FtpProfile> _profiles = const [];
  String? _defaultUuid;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final repo = ref.read(ftpProfileRepositoryProvider);
    final profiles = await repo.list();
    final defaultUuid = await repo.getDefaultUuid();
    if (!mounted) return;
    setState(() {
      _profiles = profiles;
      _defaultUuid = defaultUuid;
      _loading = false;
    });
  }

  Future<void> _edit({FtpProfile? existing}) async {
    final repo = ref.read(ftpProfileRepositoryProvider);
    final hostKeys = ref.read(ftpHostKeyStoreProvider);
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => _FtpProfileEditPage(
          existing: existing,
          repository: repo,
          hostKeys: hostKeys,
        ),
      ),
    );
    if (result == true) {
      await _reload();
    }
  }

  Future<void> _delete(FtpProfile p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(LocServ.inst.t('ftp_delete_profile')),
        content: Text(p.displayName),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(LocServ.inst.t('delete')),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(ftpProfileRepositoryProvider).delete(p.profileUuid);
    await _reload();
  }

  Future<void> _setDefault(FtpProfile p) async {
    await ref.read(ftpProfileRepositoryProvider).setDefaultUuid(p.profileUuid);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('ftp_sync_title')),
        actions: [buildAppBarMenuButton()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: Text(LocServ.inst.t('ftp_add_profile')),
        onPressed: () => _edit(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _profiles.isEmpty
          ? _EmptyState(onAdd: () => _edit())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _profiles.length,
              itemBuilder: (ctx, i) {
                final p = _profiles[i];
                final isDefault = p.profileUuid == _defaultUuid;
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  child: ListTile(
                    leading: Icon(_iconFor(p.protocol)),
                    title: Text(p.displayName),
                    subtitle: Text(
                      '${p.protocol.name.toUpperCase()} · '
                      '${p.username}@${p.host}:${p.effectivePort}'
                      '${p.remoteFolder}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (v) {
                        switch (v) {
                          case 'default':
                            _setDefault(p);
                            break;
                          case 'edit':
                            _edit(existing: p);
                            break;
                          case 'delete':
                            _delete(p);
                            break;
                        }
                      },
                      itemBuilder: (_) => [
                        if (!isDefault)
                          PopupMenuItem(
                            value: 'default',
                            child: Text(LocServ.inst.t('ftp_use_this_profile')),
                          ),
                        PopupMenuItem(
                          value: 'edit',
                          child: Text(LocServ.inst.t('edit')),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(LocServ.inst.t('delete')),
                        ),
                      ],
                    ),
                    onTap: () => _edit(existing: p),
                    selected: isDefault,
                    selectedTileColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    subtitleTextStyle: isDefault
                        ? const TextStyle(fontWeight: FontWeight.w500)
                        : null,
                  ),
                );
              },
            ),
    );
  }

  IconData _iconFor(FtpProtocol protocol) {
    switch (protocol) {
      case FtpProtocol.ftp:
        return Icons.cloud_outlined;
      case FtpProtocol.ftps:
        return Icons.warning_amber_outlined;
      case FtpProtocol.sftp:
        return Icons.lock_outline;
    }
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(
              LocServ.inst.t('ftp_no_profiles'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              LocServ.inst.t('ftp_no_profiles_desc'),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              icon: const Icon(Icons.add),
              label: Text(LocServ.inst.t('ftp_add_profile')),
              onPressed: onAdd,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit page
// ---------------------------------------------------------------------------

class _FtpProfileEditPage extends StatefulWidget {
  final FtpProfile? existing;
  final FtpProfileRepository repository;
  final FtpHostKeyStore hostKeys;

  const _FtpProfileEditPage({
    required this.existing,
    required this.repository,
    required this.hostKeys,
  });

  @override
  State<_FtpProfileEditPage> createState() => _FtpProfileEditPageState();
}

class _FtpProfileEditPageState extends State<_FtpProfileEditPage> {
  final _formKey = GlobalKey<FormState>();

  late FtpProtocol _protocol;
  late final TextEditingController _displayName;
  late final TextEditingController _host;
  late final TextEditingController _port;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late final TextEditingController _remoteFolder;
  late bool _passiveMode;

  /// Fixed for the page's lifetime so that a host key trusted during a
  /// connection test of a new profile is stored under the uuid it is saved
  /// with.
  late final String _profileUuid =
      widget.existing?.profileUuid ?? Uuid.v7().toString();
  SftpHostKey? _hostKey;
  bool _hostKeyUnreadable = false;

  /// A connection test trusts keys for the address typed in the form, which
  /// only becomes the profile's on save. Leaving without saving puts back
  /// [_hostKeyBeforeTest], so the stored profile keeps the key of the
  /// address it still points at.
  bool _hostKeyTrustedByTest = false;
  SftpHostKey? _hostKeyBeforeTest;
  bool _saved = false;
  bool _passwordChanged = false;
  bool _showPassword = false;
  bool _testing = false;
  bool _saving = false;

  /// True while the password field shows the saved-password placeholder ("********").
  bool _hasPlaceholder = false;

  /// Prevents the password listener from treating programmatic text changes as
  /// user edits (e.g. when loading the real password for the view button).
  bool _suppressPasswordListener = false;
  bool _loadingPassword = false;
  late final FocusNode _passwordFocusNode;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _protocol = e?.protocol ?? FtpProtocol.ftp;
    _displayName = TextEditingController(text: e?.displayName ?? '');
    _host = TextEditingController(text: e?.host ?? '');
    _port = TextEditingController(text: e?.port?.toString() ?? '');
    _username = TextEditingController(text: e?.username ?? '');
    final bool isEditing = e != null;
    _hasPlaceholder = isEditing;
    _password = TextEditingController(text: isEditing ? '********' : '');
    _remoteFolder = TextEditingController(text: e?.remoteFolder ?? '/');
    _passiveMode = e?.passiveMode ?? true;
    _password.addListener(() {
      if (!_suppressPasswordListener) {
        _hasPlaceholder = false;
        _passwordChanged = true;
      }
    });
    _passwordFocusNode = FocusNode();
    _passwordFocusNode.addListener(() {
      if (_passwordFocusNode.hasFocus && _hasPlaceholder) {
        _suppressPasswordListener = true;
        _password.clear();
        _suppressPasswordListener = false;
        // _passwordChanged intentionally stays false until the user actually types.
      }
    });
    unawaited(_loadHostKey());
  }

  Future<void> _loadHostKey() async {
    SftpHostKey? key;
    var unreadable = false;
    try {
      key = await widget.hostKeys.read(_profileUuid);
    } catch (e, st) {
      AppLogger.of('FtpSyncSettings').warning('host key unreadable', e, st);
      unreadable = true;
    }
    if (!mounted) return;
    setState(() {
      _hostKey = key;
      _hostKeyUnreadable = unreadable;
    });
  }

  Future<void> _forgetHostKey() async {
    if (!await confirmForgetSftpHostKey(context)) return;
    await widget.hostKeys.forget(_profileUuid);
    _hostKeyTrustedByTest = false;
    _hostKeyBeforeTest = null;
    await _loadHostKey();
  }

  Future<void> _restoreHostKeyBeforeTest() {
    final before = _hostKeyBeforeTest;
    return before == null
        ? widget.hostKeys.forget(_profileUuid)
        : widget.hostKeys.write(_profileUuid, before);
  }

  Future<bool> _confirmFirstUse(
    FtpProfile profile,
    SftpHostKey presented,
    SftpHostKey? previous,
  ) async {
    if (!mounted) return false;
    return confirmTrustSftpHostKey(context, presented, previous);
  }

  @override
  void dispose() {
    if (_hostKeyTrustedByTest && !_saved) {
      unawaited(_restoreHostKeyBeforeTest());
    }
    _displayName.dispose();
    _host.dispose();
    _port.dispose();
    _username.dispose();
    _password.dispose();
    _passwordFocusNode.dispose();
    _remoteFolder.dispose();
    super.dispose();
  }

  /// Resolves an [FtpProfile] from the current form fields, preserving the
  /// existing UUID on edit.
  FtpProfile _currentProfile() {
    final portText = _port.text.trim();
    return FtpProfile(
      profileUuid: _profileUuid,
      displayName: _displayName.text.trim(),
      protocol: _protocol,
      host: _host.text.trim(),
      port: portText.isEmpty ? null : int.tryParse(portText),
      username: _username.text.trim(),
      remoteFolder: _remoteFolder.text.trim().isEmpty
          ? '/'
          : _remoteFolder.text.trim(),
      passiveMode: _passiveMode,
    );
  }

  /// Toggles visibility of the password field.
  /// When the field still shows the placeholder, the first reveal attempts to
  /// load the real password from storage and replace the placeholder with it.
  Future<void> _toggleShowPassword() async {
    if (_hasPlaceholder) {
      if (!_showPassword) {
        setState(() => _loadingPassword = true);
        final realPw = await widget.repository.readPassword(
          widget.existing!.profileUuid,
        );
        if (!mounted) return;
        if (realPw != null && realPw.isNotEmpty) {
          _suppressPasswordListener = true;
          _password.text = realPw;
          _suppressPasswordListener = false;
          _hasPlaceholder = false;
        }
        setState(() {
          _loadingPassword = false;
          _showPassword = true;
        });
      } else {
        // Collapse back to the obscured placeholder.
        _suppressPasswordListener = true;
        _password.text = '********';
        _suppressPasswordListener = false;
        _hasPlaceholder = true;
        setState(() => _showPassword = false);
      }
      return;
    }
    setState(() => _showPassword = !_showPassword);
  }

  Future<String?> _resolvePassword() async {
    if (_passwordChanged || widget.existing == null) {
      return _password.text;
    }
    return widget.repository.readPassword(widget.existing!.profileUuid);
  }

  Future<void> _test() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _testing = true);
    final profile = _currentProfile();
    final password = await _resolvePassword();
    if (password == null || password.isEmpty) {
      if (mounted) {
        _showSnack(LocServ.inst.t('ftp_password_required'), isError: true);
        setState(() => _testing = false);
      }
      return;
    }
    if (!_hostKeyTrustedByTest) _hostKeyBeforeTest = _hostKey;
    final transport = ftpTransportBuilder(
      hostKeys: widget.hostKeys,
      confirmFirstUse: _confirmFirstUse,
    )(profile);
    String? errorMsg;
    try {
      await transport.connect(password: password);
      await transport.listFolder();
      await transport.verifyReadWriteAccess();
    } on FtpHostKeyMismatchException catch (e) {
      errorMsg = '${LocServ.inst.t('ftp_host_key_changed')}: ${e.message}';
    } on FtpHostKeyNotTrustedException {
      errorMsg = LocServ.inst.t('ftp_host_key_not_trusted');
    } on FtpsUnsupportedException {
      errorMsg = LocServ.inst.t('ftp_ftps_unsupported');
    } on FtpAuthException catch (e) {
      errorMsg = '${LocServ.inst.t('ftp_auth_failed')}: ${e.message}';
    } on FtpTransportException catch (e) {
      errorMsg = '${LocServ.inst.t('ftp_connection_failed')}: ${e.message}';
    } catch (e) {
      errorMsg = '${LocServ.inst.t('ftp_connection_failed')}: $e';
    } finally {
      try {
        await transport.disconnect();
      } catch (e, st) {
        AppLogger.of(
          'FtpSyncSettings',
        ).fine('disconnect after test failed', e, st);
      }
    }
    if (!mounted) return;
    setState(() => _testing = false);
    if (profile.protocol == FtpProtocol.sftp) {
      await _loadHostKey();
      final saved = widget.existing;
      final addressIsSaved =
          saved != null &&
          saved.host == profile.host &&
          saved.effectivePort == profile.effectivePort;
      final now = _hostKey;
      final before = _hostKeyBeforeTest;
      if (!addressIsSaved &&
          now != null &&
          (before == null ||
              !now.sameKeyAs(before) ||
              now.endpoint != before.endpoint)) {
        _hostKeyTrustedByTest = true;
      }
    }
    if (!mounted) return;
    if (errorMsg == null) {
      _showSnack(LocServ.inst.t('ftp_connection_ok'));
    } else {
      _showSnack(errorMsg, isError: true);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    // Require a password when creating a new profile.
    final bool isNew = widget.existing == null;
    if (isNew && _password.text.isEmpty) {
      _showSnack(LocServ.inst.t('ftp_password_required'), isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.repository.save(
        _currentProfile(),
        password: _passwordChanged ? _password.text : null,
      );
      _saved = true;
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e, st) {
      AppLogger.of(
        'FtpSyncSettings',
      ).warning('profile could not be saved', e, st);
      if (!mounted) return;
      setState(() => _saving = false);
      _showSnack('${LocServ.inst.t('error')}: $e', isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (isError) {
      SnackBarService.showError(message);
    } else {
      SnackBarService.showSuccess(
        message,
        duration: const Duration(seconds: 4),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          LocServ.inst.t(
            widget.existing == null ? 'ftp_add_profile' : 'ftp_edit_profile',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: LocServ.inst.t('save'),
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _displayName,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('ftp_display_name'),
                border: const OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? LocServ.inst.t('ftp_required_field')
                  : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<FtpProtocol>(
              initialValue: _protocol,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('ftp_protocol'),
                border: const OutlineInputBorder(),
              ),
              items: [
                for (final p in FtpProtocol.values)
                  // FTPS stays listed only so a stored FTPS profile can
                  // show what it is; it cannot be picked.
                  if (p != FtpProtocol.ftps ||
                      widget.existing?.protocol == FtpProtocol.ftps)
                    DropdownMenuItem(
                      value: p,
                      enabled: p != FtpProtocol.ftps,
                      child: Text(LocServ.inst.t('ftp_protocol_${p.name}')),
                    ),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  // An FTP or FTPS port carried into SFTP only fails to
                  // connect; empty means SFTP's own default.
                  if (v == FtpProtocol.sftp &&
                      const {'21', '990'}.contains(_port.text.trim())) {
                    _port.clear();
                  }
                  _protocol = v;
                });
              },
            ),
            if (_protocol == FtpProtocol.ftps) ...[
              const SizedBox(height: 8),
              const FtpsUnsupportedNotice(),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _host,
                    decoration: InputDecoration(
                      labelText: LocServ.inst.t('ftp_host'),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? LocServ.inst.t('ftp_required_field')
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: TextFormField(
                    controller: _port,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: LocServ.inst.t('ftp_port'),
                      hintText: _defaultPortHint(),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = int.tryParse(v.trim());
                      if (n == null || n <= 0 || n > 65535) {
                        return LocServ.inst.t('ftp_port_invalid');
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _username,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('ftp_username'),
                border: const OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty
                  ? LocServ.inst.t('ftp_required_field')
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _password,
              focusNode: _passwordFocusNode,
              obscureText: !_showPassword,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('ftp_password'),
                helperText: widget.existing == null
                    ? null
                    : LocServ.inst.t('ftp_password_leave_empty_to_keep'),
                border: const OutlineInputBorder(),
                suffixIcon: _loadingPassword
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: _toggleShowPassword,
                      ),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remoteFolder,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('ftp_remote_path'),
                hintText: '/speleo_loc/sync/',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            if (_protocol == FtpProtocol.ftp)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(LocServ.inst.t('ftp_passive_mode')),
                subtitle: Text(LocServ.inst.t('ftp_passive_mode_desc')),
                value: _passiveMode,
                onChanged: (v) => setState(() => _passiveMode = v),
              ),
            if (_protocol == FtpProtocol.sftp) ...[
              const SizedBox(height: 8),
              SftpHostKeyTile(
                hostKey: _hostKey,
                unreadable: _hostKeyUnreadable,
                onForget: _testing || _saving ? null : _forgetHostKey,
              ),
            ],
            const SizedBox(height: 24),
            OutlinedButton.icon(
              icon: _testing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.wifi_tethering),
              label: Text(LocServ.inst.t('ftp_test_connection')),
              onPressed: _testing || _saving ? null : _test,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(LocServ.inst.t('save')),
              onPressed: _saving || _testing ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  String _defaultPortHint() {
    switch (_protocol) {
      case FtpProtocol.ftp:
        return '21';
      case FtpProtocol.ftps:
        return '21';
      case FtpProtocol.sftp:
        return '22';
    }
  }
}
