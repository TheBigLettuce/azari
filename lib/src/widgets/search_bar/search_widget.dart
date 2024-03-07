// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'search_filter_grid.dart';

class _SearchWidget<T extends Cell> extends StatefulWidget {
  final SearchFilterGrid<T> instance;
  final String? hint;
  final int? count;

  const _SearchWidget({
    super.key,
    required this.instance,
    required this.count,
    required this.hint,
  });

  @override
  State<_SearchWidget<T>> createState() => __SearchWidgetState();
}

class __SearchWidgetState<T extends Cell> extends State<_SearchWidget<T>> {
  late int count = widget.count ?? 0;

  void update() {
    count =
        widget.instance._state.gridKey.currentState?.mutation.cellCount ?? 0;

    setState(() {});
  }

  List<Widget> _addItems() => [
        if (widget.instance._state.filteringModes.isNotEmpty)
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                useRootNavigator: true,
                isScrollControlled: true,
                showDragHandle: true,
                context: context,
                builder: (context) {
                  return SafeArea(
                    child: _FilteringWidget(
                      selectSorting: (e) {
                        widget.instance._state.filter.setSortingMode(e);
                        widget.instance._onChanged(
                            widget.instance.searchTextController.text, true);
                      },
                      currentSorting:
                          widget.instance._state.filter.currentSortingMode,
                      enabledSorting: widget.instance._state.sortingModes,
                      select: (e) {
                        widget.instance._searchVirtual = false;
                        widget.instance._currentFilterMode = e;
                        widget.instance._onChanged(
                            widget.instance.searchTextController.text, true);
                      },
                      currentFilter: widget.instance._currentFilterMode,
                      enabledModes: widget.instance._state.filteringModes,
                    ),
                  );
                },
              );
            },
            icon: Icon(widget.instance._currentFilterMode.icon),
            padding: EdgeInsets.zero,
          ),
        if (widget.instance.addItems != null) ...widget.instance.addItems!
      ];

  Widget _autocompleteWidget() => AutocompleteWidget(
        widget.instance.searchTextController,
        (p0) {},
        (p0) {},
        () {
          widget.instance._state.mainFocus.requestFocus();
        },
        widget.instance._localTagCompleteFunc,
        widget.instance.searchFocus,
        roundBorders: false,
        swapSearchIcon: true,
        searchCount: count,
        addItems: _addItems(),
        onChanged: () {
          widget.instance
              ._onChanged(widget.instance.searchTextController.text, true);
        },
        customHint: widget.hint,
        searchTextOverride: AppLocalizations.of(context)!.filterHint,
        noUnfocus: true,
        scrollHack: _ScrollHack(),
      );

  @override
  Widget build(BuildContext context) {
    return switch (widget.instance._currentFilterMode) {
      FilteringMode.tag || FilteringMode.tagReversed => _autocompleteWidget(),
      FilteringMode() => makeSearchBar(
          context,
          swapSearchIcon: true,
          disable: false,
          focusNode: widget.instance.searchFocus,
          addItems: _addItems(),
          count: count,
          textController: widget.instance.searchTextController,
          onChanged: () => widget.instance
              ._onChanged(widget.instance.searchTextController.text, false),
          searchTextOverride: AppLocalizations.of(context)!.filterHint,
          customHint: widget.hint,
          onSubmit: (_) {},
        ),
    };
  }
}

class _FilteringWidget extends StatefulWidget {
  final FilteringMode currentFilter;
  final SortingMode currentSorting;
  final Set<FilteringMode> enabledModes;
  final Set<SortingMode> enabledSorting;
  final void Function(FilteringMode) select;
  final void Function(SortingMode) selectSorting;

  const _FilteringWidget({
    super.key,
    required this.currentFilter,
    required this.enabledModes,
    required this.select,
    required this.currentSorting,
    required this.enabledSorting,
    required this.selectSorting,
  });

  @override
  State<_FilteringWidget> createState() => __FilteringWidgetState();
}

class __FilteringWidgetState extends State<_FilteringWidget> {
  late FilteringMode currentFilter = widget.currentFilter;
  late SortingMode currentSorting = widget.currentSorting;

  void _selectFilter(FilteringMode? mode) {
    if (mode == null) {
      currentFilter = FilteringMode.noFilter;
    } else {
      currentFilter = mode;
    }

    widget.select(currentFilter);

    setState(() {});
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
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.filteringLabel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SegmentedButtonGroup<FilteringMode>(
              select: _selectFilter,
              selected: currentFilter,
              allowUnselect: true,
              values: widget.enabledModes
                  .where((element) => element != FilteringMode.noFilter)
                  .map((e) => SegmentedButtonValue(
                        e,
                        e.translatedString(context),
                        icon: e.icon,
                      )),
              title: AppLocalizations.of(context)!.filteringModesLabel,
            ),
            SegmentedButtonGroup<SortingMode>(
              select: _selectSorting,
              selected: currentSorting,
              values: widget.enabledSorting.isEmpty
                  ? [
                      SegmentedButtonValue(currentSorting,
                          currentSorting.translatedString(context))
                    ]
                  : widget.enabledSorting.map((e) =>
                      SegmentedButtonValue(e, e.translatedString(context))),
              title: AppLocalizations.of(context)!.sortingModesLabel,
            )
          ],
        ),
      ),
    );
  }
}
