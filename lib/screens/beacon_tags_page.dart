import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/screens/beacon_tag_edit_page.dart';
import 'package:speleoloc/services/beacon/beacon_photo_store.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/utils/localization.dart';

/// Tag management: every registered tag across all caves with its
/// user-given title, photo thumbnail and assigned place. Tapping a tag
/// opens [BeaconTagEditPage] (title, description, photo, place shortcut).
/// Entry point: Settings → Beacon detection.
class BeaconTagsPage extends ConsumerStatefulWidget {
  const BeaconTagsPage({super.key});

  @override
  ConsumerState<BeaconTagsPage> createState() => _BeaconTagsPageState();
}

class _BeaconTagsPageState extends ConsumerState<BeaconTagsPage> {
  List<BeaconWithPlace> _tags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final tags = await ref.read(beaconRepositoryProvider).getAllBeacons();
    if (!mounted) return;
    tags.sort((a, b) {
      final byCave = a.caveTitle.compareTo(b.caveTitle);
      if (byCave != 0) return byCave;
      return a.cavePlace.title.compareTo(b.cavePlace.title);
    });
    setState(() {
      _tags = tags;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(LocServ.inst.t('tag_management_title'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tags.isEmpty
          ? Center(child: Text(LocServ.inst.t('tag_management_empty')))
          : ListView.separated(
              itemCount: _tags.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) => _tile(_tags[i]),
            ),
    );
  }

  Widget _tile(BeaconWithPlace item) {
    final b = item.beacon;
    final isRuuvi = b.beaconType == BeaconTypes.ruuvi;
    final identity = isRuuvi
        ? b.macAddress ?? ''
        : 'major ${b.major} / minor ${b.minor}';
    final lastSeen = b.lastSeenAt != null
        ? DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(DateTime.fromMillisecondsSinceEpoch(b.lastSeenAt!))
        : LocServ.inst.t('beacon_never_seen');
    final title = b.title?.trim().isNotEmpty == true
        ? b.title!
        : (b.model ?? identity);
    return ListTile(
      leading: _TagThumbnail(item: item),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${item.caveTitle} · ${item.cavePlace.title}\n'
        '$identity · ${LocServ.inst.t('beacon_last_seen')}: $lastSeen',
        style: const TextStyle(fontSize: 12),
      ),
      isThreeLine: true,
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => BeaconTagEditPage(item: item),
          ),
        );
        // Title/photo may have changed in the editor.
        await _load();
      },
    );
  }
}

/// Photo thumbnail with the tag-kind icon as fallback.
class _TagThumbnail extends StatelessWidget {
  const _TagThumbnail({required this.item});

  final BeaconWithPlace item;

  @override
  Widget build(BuildContext context) {
    final isRuuvi = item.beacon.beaconType == BeaconTypes.ruuvi;
    return FutureBuilder<File?>(
      future: BeaconPhotoStore.find(item.beacon.uuid),
      builder: (context, snapshot) {
        final photo = snapshot.data;
        if (photo == null) {
          return CircleAvatar(
            child: Icon(isRuuvi ? Icons.sensors : Icons.wifi_tethering),
          );
        }
        return ClipOval(
          child: Image.file(photo, width: 40, height: 40, fit: BoxFit.cover),
        );
      },
    );
  }
}
