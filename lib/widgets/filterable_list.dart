import 'package:flutter/material.dart';
import 'package:speleoloc/utils/localization.dart';

/// Theme data for [FilterableList]. All fields are optional; null means
/// "fall back to the surrounding [Theme] / sensible defaults". The widget
/// can be themed in the future without touching call-sites.
@immutable
class FilterableListTheme {
  const FilterableListTheme({
    this.headerLabelStyle,
    this.dividerColor,
    this.selectedRowColor,
    this.bulkActionColor,
    this.bulkActionDestructiveColor,
    this.checkboxActiveColor,
    this.activeToggleColor,
    this.actionIconSize = 20,
    this.rowPadding = const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
    this.filterFieldDecoration,
  });

  final TextStyle? headerLabelStyle;
  final Color? dividerColor;
  final Color? selectedRowColor;
  final Color? bulkActionColor;
  final Color? bulkActionDestructiveColor;
  final Color? checkboxActiveColor;
  final Color? activeToggleColor;
  final double actionIconSize;
  final EdgeInsetsGeometry rowPadding;
  final InputDecoration? filterFieldDecoration;
}

/// Per-row state passed to [FilterableListItemBuilder]. Lets the client
/// react to selection state when drawing its row content (e.g. dimming,
/// highlighting, hiding trailing actions).
@immutable
class FilterableListItemContext {
  const FilterableListItemContext({
    required this.selectionMode,
    required this.isSelected,
  });

  final bool selectionMode;
  final bool isSelected;
}

typedef FilterableListItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  FilterableListItemContext state,
);

/// Predicate used to filter items against a (lower-cased, trimmed) query.
typedef FilterableListPredicate<T> = bool Function(T item, String queryLower);

/// Imperative handle for parents that need to read/manipulate the list
/// state from the outside (e.g. "print QR codes for selected items").
class FilterableListController<T> extends ChangeNotifier {
  _FilterableListState<T>? _state;

  void _attach(_FilterableListState<T> s) => _state = s;
  void _detach(_FilterableListState<T> s) {
    if (identical(_state, s)) _state = null;
  }

  /// Items currently visible after filtering, in display order.
  List<T> get filteredItems =>
      _state?._filtered ?? const <Never>[].cast<T>();

  /// Items the user has ticked. Always a subset of [filteredItems] view —
  /// items that are filtered-out stay selected internally but are not
  /// reachable for bulk actions until the filter changes.
  List<T> get selectedItems => _state?._selectedItems() ?? const <Never>[].cast<T>();

  Set<Object> get selectedKeys =>
      _state?._selection.value ?? const <Object>{};

  bool get selectionMode => _state?._selectionMode.value ?? false;

  void clearSelection() => _state?._clearSelection();

  void exitSelectionMode() => _state?._setSelectionMode(false);

  void enterSelectionMode() => _state?._setSelectionMode(true);

  void setFilterQuery(String q) => _state?._setQuery(q);
}

/// A reusable, virtualized, themeable list with optional filtering, batch
/// selection (checkboxes) and batch deletion. Item content is fully
/// delegated to [itemBuilder], so each call-site can draw its own row
/// chrome (icons, badges, per-row delete buttons, …).
///
/// Performance notes:
///   * Backed by [ListView.builder] — handles hundreds/thousands of items.
///   * Selection state is a [ValueNotifier]; only the toggled row rebuilds
///     when a checkbox flips, not the whole list.
///   * Filter results are cached and recomputed only on
///     `items` / `query` / `filter` changes.
class FilterableList<T> extends StatefulWidget {
  const FilterableList({
    super.key,
    required this.items,
    required this.keyOf,
    required this.itemBuilder,
    this.onItemTap,
    this.filter,
    this.searchableText,
    this.filterHintText,
    this.headerLabel,
    this.headerLabelText,
    this.headerKey,
    this.headerLeading = const <Widget>[],
    this.headerTrailing = const <Widget>[],
    this.enableFilter = true,
    this.enableSelection = true,
    this.enableBulkDelete = true,
    this.onBulkDelete,
    this.bulkDeleteConfirmTitle,
    this.bulkDeleteConfirmMessage,
    this.onSelectionChanged,
    this.onSelectionModeChanged,
    this.itemDecoration,
    this.separatorBuilder,
    this.emptyPlaceholder,
    this.padding,
    this.scrollController,
    this.theme,
    this.controller,
    this.selectModeButtonKey,
    this.filterButtonKey,
  })  : assert(filter != null || searchableText != null || enableFilter == false,
            'Provide either `filter` or `searchableText` when filtering is enabled.'),
        assert(enableBulkDelete == false || onBulkDelete != null || enableSelection == false,
            'Provide `onBulkDelete` when `enableBulkDelete` is true.');

