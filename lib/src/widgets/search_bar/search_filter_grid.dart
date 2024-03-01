// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/widgets/search_bar/autocomplete/autocomplete_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

import '../../interfaces/cell/cell.dart';
import '../../interfaces/filtering/filtering_mode.dart';

part 'search_widget.dart';

/// Search mixin which filters the elements on a grid.
class SearchFilterGrid<T extends Cell> {
  SearchFilterGrid(this._state, this.addItems);

  final TextEditingController searchTextController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  final List<Widget>? addItems;
  final GlobalKey<__SearchWidgetState> _key = GlobalKey();

  final GridSkeletonStateFilter<T> _state;

  late FilteringMode _currentFilterMode = _state.defaultMode;
  bool _searchVirtual = false;
  Future<List<String>> Function(String string) _localTagCompleteFunc =
      PostTags.g.completeLocalTag;

  void _onChanged(String value, bool direct) {
    var interf = _state.refreshingStatus.mutation;
    final sorting = _state.hook(_currentFilterMode);
    // if (!direct) {
    //   value = value.trim();
    //   if (value.isEmpty) {
    //     interf.restore();
    //     widget.instance._state.filter.resetFilter();
    //     setState(() {});
    //     return;
    //   }
    // }

    _state.filter.setSortingMode(sorting);

    var res =
        _state.filter.filter(_searchVirtual ? "" : value, _currentFilterMode);

    interf.cellCount = res.count;
    _key.currentState?.update();
  }

  void performSearch(String s, [bool orDirectly = false]) {
    if (orDirectly) {
      if (_key.currentState == null) {
        prewarmResults();

        return;
      }
    }

    searchTextController.text = s;
    _onChanged(s, true);
  }

  void prewarmResults() {
    final sorting = _state.hook(_currentFilterMode);

    _state.filter.setSortingMode(sorting);

    var res = _state.filter.filter("", _currentFilterMode);

    // mutation.setSource(res.count, (i) {
    //   final cell = res.cell(i);
    //   return _state.transform(cell, sorting);
    // });
  }

  FilteringMode currentFilteringMode() {
    return _currentFilterMode;
  }

  void setFilteringMode(FilteringMode f) {
    if (_state.filteringModes.contains(f)) {
      _currentFilterMode = f;
    }
  }

  void setLocalTagCompleteF(Future<List<String>> Function(String string) f) {
    _localTagCompleteFunc = f;
  }

  void _reset(bool resetFilterMode) {
    searchTextController.clear();
    _state.gridKey.currentState?.mutation.reset();
    if (_state.filteringModes.isNotEmpty) {
      _searchVirtual = false;
      if (resetFilterMode) {
        _currentFilterMode = _state.defaultMode;
      }
    }
    _onChanged(searchTextController.text, true);

    _key.currentState?.update();
  }

  void markSearchVirtual() {
    _searchVirtual = true;
  }

  void resetSearch([bool resetFilterMode = true]) {
    _reset(resetFilterMode);
  }

  void dispose() {
    searchTextController.dispose();
    searchFocus.dispose();
  }

  Widget searchWidget(BuildContext context, {String? hint, int? count}) =>
      _SearchWidget<T>(
        key: _key,
        instance: this,
        hint: hint,
        count: count,
      );
}

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}
