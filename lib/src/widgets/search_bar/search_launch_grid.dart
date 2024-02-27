// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';

import '../../interfaces/cell/cell.dart';
import '../../interfaces/search_mixin.dart';
import 'autocomplete/autocomplete_widget.dart';
import '../notifiers/booru_api.dart';
import 'search_launch_grid_data.dart';

/// Search mixin which launches a new page with a grid.
class SearchLaunchGrid<T extends Cell>
    implements SearchMixin<SearchLaunchGridData> {
  @override
  final TextEditingController searchTextController = TextEditingController();
  @override
  final FocusNode searchFocus = FocusNode();

  String currentlyHighlightedTag = "";
  final _ScrollHack _scrollHack = _ScrollHack();
  // late final BooruAPI booru;
  late final SearchLaunchGridData _state;

  @override
  void searchHook(SearchLaunchGridData data, [List<Widget>? items]) {
    _state = data;
    searchTextController.text = data.searchText;

    searchFocus.addListener(() {
      if (!searchFocus.hasFocus) {
        currentlyHighlightedTag = "";
        data.mainFocus.requestFocus();
      }
    });
  }

  @override
  void disposeSearch() {
    searchTextController.dispose();
    searchFocus.dispose();
    _scrollHack.dispose();
  }

  @override
  Widget searchWidget(BuildContext context, {String? hint, int? count}) =>
      AutocompleteWidget(
        searchTextController,
        (s) {
          currentlyHighlightedTag = s;
        },
        (s) => _state.onSubmit(context, s),
        () => _state.mainFocus.requestFocus(),
        BooruAPINotifier.of(context).completeTag,
        searchFocus,
        scrollHack: _scrollHack,
        // showSearch: !Platform.isAndroid,
        roundBorders: false,
        swapSearchIcon: _state.swapSearchIconWithAddItems,
        // ignoreFocusNotifier: Platform.isAndroid,
        addItems: _state.addItems,
      );
}

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}
