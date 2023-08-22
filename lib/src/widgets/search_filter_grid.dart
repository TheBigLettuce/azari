// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/booru/tags/tags.dart';
import 'package:gallery/src/widgets/booru/autocomplete_tag.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_launch_grid.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';

import '../cell/cell.dart';

/// Result of the filter to provide to the [GridMutationInterface].
class Result<T extends Cell> {
  final int count;
  final T Function(int i) cell;
  const Result(this.cell, this.count);
}

/// Filtering modes.
/// Implemented outside the [FilterInterface].
enum FilteringMode {
  /// Filter by the favorite.
  favorite("Favorite", Icons.star_border),

  /// Filter by the  "original" tag.
  original("Original", Icons.circle_outlined),

  /// Filter by filenames, which have (1).ext format.
  duplicate("Duplicate", Icons.mode_standby_outlined),

  /// Filter by similarity.
  same("Same", Icons.drag_handle),

  /// Filter by video.
  video("Video", Icons.play_circle),

  /// Filter by GIF.
  gif("GIF", Icons.gif_outlined),

  /// Filter by tag. Virtual.
  tag("Tag", Icons.tag),

  /// Filter by size, from bif to small.
  size("Size", Icons.arrow_downward),

  /// No filter.
  noFilter("No filter", Icons.filter_list_outlined),

  /// Filter by not tag not included.
  tagReversed("Tag reversed", Icons.label_off_outlined),

  /// Filter by no tags on image.
  untagged("Untagged", Icons.label_off);

  /// Name displayed in search bar.
  final String string;

  /// Icon displayed in search bar.
  final IconData icon;

  const FilteringMode(this.string, this.icon);
}

/// Sorting modes.
/// Implemented inside the [FilterInterface].
enum SortingMode { none, size }

abstract class FilterInterface<T extends Cell> {
  Result<T> filter(String s);
  void setSortingMode(SortingMode mode);
  void resetFilter();
}

class IsarFilter<T extends Cell> implements FilterInterface<T> {
  Isar _from;
  final Isar _to;
  bool isFiltering = false;
  final Iterable<T> Function(int offset, int limit, String s) getElems;
  (Iterable<T>, dynamic) Function(Iterable<T>, dynamic, bool)? passFilter;
  SortingMode currentSorting = SortingMode.none;

  Isar get to => _to;

  void setFrom(Isar from) {
    _from = from;
  }

  void dispose() {
    _to.close(deleteFromDisk: true);
  }

  void _writeFromTo(Isar from,
      Iterable<T> Function(int offset, int limit) getElems, Isar to) {
    from.writeTxnSync(() {
      var offset = 0;
      var loopCount = 0;
      dynamic data;

      for (;;) {
        loopCount++;

        var sorted = getElems(offset, 40);
        final end = sorted.length != 40;
        offset += 40;
        if (loopCount > 10000) {
          throw "infinite loop: $offset, last elems count: ${sorted.length}";
        }

        if (passFilter != null) {
          (sorted, data) = passFilter!(sorted, data, end);
        }
        for (var element in sorted) {
          element.isarId = null;
        }

        final l = <T>[];
        var count = 0;
        for (final elem in sorted) {
          count++;
          l.add(elem);
          if (count == 40) {
            _to.writeTxnSync(() => _to.collection<T>().putAllSync(l));
            l.clear();
            count = 0;
          }
        }

        if (l.isNotEmpty) {
          _to.writeTxnSync(() => _to.collection<T>().putAllSync(l));
        }

        if (end) {
          break;
        }
      }
    });
  }

  @override
  void setSortingMode(SortingMode sortingMode) {
    currentSorting = sortingMode;
  }

  @override
  Result<T> filter(String s) {
    isFiltering = true;
    _to.writeTxnSync(
      () => _to.collection<T>().clearSync(),
    );

    _writeFromTo(_from, (offset, limit) {
      return getElems(offset, limit, s);
    }, _to);

    return Result((i) => _to.collection<T>().getSync(i + 1)!,
        _to.collection<T>().countSync());
  }

