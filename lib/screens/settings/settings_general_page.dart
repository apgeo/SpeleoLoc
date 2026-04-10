import 'package:flutter/material.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';
import 'package:speleoloc/widgets/product_tour.dart';

/// General settings: app language.
class SettingsGeneralPage extends StatefulWidget {
  const SettingsGeneralPage({super.key});

  @override
  State<SettingsGeneralPage> createState() => _SettingsGeneralPageState();
}

class _SettingsGeneralPageState extends State<SettingsGeneralPage>
    with AppBarMenuMixin<SettingsGeneralPage>, ProductTourMixin<SettingsGeneralPage> {
  @override
  String get tourId => 'settings_general';
  @override
  final TourKeySet tourKeys = TourKeySet();
  @override
  List<TourStepDef> get tourSteps => [
    TourStepDef(keyId: 'list', titleLocKey: 'tour_settings_general_list_title', bodyLocKey: 'tour_settings_general_list_body'),
    TourStepDef(keyId: 'menu', titleLocKey: 'tour_settings_general_menu_title', bodyLocKey: 'tour_settings_general_menu_body'),
  ];

  String? _appLanguage;
  bool _needsReload = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _appLanguage = LocServ.inst.locale;
      });
    }
  }

  Future<void> _saveConfig(String lang) async {
    await SettingsHelper.saveStringConfig(appLanguageKey, lang);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && _needsReload) {
          Navigator.of(context);
        }
      },
      child: Scaffold(
        key: appMenuScaffoldKey,
        endDrawer: buildAppMenuEndDrawer(),
        appBar: AppBar(
          title: Text(LocServ.inst.t('settings_general')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _needsReload),
          ),
          actions: [KeyedSubtree(key: tourKeys['menu'], child: buildAppBarMenuButton())],
        ),
        body: ListView(
          key: tourKeys['list'],
          padding: const EdgeInsets.all(16),
          children: [
            // App language
            ListTile(
              title: Text(LocServ.inst.t('app_language')),
              trailing: DropdownButton<String>(
                value: _appLanguage,
                items: LocServ.inst
                    .supportedLocales()
                    .map((code) =>
                        DropdownMenuItem(value: code, child: Text(code)))
                    .toList(),
                onChanged: (v) async {
                  if (v == null) return;
                  await LocServ.inst.setLocale(v);
                  await _saveConfig(v);
                  if (mounted) {
                    setState(() {
                      _appLanguage = v;
                      _needsReload = true;
                    });
                  }
                },
              ),
            ),
            const Divider(),
            // Reset tours
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(LocServ.inst.t('reset_tours')),
              onTap: () async {
                await resetAllTours(allTourIds);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(LocServ.inst.t('tours_reset_done'))),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
