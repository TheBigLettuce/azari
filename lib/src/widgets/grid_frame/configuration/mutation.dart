// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of '../grid_frame.dart';

class DefaultMutationInterface implements GridMutationInterface {
  DefaultMutationInterface(this._cellCount);
  final _updates = StreamController<void>.broadcast();

  int _cellCount = 0;
  bool _refreshing = false;

  @override
  int get cellCount => _cellCount;

  @override
  set cellCount(int c) {
    _cellCount = c;

    _update();
  }

  @override
  bool get isRefreshing => _refreshing;

  @override
  set isRefreshing(bool b) {
    _refreshing = b;

    _update();
  }

  @override
  void reset() {
    cellCount = 0;
    isRefreshing = false;

    _update();
  }

  void _update() {
    if (!_updates.isClosed) {
      _updates.add(null);
    }
  }

  @override
  StreamSubscription<void> registerStatusUpdate(void Function(void) f) {
    return _updates.stream.listen(f);
  }

  @override
  void dispose() {
    _updates.close();
  }
}
