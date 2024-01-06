// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

part of 'cell_loader.dart';

// class BasicCellDataTransformer<T extends Cell, I>
//     implements DataTransformer<T, int> {
//   final void Function() notifyChange;
//   final T Function(BasicCellDataTransformer<T, I>, T) _transformCell;
//   final int Function(BasicCellDataTransformer<T, I>) _count;

//   final FilteringMode _defaultFilteringMode;
//   final SortingMode _defaultSortingMode;

//   @override
//   SortingMode currentSoring;

//   @override
//   FilteringMode currentFiltering;

//   @override
//   final Set<FilteringMode> capabilityFiltering;

//   @override
//   final Set<SortingMode> capabilitySorting;

//   BasicCellDataTransformer(this._transformCell, this._count,
//       this._defaultFilteringMode, this._defaultSortingMode,

//       {this.currentFiltering = FilteringMode.noFilter,
//       zzzzthis.notifyChange,
//       this.currentSoring = SortingMode.none,
//       Set<FilteringMode> addFilteringModes = const {},
//       Set<SortingMode> addSortingModes = const {}})
//       : capabilityFiltering = {...addFilteringModes, FilteringMode.noFilter},
//         capabilitySorting = {...addSortingModes, SortingMode.none};

//   @override
//   void reset() {
//     currentFiltering = _defaultFilteringMode;
//     currentSoring = _defaultSortingMode;

//     _notifyChange();
//   }

//   @override
//   void setFilteringMode(FilteringMode filtering) {
//     if (currentFiltering == filtering) {
//       return;
//     }
//     currentFiltering = filtering;

//     _notifyChange();
//   }

//   @override
//   void setSortingMode(SortingMode sorting) {
//     if (currentSoring == sorting) {
//       return;
//     }
//     currentSoring = sorting;

//     _notifyChange();
//   }

//   @override
//   T transformCell(T elem) => _transformCell(this, elem);

//   @override
//   void transformStatusCallback(void Function(int count) f) {
//     f(_count(this));
//   }
// }

class CellDataTransformer<T extends Cell> implements DataTransformer<T> {
  final void Function(ControlMessage) _send;
  final T Function(CellDataTransformer<T>, T) _transformCell;
  final int Function(CellDataTransformer<T>) _count;

  final FilteringMode _defaultFilteringMode;
  final SortingMode _defaultSortingMode;

  @override
  SortingMode currentSoring;

  @override
  FilteringMode currentFiltering;

  @override
  final Set<FilteringMode> capabilityFiltering;

  @override
  final Set<SortingMode> capabilitySorting;

  void _notifyChange() {
    _send(const Poll());
  }

  CellDataTransformer(BackgroundDataLoader<T> loader, this._transformCell,
      this._count, this._defaultFilteringMode, this._defaultSortingMode,
      {this.currentFiltering = FilteringMode.noFilter,
      this.currentSoring = SortingMode.none,
      Set<FilteringMode> addFilteringModes = const {},
      Set<SortingMode> addSortingModes = const {}})
      : capabilityFiltering = {...addFilteringModes, FilteringMode.noFilter},
        capabilitySorting = {...addSortingModes, SortingMode.none},
        _send = loader.send;

  @override
  void reset() {
    currentFiltering = _defaultFilteringMode;
    currentSoring = _defaultSortingMode;

    _notifyChange();
  }

  @override
  void setFilteringMode(FilteringMode filtering) {
    if (currentFiltering == filtering) {
      return;
    }
    currentFiltering = filtering;

    _notifyChange();
  }

  @override
  void setSortingMode(SortingMode sorting) {
    if (currentSoring == sorting) {
      return;
    }
    currentSoring = sorting;

    _notifyChange();
  }

  @override
  T transformCell(T elem) => _transformCell(this, elem);

  @override
  void transformStatusCallback(void Function(int count) f) {
    f(_count(this));
  }
}
