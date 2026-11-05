import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Adds a cave area, or renames [existing], and pops `true` once stored.
///
/// A state object of its own because the text field must outlive the route's
/// exit transition: a controller disposed by the caller as soon as the
/// dialog's future completes is still being read while the dialog fades out.
class CaveAreaDialog extends ConsumerStatefulWidget {
  const CaveAreaDialog({super.key, required this.caveUuid, this.existing});

  final Uuid caveUuid;
  final CaveArea? existing;

  static Future<bool?> show(
    BuildContext context, {
    required Uuid caveUuid,
    CaveArea? existing,
  }) => showDialog<bool>(
    context: context,
    builder: (_) => CaveAreaDialog(caveUuid: caveUuid, existing: existing),
  );

  @override
  ConsumerState<CaveAreaDialog> createState() => _CaveAreaDialogState();
}

class _CaveAreaDialogState extends ConsumerState<CaveAreaDialog> {
  static final _log = AppLogger.of('CaveAreaDialog');

  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    final existing = widget.existing;
    final repository = ref.read(caveRepositoryProvider);
    try {
      if (existing == null) {
        await repository.addCaveArea(widget.caveUuid, title);
      } else {
        await repository.updateCaveAreaTitle(
          uuid: existing.uuid,
          newTitle: title,
          oldTitle: existing.title,
        );
      }
    } on Exception catch (e, st) {
      _log.warning('saving the cave area failed', e, st);
      if (!mounted) return;
      setState(() => _saving = false);
      SnackBarService.showError(LocServ.inst.t('area_save_failed'));
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null
            ? LocServ.inst.t('add_cave_area')
            : LocServ.inst.t('edit'),
      ),
      content: TextField(
        controller: _title,
        decoration: InputDecoration(
          labelText: LocServ.inst.t('enter_area_title'),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(LocServ.inst.t('cancel')),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(LocServ.inst.t('save')),
        ),
      ],
    );
  }
}
