// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/gesture_dead_zones.dart';

import '../../interfaces/booru.dart';
import '../../interfaces/cell.dart';
import '../grid/callback_grid.dart';
import 'grid_skeleton_state.dart';

Widget makeGridSkeleton<T extends Cell>(
    BuildContext context, GridSkeletonState<T> state, CallbackGrid<T> grid,
    {bool noDrawer = false,
    Booru? overrideBooru,
    required bool canPop,
    void Function(bool, bool Function())? overrideOnPop}) {
  return PopScope(
    canPop: canPop,
    onPopInvoked: overrideOnPop == null
        ? null
        : (pop) {
            overrideOnPop(pop, () {
              final s = state.gridKey.currentState;
              if (s != null) {
                if (s.showSearchBar) {
                  s.showSearchBar = false;
                  // ignore: invalid_use_of_protected_member
                  s.setState(() {});

                  return true;
                }
              }

              return false;
            });
          },
    child: gestureDeadZones(context, child: grid, left: true, right: true),
  );
}
