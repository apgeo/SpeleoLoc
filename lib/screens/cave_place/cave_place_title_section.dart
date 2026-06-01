import 'package:flutter/material.dart';
import 'package:speleoloc/screens/cave_place/cave_place_form_controller.dart';
import 'package:speleoloc/utils/localization.dart';

/// Title field + multiline Description with an expand button.
/// Extracted from `cave_place_page.dart` build method.
class CavePlaceTitleSection extends StatelessWidget {
  const CavePlaceTitleSection({
    super.key,
    required this.form,
    required this.descriptionLines,
    required this.onExpandDescription,
    this.titleFieldKey,
    this.descFieldKey,
  });

  final CavePlaceFormController form;
  final int descriptionLines;
  final VoidCallback onExpandDescription;
  final Key? titleFieldKey;
  final Key? descFieldKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          key: titleFieldKey,
          controller: form.title,
          decoration: InputDecoration(
            labelText: LocServ.inst.t('title'),
            filled: form.titleModified,
            fillColor: form.titleModified
                ? Colors.green.withValues(alpha: 0.06)
                : null,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextFormField(
                key: descFieldKey,
                controller: form.description,
                decoration: InputDecoration(
                  labelText: LocServ.inst.t('description'),
                  filled: form.descriptionModified,
                  fillColor: form.descriptionModified
                      ? Colors.green.withValues(alpha: 0.06)
                      : null,
                ),
                minLines: 1,
                maxLines: descriptionLines,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.unfold_more, size: 18),
              tooltip: LocServ.inst.t('expand_description'),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              style: IconButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onExpandDescription,
            ),
          ],
        ),
      ],
    );
  }
}
