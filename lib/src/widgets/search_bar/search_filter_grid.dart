// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_gen/gen_l10n/app_localizations.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/interfaces/filtering/filtering_mode.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_settings_button.dart";
import "package:gallery/src/widgets/search_bar/autocomplete/autocomplete_widget.dart";

class FilteringSearchWidget<T extends CellBase> extends StatefulWidget {
  const FilteringSearchWidget({
    super.key,
    required this.hint,
    required this.filter,
    required this.textController,
    this.addItems,
    required this.localTagDictionary,
    required this.focusNode,
  });

  final String? hint;

  final ChainedFilterResourceSource<dynamic, T> filter;

  final TextEditingController textController;
  final List<Widget>? addItems;
  final LocalTagDictionaryService localTagDictionary;

  final FocusNode focusNode;

  @override
  State<FilteringSearchWidget<T>> createState() =>
      _FilteringSearchWidgetState();
}

class _FilteringSearchWidgetState<T extends CellBase>
    extends State<FilteringSearchWidget<T>> {
  ChainedFilterResourceSource<dynamic, T> get filter => widget.filter;
  TextEditingController get textController => widget.textController;

  late final StreamSubscription<void> _watcher;
  FocusNode get focusNode => widget.focusNode;

  @override
  void initState() {
    super.initState();

    _watcher = filter.backingStorage.watch((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _watcher.cancel();

    super.dispose();
  }

  List<Widget> _addItems() => [
        if (filter.allowedFilteringModes.isNotEmpty)
          IconButton(
            onPressed: () {
              showModalBottomSheet<void>(
                useRootNavigator: true,
                isScrollControlled: true,
                showDragHandle: true,
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: _FilteringWidget(
                      selectSorting: (e) => filter.sortingMode = e,
                      currentSorting: filter.sortingMode,
                      enabledSorting: filter.allowedSortingModes,
                      select: (e) => filter.filteringMode = e,
                      currentFilter: filter.filteringMode,
                      enabledModes: filter.allowedFilteringModes,
                    ),
                  );
                },
              );
            },
            icon: Icon(filter.filteringMode.icon),
            padding: EdgeInsets.zero,
          ),
        if (widget.addItems != null) ...widget.addItems!,
      ];

  void onChanged() => filter.clearRefresh();

  Widget _autocompleteWidget() => AutocompleteWidget(
        textController,
        (p0) {},
        (p0) {},
        () {
          focusNode.unfocus();
          // widget.instance._state.mainFocus.requestFocus();
        },
        widget.localTagDictionary.complete,
        focusNode,
        swapSearchIcon: true,
        searchCount: filter.count,
        addItems: _addItems(),
        onChanged: onChanged,
        customHint: widget.hint,
        searchTextOverride: AppLocalizations.of(context)!.filterHint,
        noUnfocus: true,
        scrollHack: _ScrollHack(),
      );

  @override
  Widget build(BuildContext context) {
    return switch (filter.filteringMode) {
      FilteringMode.tag || FilteringMode.tagReversed => _autocompleteWidget(),
      FilteringMode() => AutocompleteSearchBar(
          swapSearchIcon: true,
          disable: false,
          focusNode: focusNode,
          addItems: _addItems(),
          count: filter.count,
          textController: textController,
          onChanged: onChanged,
          searchTextOverride: AppLocalizations.of(context)!.filterHint,
          customHint: widget.hint,
          onSubmit: (_) {},
        ),
    };
  }
}

class _FilteringWidget extends StatefulWidget {
  const _FilteringWidget({
    required this.currentFilter,
    required this.enabledModes,
    required this.select,
    required this.currentSorting,
    required this.enabledSorting,
    required this.selectSorting,
  });

  final FilteringMode currentFilter;
  final SortingMode currentSorting;
  final Set<FilteringMode> enabledModes;
  final Set<SortingMode> enabledSorting;
  final FilteringMode Function(FilteringMode) select;
  final void Function(SortingMode) selectSorting;

  @override
  State<_FilteringWidget> createState() => __FilteringWidgetState();
}

class __FilteringWidgetState extends State<_FilteringWidget> {
  late FilteringMode currentFilter = widget.currentFilter;
  late SortingMode currentSorting = widget.currentSorting;

  void _selectFilter(FilteringMode? mode) {
    if (mode == null) {
      if (widget.enabledModes.contains(FilteringMode.noFilter)) {
        currentFilter = widget.select(FilteringMode.noFilter);

        setState(() {});
      }

      return;
    } else {
      currentFilter = widget.select(mode);

      setState(() {});
    }
  }

  void _selectSorting(SortingMode? sort) {
    if (sort != null) {
      currentSorting = sort;

      widget.selectSorting(sort);

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.filteringLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SegmentedButtonGroup<FilteringMode>(
              variant: SegmentedButtonVariant.chip,
              select: _selectFilter,
              selected: currentFilter,
              allowUnselect: true,
              values: widget.enabledModes
                  .where((element) => element != FilteringMode.noFilter)
                  .map(
                    (e) => SegmentedButtonValue(
                      e,
                      e.translatedString(l10n),
                      icon: e.icon,
                    ),
                  ),
              title: l10n.filteringModesLabel,
            ),
            SegmentedButtonGroup<SortingMode>(
              variant: SegmentedButtonVariant.segments,
              select: _selectSorting,
              selected: currentSorting,
              values: widget.enabledSorting.isEmpty
                  ? [
                      SegmentedButtonValue(
                        currentSorting,
                        currentSorting.translatedString(l10n),
                      ),
                    ]
                  : widget.enabledSorting.map(
                      (e) => SegmentedButtonValue(e, e.translatedString(l10n)),
                    ),
              title: l10n.sortingModesLabel,
            ),
            const Padding(padding: EdgeInsets.only(bottom: 8)),
          ],
        ),
      ),
    );
  }
}

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}
