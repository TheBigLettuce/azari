// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell.dart';
import 'package:gallery/src/widgets/grid/sticker.dart';
import 'package:logging/logging.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../pages/image_view.dart';

mixin ImageViewPaletteMixin<T extends Cell> on State<ImageView<T>> {
  PaletteGenerator? currentPalette;
  PaletteGenerator? previousPallete;

  List<Widget>? currentStickers;
  List<Widget>? addButtons;
  List<Widget>? addInfo;

  void extractPalette(
      BuildContext context,
      T currentCell,
      GlobalKey<ScaffoldState> scaffoldKey,
      ScrollController scrollController,
      int currentPage,
      AnimationController animationController) {
    final t = currentCell.getCellData(false, context: context).thumb;
    if (t == null) {
      return;
    }

    PaletteGenerator.fromImageProvider(t).then((value) {
      setState(() {
        previousPallete = currentPalette;
        currentPalette = value;
        addInfo = currentCell.addInfo(context, () {
          widget.updateTagScrollPos(scrollController.offset, currentPage);
        },
            AddInfoColorData(
              borderColor: Theme.of(context).colorScheme.outlineVariant,
              foregroundColor: value.mutedColor?.bodyTextColor
                      .harmonizeWith(Theme.of(context).colorScheme.primary) ??
                  kListTileColorInInfo,
              systemOverlayColor: widget.systemOverlayRestoreColor,
            ));

        final b = currentCell.addButtons(context);

        addButtons = addInfo == null && b == null
            ? null
            : [
                if (b != null) ...b,
                if (addInfo != null)
                  IconButton(
                      onPressed: () {
                        scaffoldKey.currentState?.openEndDrawer();
                      },
                      icon: const Icon(Icons.info_outline)),
              ];

        currentStickers = currentCell
            .addStickers(context)
            ?.map((e) => StickerWidget(
                  Sticker(e.$1,
                      color: ColorTween(
                        begin: previousPallete?.dominantColor?.bodyTextColor
                                .harmonizeWith(
                                    Theme.of(context).colorScheme.primary)
                                .withOpacity(0.8) ??
                            kListTileColorInInfo,
                        end: currentPalette?.dominantColor?.bodyTextColor
                                .harmonizeWith(
                                    Theme.of(context).colorScheme.primary)
                                .withOpacity(0.8) ??
                            kListTileColorInInfo,
                      ).transform(animationController.value),
                      backgroundColor: ColorTween(
                        begin: previousPallete?.dominantColor?.color
                                .harmonizeWith(
                                    Theme.of(context).colorScheme.primary)
                                .withOpacity(0.5) ??
                            Colors.black.withOpacity(0.5),
                        end: currentPalette?.dominantColor?.color
                                .harmonizeWith(
                                    Theme.of(context).colorScheme.primary)
                                .withOpacity(0.5) ??
                            Colors.black.withOpacity(0.5),
                      ).transform(animationController.value)),
                  onPressed: e.$2,
                ))
            .toList();
        animationController.reset();
        animationController.forward(from: 0);
      });
    }).onError((error, stackTrace) {
      log("making palette for image_view",
          level: Level.SEVERE.value, error: error, stackTrace: stackTrace);
    });
  }
}
