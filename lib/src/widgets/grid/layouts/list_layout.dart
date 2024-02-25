// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/interfaces/grid/grid_layouter.dart';
import 'package:gallery/src/interfaces/grid/grid_column.dart';
import 'package:gallery/src/interfaces/grid/grid_mutation_interface.dart';

import '../grid_frame.dart';

class ListLayout<T extends Cell> implements GridLayouter<T> {
  final bool hideThumbnails;
  final bool unpressable;

  @override
  List<Widget> call(BuildContext context, GridFrameState<T> state) {
    return [
      blueprint<T>(
        context,
        state.mutation,
        state.selection,
        state.widget.systemNavigationInsets.bottom,
        hideThumbnails: hideThumbnails,
        onPressed: unpressable
            ? null
            : (context, cell, idx) {
                state.widget.functionality.onPressed.launch(
                  context,
                  idx,
                  state,
                );
              },
      )
    ];
  }

  static Widget blueprint<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection,
    double systemNavigationInsets, {
    required bool hideThumbnails,
    required void Function(BuildContext, T, int)? onPressed,
  }) =>
      SliverList.separated(
        separatorBuilder: (context, index) => const Divider(
          height: 1,
        ),
        itemCount: state.cellCount,
        itemBuilder: (context, index) => _tile(
          context,
          state,
          selection,
          index: index,
          systemNavigationInsets: systemNavigationInsets,
          hideThumbnails: hideThumbnails,
          onPressed: onPressed,
        ),
      );

  static Widget _tile<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridSelection<T> selection, {
    required int index,
    required double systemNavigationInsets,
    required bool hideThumbnails,
    required void Function(BuildContext, T, int)? onPressed,
  }) {
    final cell = state.getCell(index);
    final selected = selection.isSelected(index);

    return WrapSelection(
      actionsAreEmpty: selection.addActions.isEmpty,
      selectUntil: (i) => selection.selectUnselectUntil(i, state),
      thisIndx: index,
      isSelected: selected,
      ignoreSwipeGesture: selection.ignoreSwipe,
      selectionEnabled: selection.isNotEmpty,
      currentScroll: selection.controller,
      bottomPadding: systemNavigationInsets,
      selectUnselect: () => selection.selectOrUnselect(context, index),
      child: ListTile(
        textColor:
            selected ? Theme.of(context).colorScheme.inversePrimary : null,
        onLongPress: () => selection.selectOrUnselect(context, index),
        onTap: onPressed == null ? null : () => onPressed(context, cell, index),
        leading: !hideThumbnails && cell.thumbnail() != null
            ? CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.background,
                foregroundImage: cell.thumbnail(),
                onForegroundImageError: (_, __) {},
              )
            : null,
        title: Text(
          cell.alias(true),
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ).animate(key: cell.uniqueKey()).fadeIn();
  }

  @override
  GridColumn? get columns => null;

  @override
  bool get isList => true;

  const ListLayout({
    this.hideThumbnails = false,
    this.unpressable = false,
  });
}
