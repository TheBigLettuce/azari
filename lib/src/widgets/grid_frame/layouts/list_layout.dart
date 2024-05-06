// SPDX-License-Identifier: GPL-2.0-only
//
// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:gallery/src/db/services/services.dart";
import "package:gallery/src/interfaces/cell/cell.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_functionality.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_layouter.dart";
import "package:gallery/src/widgets/grid_frame/configuration/grid_mutation_interface.dart";
import "package:gallery/src/widgets/grid_frame/grid_frame.dart";
import "package:gallery/src/widgets/notifiers/selection_count.dart";

class ListLayout<T extends CellBase> implements GridLayouter<T> {
  const ListLayout({this.hideThumbnails = false});

  final bool hideThumbnails;

  @override
  bool get isList => true;

  @override
  List<Widget> call(
    BuildContext context,
    GridSettingsData settings,
    GridFrameState<T> state,
  ) {
    return [
      blueprint<T>(
        context,
        state.mutation,
        state.widget.functionality,
        state.selection,
        hideThumbnails: hideThumbnails,
      ),
    ];
  }

  static Widget blueprint<T extends CellBase>(
    BuildContext context,
    GridMutationInterface state,
    GridFunctionality<T> functionality,
    GridSelection<T> selection, {
    required bool hideThumbnails,
  }) {
    final getCell = CellProvider.of<T>(context);

    return SliverPadding(
      padding: const EdgeInsets.only(right: 8, left: 8),
      sliver: SliverList.builder(
        itemCount: state.cellCount,
        itemBuilder: (context, index) {
          final cell = getCell(index);

          return _tile(
            context,
            functionality,
            selection,
            cell: cell,
            index: index,
            hideThumbnails: hideThumbnails,
          );
        },
      ),
    );
  }

  static Widget _tile<T extends CellBase>(
    BuildContext context,
    GridFunctionality<T> functionality,
    GridSelection<T> selection, {
    required int index,
    required T cell,
    required bool hideThumbnails,
  }) {
    final thumbnail = cell.tryAsThumbnailable();

    return WrapSelection(
      selection: selection,
      selectFrom: null,
      limitedSize: true,
      description: cell.description(),
      onPressed: cell.tryAsPressable(context, functionality, index),
      functionality: functionality,
      thisIndx: index,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          SelectionCountNotifier.countOf(context);
          final isSelected = selection.isSelected(index);

          return DecoratedBox(
            decoration: ShapeDecoration(
              shape: const StadiumBorder(),
              color: isSelected
                  ? null
                  : index.isOdd
                      ? theme.colorScheme.secondary.withOpacity(0.1)
                      : theme.colorScheme.surfaceVariant.withOpacity(0.1),
            ),
            child: ListTile(
              textColor: isSelected ? theme.colorScheme.inversePrimary : null,
              leading: !hideThumbnails && thumbnail != null
                  ? CircleAvatar(
                      backgroundColor: theme.colorScheme.background,
                      foregroundImage: thumbnail,
                      onForegroundImageError: (_, __) {},
                    )
                  : null,
              title: Text(
                cell.alias(true),
                softWrap: false,
                style: TextStyle(
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withOpacity(0.8)
                      : index.isOdd
                          ? theme.colorScheme.onSurface.withOpacity(0.8)
                          : theme.colorScheme.onSurface.withOpacity(0.9),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    ).animate(key: cell.uniqueKey()).fadeIn();
  }
}
