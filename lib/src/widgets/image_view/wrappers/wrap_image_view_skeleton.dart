// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/cell/sticker.dart';
import 'package:gallery/src/widgets/grid_frame/parts/sticker_widget.dart';
import 'package:palette_generator/palette_generator.dart';

import '../../notifiers/current_cell.dart';
import '../app_bar/app_bar.dart';

class WrapImageViewSkeleton<T extends Cell> extends StatelessWidget {
  final Widget child;
  final FocusNode mainFocus;
  final Widget? bottomAppBar;
  final Widget? endDrawer;
  final PaletteGenerator? currentPalette;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final List<Widget> addAppBarActions;

  const WrapImageViewSkeleton({
    super.key,
    required this.mainFocus,
    required this.scaffoldKey,
    required this.currentPalette,
    required this.bottomAppBar,
    required this.endDrawer,
    required this.child,
    required this.addAppBarActions,
  });

  @override
  Widget build(BuildContext context) {
    final currentCell = CurrentCellNotifier.of<T>(context);
    final b = currentCell.addButtons(context);

    final currentStickers = currentCell
        .addStickers(context)
        ?.map((e) => StickerWidget(
              Sticker(e.$1),
              onPressed: e.$2,
            ))
        .toList();

    return Scaffold(
      key: scaffoldKey,
      extendBodyBehindAppBar: true,
      extendBody: true,
      endDrawerEnableOpenDragGesture: false,
      resizeToAvoidBottomInset: false,
      bottomNavigationBar: bottomAppBar,
      endDrawer: endDrawer,
      appBar: PreferredSize(
          preferredSize: currentStickers == null
              ? const Size.fromHeight(kToolbarHeight + 4)
              : const Size.fromHeight(kToolbarHeight + 36 + 4),
          child: ImageViewAppBar<T>(
            stickers: currentStickers ?? const [],
            actions: addAppBarActions + (b ?? const []),
          )),
      body: child,
    );
  }
}
