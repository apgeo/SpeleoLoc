import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/place_code/batch/place_code_batch_runner.dart';
import 'package:speleoloc/utils/app_logger.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/place_code_batch_ui.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Adds a surface area, or edits [existing], and pops `true` once stored.
///
/// A state object of its own because the text fields must outlive the route's
/// exit transition: controllers disposed by the caller as soon as the
/// dialog's future completes are still being read while the dialog fades out.
class SurfaceAreaDialog extends ConsumerStatefulWidget {
  const SurfaceAreaDialog({super.key, this.existing});

  final SurfaceArea? existing;

  static Future<bool?> show(BuildContext context, {SurfaceArea? existing}) =>
      showDialog<bool>(
        context: context,
        builder: (_) => SurfaceAreaDialog(existing: existing),
      );

  @override
  ConsumerState<SurfaceAreaDialog> createState() => _SurfaceAreaDialogState();
}

class _SurfaceAreaDialogState extends ConsumerState<SurfaceAreaDialog> {
  static final _log = AppLogger.of('SurfaceAreaDialog');

  late final TextEditingController _title = TextEditingController(
    text: widget.existing?.title ?? '',
  );
  late final TextEditingController _description = TextEditingController(
    text: widget.existing?.description ?? '',
  );
  late final TextEditingController _identifier = TextEditingController(
    text: widget.existing?.generalAreaIdentifier ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _identifier.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _saving) return;
    setState(() => _saving = true);
    final desc = _description.text.trim().isEmpty
        ? null
        : _description.text.trim();
    final identifier = _identifier.text.trim().isEmpty
        ? null
        : _identifier.text.trim();
    final existing = widget.existing;
    final repository = ref.read(caveRepositoryProvider);
    try {
      if (existing == null) {
        await repository.addSurfaceArea(
          title: title,
          description: desc,
          generalAreaIdentifier: identifier,
        );
      } else {
        await repository.updateSurfaceArea(
          existing: existing,
          title: title,
          description: desc,
          generalAreaIdentifier: identifier,
        );
      }
    } on Exception catch (e, st) {
      _log.warning('saving the surface area failed', e, st);
      if (!mounted) return;
      setState(() => _saving = false);
      SnackBarService.showError(LocServ.inst.t('surface_area_save_failed'));
      return;
    }
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final existing = widget.existing;
    return AlertDialog(
      title: Text(
        existing == null
            ? LocServ.inst.t('add_surface_area')
            : LocServ.inst.t('edit'),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _title,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('enter_surface_area_title'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _identifier,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('general_area_identifier'),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            decoration: InputDecoration(
              labelText: LocServ.inst.t('description'),
            ),
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        if (existing != null)
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome, size: 18),
            label: Text(LocServ.inst.t('generate_codes')),
            onPressed: _saving
                ? null
                : () async {
                    await PlaceCodeBatchUi.run(
                      context,
                      runner: ref.read(placeCodeBatchRunnerProvider),
                      scope: PerAreaScope(existing.uuid),
                      confirmTitle: LocServ.inst.t('generate_codes'),
                      confirmBody: LocServ.inst.t(
                        'generate_codes_confirm_area',
                      ),
                    );
                  },
          ),
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
