import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/utils/localization.dart';

/// How a trip's written log follows changes to its recorded points.
///
/// Its own page rather than a line in the general settings so the trip
/// screens can link straight to it from the warnings that mention it.
class SettingsTripLogPage extends ConsumerStatefulWidget {
  const SettingsTripLogPage({super.key});

  @override
  ConsumerState<SettingsTripLogPage> createState() =>
      _SettingsTripLogPageState();
}

class _SettingsTripLogPageState extends ConsumerState<SettingsTripLogPage> {
  bool? _regenerateOnEdit;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final value = await ref
        .read(currentUserServiceProvider)
        .getTripLogRegenerateOnEdit();
    if (mounted) setState(() => _regenerateOnEdit = value);
  }

  Future<void> _set(bool value) async {
    setState(() => _regenerateOnEdit = value);
    await ref
        .read(currentUserServiceProvider)
        .setTripLogRegenerateOnEdit(value);
  }

  @override
  Widget build(BuildContext context) {
    final on = _regenerateOnEdit;
    return Scaffold(
      appBar: AppBar(title: Text(LocServ.inst.t('trip_log_settings_title'))),
      body: on == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  value: on,
                  title: Text(LocServ.inst.t('trip_log_regenerate_on_edit')),
                  subtitle: Text(
                    LocServ.inst.t(
                      on
                          ? 'trip_log_regenerate_on_edit_on'
                          : 'trip_log_regenerate_on_edit_off',
                    ),
                  ),
                  onChanged: (v) => unawaited(_set(v)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Text(
                    LocServ.inst.t('trip_log_regenerate_explained'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
