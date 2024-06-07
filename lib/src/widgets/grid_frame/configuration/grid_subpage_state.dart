// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";

mixin GridSubpageState<T extends CellBase> on State<GridFrame<T>> {
  int currentPage = 0;
  double savedOffset = 0;

  bool get atHomePage => currentPage == 0;
  bool get atNotHomePage => !atHomePage;

  int currentPageF() => currentPage;

  void onSubpageSwitched(
    BuildContext context,
    int next,
    GridSelection<T> selection,
  ) =>
      onSubpageSwitchedGrid(next, selection, GridScrollNotifier.of(context));

  @protected
  void onSubpageSwitchedGrid(
    int next,
    GridSelection<T> selection,
    ScrollController controller,
  ) {
    selection.reset(true);

    if (atHomePage) {
      savedOffset = controller.offset;
    }

    currentPage = next;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (atHomePage && controller.offset == 0 && savedOffset != 0) {
        controller.position.animateTo(
          savedOffset,
          duration: const Duration(milliseconds: 200),
          curve: Easing.standard,
        );

        savedOffset = 0;
      }
    });

    setState(() {});
  }
}
