// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_refreshing_status.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";

class SkeletonState {
  SkeletonState();
  final FocusNode mainFocus = FocusNode();
  final gridSeed = math.Random().nextInt(948512342);

  void dispose() {
    mainFocus.dispose();
  }
}

class GridSkeletonRefreshingState<T extends CellBase>
    extends GridSkeletonState<T> {
  GridSkeletonRefreshingState({
    int initalCellCount = 0,
    bool Function() reachedEnd = _alwaysTrue,
    required GridRefreshType clearRefresh,
    Future<int> Function()? next,
    GridRefreshingStatus<T>? overrideRefreshStatus,
  }) : refreshingStatus = overrideRefreshStatus ??
            GridRefreshingStatus<T>(
              initalCellCount,
              reachedEnd,
              clearRefresh: clearRefresh,
              next: next,
            );
  final GridRefreshingStatus<T> refreshingStatus;

  @override
  void dispose() {
    super.dispose();
    refreshingStatus.dispose();
  }

  static bool _alwaysTrue() => true;
}

class GridSkeletonState<T extends CellBase> extends SkeletonState {
  GridSkeletonState();

  final GlobalKey<GridFrameState<T>> gridKey = GlobalKey();
  SettingsData settings = SettingsService.db().current;
}

// class GridSkeletonStateFilter<T extends CellBase>
//     extends GridSkeletonRefreshingState<T> {
//   GridSkeletonStateFilter({
//     required this.filter,
//     required this.transform,
//     this.hook = _doNothing,
//     this.filteringModes = const {},
//     this.sortingModes = const {},
//     this.defaultMode = FilteringMode.noFilter,
//     this.unsetFilteringModeOnReset = true,
//     super.initalCellCount = 0,
//     required super.clearRefresh,
//     super.next,
//   });
//   final FilterInterface<T> filter;
//   final Set<FilteringMode> filteringModes;
//   final Set<SortingMode> sortingModes;
//   final bool unsetFilteringModeOnReset;
//   final FilteringMode defaultMode;
//   final void Function(FilteringMode selected) hook;
//   final T Function(T cell) transform;

//   static void _doNothing(FilteringMode m) {}
// }
