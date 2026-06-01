import 'package:flutter/material.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_controller.dart';
import 'package:speleoloc/utils/localization.dart';

/// Lat / long / altitude row plus the "record GPS" icon button.
///
/// Visible only when [visible] is true. Reads + writes the form's
/// `lat`, `long`, `alt` text controllers directly; the parent owns
/// the GPS-recorder dialog flow via [onOpenGpsRecorder].
class CavePlaceCoordinatesSection extends StatelessWidget {
  const CavePlaceCoordinatesSection({
    super.key,
    required this.visible,
    required this.form,
    required this.onOpenGpsRecorder,
  });

  final bool visible;
  final CavePlaceFormController form;
  final VoidCallback onOpenGpsRecorder;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Column(
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: form.lat,
                decoration: InputDecoration(
                  labelText: LocServ.inst.t('latitude'),
                  filled: form.latModified,
                  fillColor: form.latModified
                      ? Colors.green.withValues(alpha: 0.06)
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: form.long,
                decoration: InputDecoration(
                  labelText: LocServ.inst.t('longitude'),
                  filled: form.longModified,
                  fillColor: form.longModified
                      ? Colors.green.withValues(alpha: 0.06)
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: form.alt,
                decoration: InputDecoration(
                  labelText: LocServ.inst.t('altitude'),
                  suffixText: 'm',
                  filled: form.altModified,
                  fillColor: form.altModified
                      ? Colors.green.withValues(alpha: 0.06)
                      : null,
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                  signed: true,
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              tooltip: LocServ.inst.t('record_gps_point'),
              onPressed: onOpenGpsRecorder,
              icon: const Icon(Icons.gps_fixed),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