  /// Source of truth for the list. Recomputed filter when this changes.
  final List<T> items;

  /// Stable identity for an item; used as React-style key, for selection
  /// tracking and as `Key` for the row widget. Use the item's UUID/ID.
  final Object Function(T item) keyOf;

  final FilterableListItemBuilder<T> itemBuilder;

  /// Tapped row in non-selection mode. In selection mode, the widget
  /// itself toggles selection and this callback is not fired.
  final ValueChanged<T>? onItemTap;

  /// Custom predicate. If null, [searchableText] is used.
  final FilterableListPredicate<T>? filter;

  /// Convenience: returns the searchable representation of an item; the
  /// widget will do a case-insensitive `contains` against the trimmed
  /// query. Only used when [filter] is null.
  final String Function(T item)? searchableText;

  final String? filterHintText;

  /// Header label widget (e.g. a localized "Caves:" line). Wins over
  /// [headerLabelText] when both are provided.
  final Widget? headerLabel;
  final String? headerLabelText;

  /// Key applied to the inline header row that contains the label and
  /// the action buttons. Useful for product-tour overlays.
  final Key? headerKey;
  final Key? selectModeButtonKey;
  final Key? filterButtonKey;

  /// Extra widgets to render at the start/end of the inline header row,
  /// before/after the built-in selection & filter buttons.
  final List<Widget> headerLeading;
  final List<Widget> headerTrailing;

  final bool enableFilter;
  final bool enableSelection;
  final bool enableBulkDelete;

  /// Called when the user confirms bulk deletion. Receives the items
  /// the user picked. Should perform the deletion (the widget will then
  /// clear its selection and exit selection mode).
  final Future<void> Function(List<T> items)? onBulkDelete;

  final String? bulkDeleteConfirmTitle;

  /// Optional confirmation body. The substring `{count}` is replaced with
  /// the number of selected items.
  final String? bulkDeleteConfirmMessage;

  final void Function(Set<Object> selectedKeys, List<T> selectedItems)?
      onSelectionChanged;
  final ValueChanged<bool>? onSelectionModeChanged;

  /// Optional decoration wrapper around each row (e.g. background color
  /// for "entrance" places). Receives the inner row widget.
  final Widget Function(BuildContext context, T item, Widget child)?
      itemDecoration;

  /// Optional row separator. Defaults to a 1px grey divider.
  final IndexedWidgetBuilder? separatorBuilder;

  /// Shown when there are no items (or no items match the filter).
  final Widget? emptyPlaceholder;

  final EdgeInsetsGeometry? padding;
  final ScrollController? scrollController;
  final FilterableListTheme? theme;

  final FilterableListController<T>? controller;

  @override
  State<FilterableList<T>> createState() => _FilterableListState<T>();
}

class _FilterableListState<T> extends State<FilterableList<T>> {
  late final ValueNotifier<Set<Object>> _selection =
      ValueNotifier<Set<Object>>(<Object>{});
  late final ValueNotifier<bool> _selectionMode = ValueNotifier<bool>(false);
  late final ValueNotifier<String> _query = ValueNotifier<String>('');
  late final ValueNotifier<bool> _filterVisible = ValueNotifier<bool>(false);

  late final TextEditingController _filterController = TextEditingController();

