import 'package:flutter/material.dart';
import 'package:speleoloc/utils/image_compression_settings.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/app_global_menu.dart';

/// Settings page for image compression on import.
class SettingsImageCompressionPage extends StatefulWidget {
  const SettingsImageCompressionPage({super.key});

  @override
  State<SettingsImageCompressionPage> createState() =>
      _SettingsImageCompressionPageState();
}

class _SettingsImageCompressionPageState
    extends State<SettingsImageCompressionPage>
    with AppBarMenuMixin<SettingsImageCompressionPage> {
  ImageCompressionSettings? _settings;
  late TextEditingController _resolutionCtrl;
  late TextEditingController _qualityCtrl;

  @override
  void initState() {
    super.initState();
    _resolutionCtrl = TextEditingController();
    _qualityCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _resolutionCtrl.dispose();
    _qualityCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final s = await ImageCompressionSettings.load();
    if (!mounted) return;
    setState(() {
      _settings = s;
      _resolutionCtrl.text = s.maxResolution.toString();
      _qualityCtrl.text = s.quality.toString();
    });
  }

  Future<void> _save(ImageCompressionSettings s) async {
    setState(() => _settings = s);
    await s.save();
  }

  String _profileLabel(ImageCompressionProfile p) {
    switch (p) {
      case ImageCompressionProfile.low:
        return LocServ.inst.t('image_compression_profile_low');
      case ImageCompressionProfile.medium:
        return LocServ.inst.t('image_compression_profile_medium');
      case ImageCompressionProfile.high:
        return LocServ.inst.t('image_compression_profile_high');
      case ImageCompressionProfile.veryHigh:
        return LocServ.inst.t('image_compression_profile_very_high');
      case ImageCompressionProfile.manual:
        return LocServ.inst.t('image_compression_profile_manual');
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    if (s == null) {
      return Scaffold(
        appBar: AppBar(title: Text(LocServ.inst.t('image_compression'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final isManual = s.profile == ImageCompressionProfile.manual;

    return Scaffold(
      key: appMenuScaffoldKey,
      endDrawer: buildAppMenuEndDrawer(),
      appBar: AppBar(
        title: Text(LocServ.inst.t('image_compression')),
        actions: [buildAppBarMenuButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Enable / disable toggle
          SwitchListTile(
            title: Text(LocServ.inst.t('image_compression_enabled')),
            value: s.enabled,
            onChanged: (v) => _save(ImageCompressionSettings(
              enabled: v,
              profile: s.profile,
              maxResolution: s.maxResolution,
              quality: s.quality,
            )),
          ),
          const SizedBox(height: 12),

          // Profile dropdown
          ListTile(
            title: Text(LocServ.inst.t('image_compression_profile')),
            trailing: DropdownButton<ImageCompressionProfile>(
              value: s.profile,
              items: ImageCompressionProfile.values
                  .map((p) => DropdownMenuItem(
                        value: p,
                        child: Text(_profileLabel(p)),
                      ))
                  .toList(),
              onChanged: s.enabled
                  ? (p) {
                      if (p == null) return;
                      final updated = s.applyProfile(p);
                      _resolutionCtrl.text =
                          updated.maxResolution.toString();
                      _qualityCtrl.text = updated.quality.toString();
                      _save(updated);
                    }
                  : null,
            ),
          ),
          const SizedBox(height: 12),

          // Max resolution
          TextField(
            controller: _resolutionCtrl,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('image_max_resolution'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: s.enabled && isManual,
            onChanged: (v) {
              final res = int.tryParse(v);
              if (res != null && res > 0) {
                _save(ImageCompressionSettings(
                  enabled: s.enabled,
                  profile: ImageCompressionProfile.manual,
                  maxResolution: res,
                  quality: s.quality,
                ));
              }
            },
          ),
          const SizedBox(height: 12),

          // Image quality
          TextField(
            controller: _qualityCtrl,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('image_quality'),
              border: const OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            enabled: s.enabled && isManual,
            onChanged: (v) {
              final q = int.tryParse(v);
              if (q != null && q >= 1 && q <= 100) {
                _save(ImageCompressionSettings(
                  enabled: s.enabled,
                  profile: ImageCompressionProfile.manual,
                  maxResolution: s.maxResolution,
                  quality: q,
                ));
              }
            },
          ),

          // Show preset info for non-manual profiles
          if (s.enabled && !isManual)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '${LocServ.inst.t('image_max_resolution')}: ${s.maxResolution}px  •  '
                '${LocServ.inst.t('image_quality')}: ${s.quality}%',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
