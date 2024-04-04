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

class PageSwitchingWidget<T extends CellBase> extends StatelessWidget {
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
                icon: _IconWithCount(
                  count: e.$2.count,
                  icon: Icon(e.$2.icon),
                  background: e.$1 + 1 == state.currentPage
                      ? Theme.of(context).colorScheme.secondary
                      : Theme.of(context).colorScheme.surfaceVariant,
                  foreground: e.$1 + 1 == state.currentPage
                      ? Theme.of(context).colorScheme.onSecondary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                value: e.$1 + 1,
              )),
        ],
        selected: {state.currentPage},
      ),
    );
  }
}

class _IconWithCount extends StatelessWidget {
  final Icon icon;
  final int count;
  final Color background;
  final Color foreground;

  const _IconWithCount({
    super.key,
    required this.count,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return count.isNegative
        ? icon
        : Row(
            children: [
              icon,
              const Padding(padding: EdgeInsets.only(left: 2)),
              Badge.count(
                backgroundColor: background,
                textColor: foreground,
                alignment: Alignment.bottomCenter,
                count: count,
              )
            ],
          );
  }
}
