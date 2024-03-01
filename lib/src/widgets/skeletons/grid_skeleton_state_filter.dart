// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import '../../interfaces/cell/cell.dart';
import '../../interfaces/filtering/filtering_interface.dart';
import '../../interfaces/filtering/filtering_mode.dart';
import 'grid_skeleton_state.dart';

class GridSkeletonStateFilter<T extends Cell> extends GridSkeletonState<T> {
  final FilterInterface<T> filter;
  final Set<FilteringMode> filteringModes;
  final bool unsetFilteringModeOnReset;
  final FilteringMode defaultMode;

  static SortingMode _doNothing(FilteringMode m) => SortingMode.none;

  final SortingMode Function(FilteringMode selected) hook;

  final T Function(T cell, SortingMode sort) transform;

  GridSkeletonStateFilter({
    required this.filter,
    required this.transform,
    this.filteringModes = const {},
    this.defaultMode = FilteringMode.noFilter,
    this.hook = _doNothing,
    this.unsetFilteringModeOnReset = true,
    super.initalCellCount = 0,
  });
}
