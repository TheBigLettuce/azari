// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'dart:developer';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:logging/logging.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../pages/image_view.dart';

mixin ImageViewPaletteMixin<T extends Cell> on State<ImageView<T>> {
  PaletteGenerator? currentPalette;
  PaletteGenerator? previousPallete;

  void extractPalette(
      BuildContext context,
      T currentCell,
      GlobalKey<ScaffoldState> scaffoldKey,
      ScrollController scrollController,
      int currentPage,
      void Function() resetAnimation) {
    final t = currentCell.thumbnail();
    if (t == null) {
      return;
    }

    PaletteGenerator.fromImageProvider(t).then((value) {
      previousPallete = currentPalette;
      currentPalette = value;

      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(
          systemNavigationBarColor: value.dominantColor?.color
              .harmonizeWith(Theme.of(context).colorScheme.primary)
              .withOpacity(0.1),
        ),
      );

      resetAnimation();

      setState(() {});
    }).onError((error, stackTrace) {
      log("making palette for image_view",
          level: Level.SEVERE.value, error: error, stackTrace: stackTrace);
    });
  }
}
