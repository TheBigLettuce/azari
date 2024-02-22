// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/tags/post_tags.dart';
import 'package:gallery/src/interfaces/grid/grid_mutation_interface.dart';
import 'package:gallery/src/interfaces/search_mixin.dart';
import 'package:gallery/src/widgets/search_bar/autocomplete/autocomplete_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../interfaces/cell/cell.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../skeletons/grid_skeleton_state_filter.dart';

part 'search_widget.dart';

/// Search mixin which filters the elements on a grid.
mixin SearchFilterGrid<T extends Cell>
    implements SearchMixin<GridSkeletonStateFilter<T>> {
  @override
  final TextEditingController searchTextController = TextEditingController();
  @override
  final FocusNode searchFocus = FocusNode();

  late final List<Widget>? addItems;
  final GlobalKey<__SearchWidgetState> _key = GlobalKey();

  late final GridSkeletonStateFilter<T> _state;

  @override
  void searchHook(state, [List<Widget>? items]) {
    addItems = items;
    _state = state;
  }

  @override
  void disposeSearch() {
    searchTextController.dispose();
    searchFocus.dispose();
  }

  late FilteringMode _currentFilterMode = _state.defaultMode;
  bool _searchVirtual = false;
  Future<List<String>> Function(String string) _localTagCompleteFunc =
      PostTags.g.completeLocalTag;

  void _onChanged(String value, bool direct) {
    var interf = _state.gridKey.currentState?.mutationInterface;
    if (interf != null) {
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

      interf.setSource(res.count, (i) {
        final cell = res.cell(i);
        return _state.transform(cell, sorting);
      });
      _key.currentState?.update();
    }
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
    _state.gridKey.currentState?.mutationInterface.restore();
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

  @override
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
