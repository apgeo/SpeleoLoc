import 'dart:async';

import 'package:flutter/material.dart';
import 'package:speleoloc/screens/settings/settings_helper.dart';
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

/// Definition of a single sortable field exposed by [FilterableList].
///
/// [id] uniquely identifies the field (used as a stable identifier across
/// rebuilds, persistence, and to express primary/secondary references in
/// [FilterableListSortSpec]).
///
/// [compare] is a normal Dart comparator returning negative/zero/positive
/// for an ascending order. The widget multiplies the result by -1 when the
/// user picks descending order, so callers should always provide an
/// ascending comparator.
@immutable
class FilterableListSortField<T> {
  const FilterableListSortField({
    required this.id,
    required this.label,
    required this.compare,
    this.tooltip,
    this.groupKeyOf,
    this.groupHeaderBuilder,
  });

  final String id;
  final String label;
  final int Function(T a, T b) compare;
  final String? tooltip;

  /// Optional group-key extractor. When this field is active as the primary
  /// sort, consecutive items that return the same key are placed under a
  /// shared group-header row in the list.
  final String Function(T item)? groupKeyOf;

  /// Optional custom group-header renderer. Receives the string returned by
  /// [groupKeyOf]. When null a default grey label is shown.
  final Widget Function(BuildContext context, String groupKey)? groupHeaderBuilder;
}

/// Resolved sort settings: which primary field, optional secondary field
/// (used as a tie-breaker for equal primary keys), and the direction of
/// each.
@immutable
class FilterableListSortSpec {
  const FilterableListSortSpec({
    required this.primaryFieldId,
    this.primaryAscending = true,
    this.secondaryFieldId,
    this.secondaryAscending = true,
  });

  final String primaryFieldId;
  final bool primaryAscending;
  final String? secondaryFieldId;
  final bool secondaryAscending;

