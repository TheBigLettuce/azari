// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart';
import 'package:gallery/src/widgets/grid_frame/parts/grid_cell.dart';

import '../grid_frame.dart';

class GridLayout<T extends CellBase> implements GridLayouter<T> {
  const GridLayout();

  @override
  List<Widget> call(BuildContext context, GridSettingsBase settings,
      GridFrameState<T> state) {
    return [
      blueprint<T>(
        context,
        state.widget.functionality,
        state.selection,
        aspectRatio: settings.aspectRatio.value,
        columns: settings.columns.number,
        gridCell: (context, cell, idx) {
          return GridCell.frameDefault(
            context,
            idx,
            cell,
            hideTitle: settings.hideName,
            isList: isList,
            imageAlign: Alignment.center,
            animated: PlayAnimationNotifier.maybeOf(context) ?? false,
            state: state,
          );
        },
      )
    ];
  }

  static Widget blueprint<T extends CellBase>(
    BuildContext context,
    GridFunctionality<T> functionality,
    GridSelection<T> selection, {
    required int columns,
    required MakeCellFunc<T> gridCell,
    required double aspectRatio,
  }) {
    final getCell = CellProvider.of<T>(context);

    return SliverGrid.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: aspectRatio, crossAxisCount: columns),
      itemCount: functionality.refreshingStatus.mutation.cellCount,
      itemBuilder: (context, indx) {
        final cell = getCell(indx);

        return WrapSelection(
          selection: selection,
          thisIndx: indx,
          onPressed: cell.tryAsPressable(context, functionality, indx),
          description: cell.description(),
          functionality: functionality,
          selectFrom: null,
          child: gridCell(context, cell, indx),
        );
      },
    );
  }

  @override
  bool get isList => false;
}
