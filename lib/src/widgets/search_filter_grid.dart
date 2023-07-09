// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/booru/autocomplete_tag.dart';
import 'package:gallery/src/widgets/grid/callback_grid.dart';
import 'package:gallery/src/widgets/make_skeleton.dart';
import 'package:gallery/src/widgets/search_launch_grid.dart';
import 'package:isar/isar.dart';

import '../cell/cell.dart';
import '../gallery/interface.dart';

void isarFilterFunc<T extends Cell<B>, B>(String value,
    GridMutationInterface<T, B>? interf, IsarFilter<T, B> filter) {
  if (interf != null) {
    value = value.trim();
    if (value.isEmpty) {
      interf.restore();
      filter.resetFilter();
      return;
    }

    var res = filter.filter(value);

    interf.setSource(res.count, res.cell);
  }
}

class IsarFilter<T extends Cell<B>, B> {
  final Isar _from;
  final Isar _to;
  bool isFiltering = false;
  final List<T> Function(int offset, int limit, String s) getElems;

  Isar get to => _to;

  void dispose() {
    _to.close(deleteFromDisk: true);
  }

  void _writeFromTo(
      Isar from, List<T> Function(int offset, int limit) getElems, Isar to) {
    from.writeTxnSync(() {
      var offset = 0;

      for (;;) {
        var sorted = getElems(offset, 40);
        offset += 40;

        for (var element in sorted) {
          element.isarId = null;
        }

        to.writeTxnSync(() => to.collection<T>().putAllSync(sorted));

        if (sorted.length != 40) {
          break;
        }
      }
    });
  }

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

  void resetFilter() {
    isFiltering = false;
    _to.writeTxnSync(() => _to.collection<T>().clearSync());
  }

  IsarFilter(Isar from, Isar to, this.getElems)
      : _from = from,
        _to = to;
}

mixin SearchFilterGrid<T extends Cell<B>, B>
    implements SearchMixin<GridSkeletonStateFilter<T, B>> {
  @override
  final TextEditingController searchTextController = TextEditingController();
  @override
  final FocusNode searchFocus = FocusNode();

  late final void Function() _focusMain;
  late final void Function(String s) _onChanged;
  late final GlobalKey<CallbackGridState<T, B>> _gridKey;

  late final List<Widget>? addItems;
  late final String? addHint;

  @override
  void searchHook(state, [String? hint, List<Widget>? items]) {
    addHint = hint;
    addItems = items;
    _focusMain = () => state.mainFocus.requestFocus();
    _gridKey = state.gridKey;
    _onChanged = state.filterFunc;
  }

  @override
  void disposeSearch() {
    searchTextController.dispose();
    searchFocus.dispose();
  }

  @override
  Widget searchWidget(BuildContext context) => FocusNotifier(
      focusMain: _focusMain,
      notifier: searchFocus,
      child: Builder(
        builder: (context) => TextField(
          focusNode: searchFocus,
          controller: searchTextController,
          decoration: autocompleteBarDecoration(context, () {
            searchTextController.clear();
            _gridKey.currentState?.mutationInterface?.restore();
          }, addItems,
              showSearch: true,
              roundBorders: false,
              hint:
                  "Filter${addHint != null ? ' $addHint' : ''}"), // TODO: change
          onChanged: _onChanged,
        ),
      ));
}



// mixin SearchFilterGridDirectory on State<ServerDirectories>
//     implements SearchMixin<GridSkeletonState<Directory, Directory>> {
//   @override
//   final TextEditingController searchTextController = TextEditingController();
//   @override
//   final FocusNode searchFocus = FocusNode();

//   final api = ServerAPI(db.openServerApiIsar());

//   List<Directory>? filterResults;

//   late final void Function() focusMain;


//   late final GlobalKey<CallbackGridState<Directory, Directory>> gridKey;

//   @override
//   void searchHook(state) {
//     focusMain = () => state.mainFocus.requestFocus();
//     gridKey = state.gridKey;
//   }

//   @override
//   void disposeSearch() {
//     searchTextController.dispose();
//     searchFocus.dispose();
//   }

//   @override
//   Widget searchWidget(BuildContext context) => FocusNotifier(
//       focusMain: focusMain,
//       notifier: searchFocus,
//       child: Builder(
//         builder: (context) => TextField(
//           focusNode: searchFocus,
//           controller: searchTextController,
//           decoration: autocompleteBarDecoration(context, () {
//             searchTextController.clear();
//             gridKey.currentState?.mutationInterface?.restore();
//           }, null,
//               showSearch: true,
//               roundBorders: false,
//               hint: "Filter"), // TODO: change
//           onChanged: (value) {
//             var interface = gridKey.currentState?.mutationInterface;
//             if (interface != null) {
//               value = value.trim();
//               if (value.isEmpty) {
//                 interface.restore();
//                 filterResults = null;
//                 return;
//               }

//               filterResults = api.serverIsar.directorys
//                   .filter()
//                   .dirNameContains(value, caseSensitive: false)
//                   .findAllSync();

//               interface.setSource(filterResults!.length, (i) {
//                 return filterResults![i];
//               });
//             }
//           },
//         ),
//       ));
// }