  @override
  void resetFilter() {
    isFiltering = false;
    currentSorting = SortingMode.none;
    _to.writeTxnSync(() => _to.collection<T>().clearSync());
  }

  IsarFilter(Isar from, Isar to, this.getElems, {this.passFilter})
      : _from = from,
        _to = to;
}

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

  void markSearchVirtual() {
    _key.currentState?.searchVirtual = true;
  }

  void resetSearch() {
    _key.currentState!.reset();
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
  bool searchVirtual = false;
  FilteringMode currentFilterMode = FilteringMode.noFilter;
  void onChanged(String value, bool direct) {
    var interf = widget.instance._state.gridKey.currentState?.mutationInterface;
    if (interf != null) {
      final sorting = widget.instance._state.hook(currentFilterMode);
      // if (!direct) {
      //   value = value.trim();
      //   if (value.isEmpty) {
      //     interf.restore();
      //     widget.instance._state.filter.resetFilter();
      //     setState(() {});
      //     return;
      //   }
      // }

      widget.instance._state.filter.setSortingMode(sorting);

      var res =
          widget.instance._state.filter.filter(searchVirtual ? "" : value);

      interf.setSource(res.count, (i) {
        final cell = res.cell(i);
        return widget.instance._state.transform(cell, sorting);
      });
      setState(() {});
    }
  }

  List<Widget> _addItems() => [
        if (widget.instance._state.filteringModes.isNotEmpty)
          PopupMenuButton<FilteringMode>(
            itemBuilder: (context) {
              return widget.instance._state.filteringModes
                  .map((e) => PopupMenuItem(value: e, child: Text(e.string)))
                  .toList();
            },
            initialValue: currentFilterMode,
            onSelected: (value) {
              searchVirtual = false;
              currentFilterMode = value;
              onChanged(widget.instance.searchTextController.text, true);
            },
            icon: Icon(
              currentFilterMode.icon,
            ),
            padding: EdgeInsets.zero,
          ),
        if (widget.instance.addItems != null) ...widget.instance.addItems!
      ];

  String _makeHint(BuildContext context) =>
      "${AppLocalizations.of(context)!.filterHint}${widget.hint != null ? ' ${widget.hint}' : ''}";

  void reset() {
    widget.instance.searchTextController.clear();
    widget.instance._state.gridKey.currentState?.mutationInterface?.restore();
    if (widget.instance._state.filteringModes.isNotEmpty) {
      searchVirtual = false;
      currentFilterMode = FilteringMode.noFilter;
      onChanged(widget.instance.searchTextController.text, true);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return FocusNotifier(
        focusMain: widget.instance._state.mainFocus.requestFocus,
        notifier: widget.instance.searchFocus,
        child: Builder(
          builder: (context) => currentFilterMode == FilteringMode.tag ||
                  currentFilterMode == FilteringMode.tagReversed
              ? autocompleteWidget(
                  widget.instance.searchTextController,
                  (p0) {},
                  (p0) {},
                  () {
                    widget.instance._state.mainFocus.requestFocus();
                  },
                  PostTags().completeLocalTag,
                  widget.instance.searchFocus,
                  showSearch: true,
                  searchCount: widget.instance._state.gridKey.currentState
                      ?.mutationInterface?.cellCount,
                  addItems: _addItems(),
                  onChanged: () {
                    onChanged(widget.instance.searchTextController.text, true);
                  },
                  customHint: _makeHint(context),
                  noUnfocus: true,
                  scrollHack: _ScrollHack())
              : TextField(
                  focusNode: widget.instance.searchFocus,
                  controller: widget.instance.searchTextController,
                  decoration: autocompleteBarDecoration(
                      context, reset, _addItems(),
                      searchCount: widget.instance._state.gridKey.currentState
                          ?.mutationInterface?.cellCount,
                      showSearch: true,
                      roundBorders: false,
                      hint: _makeHint(context)),
                  onChanged: (s) => onChanged(s, false),
                ),
        ));
  }
}

class _ScrollHack extends ScrollController {
  @override
  bool get hasClients => false;
}
