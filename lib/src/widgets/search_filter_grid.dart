// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/booru/autocomplete_tag.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_launch_grid.dart';
import 'package:isar/isar.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../cell/cell.dart';

import '../gallery/interface.dart';

enum FilteringMode {
  original("Original", Icons.circle_outlined),
  duplicate("Duplicate", Icons.mode_standby_outlined),
  video("Video", Icons.play_circle),
  gif("GIF", Icons.gif_outlined),
  noFilter("No filter", Icons.filter_list_outlined);

  final String string;
  final IconData icon;

  const FilteringMode(this.string, this.icon);
}

abstract class FilterInterface<T extends Cell<B>, B> {
  Result<T> filter(String s);
  void resetFilter();
}

class IsarFilter<T extends Cell<B>, B> implements FilterInterface<T, B> {
  Isar _from;
  final Isar _to;
  bool isFiltering = false;
  final List<T> Function(int offset, int limit, String s) getElems;
  List<T> Function(List<T>)? passFilter;

  Isar get to => _to;

  void setFrom(Isar from) {
    _from = from;
  }

  void dispose() {
    _to.close(deleteFromDisk: true);
  }

  void _writeFromTo(
      Isar from, List<T> Function(int offset, int limit) getElems, Isar to) {
    from.writeTxnSync(() {
      var offset = 0;
      var loopCount = 0;

      for (;;) {
        loopCount++;

        var sorted = getElems(offset, 40);
        final end = sorted.length != 40;
        offset += 40;
        if (loopCount > 1000) {
          throw "infinite loop: $offset, last elems count: ${sorted.length}";
        }

        if (passFilter != null) {
          sorted = passFilter!(sorted);
        }
        for (var element in sorted) {
          element.isarId = null;
        }

        to.writeTxnSync(() => to.collection<T>().putAllSync(sorted));

        if (end) {
          break;
        }
      }
    });
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
    _to.writeTxnSync(() => _to.collection<T>().clearSync());
  }

  IsarFilter(Isar from, Isar to, this.getElems, {this.passFilter})
      : _from = from,
        _to = to;
}

mixin SearchFilterGrid<T extends Cell<B>, B>
    implements SearchMixin<GridSkeletonStateFilter<T, B>> {
  @override
  final TextEditingController searchTextController = TextEditingController();
  @override
  final FocusNode searchFocus = FocusNode();

  late final List<Widget>? addItems;
  final GlobalKey<__SearchWidgetState> _key = GlobalKey();

  late final GridSkeletonStateFilter<T, B> _state;

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

  @override
  Widget searchWidget(BuildContext context, {String? hint, int? count}) =>
      _SearchWidget(
        key: _key,
        instance: this,
        hint: hint,
        count: count,
      );
}

class _SearchWidget extends StatefulWidget {
  final SearchFilterGrid instance;
  final String? hint;
  final int? count;
  const _SearchWidget(
      {super.key,
      required this.instance,
      required this.count,
      required this.hint});

  @override
  State<_SearchWidget> createState() => __SearchWidgetState();
}

class __SearchWidgetState extends State<_SearchWidget> {
  FilteringMode currentFilterMode = FilteringMode.noFilter;
  void onChanged(String value, bool direct) {
    var interf = widget.instance._state.gridKey.currentState?.mutationInterface;
    if (interf != null) {
      if (!direct) {
        value = value.trim();
        if (value.isEmpty) {
          interf.restore();
          widget.instance._state.filter.resetFilter();
          setState(() {});
          return;
        }
      }

      var res = widget.instance._state.filter.filter(value);

      interf.setSource(res.count, res.cell);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusNotifier(
        focusMain: widget.instance._state.mainFocus.requestFocus,
        notifier: widget.instance.searchFocus,
        child: Builder(
          builder: (context) => TextField(
            focusNode: widget.instance.searchFocus,
            controller: widget.instance.searchTextController,
            decoration: autocompleteBarDecoration(context, () {
              widget.instance.searchTextController.clear();
              widget.instance._state.gridKey.currentState?.mutationInterface
                  ?.restore();
              if (widget.instance._state.filteringModes.isNotEmpty) {
                onChanged(widget.instance.searchTextController.text, true);
              }
              setState(() {});
            }, [
              if (widget.instance._state.filteringModes.isNotEmpty)
                PopupMenuButton<FilteringMode>(
                  itemBuilder: (context) {
                    return widget.instance._state.filteringModes
                        .map((e) =>
                            PopupMenuItem(value: e, child: Text(e.string)))
                        .toList();
                  },
                  initialValue: currentFilterMode,
                  onSelected: (value) {
                    currentFilterMode = value;
                    onChanged(widget.instance.searchTextController.text, true);
                    widget.instance._state.hook(value);
                  },
                  icon: Icon(
                    currentFilterMode.icon,
                  ),
                  padding: EdgeInsets.zero,
                ),
              if (widget.instance.addItems != null) ...widget.instance.addItems!
            ],
                searchCount: widget.instance._state.gridKey.currentState
                    ?.mutationInterface?.cellCount,
                showSearch: true,
                roundBorders: false,
                hint:
                    "${AppLocalizations.of(context)!.filterHint}${widget.hint != null ? ' ${widget.hint}' : ''}"),
            onChanged: (s) => onChanged(s, false),
          ),
        ));
  }
}
