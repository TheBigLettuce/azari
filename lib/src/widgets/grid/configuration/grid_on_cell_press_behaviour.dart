// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid/grid_frame.dart';
import 'package:gallery/src/widgets/image_view/image_view.dart';

abstract class GridOnCellPressedBehaviour {
  const GridOnCellPressedBehaviour();

  void launch<T extends Cell>(
    BuildContext gridContext,
    int startingCell,
    GridFrameState<T> state, {
    double? startingOffset,
    T? useCellInsteadIdx,
  });
}

class OverrideGridOnCellPressBehaviour implements GridOnCellPressedBehaviour {
  const OverrideGridOnCellPressBehaviour({
    this.onPressed = _doNothing,
  });

  static void _doNothing(
    BuildContext context,
    int idx,
    Cell? overrideCell,
  ) {}

  final void Function(
    BuildContext context,
    int idx,
    Cell? overrideCell,
  ) onPressed;

  @override
  void launch<T extends Cell>(
    BuildContext gridContext,
    int startingCell,
    GridFrameState<T> state, {
    double? startingOffset,
    T? useCellInsteadIdx,
  }) {
    state.widget.mainFocus.requestFocus();
    onPressed(gridContext, startingCell, useCellInsteadIdx);
  }
}

class DefaultGridOnCellPressBehaviour implements GridOnCellPressedBehaviour {
  const DefaultGridOnCellPressBehaviour();

  @override
  void launch<T extends Cell>(
    BuildContext gridContext,
    int startingCell,
    GridFrameState<T> state, {
    double? startingOffset,
    T? useCellInsteadIdx,
  }) {
    final functionality = state.widget.functionality;
    final imageDesctipion = state.widget.imageViewDescription;
    final mutation = state.mutation;

    state.inImageView = true;

    state.widget.mainFocus.requestFocus();

    final offsetGrid =
        state.controller.hasClients ? state.controller.offset : 0.0;
    final overlayColor =
        Theme.of(gridContext).colorScheme.background.withOpacity(0.5);

    functionality.selectionGlue.hideNavBar(true);

    Navigator.of(gridContext, rootNavigator: true)
        .push(MaterialPageRoute(builder: (context) {
      return ImageView<T>(
        key: imageDesctipion.imageViewKey,
        gridContext: gridContext,
        statistics: imageDesctipion.statistics,
        registerNotifiers: functionality.registerNotifiers,
        systemOverlayRestoreColor: overlayColor,
        updateTagScrollPos: (pos, selectedCell) =>
            functionality.updateScrollPosition?.call(offsetGrid),
        scrollUntill: state.tryScrollUntil,
        pageChange: imageDesctipion.pageChangeImage,
        onExit: () {
          state.inImageView = false;
          imageDesctipion.onExitImageView?.call();
        },
        ignoreEndDrawer: imageDesctipion.ignoreImageViewEndDrawer,
        addIcons: imageDesctipion.addIconsImage,
        focusMain: state.widget.mainFocus.requestFocus,
        infoScrollOffset: startingOffset,
        // predefinedIndexes: segTranslation,
        getCell: state.widget.getCell,
        // noteInterface: widget.noteInterface,
        cellCount: mutation.cellCount,
        download: functionality.download,
        startingCell:
            // segTranslation != null
            //     ? () {
            //         for (final (i, e) in segTranslation!.indexed) {
            //           if (e == startingCell) {
            //             return i;
            //           }
            //         }

            //         return 0;
            //       }()
            //     :
            startingCell,
        onNearEnd: () =>
            state.refreshingStatus.onNearEnd(state.widget.functionality),
      );
    })).then((value) => functionality.selectionGlue.hideNavBar(false));
  }
}
