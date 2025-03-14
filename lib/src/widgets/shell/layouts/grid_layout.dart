// Copyright (C) 2023 Bob
// This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation; version 2.
// This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
// You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

import "package:azari/src/db/services/resource_source/resource_source.dart";
import "package:azari/src/db/services/resource_source/source_storage.dart";
import "package:azari/src/widgets/grid_cell/cell.dart";
import "package:azari/src/widgets/shell/layouts/placeholders.dart";
import "package:azari/src/widgets/shell/parts/shell_configuration.dart";
import "package:azari/src/widgets/shell/shell_scope.dart";
import "package:flutter/material.dart";

class GridLayout<T extends CellBase> extends StatefulWidget {
  const GridLayout({
    super.key,
    required this.source,
    this.buildEmpty,
    required this.progress,
    required this.selection,
  });

  final ShellSelectionHolder? selection;

  final ReadOnlyStorage<int, T> source;
  final RefreshingProgress progress;

  final Widget Function(Object? error)? buildEmpty;

  @override
  State<GridLayout<T>> createState() => _GridLayoutState();
}

class _GridLayoutState<T extends CellBase> extends State<GridLayout<T>>
    with ResetSelectionOnUpdate<T, GridLayout<T>> {
  @override
  ReadOnlyStorage<int, T> get source => widget.source;

  @override
  ShellSelectionHolder? get selection => widget.selection;

  @override
  Widget build(BuildContext context) {
    final config = ShellConfiguration.of(context);

    return EmptyWidgetOrContent(
      source: source,
      progress: widget.progress,
      buildEmpty: widget.buildEmpty,
      child: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          childAspectRatio: config.aspectRatio.value,
          crossAxisCount: config.columns.number,
        ),
        itemCount: source.count,
        itemBuilder: (context, idx) {
          final cell = widget.source[idx];

          return cell.buildCell<T>(
            context,
            idx,
            cell,
            hideTitle: config.hideName,
            isList: false,
            imageAlign: Alignment.center,
            animated: PlayAnimations.maybeOf(context) ?? false,
            wrapSelection: (child) =>
                cell.tryAsSelectionWrapperable()?.buildSelectionWrapper<T>(
                      context: context,
                      thisIndx: idx,
                      onPressed: cell.tryAsPressable(
                        context,
                        idx,
                      ),
                      description: cell.description(),
                      selectFrom: null,
                      child: child,
                    ) ??
                WrapSelection<T>(
                  thisIndx: idx,
                  onPressed: cell.tryAsPressable(context, idx),
                  description: cell.description(),
                  selectFrom: null,
                  child: child,
                ),
          );
        },
      ),
    );
  }
}
