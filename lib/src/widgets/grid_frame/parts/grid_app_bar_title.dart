// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_search_widget.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/page_description.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';

class GridAppBarTitle<T extends CellBase> extends StatelessWidget {
  final GridFrameState<T> state;
  final PageDescription? page;

  const GridAppBarTitle({
    super.key,
    required this.state,
    required this.page,
  });

  @override
  Widget build(BuildContext context) {
    final s = state.widget.functionality.search;

    if (state.atNotHomePage && page?.search == null) {
      return state.widget.description.pages!.switcherWidget(context, state);
    } else if (page?.search != null) {
      return page!.search!.search;
    }

    return switch (s) {
      EmptyGridSearchWidget() => const SizedBox.shrink(),
      OverrideGridSearchWidget() => s.widget.search,
      PageNameSearchWidget() => Text(
          state.widget.description.pageName ??
              state.widget.description.keybindsDescription,
        ),
    };
  }
}
