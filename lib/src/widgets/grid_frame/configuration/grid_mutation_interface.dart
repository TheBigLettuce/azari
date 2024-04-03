// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:async';

import '../../../interfaces/cell/cell.dart';

abstract class GridMutationInterface<T extends Cell> {
  int get cellCount;
  set cellCount(int c);

  bool get isRefreshing;
  set isRefreshing(bool b);

  StreamSubscription<void> registerStatusUpdate(void Function(void) f);

  void dispose();
  void reset();
}

class StaticNumberGridMutation<T extends Cell>
    implements GridMutationInterface<T> {
  const StaticNumberGridMutation(this.currentCount);

  final int Function() currentCount;

  @override
  int get cellCount => currentCount();

  @override
  bool get isRefreshing => false;

  @override
  void dispose() {}

  @override
  StreamSubscription<void> registerStatusUpdate(void Function(void p1) f) {
    throw UnimplementedError();
  }

  @override
  void reset() {}

  @override
  set cellCount(int c) {}

  @override
  set isRefreshing(bool b) {}
}
