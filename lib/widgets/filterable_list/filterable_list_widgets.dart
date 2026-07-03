import 'package:flutter/material.dart';
import 'package:speleoloc/widgets/filterable_list/filterable_list_models.dart';

/// Internal row that listens only to the bits of state it needs (its own
/// selection flag + the global selection-mode flag) so flipping a single
/// checkbox doesn't rebuild the rest of the list.
class SelectableRow<T> extends StatefulWidget {
  const SelectableRow({
    super.key,
    required this.itemKey,
    required this.item,
    required this.selection,
    required this.selectionMode,
    required this.enableSelection,
    required this.onToggle,
    required this.itemBuilder,
    required this.theme,
    this.onTapItem,
    this.itemDecoration,
  });

  final Object itemKey;
  final T item;
  final ValueNotifier<Set<Object>> selection;
  final ValueNotifier<bool> selectionMode;
  final bool enableSelection;
  final void Function(Object key) onToggle;
  final ValueChanged<T>? onTapItem;
  final FilterableListItemBuilder<T> itemBuilder;
  final Widget Function(BuildContext, T, Widget)? itemDecoration;
  final FilterableListTheme theme;

  @override
  State<SelectableRow<T>> createState() => _SelectableRowState<T>();
}

class _SelectableRowState<T> extends State<SelectableRow<T>> {
  late bool _isSelected;
  late bool _selectionMode;

  @override
  void initState() {
    super.initState();
    _isSelected = widget.selection.value.contains(widget.itemKey);
    _selectionMode = widget.selectionMode.value;
    widget.selection.addListener(_onSelectionChanged);
    widget.selectionMode.addListener(_onModeChanged);
  }

  @override
  void didUpdateWidget(covariant SelectableRow<T> old) {
    super.didUpdateWidget(old);
    if (!identical(old.selection, widget.selection)) {
      old.selection.removeListener(_onSelectionChanged);
      widget.selection.addListener(_onSelectionChanged);
      _isSelected = widget.selection.value.contains(widget.itemKey);
    }
    if (!identical(old.selectionMode, widget.selectionMode)) {
      old.selectionMode.removeListener(_onModeChanged);
      widget.selectionMode.addListener(_onModeChanged);
      _selectionMode = widget.selectionMode.value;
    }
  }

  @override
  void dispose() {
    widget.selection.removeListener(_onSelectionChanged);
    widget.selectionMode.removeListener(_onModeChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    final next = widget.selection.value.contains(widget.itemKey);
    if (next != _isSelected) setState(() => _isSelected = next);
  }

  void _onModeChanged() {
    final next = widget.selectionMode.value;
    if (next != _selectionMode) setState(() => _selectionMode = next);
  }

  @override
  Widget build(BuildContext context) {
    final ctx = FilterableListItemContext(
      selectionMode: _selectionMode && widget.enableSelection,
      isSelected: _isSelected,
    );

    Widget content = widget.itemBuilder(context, widget.item, ctx);

    if (ctx.selectionMode) {
      content = Row(
        children: [
          Checkbox(
            value: _isSelected,
            activeColor: widget.theme.checkboxActiveColor,
            onChanged: (_) => widget.onToggle(widget.itemKey),
          ),
          Expanded(child: content),
        ],
      );
    }

    Widget row = InkWell(
      onTap: () {
        if (ctx.selectionMode) {
          widget.onToggle(widget.itemKey);
        } else {
          widget.onTapItem?.call(widget.item);
        }
      },
      child: Padding(padding: widget.theme.rowPadding, child: content),
    );

    if (_isSelected && widget.theme.selectedRowColor != null) {
      row = ColoredBox(color: widget.theme.selectedRowColor!, child: row);
    }

    if (widget.itemDecoration != null) {
      row = widget.itemDecoration!(context, widget.item, row);
    }

    // RepaintBoundary keeps each row's painting independent — selecting one
    // row will not invalidate sibling rows in the layer tree.
    return RepaintBoundary(child: row);
  }
}

// ---------------------------------------------------------------------------
//  Active-state icon button
// ---------------------------------------------------------------------------

/// An [IconButton] that shows a small tinted rounded-rectangle background
/// when [active] is true, making the active state unmistakable without
/// relying solely on icon colour.
class ActiveIconButton extends StatelessWidget {
  const ActiveIconButton({
    super.key,
    required this.active,
    required this.icon,
    required this.size,
    required this.tooltip,
    required this.onPressed,
    this.activeColor,
    this.buttonKey,
  });

  final bool active;
  final IconData icon;
  final double size;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Override the tint colour; falls back to the theme's primary colour.
  final Color? activeColor;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    final Color accent = activeColor ?? Theme.of(context).colorScheme.primary;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        key: buttonKey,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: active
              ? BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.45),
                    width: 1,
                  ),
                )
              : const BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.zero,
                ),
          child: Icon(icon, size: size, color: active ? accent : null),
        ),
      ),
    );
  }
}