  FilterableListSortSpec copyWith({
    String? primaryFieldId,
    bool? primaryAscending,
    Object? secondaryFieldId = _unset,
    bool? secondaryAscending,
  }) {
    return FilterableListSortSpec(
      primaryFieldId: primaryFieldId ?? this.primaryFieldId,
      primaryAscending: primaryAscending ?? this.primaryAscending,
      secondaryFieldId: identical(secondaryFieldId, _unset)
          ? this.secondaryFieldId
          : secondaryFieldId as String?,
      secondaryAscending: secondaryAscending ?? this.secondaryAscending,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FilterableListSortSpec &&
      other.primaryFieldId == primaryFieldId &&
      other.primaryAscending == primaryAscending &&
      other.secondaryFieldId == secondaryFieldId &&
      other.secondaryAscending == secondaryAscending;

  @override
  int get hashCode => Object.hash(
        primaryFieldId,
        primaryAscending,
        secondaryFieldId,
        secondaryAscending,
      );
}

const _unset = Object();

/// Imperative handle for parents that need to read/manipulate the list
/// state from the outside (e.g. "print QR codes for selected items").
class FilterableListController<T> extends ChangeNotifier {
  _FilterableListState<T>? _state;

  void _attach(_FilterableListState<T> s) => _state = s;
  void _detach(_FilterableListState<T> s) {
    if (identical(_state, s)) _state = null;
  }

  /// Items currently visible after filtering and sorting, in display order.
  List<T> get filteredItems =>
      _state?._filtered ?? const <Never>[].cast<T>();

  /// Currently active sort specification (if any).
  FilterableListSortSpec? get currentSort => _state?._sort.value;

  /// Programmatically replace the current sort spec. Pass `null` to clear.
  void setSort(FilterableListSortSpec? spec) => _state?._setSort(spec);

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
    this.sortButtonKey,
    this.sortFields = const [],
    this.initialSort,
    this.onSortChanged,
    this.persistKey,
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
  final Key? sortButtonKey;

  /// Sortable fields exposed in the header sort picker. When empty, the
  /// sort button is hidden and the list is shown in [items] order.
  final List<FilterableListSortField<T>> sortFields;

  /// Optional initial sort applied on mount. Ignored if [sortFields] does
  /// not contain a field with the referenced [FilterableListSortSpec.primaryFieldId].
  final FilterableListSortSpec? initialSort;

  /// Called when the sort spec changes (user picked or cleared a sort).
  final ValueChanged<FilterableListSortSpec?>? onSortChanged;

  /// When non-null the active sort spec is persisted in the `configurations`
  /// table under `filterable_sort_<persistKey>` and restored on next mount.
  /// Use a stable, app-unique key such as `'cave_list_sort'`.
  final String? persistKey;

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

// ---------------------------------------------------------------------------
//  Display-item union — data rows and group headers share one list
// ---------------------------------------------------------------------------

sealed class _ListDisplayItem {}

final class _ListGroupHeader extends _ListDisplayItem {
  _ListGroupHeader(this.key);
  final String key;
}

final class _ListDataRow extends _ListDisplayItem {
  _ListDataRow(this.filteredIndex);
  final int filteredIndex;
}

class _FilterableListState<T> extends State<FilterableList<T>> {
  late final ValueNotifier<Set<Object>> _selection =
      ValueNotifier<Set<Object>>(<Object>{});
  late final ValueNotifier<bool> _selectionMode = ValueNotifier<bool>(false);
  late final ValueNotifier<String> _query = ValueNotifier<String>('');
  late final ValueNotifier<bool> _filterVisible = ValueNotifier<bool>(false);
  late final ValueNotifier<FilterableListSortSpec?> _sort =
      ValueNotifier<FilterableListSortSpec?>(null);

  late final TextEditingController _filterController = TextEditingController();

  /// Cached filtered+sorted view; rebuilt only when items / query /
  /// predicate / sort change.
  List<T> _filtered = const [];
  /// Flat list of displayable items: group headers interleaved with data rows.
  List<_ListDisplayItem> _displayItems = const [];
  String _filteredQuery = '\u0000'; // sentinel
  List<T>? _filteredSource;
  FilterableListSortSpec? _filteredSort = const FilterableListSortSpec(
    primaryFieldId: '\u0000',
  );

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);
    _sort.value = _validateSpec(widget.initialSort);
    _recomputeFilter();
    if (widget.persistKey != null) _loadPersistedSort();
  }

  @override
  void didUpdateWidget(covariant FilterableList<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?._detach(this);
      widget.controller?._attach(this);
    }
    // Revalidate sort spec against the (possibly changed) sort field set.
    if (!identical(oldWidget.sortFields, widget.sortFields)) {
      final revalidated = _validateSpec(_sort.value);
      if (_sort.value != revalidated) {
        _sort.value = revalidated;
      }
    }
    if (!identical(oldWidget.items, widget.items) ||
        oldWidget.filter != widget.filter ||
        oldWidget.searchableText != widget.searchableText ||
        !identical(oldWidget.sortFields, widget.sortFields)) {
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
    _sort.dispose();
    _filterController.dispose();
    super.dispose();
  }

  // ---------- Filtering ----------

  /// Applies the current sort (if any) to a fresh copy of [widget.items].
  /// Returns the original list when no valid sort is active.
  List<T> _sortedSource() {
    final spec = _sort.value;
    if (spec == null || widget.sortFields.isEmpty) return widget.items;
    final byId = {for (final f in widget.sortFields) f.id: f};
    final primary = byId[spec.primaryFieldId];
    if (primary == null) return widget.items;
    final secondary = spec.secondaryFieldId != null
        ? byId[spec.secondaryFieldId!]
        : null;
    final pSign = spec.primaryAscending ? 1 : -1;
    final sSign = spec.secondaryAscending ? 1 : -1;
    final out = List<T>.of(widget.items);
    out.sort((a, b) {
      final c1 = primary.compare(a, b) * pSign;
      if (c1 != 0) return c1;
      if (secondary != null) {
        return secondary.compare(a, b) * sSign;
      }
      return 0;
    });
    return out;
  }

  void _recomputeFilter() {
    final q = _query.value.trim();
    final spec = _sort.value;
    if (identical(_filteredSource, widget.items) &&
        _filteredQuery == q &&
        _filteredSort == spec) {
      return;
    }
    _filteredSource = widget.items;
    _filteredQuery = q;
    _filteredSort = spec;
    final sorted = _sortedSource();
    if (q.isEmpty) {
      _filtered = sorted;
    } else {
      final qLower = q.toLowerCase();
      final pred = widget.filter;
      if (pred != null) {
        _filtered = [for (final it in sorted) if (pred(it, qLower)) it];
      } else {
        final getText = widget.searchableText!;
        _filtered = [
          for (final it in sorted)
            if (getText(it).toLowerCase().contains(qLower)) it
        ];
      }
    }
    _displayItems = _buildDisplayItems();
  }

  // Converts _filtered into a flat list of _ListGroupHeader / _ListDataRow.
  List<_ListDisplayItem> _buildDisplayItems() {
    if (_filtered.isEmpty) return const [];
    final spec = _sort.value;
    String Function(T)? groupKeyOf;
    if (spec != null && widget.sortFields.isNotEmpty) {
      final byId = {for (final f in widget.sortFields) f.id: f};
      groupKeyOf = byId[spec.primaryFieldId]?.groupKeyOf;
    }
    if (groupKeyOf == null) {
      return [for (var i = 0; i < _filtered.length; i++) _ListDataRow(i)];
    }
    String? lastKey;
    final result = <_ListDisplayItem>[];
    for (var i = 0; i < _filtered.length; i++) {
      final key = groupKeyOf(_filtered[i]);
      if (key != lastKey) {
        result.add(_ListGroupHeader(key));
        lastKey = key;
      }
      result.add(_ListDataRow(i));
    }
    return result;
  }

  // ---------- Persistence ----------

  Future<void> _loadPersistedSort() async {
    final key = 'filterable_sort_${widget.persistKey}';
    final json = await SettingsHelper.loadJsonConfig(key, () => const {});
    if (!mounted) return;
    if (json.isEmpty) return;
    try {
      final spec = FilterableListSortSpec(
        primaryFieldId: json['primaryFieldId'] as String,
        primaryAscending: (json['primaryAscending'] as bool?) ?? true,
        secondaryFieldId: json['secondaryFieldId'] as String?,
        secondaryAscending: (json['secondaryAscending'] as bool?) ?? true,
      );
      final validated = _validateSpec(spec);
      if (validated != null && validated != _sort.value) {
        _sort.value = validated;
        setState(_recomputeFilter);
      }
    } catch (_) {}
  }

  Future<void> _saveSort(FilterableListSortSpec? spec) async {
    final key = widget.persistKey;
    if (key == null) return;
    final storageKey = 'filterable_sort_$key';
    if (spec == null) {
      await SettingsHelper.saveJsonConfig(storageKey, const {});
    } else {
      await SettingsHelper.saveJsonConfig(storageKey, {
        'primaryFieldId': spec.primaryFieldId,
        'primaryAscending': spec.primaryAscending,
        if (spec.secondaryFieldId != null)
          'secondaryFieldId': spec.secondaryFieldId,
        'secondaryAscending': spec.secondaryAscending,
      });
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

  /// Returns [spec] unchanged if it references a field that exists in
  /// [widget.sortFields]; otherwise returns null.
  FilterableListSortSpec? _validateSpec(FilterableListSortSpec? spec) {
    if (spec == null || widget.sortFields.isEmpty) return null;
    final ids = {for (final f in widget.sortFields) f.id};
    if (!ids.contains(spec.primaryFieldId)) return null;
    if (spec.secondaryFieldId != null &&
        !ids.contains(spec.secondaryFieldId!)) {
      return spec.copyWith(secondaryFieldId: null);
    }
    return spec;
  }

  void _setSort(FilterableListSortSpec? spec) {
    final validated = _validateSpec(spec);
    if (_sort.value == validated) return;
    _sort.value = validated;
    widget.onSortChanged?.call(validated);
    unawaited(_saveSort(validated));
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
        : ListView.builder(
            controller: widget.scrollController,
            padding: widget.padding,
            itemCount: _displayItems.length,
            itemBuilder: (ctx, i) => _buildDisplayItem(ctx, i, theme, dividerColor),
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

  Widget _buildDisplayItem(
      BuildContext context, int displayIdx, FilterableListTheme theme, Color? dividerColor) {
    final di = _displayItems[displayIdx];
    if (di is _ListGroupHeader) {
      return _buildGroupHeader(context, di.key);
    }
    final filteredIdx = (di as _ListDataRow).filteredIndex;
    final row = _buildRow(context, filteredIdx);
    // No separator between a data row and a following group header, or at end.
    final isLast = displayIdx == _displayItems.length - 1;
    if (isLast || _displayItems[displayIdx + 1] is _ListGroupHeader) return row;
    final separator = widget.separatorBuilder != null
        ? widget.separatorBuilder!(context, filteredIdx)
        : Divider(height: 1, color: dividerColor);
    return Column(mainAxisSize: MainAxisSize.min, children: [row, separator]);
  }

  Widget _buildGroupHeader(BuildContext context, String groupKey) {
    final spec = _sort.value;
    if (spec != null && widget.sortFields.isNotEmpty) {
      final primary = widget.sortFields
          .where((f) => f.id == spec.primaryFieldId)
          .firstOrNull;
      final custom = primary?.groupHeaderBuilder?.call(context, groupKey);
      if (custom != null) return custom;
    }
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      width: double.infinity,
      child: Text(
        groupKey.isEmpty ? '—' : groupKey,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
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
          if (widget.sortFields.isNotEmpty)
            ValueListenableBuilder<FilterableListSortSpec?>(
              valueListenable: _sort,
              builder: (context, spec, _) => IconButton(
                key: widget.sortButtonKey,
                icon: Icon(Icons.sort, size: theme.actionIconSize),
                tooltip: loc.t('sort_by'),
                color: spec != null
                    ? (theme.activeToggleColor ??
                        Theme.of(context).colorScheme.primary)
                    : null,
                onPressed: _openSortPicker,
              ),
            ),
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

  Future<void> _openSortPicker() async {
    final result = await showDialog<_SortPickerResult>(
      context: context,
      builder: (ctx) => _SortPickerDialog(
        fields: widget.sortFields
            .map((f) => _SortPickerField(id: f.id, label: f.label))
            .toList(growable: false),
        initial: _sort.value,
      ),
    );
    if (result == null) return; // dismissed
    if (result.cleared) {
      _setSort(null);
    } else {
      _setSort(result.spec);
    }
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

// ---------------------------------------------------------------------------
//  Sort picker dialog
// ---------------------------------------------------------------------------

@immutable
class _SortPickerField {
  const _SortPickerField({required this.id, required this.label});
  final String id;
  final String label;
}

@immutable
class _SortPickerResult {
  const _SortPickerResult({required this.spec, this.cleared = false});
  final FilterableListSortSpec? spec;
  final bool cleared;
}

class _SortPickerDialog extends StatefulWidget {
  const _SortPickerDialog({required this.fields, required this.initial});

  final List<_SortPickerField> fields;
  final FilterableListSortSpec? initial;

  @override
  State<_SortPickerDialog> createState() => _SortPickerDialogState();
}

class _SortPickerDialogState extends State<_SortPickerDialog> {
  String? _primary;
  bool _primaryAsc = true;
  String? _secondary;
  bool _secondaryAsc = true;

  @override
  void initState() {
    super.initState();
    final ids = {for (final f in widget.fields) f.id};
    final init = widget.initial;
    if (init != null && ids.contains(init.primaryFieldId)) {
      _primary = init.primaryFieldId;
      _primaryAsc = init.primaryAscending;
      if (init.secondaryFieldId != null && ids.contains(init.secondaryFieldId!)) {
        _secondary = init.secondaryFieldId;
        _secondaryAsc = init.secondaryAscending;
      }
    }
  }

  void _selectPrimary(String id, bool asc) {
    setState(() {
      _primary = id;
      _primaryAsc = asc;
      // Don't allow primary == secondary.
      if (_secondary == id) _secondary = null;
    });
  }

  void _selectSecondary(String? id, bool asc) {
    setState(() {
      _secondary = id;
      _secondaryAsc = asc;
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = LocServ.inst;
    final theme = Theme.of(context);
    final headerStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.primary,
    );
    return AlertDialog(
      title: Text(loc.t('sort_by')),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      content: SizedBox(
        width: 360,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(loc.t('sort_primary'), style: headerStyle),
              const SizedBox(height: 4),
              for (final f in widget.fields)
                _SortFieldRow(
                  label: f.label,
                  selected: _primary == f.id,
                  ascending: _primaryAsc,
                  onAscending: () => _selectPrimary(f.id, true),
                  onDescending: () => _selectPrimary(f.id, false),
                ),
              const Divider(height: 16),
              Text(loc.t('sort_secondary'), style: headerStyle),
              const SizedBox(height: 4),
              _SortFieldRow(
                label: loc.t('none'),
                selected: _secondary == null,
                ascending: true,
                showArrows: false,
                onSelect: () => _selectSecondary(null, true),
              ),
              for (final f in widget.fields)
                if (f.id != _primary)
                  _SortFieldRow(
                    label: f.label,
                    selected: _secondary == f.id,
                    ascending: _secondaryAsc,
                    enabled: _primary != null,
                    onAscending: () => _selectSecondary(f.id, true),
                    onDescending: () => _selectSecondary(f.id, false),
                  ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      actions: [
        Row(
          children: [
            TextButton(
              onPressed: widget.initial == null
                  ? null
                  : () => Navigator.pop(
                      context, const _SortPickerResult(spec: null, cleared: true)),
              child: Text(loc.t('sort_clear')),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.t('cancel')),
            ),
            TextButton(
              onPressed: _primary == null
                  ? null
                  : () => Navigator.pop(
                        context,
                        _SortPickerResult(
                          spec: FilterableListSortSpec(
                            primaryFieldId: _primary!,
                            primaryAscending: _primaryAsc,
                            secondaryFieldId: _secondary,
                            secondaryAscending: _secondaryAsc,
                          ),
                        ),
                      ),
              child: Text(loc.t('ok')),
            ),
          ],
        ),
      ],
    );
  }
}

class _SortFieldRow extends StatelessWidget {
  const _SortFieldRow({
    required this.label,
    required this.selected,
    required this.ascending,
    this.onAscending,
    this.onDescending,
    this.onSelect,
    this.enabled = true,
    this.showArrows = true,
  });

  final String label;
  final bool selected;
  final bool ascending;
  final VoidCallback? onAscending;
  final VoidCallback? onDescending;
  final VoidCallback? onSelect;
  final bool enabled;
  final bool showArrows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final disabledColor = theme.disabledColor;
    final inactive = Colors.grey.shade500;
    final loc = LocServ.inst;

    // Compute the callback for a label tap:
    //   "None" / no-arrow rows → onSelect
    //   Arrow rows → first tap selects ascending; subsequent taps toggle direction.
    VoidCallback? labelTap;
    if (enabled) {
      if (onSelect != null && !showArrows) {
        labelTap = onSelect;
      } else if (showArrows) {
        if (!selected) {
          labelTap = onAscending; // first selection
        } else {
          labelTap = ascending ? onDescending : onAscending; // toggle
        }
      }
    }

    final labelText = Text(
      label,
      style: TextStyle(
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        color: !enabled ? disabledColor : (selected ? accent : null),
      ),
    );

    final labelWidget = InkWell(
      onTap: labelTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: labelText,
      ),
    );

    return Row(
      children: [
        if (selected)
          Icon(Icons.check, size: 16, color: accent)
        else
          const SizedBox(width: 16),
        const SizedBox(width: 4),
        Expanded(child: labelWidget),
        if (showArrows) ...[
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: loc.t('sort_ascending'),
            icon: Icon(
              Icons.arrow_upward,
              size: 18,
              color: !enabled
                  ? disabledColor
                  : (selected && ascending ? accent : inactive),
            ),
            onPressed: enabled ? onAscending : null,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            tooltip: loc.t('sort_descending'),
            icon: Icon(
              Icons.arrow_downward,
              size: 18,
              color: !enabled
                  ? disabledColor
                  : (selected && !ascending ? accent : inactive),
            ),
            onPressed: enabled ? onDescending : null,
          ),
        ],
      ],
    );
  }
}
