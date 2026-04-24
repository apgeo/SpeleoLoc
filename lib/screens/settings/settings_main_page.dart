import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/screens/settings/settings_general_page.dart';
import 'package:speleoloc/screens/settings/settings_image_compression_page.dart';
import 'package:speleoloc/screens/settings/settings_qr_generation_page.dart';
import 'package:speleoloc/screens/settings/settings_pdf_output_page.dart';
import 'package:speleoloc/screens/settings/settings_database_page.dart';
import 'package:speleoloc/screens/settings/users_page.dart';
import 'package:speleoloc/screens/settings/data_export_import_page.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// Master settings page with sections that navigate to subpages.
class SettingsMainPage extends StatefulWidget {
  const SettingsMainPage({super.key});

  @override
  State<SettingsMainPage> createState() => _SettingsMainPageState();
}

class _SettingsMainPageState extends State<SettingsMainPage>
    with AppBarMenuMixin<SettingsMainPage>, ProductTourMixin<SettingsMainPage> {
  @override
  String get tourId => 'settings_main';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'list', titleLocKey: 'tour_settings_main_list_title', bodyLocKey: 'tour_settings_main_list_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_settings_main_menu_title', bodyLocKey: 'tour_settings_main_menu_body'),
  ];

  bool shouldReloadUI = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && shouldReloadUI) {
          // The parent will handle the reload
        }
      },
      child: Scaffold(
        key: appMenuScaffoldKey,
        endDrawer: buildAppMenuEndDrawer(),
        appBar: AppBar(
          title: Text(LocServ.inst.t('settings')),
          actions: [KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton())],
        ),
        body: ListView(
          key: tourKeys['list'],
          children: [
            _SettingsSection(
              icon: Icons.tune,
              title: LocServ.inst.t('settings_general'),
              subtitle: LocServ.inst.t('settings_general_desc'),
              onTap: () async {
                final result = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsGeneralPage()),
                );
                if (result == true) {
                  shouldReloadUI = true;
                  setState(() {});
                }
              },
            ),
            _SettingsSection(
              icon: Icons.photo_size_select_large,
              title: LocServ.inst.t('image_compression'),
              subtitle: LocServ.inst.t('image_compression_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsImageCompressionPage()),
                );
              },
            ),
            _SettingsSection(
              icon: Icons.qr_code,
              title: LocServ.inst.t('settings_qr_generation'),
              subtitle: LocServ.inst.t('settings_qr_generation_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsQrGenerationPage()),
                );
              },
            ),
            _SettingsSection(
              icon: Icons.picture_as_pdf,
              title: LocServ.inst.t('settings_pdf_output'),
              subtitle: LocServ.inst.t('settings_pdf_output_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsPdfOutputPage()),
                );
              },
            ),
            _SettingsSection(
              icon: Icons.storage,
              title: LocServ.inst.t('settings_database'),
              subtitle: LocServ.inst.t('settings_database_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsDatabasePage()),
                );
              },
            ),
            _SettingsSection(
              icon: Icons.people_outline,
              title: LocServ.inst.t('settings_users'),
              subtitle: LocServ.inst.t('settings_users_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UsersPage()),
                );
              },
            ),
            _SettingsSection(
              icon: Icons.archive_outlined,
              title: LocServ.inst.t('data_export_import'),
              subtitle: LocServ.inst.t('data_export_import_desc'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DataExportImportPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }
}
