import 'package:flutter/material.dart';

/// A line of instruction over the bottom of the model while the screen waits
/// for a particular tap — the station for a place, a splay end — or shows a
/// result such as a distance, with the buttons that end or move it on.
class ModelModeBanner extends StatelessWidget {
  const ModelModeBanner({super.key, required this.text, required this.actions});

  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Expanded(child: Text(text)),
              ...actions,
            ],
          ),
        ),
      ),
    ),
  );
}
