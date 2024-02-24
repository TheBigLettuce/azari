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
import 'package:gallery/src/widgets/grid/grid_cell.dart';

import '../grid_frame.dart';

class GridQuiltedLayout<T extends Cell> implements GridLayouter<T> {
  final GridAspectRatio aspectRatio;

  final int gridSeed;

  @override
  final GridColumn columns;

  @override
  List<Widget> call(BuildContext context, GridFrameState<T> state) {
    return [
      GridLayouts.quiltedGrid<T>(
        context,
        state.mutation,
        state.selection,
        randomNumber: gridSeed,
        systemNavigationInsets: state.widget.systemNavigationInsets.bottom,
        gridCell: (BuildContext context, int idx) => GridCell.frameDefault(
          context,
          idx,
          functionality: state.widget.functionality,
          description: state.widget.description,
          imageViewDescription: state.widget.imageViewDescription,
          selection: state.selection,
        ),
        columns: columns,
      )
    ];
  }

  @override
  bool get isList => false;

  const GridQuiltedLayout(
    this.columns,
    this.aspectRatio, {
    required this.gridSeed,
  });
}
