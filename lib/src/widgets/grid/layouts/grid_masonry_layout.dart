// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/grid_layouter.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/grid/grid_mutation_interface.dart';
import 'package:gallery/src/widgets/grid/grid_cell.dart';

import '../grid_frame.dart';

class GridMasonryLayout<T extends Cell> implements GridLayouter<T> {
  final GridAspectRatio aspectRatio;

  final int gridSeed;

  @override
  final GridColumn columns;

  @override
  List<Widget> call(BuildContext context, GridFrameState<T> state) {
    return [
      blueprint<T>(
        context,
        state.mutation,
        state.selection,
        columns: columns.number,
        gridCell: (context, idx) => GridCell.frameDefault(
          context,
          idx,
          state: state,
        ),
        systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
        aspectRatio: aspectRatio.value,
        randomNumber: gridSeed,
      )
    ];
  }

  static Widget blueprint<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection, {
    required MakeCellFunc<T> gridCell,
    required double systemNavigationInsets,
    required double aspectRatio,
    required int randomNumber,
    required int columns,
  }) {
    final size = (MediaQuery.sizeOf(context).shortestSide * 0.95) / columns;

    return SliverMasonryGrid(
      mainAxisSpacing: 0,
      crossAxisSpacing: 0,
      delegate: SliverChildBuilderDelegate(childCount: state.cellCount,
          (context, indx) {
        // final cell = state.getCell(indx);

        // final n1 = switch (columns) {
        //   2 => 4,
        //   3 => 3,
        //   4 => 3,
        //   5 => 3,
        //   6 => 3,
        //   int() => 4,
        // };

        // final n2 = switch (columns) {
        //   2 => 40,
        //   3 => 40,
        //   4 => 30,
        //   5 => 30,
        //   6 => 20,
        //   int() => 40,
        // };

        // final int i = ((randomNumber + indx) % 5 + n1) * n2;

        final rem = ((randomNumber + indx) % 11) * 0.5;

        return ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: (size / aspectRatio) +
                  (rem * (size * (0.037 + (columns / 100) - rem * 0.01)))
                      .toInt()),
          child: WrapSelection(
            actionsAreEmpty: selection.addActions.isEmpty,
            selectionEnabled: selection.isNotEmpty,
            thisIndx: indx,
            ignoreSwipeGesture: selection.ignoreSwipe,
            bottomPadding: systemNavigationInsets,
            currentScroll: selection.controller,
            selectUntil: (i) => selection.selectUnselectUntil(i, state),
            selectUnselect: () => selection.selectOrUnselect(context, indx),
            isSelected: selection.isSelected(indx),
            child: gridCell(context, indx),
          ),
        );
      }),
      gridDelegate: SliverSimpleGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns),
    );
  }

  @override
  bool get isList => false;

  const GridMasonryLayout(
    this.columns,
    this.aspectRatio, {
    required this.gridSeed,
  });
}