  /// Cached filtered view; rebuilt only when items/query/predicate change.
  List<T> _filtered = const [];
  String _filteredQuery = '\u0000'; // sentinel
  List<T>? _filteredSource;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _recomputeFilter();
  }

  @override
  void didUpdateWidget(covariant FilterableList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    if (!identical(oldWidget.items, widget.items) ||
        oldWidget.filter != widget.filter ||
        oldWidget.searchableText != widget.searchableText) {
      _recomputeFilter();
      // Drop selections that no longer exist.
      final allKeys = {for (final it in widget.items) widget.keyOf(it)};
      final pruned = _selection.value.intersection(allKeys);
      if (pruned.length != _selection.value.length) {
        _selection.value = pruned;
        _emitSelectionChanged();
      }
    }
  }

  @override
  void dispose() {
    widget.controller?._detach(this);
    _selection.dispose();
    _selectionMode.dispose();
    _query.dispose();
    _filterVisible.dispose();
    _filterController.dispose();
    super.dispose();
  }

  // ---------- Filtering ----------

  void _recomputeFilter() {
    final q = _query.value.trim();
    if (identical(_filteredSource, widget.items) && _filteredQuery == q) {
      return;
    }
    _filteredSource = widget.items;
    _filteredQuery = q;
    if (q.isEmpty) {
      _filtered = widget.items;
      return;
    }
    final qLower = q.toLowerCase();
    final pred = widget.filter;
    if (pred != null) {
      _filtered = [for (final it in widget.items) if (pred(it, qLower)) it];
    } else {
      final getText = widget.searchableText!;
      _filtered = [
        for (final it in widget.items)
          if (getText(it).toLowerCase().contains(qLower)) it
      ];
    }
  }

  void _setQuery(String q) {
    if (_query.value == q) return;
    _query.value = q;
    if (_filterController.text != q) {
      _filterController.value = TextEditingValue(
        text: q,
        selection: TextSelection.collapsed(offset: q.length),
      );
    }
    setState(_recomputeFilter);
  }

  // ---------- Selection ----------

  List<T> _selectedItems() {
    final sel = _selection.value;
    if (sel.isEmpty) return const [];
    return [for (final it in widget.items) if (sel.contains(widget.keyOf(it))) it];
  }

  void _emitSelectionChanged() {
    widget.onSelectionChanged?.call(_selection.value, _selectedItems());
  }

  void _toggleKey(Object key) {
    final next = Set<Object>.of(_selection.value);
    if (!next.add(key)) next.remove(key);
    _selection.value = next;
    _emitSelectionChanged();
  }

  void _clearSelection() {
    if (_selection.value.isEmpty) return;
    _selection.value = <Object>{};
    _emitSelectionChanged();
  }

  void _selectAllVisible() {
    final next = {for (final it in _filtered) widget.keyOf(it)};
    _selection.value = next;
    _emitSelectionChanged();
  }

  void _invertVisible() {
    final visible = {for (final it in _filtered) widget.keyOf(it)};
    final next = Set<Object>.of(_selection.value);
    for (final k in visible) {
      if (!next.add(k)) next.remove(k);
    }
    _selection.value = next;
    _emitSelectionChanged();
  }

  void _setSelectionMode(bool enabled) {
    if (_selectionMode.value == enabled) return;
    _selectionMode.value = enabled;
    if (!enabled) _clearSelection();
    widget.onSelectionModeChanged?.call(enabled);
  }

  Future<void> _confirmAndBulkDelete() async {
    final selected = _selectedItems();
    if (selected.isEmpty) return;
    final loc = LocServ.inst;
    final title = widget.bulkDeleteConfirmTitle ?? loc.t('confirm');
    final messageTpl =
        widget.bulkDeleteConfirmMessage ?? loc.t('delete_selected_confirm');
    final message = messageTpl.replaceAll('{count}', '${selected.length}');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(loc.t('yes')),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await widget.onBulkDelete!(selected);
    if (!mounted) return;
    _clearSelection();
    _setSelectionMode(false);
  }

  // ---------- Build ----------

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme ?? const FilterableListTheme();
    final dividerColor = theme.dividerColor ?? Colors.grey[300];

    final listBody = _filtered.isEmpty && widget.emptyPlaceholder != null
        ? widget.emptyPlaceholder!
        : ListView.separated(
            controller: widget.scrollController,
            padding: widget.padding,
            itemCount: _filtered.length,
            // Cheap default separator — clients can override.
            separatorBuilder: widget.separatorBuilder ??
                (_, __) => Divider(height: 1, color: dividerColor),
            itemBuilder: _buildRow,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildHeader(theme),
        ValueListenableBuilder<bool>(
          valueListenable: _filterVisible,
          builder: (context, visible, _) {
            if (!visible || !widget.enableFilter) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: TextField(
                controller: _filterController,
                decoration: theme.filterFieldDecoration ??
                    InputDecoration(
                      labelText:
                          widget.filterHintText ?? LocServ.inst.t('filter'),
                    ),
                onChanged: _setQuery,
              ),
            );
          },
        ),
        Expanded(child: listBody),
      ],
    );
  }

  Widget _buildHeader(FilterableListTheme theme) {
    final loc = LocServ.inst;
    final labelStyle = theme.headerLabelStyle ??
        TextStyle(fontSize: 14, color: Colors.grey[600]);
    final destructiveColor =
        theme.bulkActionDestructiveColor ?? Colors.red;

    final Widget? labelWidget = widget.headerLabel ??
        (widget.headerLabelText != null
            ? Text(widget.headerLabelText!, style: labelStyle)
            : null);

    return KeyedSubtree(
      key: widget.headerKey,
      child: Row(
        children: [
          if (labelWidget != null) Expanded(child: labelWidget) else const Spacer(),
          ...widget.headerLeading,
          if (widget.enableSelection)
            ValueListenableBuilder<bool>(
              valueListenable: _selectionMode,
              builder: (context, mode, _) {
                if (!mode) return const SizedBox.shrink();
                return Row(mainAxisSize: MainAxisSize.min, children: [
                  IconButton(
                    icon: Icon(Icons.select_all, size: theme.actionIconSize),
                    tooltip: loc.t('select_all'),
                    onPressed: _selectAllVisible,
                  ),
                  IconButton(
                    icon: Icon(Icons.flip, size: theme.actionIconSize),
                    tooltip: loc.t('invert_selection'),
                    onPressed: _invertVisible,
                  ),
                  if (widget.enableBulkDelete)
                    ValueListenableBuilder<Set<Object>>(
                      valueListenable: _selection,
                      builder: (context, sel, _) => IconButton(
                        icon: Icon(Icons.delete_sweep,
                            size: theme.actionIconSize),
                        tooltip: loc.t('delete_selected'),
                        color: destructiveColor,
                        onPressed: sel.isEmpty ? null : _confirmAndBulkDelete,
                      ),
                    ),
                ]);
              },
            ),
          if (widget.enableSelection)
            ValueListenableBuilder<bool>(
              valueListenable: _selectionMode,
              builder: (context, mode, _) => IconButton(
                key: widget.selectModeButtonKey,
                icon: Icon(
                  Icons.checklist,
                  size: theme.actionIconSize,
                  color: mode
                      ? (theme.activeToggleColor ??
                          Theme.of(context).colorScheme.primary)
                      : null,
                ),
                tooltip: loc.t('select_mode'),
                onPressed: () => _setSelectionMode(!mode),
              ),
            ),
          if (widget.enableFilter)
            ValueListenableBuilder<bool>(
              valueListenable: _filterVisible,
              builder: (context, visible, _) => IconButton(
                key: widget.filterButtonKey,
                icon: Icon(Icons.filter_list, size: theme.actionIconSize),
                tooltip: loc.t('show_filter'),
                color: visible
                    ? (theme.activeToggleColor ??
                        Theme.of(context).colorScheme.primary)
                    : null,
                onPressed: () {
                  final next = !visible;
                  _filterVisible.value = next;
                  if (!next && _query.value.isNotEmpty) {
                    _setQuery('');
                  }
                },
              ),
            ),
          ...widget.headerTrailing,
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, int index) {
    final item = _filtered[index];
    final key = widget.keyOf(item);
    return _SelectableRow<T>(
      key: ValueKey(key),
      itemKey: key,
      item: item,
      selection: _selection,
      selectionMode: _selectionMode,
      enableSelection: widget.enableSelection,
      onTapItem: widget.onItemTap,
      onToggle: _toggleKey,
      itemBuilder: widget.itemBuilder,
      itemDecoration: widget.itemDecoration,
      theme: widget.theme ?? const FilterableListTheme(),
    );
  }
}

/// Internal row that listens only to the bits of state it needs (its own
/// selection flag + the global selection-mode flag) so flipping a single
/// checkbox doesn't rebuild the rest of the list.
class _SelectableRow<T> extends StatefulWidget {
  const _SelectableRow({
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
  State<_SelectableRow<T>> createState() => _SelectableRowState<T>();
}

class _SelectableRowState<T> extends State<_SelectableRow<T>> {
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
  void didUpdateWidget(covariant _SelectableRow<T> old) {
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
      child: Padding(
        padding: widget.theme.rowPadding,
        child: content,
      ),
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
