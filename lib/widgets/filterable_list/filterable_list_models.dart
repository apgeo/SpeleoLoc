import 'package:flutter/material.dart';

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
    this.rowPadding = const EdgeInsets.symmetric(
      vertical: 6.0,
      horizontal: 4.0,
    ),
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

typedef FilterableListItemBuilder<T> =
    Widget Function(
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
  final Widget Function(BuildContext context, String groupKey)?
  groupHeaderBuilder;
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
