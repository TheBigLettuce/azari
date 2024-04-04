// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/widgets/notifiers/glue_provider.dart';
import 'package:gallery/src/widgets/skeletons/skeleton_state.dart';

import '../../interfaces/cell/cell.dart';
import '../grid_frame/grid_frame.dart';

class GridSkeleton<T extends CellBase> extends StatelessWidget {
  final bool canPop;
  final void Function(bool)? onPop;
  final GridSkeletonState<T> state;
  final GridFrame<T> Function(BuildContext context) grid;
  final void Function()? secondarySelectionHide;

  const GridSkeleton(
    this.state,
    this.grid, {
    super.key,
    required this.canPop,
    this.secondarySelectionHide,
    this.onPop,
  });

  @override
  Widget build(BuildContext context) {
    final glue = GlueProvider.generateOf(context)();

    return PopScope(
      canPop: canPop && !glue.isOpen(),
      onPopInvoked: (pop) {
        if (glue.isOpen()) {
          state.gridKey.currentState?.selection.reset();
          secondarySelectionHide?.call();
          return;
        }

        onPop?.call(pop);
      },
      child: grid(context),
    );
  }
}
