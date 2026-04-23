import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/screens/scanner_page.dart';
import 'package:speleoloc/utils/localization.dart';

/// A compact dialog for quickly adding a new cave place.
///
/// Fields: title (required), cave area (dropdown), QR code (input + scan).
/// Validates:
/// - Title must not be empty.
/// - Title must be unique among cave places for the given cave.
/// - QR code (if provided) must be unique among cave places for the given cave.
///
/// Returns the newly created [CavePlace] id via `Navigator.pop` when saved,
/// or `null` when cancelled.
class AddCavePlacePopup extends StatefulWidget {
  const AddCavePlacePopup({
    super.key,
    required this.caveUuid,
  });

  final Uuid caveUuid;

  @override
  State<AddCavePlacePopup> createState() => _AddCavePlacePopupState();
}

class _AddCavePlacePopupState extends State<AddCavePlacePopup> {
  final _titleController = TextEditingController();
  final _qrController = TextEditingController();
  Uuid? _selectedCaveAreaId;
  List<CaveArea> _caveAreas = [];
  bool _isSaving = false;
  String? _titleError;
  String? _qrError;

  @override
  void initState() {
    super.initState();
    _loadCaveAreas();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _qrController.dispose();
    super.dispose();
  }

  Future<void> _loadCaveAreas() async {
    final areas = await (appDatabase.select(appDatabase.caveAreas)
          ..where((ca) => ca.caveUuid.equalsValue(widget.caveUuid)))
        .get();
    if (mounted) setState(() => _caveAreas = areas);
  }

  Future<bool> _validateTitle() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = LocServ.inst.t('title_required'));
      return false;
    }
    // Check uniqueness
    final existing = await (appDatabase.select(appDatabase.cavePlaces)
          ..where((cp) =>
              cp.caveUuid.equalsValue(widget.caveUuid) &
              cp.title.equals(title)))
        .getSingleOrNull();
    if (existing != null) {
      if (mounted) {
        setState(() => _titleError = LocServ.inst.t('title_already_exists'));
      }
      return false;
    }
    setState(() => _titleError = null);
    return true;
  }

  Future<bool> _validateQr() async {
    final qrText = _qrController.text.trim();
    if (qrText.isEmpty) {
      setState(() => _qrError = null);
      return true; // QR is optional
    }
    final qr = int.tryParse(qrText);
    if (qr == null) {
      setState(() => _qrError = LocServ.inst.t('invalid_qr_code'));
      return false;
    }
    // Check uniqueness within cave
    final existing = await (appDatabase.select(appDatabase.cavePlaces)
          ..where((cp) =>
              cp.caveUuid.equalsValue(widget.caveUuid) &
              cp.placeQrCodeIdentifier.equals(qr)))
        .getSingleOrNull();
    if (existing != null) {
      if (mounted) {
        setState(() => _qrError = LocServ.inst
            .t('qr_already_exists')
            .replaceAll('{qr}', qr.toString())
            .replaceAll('{title}', existing.title));
      }
      return false;
    }
    setState(() => _qrError = null);
    return true;
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final titleOk = await _validateTitle();
    final qrOk = await _validateQr();
    if (!titleOk || !qrOk) {
      setState(() => _isSaving = false);
      return;
    }

    final title = _titleController.text.trim();
    final qr = int.tryParse(_qrController.text.trim());

    try {
      final newId = await appDatabase
          .into(appDatabase.cavePlaces)
          .insert(
            CavePlacesCompanion.insert(
              uuid: Uuid.v7(),
              title: title,
              caveUuid: widget.caveUuid,
              placeQrCodeIdentifier: Value(qr),
              caveAreaUuid: Value(_selectedCaveAreaId),
            ),
          );
      if (mounted) {
        Navigator.pop(context, newId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${LocServ.inst.t('error')}: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  void _openScanner() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerPage(onScan: (code) {
          final qr = int.tryParse(code);
          if (qr != null) {
            _qrController.text = qr.toString();
            Navigator.pop(context); // close scanner
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(LocServ.inst.t('invalid_qr_code'))),
            );
          }
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(LocServ.inst.t('add_cave_place_quick')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('cave_place_title'),
                errorText: _titleError,
              ),
              onChanged: (_) {
                if (_titleError != null) setState(() => _titleError = null);
              },
            ),
            const SizedBox(height: 12),
            // Cave area dropdown
            DropdownButtonFormField<Uuid?>(
              initialValue: _selectedCaveAreaId,
              decoration: InputDecoration(
                labelText: LocServ.inst.t('cave_area'),
              ),
              items: [
                DropdownMenuItem<Uuid?>(
                  value: null,
                  child: Text(LocServ.inst.t('none')),
                ),
                ..._caveAreas.map((a) => DropdownMenuItem<Uuid?>(
                      value: a.uuid,
                      child: Text(a.title),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedCaveAreaId = v),
            ),
            const SizedBox(height: 12),
            // QR code field + scan button
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _qrController,
                    decoration: InputDecoration(
                      labelText: LocServ.inst.t('qr_code_identifier'),
                      errorText: _qrError,
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) {
                      if (_qrError != null) setState(() => _qrError = null);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _openScanner,
                  icon: const Icon(Icons.qr_code_scanner),
                  tooltip: LocServ.inst.t('scan'),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(LocServ.inst.t('cancel')),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(LocServ.inst.t('save')),
        ),
      ],
    );
  }
}
