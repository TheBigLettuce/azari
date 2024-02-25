// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/grid_layouter.dart';
import 'package:gallery/src/interfaces/grid/grid_aspect_ratio.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/grid/grid_mutation_interface.dart';
import 'package:gallery/src/widgets/grid/grid_cell.dart';

import '../grid_frame.dart';

class GridLayout<T extends Cell> implements GridLayouter<T> {
  final GridAspectRatio aspectRatio;

  @override
  final GridColumn columns;

  @override
  List<Widget> call(BuildContext context, GridFrameState<T> state) {
    return [
      blueprint<T>(
        context,
        state.mutation,
        state.selection,
        systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
        aspectRatio: aspectRatio.value,
        columns: columns.number,
        gridCell: (context, idx) {
          return GridCell.frameDefault(
            context,
            idx,
            state: state,
          );
        },
      )
    ];
  }

  static Widget blueprint<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection, {
    required int columns,
    required MakeCellFunc<T> gridCell,
    required double systemNavigationInsets,
    required double aspectRatio,
  }) {
    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: aspectRatio, crossAxisCount: columns),
      itemCount: state.cellCount,
      itemBuilder: (context, indx) {
        return WrapSelection(
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
        );
      },
    );
  }

  @override
  bool get isList => false;

  const GridLayout(this.columns, this.aspectRatio);
}
