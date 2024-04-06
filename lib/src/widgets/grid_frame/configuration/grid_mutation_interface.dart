// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

extension GridMutationInterfaceTricks on GridMutationInterface {
  /// Setting cellCount to itself triggers event on listenCount;
  void notify() {
    cellCount = cellCount;
  }
}

abstract class GridMutationInterface {
  int get cellCount;
  set cellCount(int c);

  bool get isRefreshing;
  set isRefreshing(bool b);

  StreamSubscription<int> listenCount(void Function(int) f);
  StreamSubscription<bool> listenRefresh(void Function(bool) f);

  void dispose();
  void reset();
}

class StaticNumberGridMutation implements GridMutationInterface {
  const StaticNumberGridMutation(this.currentCount);

  final int Function() currentCount;

  @override
  int get cellCount => currentCount();

  @override
  bool get isRefreshing => false;

  @override
  void dispose() {}

  @override
  void reset() {}

  @override
  set cellCount(int c) {}

  @override
  set isRefreshing(bool b) {}

  @override
  StreamSubscription<int> listenCount(void Function(int p1) f) {
    throw UnimplementedError();
  }

  @override
  StreamSubscription<bool> listenRefresh(void Function(bool p1) f) {
    throw UnimplementedError();
  }
}
