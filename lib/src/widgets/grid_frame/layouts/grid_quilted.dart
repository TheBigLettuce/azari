// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/grid_frame/parts/grid_cell.dart";

class GridQuiltedLayout<T extends CellBase> extends StatelessWidget {
  const GridQuiltedLayout({
    super.key,
    required this.randomNumber,
  });

  final int randomNumber;

  @override
  Widget build(BuildContext context) {
    final getCell = CellProvider.of<T>(context);
    final extras = GridExtrasNotifier.of<T>(context);
    final config = GridConfigurationNotifier.of(context);

    return SliverGrid.builder(
      itemCount: extras.functionality.refreshingStatus.mutation.cellCount,
      gridDelegate: SliverQuiltedGridDelegate(
        crossAxisCount: config.columns.number,
        repeatPattern: QuiltedGridRepeatPattern.inverted,
        pattern: config.columns.pattern(randomNumber),
      ),
      itemBuilder: (context, idx) {
        final cell = getCell(idx);

        return WrapSelection(
          thisIndx: idx,
          description: cell.description(),
          selection: extras.selection,
          onPressed: cell.tryAsPressable(context, extras.functionality, idx),
          functionality: extras.functionality,
          selectFrom: null,
          child: GridCell.frameDefault(
            context,
            idx,
            cell,
            imageAlign: Alignment.topCenter,
            hideTitle: config.hideName,
            isList: false,
            animated: PlayAnimationNotifier.maybeOf(context) ?? false,
          ),
        );
      },
    );
  }
}
