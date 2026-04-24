import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

/// Settings page for managing the list of known users and selecting the
/// "current user" — the identity stamped on every new/edited row's audit
/// columns and emitted on change-log entries.
class UsersPage extends ConsumerStatefulWidget {
  const UsersPage({super.key});

  @override
  ConsumerState<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends ConsumerState<UsersPage>
    with AppBarMenuMixin<UsersPage> {
  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(usersStreamProvider);
    final currentUser = ref.watch(currentUserServiceProvider);

    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('users')),
        actions: [buildAppBarMenuButton()],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        tooltip: LocServ.inst.t('add_user'),
        child: const Icon(Icons.person_add),
      ),
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('$err')),
        data: (users) {
          if (users.isEmpty) {
            return Center(child: Text(LocServ.inst.t('no_users')));
          }
          return ValueListenableBuilder<Uuid?>(
            valueListenable: currentUser.currentUserUuid,
            builder: (context, currentUuid, _) {
              return ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, i) {
                  final u = users[i];
                  final isCurrent = currentUuid == u.uuid;
                  final fullName = [u.firstName, u.lastName]
                      .whereType<String>()
                      .where((s) => s.isNotEmpty)
                      .join(' ');
                  return ListTile(
                    leading: Icon(
                      isCurrent ? Icons.person : Icons.person_outline,
                      color: isCurrent
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    title: Text(u.username),
                    subtitle: fullName.isEmpty
                        ? (u.details == null ? null : Text(u.details!))
                        : Text(fullName),
                    trailing: isCurrent
                        ? Chip(
                            label: Text(LocServ.inst.t('current_user')),
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .primaryContainer,
                          )
                        : TextButton(
                            onPressed: () async {
                              await currentUser.setCurrentUser(u.uuid);
                              if (mounted) setState(() {});
                            },
                            child: Text(LocServ.inst.t('select')),
                          ),
                    onTap: () => _showAddEditDialog(existing: u),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddEditDialog({User? existing}) async {
    final usernameCtrl = TextEditingController(text: existing?.username ?? '');
    final firstNameCtrl =
        TextEditingController(text: existing?.firstName ?? '');
    final lastNameCtrl = TextEditingController(text: existing?.lastName ?? '');
    final detailsCtrl = TextEditingController(text: existing?.details ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null
            ? LocServ.inst.t('add_user')
            : LocServ.inst.t('edit_user')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: usernameCtrl,
                decoration: InputDecoration(
                  labelText: LocServ.inst.t('username'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: firstNameCtrl,
                decoration: InputDecoration(
                  labelText: LocServ.inst.t('first_name'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lastNameCtrl,
                decoration: InputDecoration(
                  labelText: LocServ.inst.t('last_name'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: detailsCtrl,
                decoration: InputDecoration(
                  labelText: LocServ.inst.t('details'),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(LocServ.inst.t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              final username = usernameCtrl.text.trim();
              if (username.isEmpty) return;
              final repo = ref.read(userRepositoryProvider);
              final currentUser = ref.read(currentUserServiceProvider);
              final author = await currentUser.currentOrSystem();
              String? optional(TextEditingController c) =>
                  c.text.trim().isEmpty ? null : c.text.trim();
              try {
                if (existing == null) {
                  await repo.addUser(
                    username: username,
                    firstName: optional(firstNameCtrl),
                    lastName: optional(lastNameCtrl),
                    details: optional(detailsCtrl),
                    authorUserUuid: author,
                  );
                } else {
                  await repo.updateUser(
                    existing.uuid,
                    username: username,
                    firstName: optional(firstNameCtrl),
                    lastName: optional(lastNameCtrl),
                    details: optional(detailsCtrl),
                    authorUserUuid: author,
                  );
                }
                if (ctx.mounted) Navigator.pop(ctx, true);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text('$e')),
                  );
                }
              }
            },
            child: Text(LocServ.inst.t('save')),
          ),
        ],
      ),
    );
    if (saved == true && mounted) setState(() {});
  }
}
