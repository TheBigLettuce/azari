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

import 'grid_functionality.dart';
import 'image_view_description.dart';

abstract class GridOnCellPressedBehaviour {
  const GridOnCellPressedBehaviour();

  void launch<T extends Cell>(
    BuildContext gridContext, {
    required GridFunctionality<T> functionality,
    required ImageViewDescription<T> imageViewDescription,
    required GridDescription<T> gridDescription,
    required int startingCell,
    double? startingOffset,
  });
}

class DefaultGridOnCellPressBehaviour implements GridOnCellPressedBehaviour {
  const DefaultGridOnCellPressBehaviour();

  @override
  void launch<T extends Cell>(
    BuildContext gridContext, {
    required GridFunctionality<T> functionality,
    required ImageViewDescription<T> imageViewDescription,
    required GridDescription<T> gridDescription,
    required int startingCell,
    double? startingOffset,
  }) {
    if (widget.overrideOnPress != null) {
      widget.mainFocus.requestFocus();
      widget.overrideOnPress!(gridContext, cell);
      return;
    }
    inImageView = true;

    widget.mainFocus.requestFocus();

    final offsetGrid = controller.hasClients ? controller.offset : 0.0;
    final overlayColor =
        Theme.of(gridContext).colorScheme.background.withOpacity(0.5);

    widget.selectionGlue.hideNavBar(true);

    Navigator.of(gridContext, rootNavigator: true)
        .push(MaterialPageRoute(builder: (context) {
      return ImageView<T>(
          key: imageViewKey,
          gridContext: gridContext,
          statistics: imageViewDescription.statistics,
          registerNotifiers: functionality.registerNotifiers,
          systemOverlayRestoreColor: overlayColor,
          updateTagScrollPos: (pos, selectedCell) => functionality
              .updateScrollPosition
              ?.call(offsetGrid, infoPos: pos, selectedCell: selectedCell),
          scrollUntill: _scrollUntill,
          pageChange: widget.pageChangeImage,
          onExit: () {
            inImageView = false;
            widget.onExitImageView?.call();
          },
          ignoreEndDrawer: imageViewDescription.ignoreImageViewEndDrawer,
          addIcons: widget.addIconsImage,
          focusMain: () {
            grd.mainFocus.requestFocus();
          },
          infoScrollOffset: startingOffset,
          predefinedIndexes: segTranslation,
          getCell: _state.getCell,
          // noteInterface: widget.noteInterface,
          cellCount: _state.cellCount,
          download: widget.download,
          startingCell: segTranslation != null
              ? () {
                  for (final (i, e) in segTranslation!.indexed) {
                    if (e == startingCell) {
                      return i;
                    }
                  }

                  return 0;
                }()
              : startingCell,
          onNearEnd: widget.loadNext == null ? null : _state._onNearEnd);
    })).then((value) => widget.selectionGlue.hideNavBar(false));
  }
}
