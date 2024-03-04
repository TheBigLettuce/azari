// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/schemas/settings/settings.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/filtering/filtering_interface.dart';
import 'package:gallery/src/interfaces/filtering/filtering_mode.dart';
import 'dart:math' as math;

import 'package:gallery/src/widgets/grid_frame/configuration/grid_refreshing_status.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';

class SkeletonState {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
  final FocusNode mainFocus = FocusNode();
  final gridSeed = math.Random().nextInt(948512342);

  void dispose() {
    mainFocus.dispose();
  }

  SkeletonState();
}

class GridSkeletonState<T extends Cell> extends SkeletonState {
  final GlobalKey<GridFrameState<T>> gridKey = GlobalKey();
  final GlobalKey<ImageViewState<T>> imageViewKey = GlobalKey();
  Settings settings = Settings.fromDb();
  final GridRefreshingStatus<T> refreshingStatus;

  @override
  void dispose() {
    super.dispose();
    refreshingStatus.dispose();
  }

  static bool _alwaysTrue() => true;

  GridSkeletonState({
    int initalCellCount = 0,
    bool Function() reachedEnd = _alwaysTrue,
    GridRefreshingStatus<T>? overrideRefreshStatus,
  }) : refreshingStatus = overrideRefreshStatus ??
            GridRefreshingStatus<T>(initalCellCount, reachedEnd);
}

class GridSkeletonStateFilter<T extends Cell> extends GridSkeletonState<T> {
  final FilterInterface<T> filter;
  final Set<FilteringMode> filteringModes;
  final Set<SortingMode> sortingModes;
  final bool unsetFilteringModeOnReset;
  final FilteringMode defaultMode;
  final void Function(FilteringMode selected) hook;
  final T Function(T cell) transform;

  static void _doNothing(FilteringMode m) {}

  GridSkeletonStateFilter({
    required this.filter,
    required this.transform,
    this.hook = _doNothing,
    this.filteringModes = const {},
    this.sortingModes = const {},
    this.defaultMode = FilteringMode.noFilter,
    this.unsetFilteringModeOnReset = true,
    super.initalCellCount = 0,
  });
}
