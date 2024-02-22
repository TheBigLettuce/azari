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
    count = widget.instance._state.gridKey.currentState?.mutationInterface
            .cellCount ??
        0;

    setState(() {});
  }

  List<Widget> _addItems() => [
        if (widget.instance._state.filteringModes.isNotEmpty)
          PopupMenuButton<FilteringMode>(
            // position: PopupMenuPosition.under,
            // offset: const Offset(0, 14),
            itemBuilder: (context) {
              return widget.instance._state.filteringModes
                  .map((e) => PopupMenuItem(
                      value: e,
                      onTap: () {
                        widget.instance._searchVirtual = false;
                        widget.instance._currentFilterMode = e;
                        widget.instance._onChanged(
                            widget.instance.searchTextController.text, true);
                      },
                      child: Text(e.string)))
                  .toList();
            },
            initialValue: widget.instance._currentFilterMode,
            icon: Icon(
              widget.instance._currentFilterMode.icon,
            ),
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
        // showSearch: !Platform.isAndroid,
        roundBorders: false,
        swapSearchIcon: true,

        // ignoreFocusNotifier: Platform.isAndroid,
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

// AppLocalizations.of(context)!.filterHint
