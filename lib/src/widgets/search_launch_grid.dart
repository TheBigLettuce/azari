// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';
import 'package:gallery/src/pages/booru_scroll.dart';
import 'package:gallery/src/db/isar.dart' as db;

import '../../main.dart';
import '../booru/interface.dart';
import 'booru/autocomplete_tag.dart';

abstract class SearchMixin<T> {
  TextEditingController get searchTextController;
  FocusNode get searchFocus;

  void searchHook(T data, [List<Widget>? addButtons]);
  void disposeSearch();
  Widget searchWidget(BuildContext context, {String? hint, int? count});
}

class SearchLaunchGridData {
  final FocusNode mainFocus;
  final String searchText;
  const SearchLaunchGridData(this.mainFocus, this.searchText);
}

mixin SearchLaunchGrid on State<BooruScroll>
    implements SearchMixin<SearchLaunchGridData> {
  @override
  final TextEditingController searchTextController = TextEditingController();
  @override
  final FocusNode searchFocus = FocusNode();

  String currentlyHighlightedTag = "";
  final _ScrollHack _scrollHack = _ScrollHack();
  late BooruAPI booru = db.getBooru(page: widget.booruPage);
  late final void Function() focusMain;

  late final List<Widget>? addItems;

  @override
  void searchHook(SearchLaunchGridData data, [List<Widget>? items]) {
    addItems = items;
    searchTextController.text = data.searchText;
    focusMain = () => data.mainFocus.requestFocus();

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
      autocompleteWidget(searchTextController, (s) {
        currentlyHighlightedTag = s;
      }, (s) => getTab().onTagPressed(context, s), focusMain, booru.completeTag,
          searchFocus,
          scrollHack: _scrollHack, showSearch: true, addItems: addItems);
}

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}
