// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:isar/isar.dart';

import '../interfaces/cell/cell.dart';
import '../interfaces/filtering/filtering_interface.dart';
import '../interfaces/filtering/filtering_mode.dart';

class IsarFilter<T extends Cell> implements FilterInterface<T> {
  Isar _from;
  final Isar _to;
  bool isFiltering = false;
  final Iterable<T> Function(
          int offset, int limit, String s, SortingMode sort, FilteringMode mode)
      getElems;
  (Iterable<T>, dynamic) Function(Iterable<T>, dynamic, bool)? passFilter;
  SortingMode currentSorting = SortingMode.none;

  Isar get to => _to;

  @override
  SortingMode get currentSortingMode => currentSorting;

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
      dynamic data;

      for (;;) {
        var sorted = getElems(offset, 40);
        final end = sorted.length != 40;
        offset += 40;

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
  FilterResult<T> filter(String s, FilteringMode mode) {
    isFiltering = true;
    _to.writeTxnSync(
      () => _to.collection<T>().clearSync(),
    );

    _writeFromTo(_from, (offset, limit) {
      return getElems(offset, limit, s, currentSorting, mode);
    }, _to);

    return FilterResult((i) => _to.collection<T>().getSync(i + 1)!,
        _to.collection<T>().countSync());
  }

  // @override
  // void resetFilter() {
  //   isFiltering = false;
  //   currentSorting = SortingMode.none;
  //   _to.writeTxnSync(() => _to.collection<T>().clearSync());
  // }

  IsarFilter(Isar from, Isar to, this.getElems, {this.passFilter})
      : _from = from,
        _to = to;
}
