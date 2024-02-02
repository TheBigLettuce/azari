// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/booru/booru.dart';
import 'package:gallery/src/widgets/gesture_dead_zones.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';

import '../../interfaces/cell/cell.dart';
import '../grid/callback_grid.dart';
import 'grid_skeleton_state.dart';

class GridSkeleton<T extends Cell> extends StatelessWidget {
  final bool noDrawer;
  final Booru? overrideBooru;
  final bool canPop;
  final void Function(bool, bool Function())? overrideOnPop;
  final GridSkeletonState<T> state;
  final CallbackGrid<T> Function(BuildContext context) grid;

  const GridSkeleton(
    this.state,
    this.grid, {
    super.key,
    this.noDrawer = false,
    this.overrideBooru,
    required this.canPop,
    this.overrideOnPop,
  });

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: canPop && !GlueProvider.of<T>(context).isOpen(),
      onPopInvoked: overrideOnPop == null
          ? null
          : (pop) {
              if (GlueProvider.of<T>(context).isOpen()) {
                state.gridKey.currentState?.selection.reset();
                return;
              }

              overrideOnPop!(pop, () {
                final s = state.gridKey.currentState;
                if (s != null) {
                  // if (s.showSearchBar) {
                  //   s.showSearchBar = false;
                  //   // ignore: invalid_use_of_protected_member
                  //   s.setState(() {});

                  //   return true;
                  // }
                }

                return false;
              });
            },
      child: GestureDeadZones(
        left: true,
        right: true,
        child: grid(context),
      ),
    );
  }
}
