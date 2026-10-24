import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/providers/providers.dart';
import 'package:speleoloc/services/trip_participants.dart';
import 'package:speleoloc/utils/localization.dart';
import 'package:speleoloc/widgets/snack_bar_service.dart';

/// Who took part in a trip, and anything else worth writing down about it.
///
/// Participants are one comma-separated field, typed in one go; the add
/// button is for a name at a time, and the chips under the field show how
/// the text was understood and let a name be taken out again.
///
/// Resolves to true when something was saved.
class TripDetailsPage extends ConsumerStatefulWidget {
  const TripDetailsPage({super.key, required this.tripUuid});

  final Uuid tripUuid;

  @override
  ConsumerState<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends ConsumerState<TripDetailsPage> {
  final _participants = TextEditingController();
  final _details = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _participants.addListener(() => setState(() {}));
    unawaited(_load());
  }

  @override
  void dispose() {
    _participants.dispose();
    _details.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final trip = await ref
        .read(caveTripRepositoryProvider)
        .findById(widget.tripUuid);
    if (!mounted) return;
    setState(() {
      _participants.text = trip?.participants ?? '';
      _details.text = trip?.description ?? '';
      _loading = false;
    });
  }

  Future<void> _addParticipant() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _AddParticipantDialog(),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    _participants.text = TripParticipants.add(_participants.text, name);
  }

  void _remove(String name) {
    _participants.text =
        TripParticipants.format(
          TripParticipants.parse(_participants.text).where((n) => n != name),
        ) ??
        '';
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(caveTripRepositoryProvider)
          .updateTripDetails(
            widget.tripUuid,
            participants: _participants.text,
            details: _details.text,
          );
      SnackBarService.showSuccess(LocServ.inst.t('trip_details_saved'));
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      SnackBarService.showError(e);
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = TripParticipants.parse(_participants.text);
    return Scaffold(
      appBar: AppBar(
        title: Text(LocServ.inst.t('trip_details_title')),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: LocServ.inst.t('save'),
            onPressed: _loading || _saving ? null : () => unawaited(_save()),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _participants,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: LocServ.inst.t('trip_participants'),
                    helperText: LocServ.inst.t('trip_participants_hint'),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.person_add_alt),
                      tooltip: LocServ.inst.t('trip_participant_add'),
                      onPressed: () => unawaited(_addParticipant()),
                    ),
                  ),
                ),
                if (names.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      for (final name in names)
                        InputChip(
                          label: Text(name),
                          onDeleted: () => _remove(name),
                          deleteButtonTooltipMessage: LocServ.inst.t(
                            'trip_participant_remove',
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),
                TextField(
                  controller: _details,
                  minLines: 6,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: LocServ.inst.t('trip_details'),
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
    );
  }
}

/// One name at a time, for adding participants as they are called out.
class _AddParticipantDialog extends StatefulWidget {
  const _AddParticipantDialog();

  @override
  State<_AddParticipantDialog> createState() => _AddParticipantDialogState();
}

class _AddParticipantDialogState extends State<_AddParticipantDialog> {
  final _name = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _name.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocServ.inst.t('trip_participant_add')),
      content: TextField(
        controller: _name,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(
          labelText: LocServ.inst.t('trip_participant_name'),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(LocServ.inst.t('cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(LocServ.inst.t('trip_participant_add_button')),
        ),
      ],
    );
  }
}
