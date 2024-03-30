// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gallery/src/db/base/grid_settings_base.dart';
import 'package:gallery/src/interfaces/cell/cell.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart';
import 'package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart';
import 'package:gallery/src/widgets/notifiers/selection_count.dart';

import '../grid_frame.dart';

class ListLayout<T extends Cell> implements GridLayouter<T> {
  const ListLayout({
    this.hideThumbnails = false,
    this.unpressable = false,
  });

  final bool hideThumbnails;
  final bool unpressable;

  @override
  bool get isList => true;

  @override
  List<Widget> call(BuildContext context, GridSettingsBase settings,
      GridFrameState<T> state) {
    return [
      blueprint<T>(
        context,
        state.mutation,
        state.widget.functionality,
        state.selection,
        state.widget.systemNavigationInsets.bottom,
        hideThumbnails: hideThumbnails,
        onPressed: unpressable
            ? null
            : (context, cell, idx) {
                state.widget.functionality.onPressed.launch(
                  context,
                  idx,
                  state.widget.functionality,
                );
              },
      )
    ];
  }

  static Widget blueprint<T extends Cell>(
    BuildContext context,
    GridMutationInterface<T> state,
    GridFunctionality<T> functionality,
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
          functionality,
          selection,
          index: index,
          systemNavigationInsets: systemNavigationInsets,
          hideThumbnails: hideThumbnails,
          onPressed: onPressed,
        ),
      );

  static Widget _tile<T extends Cell>(
    BuildContext context,
    GridFunctionality<T> functionality,
    GridSelection<T> selection, {
    required int index,
    required double systemNavigationInsets,
    required bool hideThumbnails,
    required void Function(BuildContext, T, int)? onPressed,
  }) {
    final cell = CellProvider.getOf<T>(context, index);

    return WrapSelection(
      selection: selection,
      selectFrom: null,
      functionality: functionality,
      thisIndx: index,
      child: Builder(
        builder: (context) {
          SelectionCountNotifier.countOf(context);

          return ListTile(
            textColor: selection.isSelected(index)
                ? Theme.of(context).colorScheme.inversePrimary
                : null,
            onLongPress: () => selection.selectOrUnselect(context, index),
            onTap: onPressed == null
                ? null
                : () => onPressed(context, cell, index),
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
          );
        },
      ),
    ).animate(key: cell.uniqueKey()).fadeIn();
  }
}
