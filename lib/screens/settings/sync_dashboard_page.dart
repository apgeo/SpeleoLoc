import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/screens/settings/change_log_page.dart';
import 'package:speleoloc/screens/settings/sync_page.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

/// Combined sync dashboard with two tabs:
/// - the change-log audit list ([ChangeLogPage]),
/// - the device-to-device archive sync UI ([SyncPage]).
///
/// Each child page is rendered in its `embedded` mode so we host a single
/// shared `Scaffold`/`AppBar` here and avoid nested chrome.
class SyncDashboardPage extends ConsumerStatefulWidget {
  const SyncDashboardPage({super.key});

  @override
  ConsumerState<SyncDashboardPage> createState() => _SyncDashboardPageState();
}

class _SyncDashboardPageState extends ConsumerState<SyncDashboardPage>
    with AppBarMenuMixin<SyncDashboardPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        key: appMenuScaffoldKey,
        endDrawer: buildAppMenuEndDrawer(),
        appBar: AppBar(
          title: Text(LocServ.inst.t('sync_dashboard_title')),
          actions: [buildAppBarMenuButton()],
          bottom: TabBar(
            tabs: [
              Tab(text: LocServ.inst.t('sync_dashboard_archive_tab')),
              Tab(text: LocServ.inst.t('sync_dashboard_changes_tab')),              
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SyncPage(embedded: true),
            ChangeLogPage(embedded: true),            
          ],
        ),
      ),
    );
  }
}
