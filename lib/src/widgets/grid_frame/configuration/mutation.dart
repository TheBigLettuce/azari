// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of "../grid_frame.dart";

class DefaultMutationInterface implements GridMutationInterface {
  DefaultMutationInterface(this._cellCount);
  final _updatesCell = StreamController<int>.broadcast();
  final _updatesRefresh = StreamController<bool>.broadcast();

  int _cellCount = 0;
  bool _refreshing = false;

  @override
  int get cellCount => _cellCount;

  @override
  set cellCount(int c) {
    _cellCount = c;

    _updateCell();
  }

  @override
  bool get isRefreshing => _refreshing;

  @override
  set isRefreshing(bool b) {
    if (b == _refreshing) {
      return;
    }

    _refreshing = b;

    _updateRefresh();
  }

  @override
  void reset() {
    _cellCount = 0;
    _refreshing = false;

    _updateCell();
    _updateRefresh();
  }

  void _updateCell() {
    if (!_updatesCell.isClosed) {
      _updatesCell.add(_cellCount);
    }
  }

  void _updateRefresh() {
    if (!_updatesRefresh.isClosed) {
      _updatesRefresh.add(_refreshing);
    }
  }

  @override
  StreamSubscription<int> listenCount(void Function(int) f) {
    return _updatesCell.stream.listen(f);
  }

  @override
  StreamSubscription<bool> listenRefresh(void Function(bool) f) {
    return _updatesRefresh.stream.listen(f);
  }

  @override
  void dispose() {
    _updatesCell.close();
    _updatesRefresh.close();
  }
}
