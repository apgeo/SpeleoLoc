import 'package:flutter/material.dart';
import 'package:speleoloc/utils/constants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';

/// General settings: app language.
class SettingsGeneralPage extends StatefulWidget {
  const SettingsGeneralPage({super.key});

  @override
  State<SettingsGeneralPage> createState() => _SettingsGeneralPageState();
}

class _SettingsGeneralPageState extends State<SettingsGeneralPage> {
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
        appBar: AppBar(
          title: Text(LocServ.inst.t('settings_general')),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _needsReload),
          ),
        ),
        body: ListView(
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
          ],
        ),
      ),
    );
  }
}
