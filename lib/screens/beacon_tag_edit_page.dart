import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/beacon/beacon_photo_store.dart';
import 'package:speleoloc/services/beacon/beacon_repository.dart';
import 'package:speleoloc/utils/app_routes.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Editor for one registered tag: user-facing title and description
/// (saved to the registration row), a photo of the physical tag (stored
/// on the filesystem only — [BeaconPhotoStore]), read-only identity and
/// health info, and a shortcut to the assigned cave place.
class BeaconTagEditPage extends ConsumerStatefulWidget {
  const BeaconTagEditPage({super.key, required this.item});

  final BeaconWithPlace item;

  @override
  ConsumerState<BeaconTagEditPage> createState() => _BeaconTagEditPageState();
}

class _BeaconTagEditPageState extends ConsumerState<BeaconTagEditPage> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descriptionCtrl;
  File? _photo;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.item.beacon.title ?? '');
    _descriptionCtrl = TextEditingController(
      text: widget.item.beacon.notes ?? '',
    );
    _loadPhoto();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPhoto() async {
    final photo = await BeaconPhotoStore.find(widget.item.beacon.uuid);
    if (mounted) setState(() => _photo = photo);
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();
    try {
      await ref
          .read(beaconRepositoryProvider)
          .updateTagInfo(
            widget.item.beacon.uuid,
            title: title.isEmpty ? null : title,
            notes: description.isEmpty ? null : description,
          );
      SnackBarService.showSuccess(LocServ.inst.t('tag_saved'));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      SnackBarService.showError(e);
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;
      final saved = await BeaconPhotoStore.save(
        widget.item.beacon.uuid,
        File(picked.path),
      );
      // The stored path is reused across photos — drop the cached decode.
      await FileImage(saved).evict();
      if (mounted) setState(() => _photo = saved);
    } catch (e) {
      SnackBarService.showError(e);
    }
  }

  Future<void> _removePhoto() async {
    try {
      await BeaconPhotoStore.delete(widget.item.beacon.uuid);
      if (mounted) setState(() => _photo = null);
    } catch (e) {
      SnackBarService.showError(e);
    }
  }

  Future<void> _openPlace() async {
    await AppRoutes.pushCavePlace(
      context,
      caveUuid: widget.item.cavePlace.caveUuid,
      cavePlaceUuid: widget.item.cavePlace.uuid,
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = widget.item.beacon;
    final isRuuvi = b.beaconType == BeaconTypes.ruuvi;
    final identityLine = isRuuvi
        ? '${b.model ?? 'Ruuvi'} · ${b.macAddress}'
        : 'major ${b.major} / minor ${b.minor} · ${b.proximityUuid}';
    final lastSeen = b.lastSeenAt != null
        ? DateFormat(
            'yyyy-MM-dd HH:mm',
          ).format(DateTime.fromMillisecondsSinceEpoch(b.lastSeenAt!))
        : LocServ.inst.t('beacon_never_seen');
    final photo = _photo;
    return Scaffold(
      appBar: AppBar(
        title: Text(LocServ.inst.t('tag_management_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: LocServ.inst.t('save'),
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (photo != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                photo,
                height: 200,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isRuuvi ? Icons.sensors : Icons.wifi_tethering,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.photo_camera),
                tooltip: LocServ.inst.t('tag_photo_take'),
                onPressed: () => _pickPhoto(ImageSource.camera),
              ),
              IconButton(
                icon: const Icon(Icons.photo_library),
                tooltip: LocServ.inst.t('tag_photo_gallery'),
                onPressed: () => _pickPhoto(ImageSource.gallery),
              ),
              if (photo != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: LocServ.inst.t('tag_photo_remove'),
                  onPressed: _removePhoto,
                ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleCtrl,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('title'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descriptionCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('description'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),
          ListTile(
            dense: true,
            leading: Icon(isRuuvi ? Icons.sensors : Icons.wifi_tethering),
            title: Text(identityLine, style: const TextStyle(fontSize: 13)),
            subtitle: Text(
              '${LocServ.inst.t('beacon_last_seen')}: $lastSeen'
              '${b.lastBatteryMv != null ? ' · ${b.lastBatteryMv} mV' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
          ListTile(
            dense: true,
            leading: const Icon(Icons.place_outlined),
            title: Text(LocServ.inst.t('tag_open_place')),
            subtitle: Text(
              '${widget.item.caveTitle} · ${widget.item.cavePlace.title}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _openPlace,
          ),
        ],
      ),
    );
  }
}
