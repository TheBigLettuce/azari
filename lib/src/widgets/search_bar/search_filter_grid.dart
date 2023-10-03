// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/post_tags.dart';
import 'package:gallery/src/interfaces/search_mixin.dart';
import 'package:gallery/src/widgets/search_bar/autocomplete/autocomplete_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../interfaces/cell.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import '../notifiers/focus.dart';
import '../skeletons/grid_skeleton_state_filter.dart';
import 'autocomplete/autocomplete_bar_decoration.dart';

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

  void performSearch(String s) {
    searchTextController.text = s;
    _key.currentState?.onChanged(s, true);
  }

  FilteringMode currentFilteringMode() {
    return _key.currentState!.currentFilterMode;
  }

  void setFilteringMode(FilteringMode f) {
    if (_state.filteringModes.contains(f)) {
      _key.currentState!.currentFilterMode = f;
    }
  }

  void setLocalTagCompleteF(Future<List<String>> Function(String string) f) {
    _key.currentState?.localTagCompleteFunc = f;
  }

  void markSearchVirtual() {
    _key.currentState?.searchVirtual = true;
  }

  void resetSearch() {
    _key.currentState!.reset(true);
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
