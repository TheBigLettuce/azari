// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_subpage_state.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/page_switcher.dart';
import 'package:gallery/src/widgets/grid_frame/grid_frame.dart';

class PageSwitchingWidget<T extends Cell> extends StatelessWidget {
  final EdgeInsets padding;
  final GridSubpageState<T> state;
  final GridSelection<T> selection;
  final ScrollController controller;
  final PageSwitcher pageSwitcher;

  const PageSwitchingWidget({
    super.key,
    required this.padding,
    required this.state,
    required this.pageSwitcher,
    required this.controller,
    required this.selection,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SegmentedButton<int>(
        emptySelectionAllowed: true,
        style: const ButtonStyle(
            side: MaterialStatePropertyAll(BorderSide.none),
            visualDensity: VisualDensity.compact),
        showSelectedIcon: false,
        onSelectionChanged: (set) {
          if (set.isEmpty) {
            return;
          }

          state.onSubpageSwitched(set.first, selection, controller);
        },
        segments: [
          ButtonSegment(
            icon:
                pageSwitcher.overrideHomeIcon ?? const Icon(Icons.home_rounded),
            value: 0,
          ),
          ...pageSwitcher.pages.indexed.map((e) => ButtonSegment(
                icon: e.$2,
                // label: Text(e.$2),
                value: e.$1 + 1,
              )),
        ],
        selected: {state.currentPage},
      ),
    );
  }
}
