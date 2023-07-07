// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'callback_grid.dart';

abstract class GridMutationInterface<T extends Cell<B>, B> {
  int get cellCount;
  // set cellCount(int i);
  bool get isRefreshing;

  void setSource(int cellCount, T Function(int i) getCell);
  void tick(int i);
  void restore();
  T getCell(int i);
}

class _Mutation<T extends Cell<B>, B> implements GridMutationInterface<T, B> {
  int? _cellCountFilter;
  T Function(int i)? _filterGetCell;
  final void Function() scrollUp;

  bool cloudflareBlocked = false;

  int _cellCount = 0;
  bool _refreshing = false;
  bool _locked = false;

  @override
  void restore() {
    _cellCountFilter = null;
    _filterGetCell = null;
    _locked = false;

    update(null);
  }

  @override
  void tick(int i) {
    _cellCountFilter = i;

    update(null);
  }

  @override
  int get cellCount => _cellCountFilter ?? _cellCount;

  @override
  T getCell(int i) {
    if (_filterGetCell != null) {
      return _filterGetCell!(i);
    }

    return widget().getCell(i);
  }

  @override
  bool get isRefreshing => _refreshing;

  @override
  void setSource(int cellCount, T Function(int i) getCell) {
    _filterGetCell = getCell;
    _cellCountFilter = cellCount;

    update(null);
  }

  Future<int> _onNearEnd() async {
    if (_locked) {
      return Future.value(_cellCount);
    }

    if (_refreshing) {
      return Future.value(_cellCount);
    }

    try {
      _cellCount = await widget().loadNext!();

      update(null);
    } catch (e) {
      if (e is CloudflareException) {
        cloudflareBlocked = true;

        update(null);
      }
    }

    return _cellCount;
  }

  void _f5() {
    if (_locked) {
      return;
    }

    if (!_refreshing) {
      scrollUp();

      _cellCount = 0;
      _refreshing = true;

      update(null);

      _refresh();
    }
  }

  Future _onRefresh() {
    if (_locked) {
      return Future.value();
    }

    if (!_refreshing) {
      _cellCount = 0;
      _refreshing = true;

      update(null);

      return _refresh();
    }

    return Future.value();
  }

  void _loadNext() {
    if (_locked) {
      return;
    }

    _refreshing = true;
    update(null);

    widget().loadNext!().then((value) {
      _cellCount = value;
      _refreshing = false;

      update(null);
    }).onError((error, stackTrace) {
      if (error is CloudflareException) {
        cloudflareBlocked = true;

        update(null);
      }
      log("loading next cells in the grid",
          level: Level.WARNING.value, error: error, stackTrace: stackTrace);
    });
  }

  Future _refresh() async {
    if (_locked) {
      return Future.value(_cellCount);
    }

    _refreshing = true;

    try {
      var value = await widget().refresh();
      _cellCount = value;
      _refreshing = false;

      update(() {
        widget().updateScrollPosition(0);
      });
    } catch (e, stackTrace) {
      if (e is CloudflareException) {
        cloudflareBlocked = true;
      }

      _refreshing = false;

      update(null);

      log("refreshing cells in the grid",
          level: Level.WARNING.value, error: e, stackTrace: stackTrace);
    }

    return;
  }

  final CallbackGrid<T, B> Function() widget;
  final void Function(void Function()? f) update;

  _Mutation(
      {required bool immutable,
      required this.widget,
      required this.update,
      required this.scrollUp});
}
