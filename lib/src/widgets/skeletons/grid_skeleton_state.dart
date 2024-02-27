// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/widgets.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';

import '../../db/schemas/settings/settings.dart';
import '../../interfaces/cell/cell.dart';
import '../grid/grid_frame.dart';
import 'skeleton_state.dart';

class GridSkeletonState<T extends Cell> extends SkeletonState {
  final GlobalKey<GridFrameState<T>> gridKey = GlobalKey();
  final GlobalKey<ImageViewState<T>> imageViewKey = GlobalKey();
  Settings settings = Settings.fromDb();
  final GridRefreshingStatus<T> refreshingStatus;

  // final Future<bool> Function() onWillPop;

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
