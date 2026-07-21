import 'package:flutter/material.dart';
import 'package:speleoloc/data/source/database/app_database.dart';
import 'package:speleoloc/utils/localization.dart';

/// Details entered for a new cave created from the map.
class NewCaveInput {
  final String caveTitle;
  final String entranceTitle;
  const NewCaveInput(this.caveTitle, this.entranceTitle);
}

/// Searchable cave chooser (bottom sheet). Resolves to the picked cave's
/// uuid, or null when dismissed. [caves] must already be sorted.
Future<Uuid?> showCaveChooser(BuildContext context, List<Cave> caves) {
  return showModalBottomSheet<Uuid>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _CaveChooserSheet(caves: caves),
  );
}

/// Single-text-field prompt. Resolves to the trimmed text, or null when
/// cancelled or left empty.
Future<String?> showTextPrompt(
  BuildContext context, {
  required String titleKey,
  required String labelKey,
  String initial = '',
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (_) => _TextPromptDialog(
      titleKey: titleKey,
      labelKey: labelKey,
      initial: initial,
    ),
  );
  if (result == null || result.isEmpty) return null;
  return result;
}

/// Cave + entrance titles for a cave created from the map.
Future<NewCaveInput?> showNewCavePrompt(BuildContext context) {
  return showDialog<NewCaveInput>(
    context: context,
    builder: (_) => const _NewCavePromptDialog(),
  );
}

class _CaveChooserSheet extends StatefulWidget {
  const _CaveChooserSheet({required this.caves});

  final List<Cave> caves;

  @override
  State<_CaveChooserSheet> createState() => _CaveChooserSheetState();
}

class _CaveChooserSheetState extends State<_CaveChooserSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final filtered = _query.isEmpty
        ? widget.caves
        : widget.caves
              .where((c) => c.title.toLowerCase().contains(_query))
              .toList();
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                loc.t('map_choose_cave'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                autofocus: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: loc.t('search'),
                ),
                onChanged: (v) =>
                    setState(() => _query = v.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (_, i) => ListTile(
                  dense: true,
                  title: Text(filtered[i].title),
                  onTap: () => Navigator.pop(context, filtered[i].uuid),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog widgets own their [TextEditingController]s so disposal happens
/// with the State, after the route's exit animation — disposing right
/// after `showDialog` resolves can hit the still-mounted TextField during
/// the fade-out.
class _TextPromptDialog extends StatefulWidget {
  const _TextPromptDialog({
    required this.titleKey,
    required this.labelKey,
    required this.initial,
  });

  final String titleKey;
  final String labelKey;
  final String initial;

  @override
  State<_TextPromptDialog> createState() => _TextPromptDialogState();
}

class _TextPromptDialogState extends State<_TextPromptDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    return AlertDialog(
      title: Text(loc.t(widget.titleKey)),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: loc.t(widget.labelKey)),
        onSubmitted: (v) => Navigator.pop(context, v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.t('cancel')),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: Text(loc.t('ok')),
        ),
      ],
    );
  }
}

class _NewCavePromptDialog extends StatefulWidget {
  const _NewCavePromptDialog();

  @override
  State<_NewCavePromptDialog> createState() => _NewCavePromptDialogState();
}

class _NewCavePromptDialogState extends State<_NewCavePromptDialog> {
  final TextEditingController _cave = TextEditingController();
  late final TextEditingController _entrance = TextEditingController(
    text: LocServ.inst.t('entrance'),
  );

  @override
  void dispose() {
    _cave.dispose();
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    return AlertDialog(
      title: Text(loc.t('map_new_cave')),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _cave,
            autofocus: true,
            decoration: InputDecoration(labelText: loc.t('cave_title')),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _entrance,
            decoration: InputDecoration(labelText: loc.t('map_entrance_title')),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.t('cancel')),
        ),
        ElevatedButton(
          onPressed: () {
            final caveTitle = _cave.text.trim();
            if (caveTitle.isEmpty) return;
            final entrance = _entrance.text.trim();
            Navigator.pop(
              context,
              NewCaveInput(
                caveTitle,
                entrance.isEmpty ? LocServ.inst.t('entrance') : entrance,
              ),
            );
          },
          child: Text(loc.t('add')),
        ),
      ],
    );
  }
}
