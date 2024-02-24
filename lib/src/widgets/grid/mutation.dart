// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'grid_frame.dart';

class DefaultMutationInterface<T extends Cell>
    implements GridMutationInterface<T> {
  DefaultMutationInterface({
    required this.update,
    required this.originalCell,
    int initalCellCount = 0,
  }) : _cellCount = initalCellCount;

  final void Function({
    required bool imageView,
    required bool unselectAll,
  }) update;

  final T Function(int i) originalCell;

  T Function(int i)? _filterGetCell;

  int? _cellCountFilter;

  int _cellCount = 0;
  bool _refreshing = false;

  @override
  int get cellCount => _cellCountFilter ?? _cellCount;

  @override
  set cellCount(int c) {
    if (_filterGetCell != null) {
      _cellCountFilter = c;
    } else {
      _cellCount = c;
    }

    update(imageView: false, unselectAll: false);
  }

  @override
  bool get isRefreshing => _refreshing;

  @override
  set isRefreshing(bool b) {
    _refreshing = b;

    update(imageView: false, unselectAll: false);
  }

  @override
  bool get mutated => _filterGetCell != null;

  @override
  void reset() {
    _cellCountFilter = null;
    _filterGetCell = null;

    update(imageView: true, unselectAll: false);
  }

  @override
  T getCell(int i) {
    if (_filterGetCell != null) {
      return _filterGetCell!(i);
    }

    return originalCell(i);
  }

  @override
  void setSource(int cellCount, T Function(int i) getCell) {
    _filterGetCell = getCell;
    _cellCountFilter = cellCount;

    update(imageView: true, unselectAll: true);
  }
}
