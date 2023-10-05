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

  const _SearchWidget(
      {super.key,
      required this.instance,
      required this.count,
      required this.hint});

  @override
  State<_SearchWidget<T>> createState() => __SearchWidgetState();
}

class __SearchWidgetState<T extends Cell> extends State<_SearchWidget<T>> {
  void update() {
    setState(() {});
  }

  List<Widget> _addItems() => [
        if (widget.instance._state.filteringModes.isNotEmpty)
          PopupMenuButton<FilteringMode>(
            itemBuilder: (context) {
              return widget.instance._state.filteringModes
                  .map((e) => PopupMenuItem(value: e, child: Text(e.string)))
                  .toList();
            },
            initialValue: widget.instance._currentFilterMode,
            onSelected: (value) {
              widget.instance._searchVirtual = false;
              widget.instance._currentFilterMode = value;
              widget.instance
                  ._onChanged(widget.instance.searchTextController.text, true);
            },
            icon: Icon(
              widget.instance._currentFilterMode.icon,
            ),
            padding: EdgeInsets.zero,
          ),
        if (widget.instance.addItems != null) ...widget.instance.addItems!
      ];

  String _makeHint(BuildContext context) =>
      "${AppLocalizations.of(context)!.filterHint}${widget.hint != null ? ' ${widget.hint}' : ''}";

  Widget _autocompleteWidget() => autocompleteWidget(
        widget.instance.searchTextController,
        (p0) {},
        (p0) {},
        () {
          widget.instance._state.mainFocus.requestFocus();
        },
        widget.instance._localTagCompleteFunc,
        widget.instance.searchFocus,
        showSearch: !Platform.isAndroid,
        roundBorders: false,
        ignoreFocusNotifier: Platform.isAndroid,
        searchCount: widget
            .instance._state.gridKey.currentState?.mutationInterface?.cellCount,
        addItems: _addItems(),
        onChanged: () {
          widget.instance
              ._onChanged(widget.instance.searchTextController.text, true);
        },
        customHint: _makeHint(context),
        noUnfocus: true,
        scrollHack: _ScrollHack(),
      );

  @override
  Widget build(BuildContext context) {
    return switch (widget.instance._currentFilterMode) {
      FilteringMode.tag || FilteringMode.tagReversed => _autocompleteWidget(),
      FilteringMode() => TextField(
          focusNode: widget.instance.searchFocus,
          controller: widget.instance.searchTextController,
          decoration: autocompleteBarDecoration(
              context,
              () => widget.instance
                  ._reset(widget.instance._state.unsetFilteringModeOnReset),
              _addItems(),
              searchCount: widget.instance._state.gridKey.currentState
                  ?.mutationInterface?.cellCount,
              roundBorders: false,
              ignoreFocusNotifier: Platform.isAndroid,
              showSearch: !Platform.isAndroid,
              hint: _makeHint(context)),
          onChanged: (s) => widget.instance._onChanged(s, false),
        ),
    };
  }
}
