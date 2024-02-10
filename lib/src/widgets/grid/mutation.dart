// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'grid_frame.dart';

class _Mutation<T extends Cell> implements GridMutationInterface<T> {
  final void Function() scrollUp;
  final void Function() unselectall;
  final void Function() updateImageView;
  final void Function(void Function()? f) update;
  final GridFrame<T> Function() widget;
  final void Function(Future<int>)? saveStatus;

  T Function(int i)? _filterGetCell;

  int? _cellCountFilter;

  @override
  void unselectAll() => unselectall();

  Object? refreshingError;

  int _cellCount = 0;
  bool _refreshing = false;
  bool _locked = false;

  @override
  bool get mutated => _filterGetCell != null;

  @override
  void restore() {
    _cellCountFilter = null;
    _filterGetCell = null;
    _locked = false;

    updateImageView();
    update(null);
  }

  @override
  void tick(int i) {
    if (_filterGetCell != null) {
      _cellCountFilter = i;
    } else {
      _cellCount = i;
    }

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
  void setIsRefreshing(bool isRefreshing) {
    _refreshing = isRefreshing;

    update(null);
  }

  @override
  bool get isRefreshing => _refreshing;

  @override
  void setSource(int cellCount, T Function(int i) getCell) {
    _filterGetCell = getCell;
    _cellCountFilter = cellCount;

    unselectAll();

    updateImageView();

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
      final f = widget().loadNext!();
      _refreshing = true;

      update(null);

      if (saveStatus != null) {
        saveStatus!(f);
        return _cellCount;
      }

      _cellCount = await f;

      updateImageView();

      update(null);
    } catch (e) {
      refreshingError = e;

      update(null);
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
      refreshingError = null;

      update(null);

      _refresh();
    }
  }

  @override
  Future onRefresh() {
    if (_locked) {
      return Future.value();
    }

    if (!_refreshing) {
      _cellCount = 0;
      _refreshing = true;
      refreshingError = null;

      update(null);

      return _refresh();
    }

    return Future.value();
  }

  void _loadNext(BuildContext context) {
    if (_locked) {
      return;
    }

    _refreshing = true;
    refreshingError = null;

    update(null);

    final f = widget().loadNext!();

    if (saveStatus != null) {
      saveStatus!(f);
      return;
    }

    f.then((value) {
      _cellCount = value;
      _refreshing = false;

      update(null);
    }).onError((error, stackTrace) {
      refreshingError = error;

      update(null);

      log("loading next cells in the grid",
          level: Level.WARNING.value, error: error, stackTrace: stackTrace);
    });
  }

  Future _refresh([Future<int> Function()? overrideRefresh]) async {
    if (_locked) {
      return Future.value(_cellCount);
    }

    final valueFuture =
        overrideRefresh != null ? overrideRefresh() : widget().refresh();

    if (valueFuture == null) {
      return Future.value();
    }

    _refreshing = true;
    refreshingError = null;

    if (saveStatus != null) {
      saveStatus!(valueFuture);
      return;
    }

    try {
      _refreshing = true;
      final value = await valueFuture;

      _cellCount = value;
      _refreshing = false;

      updateImageView();

      update(() {
        widget().updateScrollPosition?.call(0);
      });
    } catch (e, stackTrace) {
      refreshingError = e;

      _refreshing = false;

      update(null);

      log("refreshing cells in the grid",
          level: Level.WARNING.value, error: e, stackTrace: stackTrace);
    }

    return;
  }

  _Mutation(
      {required this.widget,
      required this.update,
      required this.saveStatus,
      required this.updateImageView,
      required this.unselectall,
      required this.scrollUp});
}
